# Frontend（前端入口）

`frontend/` 是项目的静态 Web UI，配合根目录 `server.py` 提供的轻量 API，实现：
- 普通模式：运行谱面分析 → 选曲预览（图表/summary/音频）→ 生成并写入 `verilog/ROM.v` + 同步 BPM → 可选打开 Quartus。
- 随机模式：生成 `charts/Random/Random.txt` → 重新分析 Random → 预览 → 写入/打开 Quartus。

实现细节（UI 结构、状态机、接口调用与数据流）见：`frontend/doc/frontend.md`。

## 启动

1. 安装依赖：`pip install -r requirements.txt`
2. 启动服务：`python server.py --host 127.0.0.1 --port 8000`
3. 打开页面：`http://127.0.0.1:8000/frontend/`
