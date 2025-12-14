# Chart 引擎（`chart_engine/`）

该模块负责将 `charts/<曲目名>/<曲目名>.txt` 谱面进行校验与编译，生成 Verilog ROM，并把谱面的 BPM 同步到顶层硬件参数中。

## 对外接口（`chart_engine/chart_engine.py`）

- `chart_check(chart_name: str, chart_path: Optional[pathlib.Path] = None) -> bool`
  - 校验谱面格式与基本逻辑（事件格式、时间单调性、长条连续性等）。
  - `chart_path` 为空时默认读取：`charts/<曲目名>/<曲目名>.txt`。

- `process_chart(chart_name: str, output_filename: str = "ROM.v") -> bool`
  - 先调用 `chart_check` 校验谱面；
  - 解析 BPM 并更新 `verilog/MuseDash.v` 中的 `parameter div_cnt`；
  - 编译事件序列为 ROM 初始化内容并写入 `verilog/<output_filename>`。

- `generate_random_chart(output_dir, name="Random", bpm=None, length_seconds=None, seed=None, ...) -> Optional[pathlib.Path]`
  - 生成随机谱面并写入 `output_dir/<name>.txt`，通常用于覆盖 `charts/Random/Random.txt`。

## ROM 编码与范围

- ROM 固定为 4096 个地址（12-bit 地址）：`reg [3:0] ROM [0:4095];`
- 每个 tick 一个 4-bit 字（两条轨道各 2-bit）：
  - 低 2 位：轨道 `0`（`notedown`）
  - 高 2 位：轨道 `1`（`noteup`）
- 事件类型编码（2-bit）：
  - `00`：无事件
  - `01`：`tap`
  - `10`：`hold_start`
  - `11`：`hold_mid`
- 时间刻度：以 `TICKS_PER_BEAT = 4` 约定为 “每拍 4 tick（1/4 拍为 1 tick）”。
- 支持的最大时间：`0..4095`；超出会校验失败/编译失败。

## BPM 同步（`verilog/MuseDash.v`）

`process_chart` 会读取谱面第一行 `bpm=...`，并按下式更新硬件分频参数：

`div_cnt = int(375_000_000 / bpm)`

随后通过正则替换写回 `verilog/MuseDash.v` 中的 `parameter div_cnt = ...`。

## 使用方式

- 作为脚本（用于快速生成/测试）：`python chart_engine/chart_engine.py`
- 作为前端后端接口（推荐）：启动 `python server.py ...` 后由前端调用：
  - `POST /chart_engine/process?name=<曲目名>&output=ROM.v`
  - `POST /chart_engine/generate_random`

谱面文本格式与校验规则见 `charts/README.md`，实现细节见 `chart_engine/doc/Description.md`。
