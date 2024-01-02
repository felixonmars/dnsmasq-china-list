import os
import glob

def convert_conf_to_txt(conf_file, txt_file, dns_url):
    with open(conf_file, 'r') as conf:
        with open(txt_file, 'w') as txt:
            for line in conf:
                parts = line.strip().split('=')
                if len(parts) != 2:
                    print(f"Invalid line: {line.strip()}")
                    continue
                domain = parts[1].split('/')[1]
                txt.write(f"[/{domain}/]" + dns_url + "\n")

def main():
    current_directory = os.getcwd()  # 获取当前目录
    # 使用glob匹配以.conf结尾的文件
    conf_files = glob.glob(os.path.join(current_directory, '*china.conf'))
    # 逐个读取文件内容
    for thefile in conf_files:
        if os.path.basename(thefile) == 'bogus-nxdomain.china.conf':
            continue
        convert_conf_to_txt(thefile, thefile + ".txt", dns_url)

# 从环境变量中获取 DNS URL
dns_url = os.environ.get('DNS_URL')

# 检查 DNS URL 是否为空
if dns_url is None:
    print("DNS_URL 环境变量未设置")
else:
    main()
