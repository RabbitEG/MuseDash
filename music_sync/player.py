"""
主要接口：listen_and_play(chart_name_or_path)
- 有音频：播放对应 mp3；
- 无音频：解析谱面 txt，以谱面时间线做节拍（含 hold/tap），不再回退固定节拍；
- 再次按空格可结束监听并停止当前播放。
"""
import os
import sys
import time
import math
import threading
from array import array
import pygame
import keyboard

try:
    import winsound  # Windows 提示音
except Exception:  # pragma: no cover - 非 Windows 环境
    winsound = None

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TICKS_PER_BEAT = 4

pygame_inited = False
CLICK_SOUND = None


def _init_pygame():
    """初始化 pygame mixer（只初始化一次）。"""
    global pygame_inited
    if not pygame_inited:
        try:
            pygame.mixer.init()
            pygame_inited = True
        except Exception as e:
            print(f"[ERROR] pygame 初始化失败：{e}")
            pygame_inited = False


def _play_async(path):
    """后台播放 MP3，避免阻塞键盘监听。"""
    if not os.path.exists(path):
        print(f"[ERROR] 音频文件不存在：{path}")
        return

    def _worker():
        _init_pygame()
        try:
            pygame.mixer.music.load(path)
            pygame.mixer.music.play()
        except Exception as e:
            print(f"[ERROR] 播放失败：{e}")

    threading.Thread(target=_worker, daemon=True).start()


def _stop_music():
    if pygame_inited:
        try:
            pygame.mixer.music.stop()
        except Exception:
            pass


def _tick_to_seconds(tick, bpm):
    # tick -> 拍 -> 秒： (tick / 4) 拍；每拍 60 / bpm 秒
    return (tick / TICKS_PER_BEAT) * (60.0 / bpm)


def _parse_chart(chart_path):
    """解析谱面，返回 bpm 和所有事件时间（tick）。"""
    if not os.path.exists(chart_path):
        return None, []
    try:
        with open(chart_path, "r", encoding="utf-8") as f:
            lines = [ln.strip() for ln in f.readlines() if ln.strip()]
    except Exception as exc:
        print(f"[WARN] 读取谱面失败: {exc}")
        return None, []
    if not lines or not lines[0].startswith("bpm="):
        print("[WARN] 谱面缺少 bpm= 头部")
        return None, []
    try:
        bpm = float(lines[0].split("=", 1)[1])
        if bpm <= 0:
            raise ValueError("bpm <= 0")
    except Exception as exc:
        print(f"[WARN] 解析 BPM 失败: {exc}")
        bpm = None

    events = []
    for ln in lines[1:]:
        if not (ln.startswith("(") and ln.endswith(")")):
            continue
        body = ln[1:-1]
        parts = [p.strip() for p in body.split(",")]
        if len(parts) != 3:
            continue
        try:
            tick = int(parts[0])
        except Exception:
            continue
        events.append(tick)
    events.sort()
    return bpm, events


def _beep():
    """简易节拍提示音，优先用 pygame click，其次 winsound，再退控制台铃声。"""
    snd = _get_click_sound()
    if snd is not None:
        try:
            snd.play()
            return
        except Exception:
            pass
    if winsound:
        try:
            winsound.Beep(880, 80)
            return
        except Exception:
            pass
    # 退化为控制台提示
    sys.stdout.write("\a")
    sys.stdout.flush()


def _get_click_sound():
    """生成/缓存一个短促的点击音，用于无 mp3 的节拍提示。"""
    global CLICK_SOUND
    if CLICK_SOUND is not None:
        return CLICK_SOUND
    _init_pygame()
    if not pygame_inited:
        return None
    try:
        sample_rate = 44100
        duration = 0.06  # 秒
        freq = 880
        volume = 0.4
        total_samples = int(sample_rate * duration)
        samples = array("h")
        for n in range(total_samples):
            val = int(volume * 32767 * math.sin(2 * math.pi * freq * n / sample_rate))
            samples.append(val)
        snd = pygame.mixer.Sound(buffer=samples.tobytes())
        CLICK_SOUND = snd
        return snd
    except Exception as exc:
        print(f"[WARN] 生成点击音失败：{exc}")
        return None


def _play_timeline(chart_name, bpm, ticks, stop_evt):
    """根据谱面时间线输出节拍，支持空格停止。"""
    if not ticks:
        print("[INFO] 谱面无事件，使用均匀节拍。")
        ticks = list(range(0, 64 * TICKS_PER_BEAT, TICKS_PER_BEAT))
    use_bpm = bpm if bpm and bpm > 0 else 120.0
    start = time.monotonic()
    for tick in ticks:
        if stop_evt.is_set():
            break
        target = _tick_to_seconds(tick, use_bpm)
        # 睡眠到事件时间
        while True:
            if stop_evt.is_set():
                break
            now = time.monotonic() - start
            delta = target - now
            if delta <= 0:
                break
            time.sleep(min(delta, 0.01))
        if stop_evt.is_set():
            break
        _beep()
    print(f"[INFO] 谱面节拍结束：{chart_name}")


def listen_and_play(chart_name):
    """
    监听键盘：
      - 第一次按空格：若有音频则播放音频，否则解析谱面按节拍播放；
      - 再按空格：停止当前播放并退出监听。
    """
    audio_path = None
    chart_path = None

    # 直接路径或曲名
    if os.path.isfile(chart_name):
        if chart_name.lower().endswith(".mp3"):
            audio_path = chart_name
        else:
            chart_path = chart_name
    else:
        folder = os.path.abspath(os.path.join(BASE_DIR, "..", "charts", chart_name))
        candidate_audio = os.path.join(folder, f"{chart_name}.mp3")
        candidate_chart = os.path.join(folder, f"{chart_name}.txt")
        if os.path.exists(candidate_audio):
            audio_path = candidate_audio
            print(f"[INFO] 使用曲目音频：{audio_path}")
        elif os.path.exists(candidate_chart):
            chart_path = candidate_chart
            print(f"[INFO] 未找到音频，改用谱面节拍：{chart_path}")
        else:
            print(f"[WARN] 未找到音频或谱面，使用默认节拍（120 BPM）。")

    print("\n=== Music Sync Start ===")
    print("首次空格：播放；再次空格：停止并退出；Ctrl+C 强退\n")

    playing = False
    stop_evt = threading.Event()
    timeline_thread = None

    try:
        while True:
            if keyboard.is_pressed("space"):
                if not playing:
                    print("[EVENT] SPACE → 开始播放")
                    playing = True
                    stop_evt.clear()
                    if audio_path:
                        _play_async(audio_path)
                    else:
                        bpm, ticks = _parse_chart(chart_path) if chart_path else (None, [])
                        timeline_thread = threading.Thread(
                            target=_play_timeline,
                            args=(chart_name, bpm, ticks, stop_evt),
                            daemon=True,
                        )
                        timeline_thread.start()
                else:
                    print("[EVENT] SPACE → 停止并退出")
                    stop_evt.set()
                    _stop_music()
                    if timeline_thread and timeline_thread.is_alive():
                        timeline_thread.join(timeout=1.0)
                    break
                time.sleep(0.35)  # 去抖动
            time.sleep(0.01)
    except KeyboardInterrupt:
        stop_evt.set()
        _stop_music()
        if timeline_thread and timeline_thread.is_alive():
            timeline_thread.join(timeout=1.0)
        print("\n退出监听。")


def main():
    """
    调试入口：python music_sync/player.py songName
    例如：python music_sync/player.py Cthugha
    """
    if len(sys.argv) < 2:
        print("用法：python player.py <曲目名或路径>")
        return
    listen_and_play(sys.argv[1])


if __name__ == "__main__":
    main()
