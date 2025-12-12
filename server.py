#!/usr/bin/env python3
"""Lightweight dev server for the MuseDash frontend with basic API hooks."""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.parse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock

ROOT = Path(__file__).resolve().parent
QUARTUS_QSF = ROOT / "quartus" / "MuseDash.qsf"
CHART_ANALYSIS_SCRIPT = ROOT / "chart_analysis" / "chart_analysis.py"
MUSIC_SYNC_SCRIPT = ROOT / "music_sync" / "player.py"
ANALYSIS_LOCK = Lock()
MUSIC_SYNC_LOCK = Lock()
MUSIC_SYNC_PROC = None


def _open_with_system(path: Path):
    """Open a file with the OS default handler."""
    if not path.exists():
        return False, f"{path} not found"
    try:
        if sys.platform.startswith("win"):
            os.startfile(path)  # type: ignore[attr-defined]
        elif sys.platform == "darwin":
            subprocess.Popen(["open", str(path)])
        else:
            subprocess.Popen(["xdg-open", str(path)])
        return True, f"launched {path.name}"
    except Exception as exc:  # pragma: no cover - best effort helper
        return False, str(exc)


class FrontendHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/quartus/open":
            self._handle_open_quartus()
            return
        if parsed.path == "/chart_engine/process":
            self._handle_chart_process(parsed)
            return
        if parsed.path == "/chart_engine/generate_random":
            self._handle_generate_random()
            return
        if parsed.path == "/chart_analysis/run":
            self._handle_chart_analysis_run()
            return
        if parsed.path == "/music_sync/play":
            self._handle_music_sync(parsed)
            return
        if parsed.path == "/music_sync/stop":
            self._handle_music_sync_stop()
            return
        self.send_error(404, "Unknown POST endpoint")

    def _handle_open_quartus(self):
        ok, msg = _open_with_system(QUARTUS_QSF)
        status = 200 if ok else 500
        self._respond_json({"success": ok, "message": msg}, status=status)

    def _respond_json(self, payload, status=200):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _handle_chart_analysis_run(self):
        if not CHART_ANALYSIS_SCRIPT.exists():
            self._respond_json({"success": False, "message": f"{CHART_ANALYSIS_SCRIPT.name} not found"}, status=500)
            return
        if not ANALYSIS_LOCK.acquire(blocking=False):
            self._respond_json({"success": False, "message": "chart_analysis already running"}, status=409)
            return
        try:
            print(f"[server] chart_analysis requested from {self.client_address}")
            success, message = run_chart_analysis_script()
            status = 200 if success else 500
            self._respond_json({"success": success, "message": message}, status=status)
        finally:
            ANALYSIS_LOCK.release()

    def _handle_generate_random(self):
        try:
            from chart_engine.chart_engine import generate_random_chart
        except Exception as exc:
            self._respond_json({"success": False, "message": f"import chart_engine failed: {exc}"}, status=500)
            return

        seed = time.time_ns()
        charts_dir = ROOT / "charts" / "Random"
        try:
            output = generate_random_chart(
                charts_dir,
                name="Random",
                bpm=None,
                length_seconds=None,
                seed=seed,
            )
        except Exception as exc:
            self._respond_json({"success": False, "message": f"generate_random exception: {exc}"}, status=500)
            return

        if output is None:
            self._respond_json({"success": False, "message": "generate_random failed (None)"}, status=500)
            return

        self._respond_json(
            {
                "success": True,
                "message": f"generated {output.name} with seed={seed}",
                "path": str(output),
                "seed": seed,
            }
        )

    def _handle_chart_process(self, parsed):
        try:
            from chart_engine.chart_engine import process_chart
        except Exception as exc:
            self._respond_json({"success": False, "message": f"import chart_engine failed: {exc}"}, status=500)
            return

        qs = urllib.parse.parse_qs(parsed.query)
        chart_name = qs.get("name", [None])[0]
        output_name = qs.get("output", ["ROM.v"])[0]
        if not chart_name:
            self._respond_json({"success": False, "message": "missing chart name"}, status=400)
            return

        try:
            ok = process_chart(chart_name, output_filename=output_name)
        except Exception as exc:
            self._respond_json({"success": False, "message": f"process_chart exception: {exc}"}, status=500)
            return

        if not ok:
            self._respond_json({"success": False, "message": f"process_chart failed for {chart_name}"}, status=500)
            return

        self._respond_json(
            {"success": True, "message": f"processed {chart_name} -> verilog/{output_name}"}
        )

    def _handle_music_sync(self, parsed):
        if not MUSIC_SYNC_SCRIPT.exists():
            self._respond_json({"success": False, "message": f"{MUSIC_SYNC_SCRIPT.name} not found"}, status=500)
            return
        qs = urllib.parse.parse_qs(parsed.query)
        chart_name = qs.get("name", [None])[0]
        if not chart_name:
            self._respond_json({"success": False, "message": "missing chart name"}, status=400)
            return
        ok, msg = launch_music_sync(chart_name)
        status = 200 if ok else 500
        self._respond_json({"success": ok, "message": msg}, status=status)

    def _handle_music_sync_stop(self):
        stopped, msg = stop_music_sync()
        status = 200 if stopped else 500
        self._respond_json({"success": stopped, "message": msg}, status=status)


def run_chart_analysis_script():
    python_exe = sys.executable or "python"
    cmd = [python_exe, str(CHART_ANALYSIS_SCRIPT)]
    try:
        print(f"[server] running: {' '.join(cmd)}")
        proc = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True)
    except Exception as exc:
        print(f"[server] failed to spawn chart_analysis: {exc}")
        return False, f"failed to spawn chart_analysis: {exc}"
    output = (proc.stdout or proc.stderr or "").strip()
    message = output if output else f"chart_analysis exited with {proc.returncode}"
    print(f"[server] chart_analysis finished rc={proc.returncode}")
    return proc.returncode == 0, message


def stop_music_sync():
    """Stop existing music_sync process if running."""
    global MUSIC_SYNC_PROC
    with MUSIC_SYNC_LOCK:
        proc = MUSIC_SYNC_PROC
        MUSIC_SYNC_PROC = None
    if proc is None:
        return True, "no music_sync process"
    if proc.poll() is None:
        try:
            proc.terminate()
            try:
                proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()
            return True, "stopped previous music_sync"
        except Exception as exc:
            return False, f"failed to stop music_sync: {exc}"
    return True, "music_sync already exited"


def launch_music_sync(chart_name: str):
    """Launch player.py, stopping any previous instance."""
    stop_music_sync()
    python_exe = sys.executable or "python"
    cmd = [python_exe, str(MUSIC_SYNC_SCRIPT), chart_name]
    try:
        proc = subprocess.Popen(cmd, cwd=str(ROOT))
        with MUSIC_SYNC_LOCK:
            global MUSIC_SYNC_PROC
            MUSIC_SYNC_PROC = proc
        return True, f"player started for {chart_name}"
    except Exception as exc:
        return False, f"launch player failed: {exc}"


def run_server(host: str, port: int):
    handler_cls = partial(FrontendHandler, directory=str(ROOT))
    httpd = ThreadingHTTPServer((host, port), handler_cls)
    print(f"Serving {ROOT} on http://{host}:{port}")
    httpd.serve_forever()


def main():
    parser = argparse.ArgumentParser(description="Serve frontend with simple API helpers")
    parser.add_argument("--host", default="127.0.0.1", help="Bind address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")
    args = parser.parse_args()
    run_server(args.host, args.port)


if __name__ == "__main__":
    main()
