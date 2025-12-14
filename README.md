# MuseDash

本项目基于 FPGA 实现了一个类 Muse Dash 的节奏游戏原型，整体采用“软件预处理谱面 → 硬件实时读 ROM 判定/显示”的软硬件协同方式：
- 软件侧：生成/校验谱面（`charts/`）、将谱面编译为 Verilog ROM（`chart_engine/`）、对谱面做统计与可视化（`chart_analysis/`）、以及按空格触发的音频/节拍播放（`music_sync/`）。
- 硬件侧：Verilog 逻辑按地址读取 `ROM` 输出，驱动判定与显示（`verilog/`）。

## 快速开始
1. 安装依赖：`pip install -r requirements.txt`
2. 启动本地服务（同时提供静态前端与 API）：`python server.py --host 127.0.0.1 --port 8000`
3. 浏览器打开：`http://127.0.0.1:8000/frontend/`

## 目录与职责
- `charts/`：谱面与音频资源（格式见 `charts/README.md`）。
- `chart_engine/`：谱面校验与“TXT → Verilog ROM”编译（见 `chart_engine/doc/README.md`、`chart_engine/doc/Description.md`）。
- `chart_analysis/`：谱面统计与可视化，输出 `chart_analysis/outputs/protocol.json` + PNG + `*_summary.json`（见 `chart_analysis/doc/README.md`、`chart_analysis/doc/chart_analysis_report.md`）。
- `music_sync/`：按空格播放同名 mp3；无音频时按谱面时间线输出节拍提示音（见 `music_sync/doc/README.md`、`music_sync/doc/music_sync.md`）。
- `frontend/`：静态 Web UI（实现说明见 `frontend/doc/frontend.md`）。
- `server.py`：开发服务端，提供前端调用的接口（`/chart_analysis/run`、`/chart_engine/process`、`/music_sync/play` 等）。
- `verilog/`：硬件工程；`chart_engine.process_chart` 会更新 `verilog/MuseDash.v` 的 `div_cnt` 并生成 `verilog/ROM.v`（或自定义输出名）。
