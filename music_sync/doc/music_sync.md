## music_sync 模块说明

### 监听键盘及音乐/节拍播放

该模块实现了一个简单的“按空格触发播放”的交互：
- 若存在同名 mp3：播放 `charts/<曲目名>/<曲目名>.mp3`；
- 若无 mp3：解析谱面 txt，将谱面的事件时间（tick）映射到真实时间（秒），并在每个事件点输出一次点击/蜂鸣提示音。

主入口为 `listen_and_play(chart_name_or_path)`：
- 入参既可以是曲目名，也可以直接是 `.mp3` 或 `.txt` 路径；
- **第一次按空格**开始播放；**再次按空格**停止并退出监听（`Ctrl+C` 强退）。

实现要点：
- `pygame` 用于 mp3 播放；播放在后台线程启动，避免阻塞键盘监听。
- `keyboard.is_pressed("space")` 轮询监听按键，并通过 sleep 做简单去抖。
- 无音频时，`_parse_chart()` 读取 `bpm=...` 与事件列表；`_play_timeline()` 依据 `TICKS_PER_BEAT = 4` 将 tick 转为秒并按计划触发 `_beep()`。
- `_beep()` 优先使用 `pygame` 生成的短 click sound；否则回退到 `winsound.Beep`（Windows），再回退到控制台响铃。

依赖库：`pygame`、`keyboard`（见根目录 `requirements.txt`）。

### 软硬件协同方案（思路）

下述内容为探索性方案描述，不要求在本仓库中落地实现。

- **方案一：PC 键盘 → 软件捕获 → 串口（UART）→ FPGA**
  - 上位机捕获空格事件，通过 UART 向 FPGA 发送简单指令（如 `START`/`STOP`/`SEED`/`BPM`），FPGA 解析后启动/停止计数器与状态机。
  - 优点：接口简单，易调试；缺点：串口链路存在一定抖动，精度通常毫秒级。

- **方案二：USB HID 键盘直通 FPGA（硬件级 USB 输入）**
  - FPGA 作为 USB Host 直接读取 HID 键盘状态，绕过 PC 端软件栈。
  - 优点：链路短、时序更稳定；缺点：USB Host + HID 协议栈实现成本高。

- **方案三：PC → GPIO 硬件触发 → FPGA**
  - 上位机通过 USB-GPIO/单片机输出 TTL 脉冲，FPGA 检测上升沿启动同步。
  - 优点：低延迟、实现直观；缺点：需要额外硬件与电气集成。

综合实现难度与可维护性，快速原型阶段更适合方案一或方案三。
