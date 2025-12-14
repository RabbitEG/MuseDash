# Chart 引擎实现说明（`chart_engine/chart_engine.py`）

本文描述 Chart 引擎当前版本的实现与数据约定，确保文档表述与代码/目录结构一致。

## 1. 谱面校验：`chart_check`

### 1.1 输入与文件定位

接口：`chart_check(chart_name, chart_path=None) -> bool`

- 若传入 `chart_path`：直接校验该文件；
- 否则默认读取 `charts/<chart_name>/<chart_name>.txt`。

### 1.2 格式约定

- 第一行必须为：`bpm=<整数>`
- 后续每行事件格式：`(time,type,trace)`
  - `time`：非负整数 tick
  - `type`：`tap` / `hold_start` / `hold_mid`
  - `trace`：`0` 或 `1`

注意：实现中遇到第一行空行会停止解析（空行后的内容会被忽略）。

### 1.3 校验逻辑要点

校验采用“早失败”策略：发现错误立即返回 `False` 并打印原因。

核心约束：
- 事件行格式必须匹配括号与逗号分隔；
- `type/trace/time` 必须在合法集合与范围内；
- 全局时间单调不减（允许不同轨道同 tick）；
- 同轨时间严格递增（同一轨道不允许同 tick 重合）；
- 长条连续性：
  - `hold_mid` 必须紧接同轨上一事件（上一事件为 `hold_start/hold_mid` 且 tick 差为 1）；
  - `hold_start` 后必须跟随连续的 `hold_mid`，不允许被 `tap/hold_start` “打断”；
  - 文件结束时不允许存在未闭合的 `hold_start`。

## 2. ROM 编译：`process_chart`

接口：`process_chart(chart_name, output_filename="ROM.v") -> bool`

### 2.1 总体流程

1. 调用 `chart_check(chart_name)` 校验谱面；
2. 解析 BPM，并按 `div_cnt = int(375_000_000 / bpm)` 更新 `verilog/MuseDash.v` 的 `parameter div_cnt`；
3. 解析所有事件，将其写入固定长度 ROM（4096 tick）；
4. 输出 Verilog 文件到 `verilog/<output_filename>`。

### 2.2 ROM 布局与编码

- ROM 固定长度：4096（`addr` 为 12-bit，覆盖 `0..4095`）
- 每个地址存一个 4-bit 字：两条轨道各 2-bit
  - 低 2 位：轨道 `0`（`notedown`）
  - 高 2 位：轨道 `1`（`noteup`）

事件编码（2-bit）：
- `00`：无事件
- `01`：`tap`
- `10`：`hold_start`
- `11`：`hold_mid`

组合输出约定：

```verilog
always @(*) begin
    {noteup, notedown} = ROM[addr];
end
```

### 2.3 输出文件示例（节选）

实际生成的 `verilog/ROM.v` 会包含 4096 行初始化（`ROM[0]` 到 `ROM[4095]`）。以下仅展示片段，说明格式：

```verilog
reg [3:0] ROM [0:4095];
initial begin
    ROM[0] = 4'b0001;
    ROM[5] = 4'b0100;
    ROM[10] = 4'b0010;
    ROM[11] = 4'b0011;
    ROM[12] = 4'b0011;
    // ... 其余地址初始化略
end
```

## 3. 随机谱面生成：`generate_random_chart`

接口：`generate_random_chart(output_dir, name="Random", bpm=None, length_seconds=None, seed=None, ...)`

- 写入 `output_dir/<name>.txt`（通常为 `charts/Random/Random.txt`）。
- 随机参数（BPM、时长、物量等）可通过入参指定或由函数按范围随机生成。

## 4. 关联文档

- 谱面格式与校验规则：`charts/README.md`
- Chart 引擎对外接口概览：`chart_engine/doc/README.md`
