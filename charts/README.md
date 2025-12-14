# charts 目录说明与谱面格式

## 目录结构

每个谱面一个子目录，命名为曲目名，例如：
- `charts/Cthugha/Cthugha.txt`、`charts/Cthugha/Cthugha.mp3`
- `charts/Cyaegha/Cyaegha.txt`、`charts/Cyaegha/Cyaegha.mp3`
- `charts/Random/Random.txt`（随机生成；可无音频）

## TXT 格式

第一行：BPM 声明（整数）：

`bpm=<整数>`

后续每行：一个事件，格式为：

`(time,type,trace)`

字段含义：
- `time`：非负整数 tick（`TICKS_PER_BEAT = 4`，即 1/4 拍为 1 tick）
- `type`：事件类型（目前引擎接受：`tap` / `hold_start` / `hold_mid`）
- `trace`：轨道编号（`0` 或 `1`）

说明：`chart_engine.chart_check` 会在读到**第一行空行**后停止继续解析（空行后的内容会被忽略）。

### 示例

```txt
bpm=120
(0,tap,0)
(5,tap,1)
(10,hold_start,0)
(11,hold_mid,0)
(12,hold_mid,0)
```

## 校验规则（`chart_engine.chart_check`）

不满足即视为无效，返回 `False`：
- 文件存在且非空；第一行必须为 `bpm=<整数>`。
- 事件行必须匹配 `(time,type,trace)` 的括号/逗号格式。
- `type` 仅允许 `tap`、`hold_start`、`hold_mid`。
- `trace` 仅允许 `0`/`1`。
- `time` 必须为非负整数。
- 全局时间单调不减（允许不同轨道在同一时间点有事件）。
- 同轨时间严格递增（同一轨道不允许相同 tick）。
- 长条连续性：
  - `hold_mid` 必须紧接同轨上一事件（上一事件为 `hold_start/hold_mid` 且 `time` 相差 1）。
  - `hold_start` 后必须跟随连续的 `hold_mid`；不允许 `hold_start` 后直接出现 `tap/hold_start`。
  - 文件结束时不允许存在未闭合的 `hold_start`（即最后一个事件为 `hold_start`）。

## 编译输出（`chart_engine.process_chart`）

校验通过后，`process_chart` 会：
- 生成 `verilog/ROM.v`（或 `verilog/<output_filename>`），ROM 固定 4096 个地址；
- 更新 `verilog/MuseDash.v` 的 `parameter div_cnt` 以匹配 BPM。
