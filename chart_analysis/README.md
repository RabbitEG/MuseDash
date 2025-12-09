# 谱面可视化分析

目标：对谱面进行统计与可视化，产出密度、不同音符数量等图表。

- 实现要求（当前 Python 仅保留 main 占位，需按此补全）：
- 输入：扫描 `charts/` 下的谱面目录（含 Random，若需特殊处理请在逻辑中区分）。
- 解析：直接解析谱面 TXT（自行实现），提取 BPM、时长、音符/事件列表；校验可调用 `chart_engine.chart_check`。
- 统计：总音符数、类型分布、密度曲线、BPM 变化（如有）。
- 输出：
  - 图表：至少有饼图 `<曲目名>_note_count.png`、饼图 `<曲目名>_note_density.png`、曲线图 `<曲目名>_density_curve.png` 等（目前用 `<曲目名>_dummy.png` 占位），越多越好。
  - 数据：`<曲目名>_summary.json`（含 BPM、时长、音符数量、密度峰值/平均等，越多越好）。
  - 协议：`outputs/protocol.json`，列出曲目名、files、summary、可选 bpm/duration/folder/audio。
- 输出目录：`chart_analysis/outputs/`
- 前端读取：`protocol.json` 中的 files/summary 用于展示分析图与数据。

输出协议（建议）：
- 输出目录：`chart_analysis/outputs/`
- 协议描述 JSON：`chart_analysis/outputs/protocol.json`，列出每个曲目的图表与数据文件路径。当前附带 `_dummy` 占位示例（请替换为真实分析产物）。
- 基础占位（最低实现）：`<曲目名>_dummy.png`，供前端检测路径与加载逻辑。
- 完整命名建议（以谱面名为前缀，使用谱面文件夹名或 txt 主文件名）：
  - `<曲目名>_note_count.png`：音符类型数量（饼图）
  - `<曲目名>_note_density.png`：音符类型占比（饼图）
  - `<曲目名>_density_curve.png`：随时间的密度曲线（折线/面积图）
  - `<曲目名>_summary.json`
  - 其它各类能想到的好看的数据分析图
- 前端可直接读取协议 JSON 获取文件清单，再去 `../chart_analysis/outputs/` 读取对应 PNG/JSON。

占位文件：
- `chart_analysis.py`：仅保留 main 占位，按上述要求补全解析/统计/绘图/协议输出。
- `requirements.txt`：后续可加入 matplotlib/plotly 等依赖。
