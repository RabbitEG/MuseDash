# 谱面可视化分析（`chart_analysis/`）

该模块对 `charts/` 下的谱面进行解析与统计分析，并输出一组 PNG 图表与 `*_summary.json`，同时生成 `protocol.json` 便于前端批量读取与展示。

## 运行方式

- 直接运行：`python chart_analysis/chart_analysis.py`
- 通过前端（推荐）：启动 `python server.py ...` 后由前端调用 `POST /chart_analysis/run`

依赖：`matplotlib`、`numpy`（见根目录 `requirements.txt`）。

## 输入与校验

- 输入目录：`charts/<曲目名>/<曲目名>.txt`
- 校验：运行时会调用 `chart_engine.chart_check()` 进行基础格式/逻辑校验，失败的谱面会被跳过并打印原因。

## 输出目录与文件

所有输出写入：`chart_analysis/outputs/`

每个曲目会生成（若分析成功）：
- `"<曲目名>_note_count.png"`：音符类型数量（饼图）
- `"<曲目名>_note_density.png"`：音符类型占比（饼图）
- `"<曲目名>_density_curve.png"`：密度曲线（折线/面积）
- `"<曲目名>_track_distribution.png"`：轨道分布（柱状）
- `"<曲目名>_time_distribution.png"`：时间分布（直方）
- `"<曲目名>_difficulty_curve.png"`：难度曲线（折线/面积）
- `"<曲目名>_summary.json"`：统计摘要（为减小体积，不包含部分大数组）

并在最后生成：
- `protocol.json`：列出所有曲目的 files/summary 等信息，供前端读取。

## protocol.json 协议（概要）

`chart_analysis/outputs/protocol.json` 的基本结构如下：

```json
{
  "version": 1,
  "note": "...",
  "charts": [
    {
      "name": "Cthugha",
      "files": ["Cthugha_note_count.png", "..."],
      "summary": "Cthugha_summary.json",
      "bpm": 200,
      "duration": 1234,
      "folder": "Cthugha",
      "audio": "Cthugha.mp3"
    }
  ]
}
```

其中 `audio` 字段仅在 `charts/<曲目名>/<曲目名>.mp3` 存在时出现。
