import os
import re

def rename_files(folder_path):
    # 检查文件夹是否存在
    if not os.path.exists(folder_path):
        print(f"错误：文件夹 '{folder_path}' 不存在")
        return
    
    # 正则表达式匹配"Acquisition XYZ"格式的文件名，其中XYZ是数字
    pattern = r"^Acquisition (\d+)\.(rs3|dap|dat)$"
    
    # 获取所有符合条件的文件并分组
    file_groups = {}
    for filename in os.listdir(folder_path):
        match = re.match(pattern, filename, re.IGNORECASE)
        if match:
            number = int(match.group(1))  # 获取数字部分
            print(number)
            ext = match.group(2).lower()  # 获取扩展名
            
            # 按数字分组
            if number not in file_groups:
                file_groups[number] = {}
            file_groups[number][ext] = filename
    
    if not file_groups:
        print("没有找到符合条件的文件")
        return
    
    # 按原始数字排序
    sorted_numbers = sorted(file_groups.keys())
    
    # 重命名文件
    for new_number, original_number in enumerate(sorted_numbers, start=1):
        files = file_groups[original_number]
        for ext, old_filename in files.items():
            # 新文件名
            new_filename = f"{new_number}.{ext}"
            
            # 构建完整路径
            old_path = os.path.join(folder_path, old_filename)
            new_path = os.path.join(folder_path, new_filename)
            
            # 检查新文件是否已存在
            if os.path.exists(new_path):
                print(f"警告：文件 '{new_filename}' 已存在，跳过重命名 '{old_filename}'")
                continue
            
            # 重命名
            os.rename(old_path, new_path)
            print(f"已重命名: {old_filename} -> {new_filename}")

if __name__ == "__main__":
    # 请将下面的路径替换为你的文件所在的文件夹路径
    base_path=r"G:\2\\"
    name_list=['LY','LZ','WL','WRY','WYK']
    for p in name_list:
        print("正在重命名："+p)
        folder_path=base_path+p+"\EEG"
        rename_files(folder_path)
        print(p+"-重命名完成")
    