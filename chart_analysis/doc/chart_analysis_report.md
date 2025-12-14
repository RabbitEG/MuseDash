# 谱面可视化分析模块实现报告

## 一、概述

谱面可视化分析模块用于对 `charts/` 目录下的谱面进行统计分析与可视化输出，生成多种 PNG 图表与 `*_summary.json`，并产出 `chart_analysis/outputs/protocol.json` 供前端统一加载与展示。

## 二、系统架构设计

### 2.1 模块结构

- 主程序：`chart_analysis/chart_analysis.py`
- 输入：`charts/<曲目名>/<曲目名>.txt`（可选同名 mp3）
- 输出：`chart_analysis/outputs/`（PNG 图表、summary、protocol）

### 2.2 核心类与职责

- `ChartParser`：解析谱面 TXT，提取 BPM、事件列表、时长等信息。
- `ChartAnalyzer`：基于解析结果统计总音符数、类型分布、密度曲线、轨道分布、时间分布、难度曲线等。
- `ChartVisualizer`：将统计结果绘制为 PNG 图表（非交互式后端，适配前端展示）。

## 三、实现流程

### 3.1 谱面扫描与校验

程序扫描 `charts/` 下的子目录，寻找 `charts/<曲目名>/<曲目名>.txt`。在正式解析前，会调用 `chart_engine.chart_check()` 进行基础格式与逻辑校验，确保谱面满足当前引擎的约定（`tap/hold_start/hold_mid`、两轨、时间单调性、长条连续性等）。校验失败的谱面会被跳过并打印原因。

> 说明：分析模块对“事件类型”本身采取更宽松的解析策略（使用 `(\w+)` 匹配），因此对未来扩展（例如新增 `hold_end`）具备一定兼容性；但当前项目的谱面与硬件编译流程以 `chart_engine.chart_check` 的规则为准。

### 3.2 统计分析

统计的核心点包括：
- **总音符数**：为避免长条中段重复计数，总音符数只统计 `tap` 与 `hold_start`，不把 `hold_mid` 计入总物量。
- **类型分布**：统计每种 `type` 的出现次数，用于饼图展示。
- **密度曲线**：按时间窗口统计窗口内的物量，得到随时间变化的密度曲线。
- **轨道分布**：统计每条轨道的物量，用于柱状图展示。
- **时间分布**：提取 `tap/hold_start` 的时间点，生成直方图反映谱面节奏分布。
- **难度曲线**：将不同类型音符赋权，并结合同时出现的轨道数量与窗口内密度因子，形成随时间变化的“相对难度”曲线，用于趋势观察。

### 3.3 可视化生成

每个谱面输出 6 张图表（PNG）：
- `<曲目名>_note_count.png`
- `<曲目名>_note_density.png`
- `<曲目名>_density_curve.png`
- `<曲目名>_track_distribution.png`
- `<曲目名>_time_distribution.png`
- `<曲目名>_difficulty_curve.png`

图表使用 matplotlib 的非交互式后端（`Agg`），并配置中文字体以保证在 Windows 环境下的可读性。

### 3.4 数据输出与协议生成

- `*_summary.json`：包含 BPM、时长、物量、分布统计、密度峰值/均值等摘要信息。为减小体积，部分大数组（如完整曲线/直方原始数据）会在写入 summary 时被移除。
- `protocol.json`：汇总所有曲目条目，列出图表文件清单与 summary 路径，并附带可选的 `bpm/duration/folder/audio` 字段，便于前端统一读取与渲染。

## 四、使用方式

1. 安装依赖：`pip install -r requirements.txt`
2. 运行分析：`python chart_analysis/chart_analysis.py`
3. 查看输出：`chart_analysis/outputs/`

也可通过 `server.py` 的 `POST /chart_analysis/run` 触发分析，供 `frontend/` 调用。

## 五、总结

当前版本已实现从谱面扫描、校验、解析、统计、绘图到协议生成的一整套流水线，并与前端的读取协议对齐，可直接用于选曲预览与报告展示。
