"""
主要接口：listen_and_play(chart_path_or_audio_path)
调用后监听键盘，按下空格立即播放对应音乐（无音乐时播放默认节拍）。
"""
import os
import time
import sys
import threading
import pygame
import keyboard

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FALLBACK_TICK = os.path.join(BASE_DIR, "assets", "default.mp3")

if not os.path.isfile(FALLBACK_TICK):
    print(f"[WARN] 回退节拍文件不存在: {os.path.abspath(FALLBACK_TICK)}")

pygame_inited = False
def _init_pygame():
    """初始化 pygame mixer（仅初始化一次）"""
    global pygame_inited
    if not pygame_inited:
        try:
            pygame.mixer.init()
            pygame_inited = True
        except Exception as e:
            print(f"[ERROR] pygame 初始化失败：{e}")
            pygame_inited = False

def _play_async(path):
    """异步播放（用 pygame 播放 MP3），避免阻塞键盘监听。"""
    if not os.path.exists(path):
        print(f"[ERROR] 音频文件不存在：{path}")
        return

    def _worker():
        _init_pygame()
        try:
            pygame.mixer.music.load(path)
            pygame.mixer.music.play()
        except Exception as e:
            print(f"[ERROR] 播放失败：{e}")

    threading.Thread(target=_worker, daemon=True).start()

def listen_and_play(chart_name):
    """
    TODO: 监听键盘，空格触发播放。
    - 输入：曲目名或谱面/音频路径
    - 根据曲目名查找 charts/<曲目名>/<曲目名>.mp3，若不存在则回退播放节拍
    """
    if os.path.isfile(chart_name):
        audio_path = chart_name
    else:
        # 视为曲目名
        folder = os.path.join("charts", chart_name)
        audio = os.path.join(folder, f"{chart_name}.mp3")
        print("charts", audio)
        if os.path.exists(audio):
            print(f"[INFO] 使用曲目音频：{audio}")
            audio_path = audio
        # 回退
        else: 
            print(f"[WARN] 未找到音频 {audio}，回退播放节拍：{FALLBACK_TICK}")
            audio_path = FALLBACK_TICK    

    print("\n=== Music Sync Start ===")
    print(f"按空格播放音频{audio_path}，按 Ctrl+C 退出\n")
    try:
        while True:
            if keyboard.is_pressed("space"):
                print("[EVENT] SPACE → 播放")
                _play_async(audio_path)
                time.sleep(0.3)   # 避免长按触发多次
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\n退出监听。")
    # raise NotImplementedError("音乐播放逻辑尚未实现。")


def main():
    """
    调试入口：可手动调用 listen_and_play 进行本地测试。
    直接调用此python文件调试，在MuseDash总目录下命令行运行：python music_sync/player.py songName
    如 python music_sync/player.py Cthugha
    """ 
    if len(sys.argv) < 2: 
        print("用法：python player.py <曲目名或路径>")
        return
    listen_and_play(sys.argv[1])

if __name__ == "__main__":
    main()
