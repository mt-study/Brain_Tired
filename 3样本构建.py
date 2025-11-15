import mne
import scipy.io
import numpy as np
import pandas as pd
import os
import sys
import re  # 用于提取数字

base_path=r"G:\2\\"

def build_files(name):
    # ========== 1. 路径设置 ==========
    eeg_dir = base_path+name +"\\re"    # 包含多个 .set 文件的文件夹
    mat_save_dir = base_path+name+"\\re_mat"  # 保存 .mat 文件的路径
    target_root = base_path+name+"\\file5"    # 保存 CSV 文件的根目录

    os.makedirs(mat_save_dir, exist_ok=True)

    # ========== 2. 遍历所有 .set 文件 ==========
    for file in os.listdir(eeg_dir):
        if file.endswith('.set'):
            eeg_path = os.path.join(eeg_dir, file)
            file_name = os.path.splitext(file)[0]
            print(f"\n🚀 开始处理文件：{file_name}")

            # 从文件名中提取数字（如 re2 -> 2）
            match = re.search(r'\d+', file_name)
            if match:
                file_number = match.group()
            else:
                print(f"❌ 错误：文件名 {file_name} 中未找到数字，跳过该文件。")
                continue

            # ========== 3. 加载 EEG 数据 ==========
            eeg = mne.io.read_raw_eeglab(eeg_path, preload=True)
            data = eeg.get_data()
            sfreq = eeg.info['sfreq']

            # ⚡ 转换单位：从伏特 (V) 转为微伏 (μV)
            data = data * 1e6

            # ========== 4. 数据分段 ==========
            segment_duration = 2  # 每段 2 秒
            segment_length = int(segment_duration * sfreq)
            data_subset = data[:, :90000]  # 可修改取样长度
            num_segments = data_subset.shape[1] // segment_length

            segments = np.zeros((num_segments, data_subset.shape[0], segment_length))
            for i in range(num_segments):
                start_idx = i * segment_length
                end_idx = start_idx + segment_length
                segments[i, :, :] = data_subset[:, start_idx:end_idx]

            # ========== 5. 保存为 .mat ==========
            mat_save_path = os.path.join(mat_save_dir, f'{file_name}_1000_python.mat')
            scipy.io.savemat(mat_save_path, {f'{file_name}_1000': segments})
            print(f"💾 已保存 .mat 文件：{mat_save_path}")

            # ========== 6. 保存 CSV 分段 ==========
            target_dir = os.path.join(target_root, file_number)
            if os.path.exists(target_dir):
                print(f"⚠️ 警告：文件夹 {target_dir} 已存在，跳过以避免覆盖。")
                # continue
            else:
                os.makedirs(target_dir)
                print(f"📂 创建新文件夹：{target_dir}")

            for i in range(num_segments):
                file_path = os.path.join(target_dir, f'{i+1}.csv')
                pd.DataFrame(segments[i, :, :]).to_csv(file_path, index=False, header=False, float_format="%.4f")

            print(f"✅ 文件 {file_name} 处理完成，共生成 {num_segments} 个 EEG 分段样本")

    print("\n🎉 所有文件处理完成！")

if __name__ == "__main__":
    base_path=r"G:\2\\"
    name_list=['LY','LZ','WL','WRY','WYK']
    for p in name_list:
        print("正在处理："+p)
        build_files(p)
        print("处理完成："+p)
