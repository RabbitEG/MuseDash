# charts 目录说明与校验要求

目录结构：每个谱面一个子目录，命名为曲目名，例如：
- `charts/Cthugha/Cthugha.txt`、`charts/Cthugha/Cthugha.mp3`
- `charts/Cthugha_1/Cthugha_1.txt`、`charts/Cthugha_1/Cthugha_1.mp3`
- `charts/Random/Random.txt`（随机生成音频留空）

基础格式与校验要求（不满足即视为无效，chart_check/process_chart 应返回 False）：
- 文件存在：TXT 位于 `charts/<曲目名>/<曲目名>.txt`。
- 时间为整数：事件时间值必须是整数。
- 时间单调不减：时间序列需单调不减（同一时间可有不同轨道）。
- 不得重合：同一时间同一轨道不得有重叠事件（含长条与单点）。
- 其他格式：需满足谱面解析所需的基本字段/行格式（按工具实现自定义）。

处理流程（供 chart_engine 参考）：
1) 读取并解析 TXT，按上述规则校验。
2) 不通过则终止并返回 False。
3) 通过则生成谱面模型 -> 生成 ROM 数据。
4) 将 ROM 写入 `verilog/rom.v`，并更新 `verilog/MuseDash.v` 中的 BPM。