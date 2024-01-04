import os
import glob

def convert_conf_to_txt(conf_file, txt_file, cn_dns):
    with open(conf_file, 'r') as conf:
        with open(txt_file, 'w') as txt:
            for line in conf:
                parts = line.strip().split('=')
                if len(parts) != 2:
                    print(f"Invalid line: {line.strip()}")
                    continue
                domain = parts[1].split('/')[1]
                txt.write(f"[/{domain}/]" + cn_dns + "\n")

def main():
    current_directory = os.getcwd()  # 获取当前目录
    converted_directory = os.path.join(current_directory, 'converted')  # 创建 converted 文件夹
    os.makedirs(converted_directory, exist_ok=True)  # 确保 converted 文件夹存在
    # 使用 glob 匹配以 .conf 结尾的文件
    conf_files = glob.glob(os.path.join(current_directory, '*china.conf'))
    # 逐个读取文件内容
    for thefile in conf_files:
        if os.path.basename(thefile) == 'bogus-nxdomain.china.conf':
            continue
        txt_file = os.path.join(converted_directory, os.path.basename(thefile) + ".txt")  # 生成的 txt 文件路径
        convert_conf_to_txt(thefile, txt_file, cn_dns)

    # 合并生成的 txt 文件为 FAK-DNS.txt
    txt_files = glob.glob(os.path.join(converted_directory, '*conf.txt'))
    with open(os.path.join(converted_directory, 'FAK-DNS.txt'), 'w') as fak_dns:
        fak_dns.write(the_dns + "\n")  # 新增行，内容为自定义内容
        for txt_file in txt_files:
            with open(txt_file, 'r') as txt:
                fak_dns.write(txt.read())

# 从环境变量中获取 DNS URL
cn_dns = os.environ.get('CN_DNS')
the_dns = os.environ.get('THE_DNS')

main()
