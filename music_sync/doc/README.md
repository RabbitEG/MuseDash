# Music Sync（`music_sync/`）

该模块提供一个“按空格触发”的播放入口：
- 若曲目存在同名音频：播放 `charts/<曲目名>/<曲目名>.mp3`；
- 若无音频：解析谱面 txt，并按谱面事件时间线输出节拍提示音（beep/click）。

主要用于演示软硬同步交互，也被 `server.py` 的接口调用。

## 核心接口（`music_sync/player.py`）

- `listen_and_play(chart_name_or_path)`
  - 第一次按空格：开始播放（音频或节拍时间线）。
  - 再次按空格：停止当前播放并退出监听。
  - 入参支持：
    - 曲目名（优先查 `charts/<曲目名>/<曲目名>.mp3`，否则查 `charts/<曲目名>/<曲目名>.txt`）
    - 直接传入 `.mp3` 路径或 `.txt` 谱面路径

依赖：`pygame`、`keyboard`（见根目录 `requirements.txt`）。

## 运行方式

- 命令行调试：`python music_sync/player.py <曲目名或路径>`
  - 例如：`python music_sync/player.py Cthugha`

## 与 server.py 的对接

启动 `python server.py ...` 后：
- `POST /music_sync/play?name=<曲目名>`：启动播放（服务端会先尝试 stop 再启动）
- `POST /music_sync/stop`：停止当前播放
