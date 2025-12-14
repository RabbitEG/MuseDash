"""
谱面分析工具：对 charts/ 目录下的谱面进行统计与可视化分析。
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import sys

# 字体放大倍率
FONT_SCALE = 2.0


def fs(base: float) -> int:
    """按照倍率放大字体尺寸"""
    return int(round(base * FONT_SCALE))


def fs_smaller(base: float, delta: int = 4) -> int:
    """在放大的基础上进一步缩小字号"""
    return max(1, fs(base) - delta)


# 谱面时间刻度：每拍分成多少单位（默认 1/4 拍为一个时间单位）
TICKS_PER_BEAT = 4


def ticks_to_seconds(ticks: float, bpm: float) -> float:
    """将谱面时间刻度转换为秒"""
    if not bpm:
        return 0.0
    return ticks / TICKS_PER_BEAT * 60.0 / bpm


# 音符类型的中文标签
NOTE_TYPE_LABELS = {
    'tap': '单击',
    'hold_start': '长条',
    'hold_end': '长按结束',
    'hold_mid': '长按中段',
}

# 添加父目录到路径，以便导入 chart_engine
sys.path.insert(0, str(Path(__file__).parent.parent))
from chart_engine.chart_engine import chart_check

try:
    import matplotlib
    matplotlib.use('Agg')  # 使用非交互式后端
    import matplotlib.pyplot as plt
    import numpy as np
    plt.rcParams.update({
        'font.size': fs(11),
        'font.sans-serif': ['Microsoft YaHei', 'SimHei', 'Arial'],
        'axes.unicode_minus': False,
    })
except ImportError:
    print("警告: matplotlib 或 numpy 未安装，请运行: pip install -r requirements.txt")
    raise


# 配置路径
CHARTS_DIR = Path(__file__).parent.parent / "charts"
OUTPUT_DIR = Path(__file__).parent / "outputs"
OUTPUT_DIR.mkdir(exist_ok=True)


class ChartParser:
    """谱面解析器"""
    
    def __init__(self, chart_path: Path):
        self.chart_path = chart_path
        self.bpm = None
        self.notes: List[Tuple[int, str, int]] = []  # (time, type, track)
        self.duration = 0
        
    def parse(self) -> bool:
        """解析谱面文件，返回是否成功"""
        try:
            with open(self.chart_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # 解析 BPM
            if not lines or not lines[0].startswith('bpm='):
                print(f"错误: {self.chart_path} 缺少 BPM 行")
                return False
            
            bpm_match = re.match(r'bpm=(\d+)', lines[0].strip())
            if not bpm_match:
                print(f"错误: {self.chart_path} BPM 格式错误")
                return False
            self.bpm = int(bpm_match.group(1))
            
            # 解析音符
            for line in lines[1:]:
                line = line.strip()
                if not line:
                    continue
                
                # 匹配格式: (time,type,track)
                match = re.match(r'\((\d+),(\w+),(\d+)\)', line)
                if match:
                    time = int(match.group(1))
                    note_type = match.group(2)
                    track = int(match.group(3))
                    self.notes.append((time, note_type, track))
                    self.duration = max(self.duration, time)
            
            return True
        except Exception as e:
            print(f"解析 {self.chart_path} 时出错: {e}")
            return False


class ChartAnalyzer:
    """谱面分析器"""
    
    def __init__(self, chart_name: str, parser: ChartParser):
        self.chart_name = chart_name
        self.parser = parser
        self.stats = {}
        
    def analyze(self):
        """执行统计分析"""
        notes = self.parser.notes
        bpm = self.parser.bpm
        duration = self.parser.duration
        
        # 总音符数（只统计 tap 和 hold_start，不重复计算 hold_mid）
        tap_count = sum(1 for _, nt, _ in notes if nt == 'tap')
        hold_start_count = sum(1 for _, nt, _ in notes if nt == 'hold_start')
        total_note_count = tap_count + hold_start_count
        
        # 类型分布
        type_distribution = {}
        for _, note_type, _ in notes:
            type_distribution[note_type] = type_distribution.get(note_type, 0) + 1
        
        # 计算密度曲线（按时间窗口统计）
        window_size = max(100, duration // 100)  # 时间窗口大小
        density_curve = self._calculate_density_curve(notes, duration, window_size)
        
        # 密度统计
        if density_curve:
            density_peak = max(density_curve.values())
            density_avg = sum(density_curve.values()) / len(density_curve)
        else:
            density_peak = 0
            density_avg = 0
        
        # 轨道分布（使用字符串键以保持一致性）
        track_distribution = {}
        for _, _, track in notes:
            track_key = str(track)
            track_distribution[track_key] = track_distribution.get(track_key, 0) + 1
        
        # 时间分布（用于直方图，只统计 tap 和 hold_start）
        time_distribution = [time for time, note_type, _ in notes 
                           if note_type in ['tap', 'hold_start']]
        
        # 计算难度曲线（基于密度和音符类型复杂度）
        difficulty_curve = self._calculate_difficulty_curve(notes, duration, window_size)
        
        self.stats = {
            'title': self.chart_name,
            'bpm': bpm,
            'duration': duration,
            'total_note_count': total_note_count,
            'tap_count': tap_count,
            'hold_start_count': hold_start_count,
            'note_types': type_distribution,
            'track_distribution': track_distribution,
            'density_peak': density_peak,
            'density_avg': density_avg,
            'density_curve': density_curve,
            'time_distribution': time_distribution,
            'difficulty_curve': difficulty_curve
        }
        
    def _calculate_density_curve(self, notes: List[Tuple[int, str, int]], 
                                  duration: int, window_size: int) -> Dict[int, int]:
        """计算密度曲线：每个时间窗口内的音符数量"""
        density = {}
        for time, note_type, _ in notes:
            # 只统计 tap 和 hold_start
            if note_type in ['tap', 'hold_start']:
                window = (time // window_size) * window_size
                density[window] = density.get(window, 0) + 1
        return density
    
    def _calculate_difficulty_curve(self, notes: List[Tuple[int, str, int]], 
                                     duration: int, window_size: int) -> Dict[int, float]:
        """计算难度曲线：综合考虑密度、音符类型复杂度、轨道分布"""
        difficulty = {}
        
        # 音符类型权重：tap=1, hold_start=1.5, hold_mid=0.3
        type_weights = {'tap': 1.0, 'hold_start': 1.5, 'hold_mid': 0.3, 'hold_end': 0.5}
        
        for time, note_type, track in notes:
            window = (time // window_size) * window_size
            weight = type_weights.get(note_type, 1.0)
            
            if window not in difficulty:
                difficulty[window] = {'count': 0, 'weighted_sum': 0.0, 'tracks': set()}
            
            difficulty[window]['count'] += 1
            difficulty[window]['weighted_sum'] += weight
            difficulty[window]['tracks'].add(track)
        
        # 计算最终难度分数：加权和 * 轨道复杂度因子
        difficulty_scores = {}
        for window, data in difficulty.items():
            # 轨道复杂度：多轨道同时出现增加难度
            track_complexity = 1.0 + 0.2 * (len(data['tracks']) - 1)
            # 密度因子：音符越多，难度增长越快（非线性）
            density_factor = 1.0 + 0.1 * (data['count'] - 1)
            # 最终难度 = 加权和 * 轨道复杂度 * 密度因子
            difficulty_scores[window] = data['weighted_sum'] * track_complexity * density_factor
        
        return difficulty_scores


class ChartVisualizer:
    """谱面可视化器"""
    
    def __init__(self, chart_name: str, analyzer: ChartAnalyzer):
        self.chart_name = chart_name
        self.analyzer = analyzer
        self.stats = analyzer.stats
        
    def generate_note_count_chart(self, output_path: Path):
        """生成音符类型数量饼图（优化版）"""
        type_dist = self.stats['note_types']
        
        # 过滤掉 hold_mid（因为它们是 hold 的一部分）
        filtered_types = {k: v for k, v in type_dist.items() if k != 'hold_mid'}
        
        if not filtered_types:
            # 如果没有数据，创建空图
            fig, ax = plt.subplots(figsize=(9, 6))  # 正方形，适配饼图
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('物量', fontsize=fs(16), fontweight='bold', pad=20)
            plt.savefig(output_path, dpi=150, bbox_inches=None)
            plt.close()
            return
        
        type_keys = list(filtered_types.keys())
        labels = [NOTE_TYPE_LABELS.get(label, label) for label in type_keys]
        sizes = [filtered_types[key] for key in type_keys]
        
        # 使用更美观的配色方案
        color_map = {
            'tap': '#FF6B6B',      # 红色
            'hold_start': '#4ECDC4',  # 青色
            'hold_end': '#45B7D1',    # 蓝色
        }
        colors = [color_map.get(label, plt.cm.viridis(i/len(type_keys))) for i, label in enumerate(type_keys)]
        
        # 设置中文字体支持（如果需要）
        plt.rcParams['font.size'] = fs(11)
        
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 正方形，适配饼图圆形显示
        
        # 自定义格式化函数，显示数量而非百分比
        def format_count(pct):
            total = sum(sizes)
            count = int(round(pct/100. * total))
            return f'{count}'
        
        # 绘制饼图，添加阴影和更好的样式
        wedges, texts, autotexts = ax.pie(
            sizes, 
            labels=labels, 
            autopct=format_count,  # 显示数量
            startangle=90,
            colors=colors,
            explode=[0.05] * len(labels),  # 分离各扇形
            shadow=True,
            textprops={'fontsize': fs(12), 'fontweight': 'bold'},
            pctdistance=0.85
        )
        
        # 优化数量文字样式
        for autotext in autotexts:
            autotext.set_color('white')
            autotext.set_fontweight('bold')
            autotext.set_fontsize(fs(11))
        
        # 设置标题
        ax.set_title(
            '物量类型数量分布',
            fontsize=fs(16),
            fontweight='bold',
            pad=20,
            color='#2C3E50'
        )
        
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches=None, facecolor='white')
        plt.close()
        
    def generate_note_density_chart(self, output_path: Path):
        """生成音符类型占比饼图（优化版）"""
        type_dist = self.stats['note_types']
        filtered_types = {k: v for k, v in type_dist.items() if k != 'hold_mid'}
        
        if not filtered_types:
            fig, ax = plt.subplots(figsize=(9, 6))  # 正方形，适配饼图
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('物量类型占比', fontsize=fs(16), fontweight='bold', pad=20)
            plt.savefig(output_path, dpi=150, bbox_inches=None)
            plt.close()
            return
        
        total = sum(filtered_types.values())
        if total == 0:
            fig, ax = plt.subplots(figsize=(9, 6))  # 正方形，适配饼图
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('物量类型占比', fontsize=fs(16), fontweight='bold', pad=20)
            plt.savefig(output_path, dpi=150, bbox_inches=None)
            plt.close()
            return
        
        type_keys = list(filtered_types.keys())
        labels = [NOTE_TYPE_LABELS.get(label, label) for label in type_keys]
        sizes = [filtered_types[key] / total * 100 for key in type_keys]
        
        # 使用更美观的配色方案
        color_map = {
            'tap': '#FF6B6B',
            'hold_start': '#4ECDC4',
            'hold_end': '#45B7D1',
        }
        colors = [color_map.get(label, plt.cm.Pastel1(i/len(type_keys))) for i, label in enumerate(type_keys)]
        
        # 使用固定的画布尺寸，不使用 bbox_inches='tight' 以保持固定比例
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 正方形，适配饼图圆形显示
        
        # 绘制饼图
        wedges, texts, autotexts = ax.pie(
            sizes,
            labels=labels,
            autopct='%1.1f%%',
            startangle=90,
            colors=colors,
            explode=[0.05] * len(labels),
            shadow=True,
            textprops={'fontsize': fs(12), 'fontweight': 'bold'},
            pctdistance=0.85
        )
        
        # 优化百分比文字样式
        for autotext in autotexts:
            autotext.set_color('white')
            autotext.set_fontweight('bold')
            autotext.set_fontsize(fs(11))
        
        ax.set_title(
            '物量类型占比',
            fontsize=fs(16),
            fontweight='bold',
            pad=20,
            color='#2C3E50'
        )
        
        # 不使用 bbox_inches='tight'，保持固定画布尺寸
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches=None, facecolor='white', pad_inches=0.1)
        plt.close()
        
    def generate_density_curve_chart(self, output_path: Path):
        """生成密度曲线图"""
        density_curve = self.stats['density_curve']
        
        if not density_curve:
            fig, ax = plt.subplots(figsize=(9, 6))  # 3:2 比例，适配前端
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('物量密度曲线', fontsize=fs(14), fontweight='bold')
            ax.set_xlabel('时间（秒）', fontsize=fs(12))
            ax.set_ylabel('物量密度', fontsize=fs(12))
            plt.savefig(output_path, dpi=150, bbox_inches='tight')
            plt.close()
            return
        
        times = sorted(density_curve.keys())
        densities = [density_curve[t] for t in times]
        bpm = self.stats.get('bpm', 0) or 0
        window_size = max(100, self.stats.get('duration', 0) // 100)
        window_seconds = ticks_to_seconds(window_size, bpm)
        times_sec = [ticks_to_seconds(t, bpm) for t in times]
        densities_per_sec = [d / window_seconds if window_seconds else 0 for d in densities]
        
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 3:2 比例，适配前端
        ax.plot(times_sec, densities_per_sec, linewidth=2.5, color='#2E86AB', marker='o', markersize=3, alpha=0.8)
        ax.fill_between(times_sec, densities_per_sec, alpha=0.3, color='#2E86AB')
        ax.set_title('物量密度曲线', fontsize=fs(16), fontweight='bold', pad=15, color='#2C3E50')
        ax.set_xlabel('时间（秒）', fontsize=fs(13), fontweight='bold')
        ax.set_ylabel('物量密度', fontsize=fs(13), fontweight='bold')
        ax.grid(True, alpha=0.3, linestyle='--')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white')
        plt.close()
    
    def generate_track_distribution_chart(self, output_path: Path):
        """生成轨道分布柱状图"""
        track_dist = self.stats['track_distribution']
        
        if not track_dist:
            fig, ax = plt.subplots(figsize=(9, 6))  # 3:2 比例，适配前端
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('轨道分布', fontsize=fs(16), fontweight='bold', pad=20)
            plt.savefig(output_path, dpi=150, bbox_inches='tight')
            plt.close()
            return
        
        # 处理键可能是字符串或整数的情况
        tracks = sorted([int(k) for k in track_dist.keys()])
        counts = [track_dist.get(str(t), track_dist.get(t, 0)) for t in tracks]
        
        # 使用渐变色
        colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7']
        bar_colors = [colors[i % len(colors)] for i in range(len(tracks))]
        
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 3:2 比例，适配前端
        bars = ax.bar(
            tracks,
            counts,
            color=bar_colors,
            edgecolor='white',
            linewidth=2,
            alpha=0.8,
            width=0.6
        )
        
        # 在柱状图上添加数值标签
        for bar in bars:
            height = bar.get_height()
            ax.text(
                bar.get_x() + bar.get_width() / 2.,
                height,
                f'{int(height)}',
                ha='center',
                va='bottom',
                fontsize=fs(12),
                fontweight='bold'
            )
        
        ax.set_title(
            '轨道分布',
            fontsize=fs(16),
            fontweight='bold',
            pad=20,
            color='#2C3E50'
        )
        ax.set_xlabel('轨道', fontsize=fs(13), fontweight='bold')
        ax.set_ylabel('物量', fontsize=fs(13), fontweight='bold')
        ax.set_xticks(tracks)
        ax.set_xticklabels([f'轨道{t}' for t in tracks])
        ax.grid(True, alpha=0.3, axis='y', linestyle='--')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white')
        plt.close()
    
    def generate_time_distribution_chart(self, output_path: Path):
        """生成音符时间分布直方图"""
        time_dist = self.stats['time_distribution']
        bpm = self.stats.get('bpm', 0) or 0
        
        if not time_dist:
            fig, ax = plt.subplots(figsize=(9, 6))  # 3:2 比例，适配前端
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('物量时间分布', fontsize=fs(16), fontweight='bold', pad=20)
            ax.set_xlabel('时间（秒）', fontsize=fs(13), fontweight='bold')
            ax.set_ylabel('物量', fontsize=fs(13), fontweight='bold')
            plt.savefig(output_path, dpi=150, bbox_inches='tight')
            plt.close()
            return
        
        duration = self.stats['duration']
        # 根据时长动态调整 bins 数量
        num_bins = min(50, max(20, duration // 50))
        time_dist_sec = [ticks_to_seconds(t, bpm) for t in time_dist]
        
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 3:2 比例，适配前端
        
        # 绘制直方图，使用渐变色
        n, bins, patches = ax.hist(
            time_dist_sec,
            bins=num_bins,
            color='#4ECDC4',
            edgecolor='white',
            linewidth=1.5,
            alpha=0.7
        )
        
        # 为直方图添加渐变色效果
        for i, patch in enumerate(patches):
            patch.set_facecolor(plt.cm.viridis(i / len(patches)))
        
        ax.set_title(
            '物量时间分布',
            fontsize=fs(16),
            fontweight='bold',
            pad=20,
            color='#2C3E50'
        )
        ax.set_xlabel('时间（秒）', fontsize=fs(13), fontweight='bold')
        ax.set_ylabel('物量数量', fontsize=fs(13), fontweight='bold')
        ax.grid(True, alpha=0.3, axis='y', linestyle='--')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white')
        plt.close()
    
    def generate_difficulty_curve_chart(self, output_path: Path):
        """生成难度曲线分析图"""
        difficulty_curve = self.stats['difficulty_curve']
        bpm = self.stats.get('bpm', 0) or 0
        
        if not difficulty_curve:
            fig, ax = plt.subplots(figsize=(9, 6))  # 3:2 比例，适配前端
            ax.text(0.5, 0.5, '暂无数据', ha='center', va='center', fontsize=fs(16))
            ax.set_title('难度曲线', fontsize=fs(16), fontweight='bold', pad=20)
            ax.set_xlabel('时间（秒）', fontsize=fs(13), fontweight='bold')
            plt.savefig(output_path, dpi=150, bbox_inches='tight')
            plt.close()
            return
        
        times = sorted(difficulty_curve.keys())
        times_sec = [ticks_to_seconds(t, bpm) for t in times]
        difficulties = [difficulty_curve[t] for t in times]
        
        # 计算平均难度和峰值
        avg_difficulty = np.mean(difficulties) if difficulties else 0
        peak_difficulty = max(difficulties) if difficulties else 0
        
        fig, ax = plt.subplots(figsize=(9, 6), facecolor='white')  # 3:2 比例，适配前端
        
        # 绘制难度曲线，使用渐变色
        ax.plot(times_sec, difficulties, linewidth=2.5, color='#E74C3C', alpha=0.8, label='难度')
        ax.fill_between(times_sec, difficulties, alpha=0.3, color='#E74C3C')
        
        # 添加平均难度线
        ax.axhline(y=avg_difficulty, color='#3498DB', linestyle='--', linewidth=2, 
                   label=f'平均值: {avg_difficulty:.2f}', alpha=0.7)
        
        # 标记峰值
        peak_idx = difficulties.index(peak_difficulty)
        peak_time = times_sec[peak_idx]
        ax.plot(peak_time, peak_difficulty, 'ro', markersize=10, label=f'峰值: {peak_difficulty:.2f}')
        ax.annotate(
            f'峰值: {peak_difficulty:.2f}',
            xy=(peak_time, peak_difficulty),
            xytext=(10, 10),
            textcoords='offset points',
            fontsize=fs_smaller(11),
            fontweight='bold',
            bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.7),
            arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0')
        )
        
        ax.set_title(
            '难度曲线分析',
            fontsize=fs(16),
            fontweight='bold',
            pad=20,
            color='#2C3E50'
        )
        ax.set_xlabel('时间（秒）', fontsize=fs(13), fontweight='bold')
        ax.set_ylabel('难度评分', fontsize=fs(13), fontweight='bold')
        ax.legend(loc='upper right', fontsize=fs_smaller(11), framealpha=0.9)
        ax.grid(True, alpha=0.3, linestyle='--')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white')
        plt.close()


def process_chart(chart_name: str) -> bool:
    """处理单个谱面：解析、分析、生成图表和 summary"""
    chart_dir = CHARTS_DIR / chart_name
    chart_file = chart_dir / f"{chart_name}.txt"
    
    if not chart_file.exists():
        print(f"警告: 谱面文件不存在: {chart_file}")
        return False
    
    # 校验谱面
    if not chart_check(chart_name):
        print(f"警告: 谱面校验失败: {chart_name}")
        return False
    
    # 解析
    parser = ChartParser(chart_file)
    if not parser.parse():
        print(f"错误: 解析失败: {chart_name}")
        return False
    
    # 分析
    analyzer = ChartAnalyzer(chart_name, parser)
    analyzer.analyze()
    
    # 可视化
    visualizer = ChartVisualizer(chart_name, analyzer)
    
    # 生成图表
    note_count_path = OUTPUT_DIR / f"{chart_name}_note_count.png"
    note_density_path = OUTPUT_DIR / f"{chart_name}_note_density.png"
    density_curve_path = OUTPUT_DIR / f"{chart_name}_density_curve.png"
    track_dist_path = OUTPUT_DIR / f"{chart_name}_track_distribution.png"
    time_dist_path = OUTPUT_DIR / f"{chart_name}_time_distribution.png"
    difficulty_curve_path = OUTPUT_DIR / f"{chart_name}_difficulty_curve.png"
    
    visualizer.generate_note_count_chart(note_count_path)
    visualizer.generate_note_density_chart(note_density_path)
    visualizer.generate_density_curve_chart(density_curve_path)
    visualizer.generate_track_distribution_chart(track_dist_path)
    visualizer.generate_time_distribution_chart(time_dist_path)
    visualizer.generate_difficulty_curve_chart(difficulty_curve_path)
    
    # 生成 summary.json（移除大型数据以减小文件大小）
    summary_data = {k: v for k, v in analyzer.stats.items() 
                   if k not in ['density_curve', 'difficulty_curve', 'time_distribution']}
    summary_path = OUTPUT_DIR / f"{chart_name}_summary.json"
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump(summary_data, f, indent=2, ensure_ascii=False)
    
    print(f"[OK] 完成分析: {chart_name}")
    return True


def generate_protocol():
    """生成 protocol.json 文件"""
    protocol = {
        "version": 1,
        "note": "谱面分析协议：包含所有曲目的图表与数据文件路径",
        "charts": []
    }
    
    # 扫描 charts 目录
    if not CHARTS_DIR.exists():
        print(f"错误: charts 目录不存在: {CHARTS_DIR}")
        return
    
    for chart_dir in sorted(CHARTS_DIR.iterdir()):
        if not chart_dir.is_dir() or chart_dir.name == '__pycache__':
            continue
        
        chart_name = chart_dir.name
        chart_file = chart_dir / f"{chart_name}.txt"
        
        if not chart_file.exists():
            continue
        
        # 检查输出文件是否存在
        files = []
        patterns = [
            '_note_count.png',
            '_note_density.png',
            '_density_curve.png',
            '_track_distribution.png',
            '_time_distribution.png',
            '_difficulty_curve.png'
        ]
        for pattern in patterns:
            file_path = OUTPUT_DIR / f"{chart_name}{pattern}"
            if file_path.exists():
                files.append(f"{chart_name}{pattern}")
        
        summary_file = f"{chart_name}_summary.json"
        summary_path = OUTPUT_DIR / summary_file
        
        if summary_path.exists():
            # 读取 summary 获取额外信息
            try:
                with open(summary_path, 'r', encoding='utf-8') as f:
                    summary_data = json.load(f)
                chart_entry = {
                    "name": chart_name,
                    "files": files,
                    "summary": summary_file,
                    "bpm": summary_data.get('bpm'),
                    "duration": summary_data.get('duration'),
                    "folder": chart_name
                }
                # 检查是否有音频文件
                audio_file = chart_dir / f"{chart_name}.mp3"
                if audio_file.exists():
                    chart_entry["audio"] = f"{chart_name}.mp3"
            except:
                chart_entry = {
                    "name": chart_name,
                    "files": files,
                    "summary": summary_file
                }
        else:
            chart_entry = {
                "name": chart_name,
                "files": files,
                "summary": summary_file
            }
        
        protocol["charts"].append(chart_entry)
    
    # 保存 protocol.json
    protocol_path = OUTPUT_DIR / "protocol.json"
    with open(protocol_path, 'w', encoding='utf-8') as f:
        json.dump(protocol, f, indent=2, ensure_ascii=False)
    
    print(f"[OK] 生成协议文件: {protocol_path}")


def main():
    """主函数：扫描 charts 目录，处理所有谱面"""
    print("开始谱面分析...")
    print(f"谱面目录: {CHARTS_DIR}")
    print(f"输出目录: {OUTPUT_DIR}")
    print()
    
    if not CHARTS_DIR.exists():
        print(f"错误: charts 目录不存在: {CHARTS_DIR}")
        return
    
    # 扫描并处理所有谱面
    chart_names = []
    for chart_dir in sorted(CHARTS_DIR.iterdir()):
        if not chart_dir.is_dir() or chart_dir.name == '__pycache__':
            continue
        
        chart_name = chart_dir.name
        chart_file = chart_dir / f"{chart_name}.txt"
        
        if chart_file.exists():
            chart_names.append(chart_name)
    
    if not chart_names:
        print("未找到任何谱面文件")
        return
    
    print(f"找到 {len(chart_names)} 个谱面: {', '.join(chart_names)}")
    print()
    
    # 处理每个谱面
    success_count = 0
    for chart_name in chart_names:
        if process_chart(chart_name):
            success_count += 1
        print()
    
    print(f"处理完成: {success_count}/{len(chart_names)} 个谱面成功")
    
    # 生成 protocol.json
    generate_protocol()
    print()
    print("所有分析完成！")


if __name__ == "__main__":
    main()
