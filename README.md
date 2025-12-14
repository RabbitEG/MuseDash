# MuseDash

本项目基于 FPGA 实现了一个类 Muse Dash 的节奏游戏原型，整体采用“软件预处理谱面 → 硬件实时读 ROM 判定/显示”的软硬件协同方式：
- 软件侧：生成/校验谱面（`charts/`）、将谱面编译为 Verilog ROM（`chart_engine/`）、对谱面做统计与可视化（`chart_analysis/`）、以及按空格触发的音频/节拍播放（`music_sync/`）。
- 硬件侧：Verilog 逻辑按地址读取 `ROM` 输出，驱动判定与显示（`verilog/`）。

核心工作流是：选择/生成谱面 → 运行 `chart_engine.process_chart` 生成 `verilog/ROM.v` 并同步 `verilog/MuseDash.v` 的 BPM 分频参数 → 使用 Quartus 编译 Verilog 工程 → 下载到 DE2-115 板卡运行。

## 快速开始
1. 安装依赖：`pip install -r requirements.txt`
2. 启动本地服务（同时提供静态前端与 API）：`python server.py --host 127.0.0.1 --port 8000`
3. 浏览器打开：`http://127.0.0.1:8000/frontend/`

## 硬件上板流程（Quartus + DE2-115）

1. 生成/更新硬件要用的谱面 ROM 与 BPM：
   - 前端：在页面中选曲后点击“写入 BPM & ROM”（调用 `POST /chart_engine/process?name=<曲目名>&output=ROM.v`）。
   - 或命令行：在代码里调用 `chart_engine.process_chart("<曲目名>")`（默认输出 `verilog/ROM.v`）。
2. 打开 Quartus 工程：`quartus/MuseDash.qpf`（或 `quartus/MuseDash.qsf`）。
   - 工程已引用 `../verilog/ROM.v` 与 `../verilog/MuseDash.v`；每次更换谱面后需要重新编译以生效。
3. 编译生成 bitstream（`.sof`）：在 Quartus 中执行 Compile（Start Compilation）。
4. 下载到 DE2-115：打开 Programmer，选择 USB-Blaster（或等价下载器），加载 `quartus/output_files/` 下的 `.sof` 并 Start。

提示：如果只更新了谱面（`verilog/ROM.v`）或 BPM（`verilog/MuseDash.v` 的 `div_cnt`），硬件侧仍需要重新编译并重新下载。

## 目录与职责
- `charts/`：谱面与音频资源（格式见 `charts/README.md`）。
- `chart_engine/`：谱面校验与“TXT → Verilog ROM”编译（见 `chart_engine/doc/README.md`、`chart_engine/doc/Description.md`）。
- `chart_analysis/`：谱面统计与可视化，输出 `chart_analysis/outputs/protocol.json` + PNG + `*_summary.json`（见 `chart_analysis/doc/README.md`、`chart_analysis/doc/chart_analysis_report.md`）。
- `music_sync/`：按空格播放同名 mp3；无音频时按谱面时间线输出节拍提示音（见 `music_sync/doc/README.md`、`music_sync/doc/music_sync.md`）。
- `frontend/`：静态 Web UI（实现说明见 `frontend/doc/frontend.md`）。
- `server.py`：开发服务端，提供前端调用的接口（`/chart_analysis/run`、`/chart_engine/process`、`/music_sync/play` 等）。
- `verilog/`：硬件源码；Quartus 工程（`quartus/`）会读取这里的模块文件进行综合与下载。`chart_engine.process_chart` 会更新 `verilog/MuseDash.v` 的 `div_cnt` 并生成 `verilog/ROM.v`（或自定义输出名）。
- `quartus/`：Quartus 工程目录（`MuseDash.qpf/.qsf`、编译输出、仿真与下载相关文件）。
