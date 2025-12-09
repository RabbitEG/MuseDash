# Chart 引擎

目标：用 Python 替换旧 C++ 流程，生成 ROM.v 并更新顶层 BPM，支持随机/普通模式，使其它部分能够调用相关解析接口。

实现要求（当前仅提供占位，需按此补全）：
- 校验接口：`chart_check(chart_path) -> bool`
  - 统一校验：文件存在、基础格式、时间为整数且单调不减（同一时间可有不同轨道）、同一时间同一轨道不得重合（含长条与单点）。不通过返回 False。
- Verilog 转换接口：`process_chart(chart_name) -> bool`
  - 输入：曲目名（对应 `charts/<曲目名>/<曲目名>.txt`，含 Random）。
  - 流程：读取 TXT -> 调用 `chart_check` -> 生成谱面模型 -> 生成 ROM 数据 -> 写入 `verilog/rom.v` -> 更新顶层 BPM（如需）。
  - 输出：布尔值，表示是否成功完成生成与更新。
- 随机 chart 生成接口：调用 `generate_random_chart` 先落盘 `charts/Random/Random.txt`，再用 `process_chart("Random")` 走同样的 ROM/BPM 流程。

目录说明：
- `chart_engine.py`：仅保留 `chart_check` / `process_chart` / `main` 占位，按上述要求补全。
- `outputs/`：ROM 生成输出目录。
- `legacy_cpp/`：原 C++ 流程（只读参考）。
