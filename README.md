# MuseDash
本项目基于 FPGA 实现了一个类 Muse Dash 的节奏游戏，整体采用软硬件协同架构完成。灵感来自原作的节奏判定机制，我们通过自定义 chart 格式（含 BPM、TAP / HOLD_START / HOLD_MIDDLE 等 note 类型）、软件侧生成 ROM、硬件侧实时解析并显示谱面来完整复现核心玩法。
谱面在 TextLCD 上以两轨道从右向左滚动；玩家通过按键控制上下轨，在 note 抵达最左侧判定线时进行输入。判定逻辑以 Verilog 实现，包括 PERFECT / GOOD / MISS 三档结果，并通过七段数码管实时显示当前判定与累计得分。

硬件部分采用分布式模块化设计：Address Generator 负责按节拍读取 ROM，Queue 负责滑动窗口式数据缓存，Judgement 模块实现完整的 TAP/HOLD 判定 FSM，Score Accumulator 用 BCD 加法器链实现实时计分，TextLCD 模块完成双行帧缓冲与显示驱动。软件侧则通过 C++ 工具链自动将谱面转换为可综合的 Verilog ROM 文件，实现快速迭代。
整体系统在 DE2-115 上成功跑通，完成了谱面显示、按键输入、节奏判定、分数累计等核心功能，较好地还原了 Muse Dash 的玩法风格。未来可扩展方向包括音频播放、键盘输入、VGA 图形化界面、多曲目支持与更完整的游戏 UI。

## 项目概述
- 目标：将 Muse Dash 移植到 FPGA，软件侧包含谱面生成、分析、前端展示、音乐同步。
- 主要子模块：
  - `chart_engine/`：生成 ROM.v、更新 BPM（接口占位：`chart_check`、`process_chart`、`generate_random_chart`）。
  - `chart_analysis/`：谱面统计与可视化，输出协议/图表/summary（占位）。
  - `frontend/`：前端入口，模式选择、写入 ROM/BPM、展示分析图与摘要、音频预览（需后端接口支持）。
  - `music_sync/`：空格播放同名音频/节拍的接口占位，探索软硬件协同方案。
  - `charts/`：谱面与音频存放，含 Random。
  - `verilog/`：硬件文件，ROM 输出目标 `verilog/rom.v`。
  - `chart_engine/legacy_cpp/`：原 C++ 流程参考。

## 目录导航
- `chart_engine/doc/README.md`：引擎要求与接口说明。
- `chart_analysis/doc/README.md`：分析/协议/输出说明。
- `frontend/doc/README.md`：前端交互与对接说明。
- `music_sync/doc/README.md`：播放接口与协同思路。
- `charts/README.md`：谱面格式与校验要求。

## 依赖安装与运行
1. 确保已安装 Python 3.9+ 和 pip（推荐在虚拟环境中执行）。
2. 在项目根目录安装统一依赖：
   ```bash
   pip install -r requirements.txt
   ```

## 前端启动方式
1. 终端切换到项目根目录 `MuseDash`
2. 推荐使用带接口的本地服务（支持“打开 Quartus”等按钮）：
   ```bash
   python server.py --port 8000
   ```
3. 浏览器打开：
   ```
   http://localhost:8000/frontend/
   ```
