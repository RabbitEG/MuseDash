"""
Chart 引擎占位实现。
核心接口：process_chart(chart_name) -> bool
校验统一由 chart_check(chart_path) 执行，负责格式与约束检查；若不符合返回 False。
符合则生成 ROM 数据，写入 verilog/rom.v，并更新 BPM（如需），成功返回 True。
"""

from pathlib import Path


def chart_check(chart_path):
    """
    校验谱面 TXT（供 chart_engine 与 chart_analysis 共享）。
    TODO:
    - 确认文件存在
    - 时间为整数，时间序列单调不减（同一时间可有不同轨道）
    - 同一时间同一轨道不得重合（含长条与单点）
    - 其他必要格式校验
    返回：bool（通过为 True）；当前占位直接返回 True，便于联调。
    """
    return True


def generate_random_chart(output_dir, name="Random", bpm=120, length_seconds=60, seed=None):
    """
    生成随机谱面 TXT 占位（满足基本格式即可，无需复杂算法）。
    - output_dir: 输出目录（建议 charts/Random/）
    - name: 曲目名（默认 Random）
    - bpm: 生成使用的 BPM，占位
    - length_seconds: 生成时长，占位
    - seed: 随机种子（可选）
    预期：直接覆盖 charts/Random/Random.txt；当前占位不执行任何逻辑。
    """
    # 占位：不做任何操作，供后续实现覆盖 charts/Random/Random.txt
    return None


def process_chart(chart_name):
    """
    输入：曲目名（对应 charts/<曲目名>/<曲目名>.txt）
    输出：布尔值，表示是否成功生成 ROM 并更新 BPM。
    TODO:
    - 读取对应 TXT
    - 调用 chart_check 校验，不通过返回 False
    - 生成谱面模型 -> ROM 数据
    - 将 ROM 写入 verilog/rom.v
    - 视需求更新顶层 BPM
    """
    # 占位：未实现返回 False
    return False


def main():
    """
    调试入口：可在此解析 CLI 参数调用 process_chart(chart_name) 做本地测试。
    校验逻辑统一走 chart_check。
    生产环境请通过后端接口调用 process_chart。
    """
    raise NotImplementedError("chart_engine 主逻辑尚未实现。")


if __name__ == "__main__":
    main()
