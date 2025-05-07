import random

# 生成数据（同上）
a = [random.randint(0, 0xFFF) for _ in range(512)]
b = [random.randint(0, 0xFFF) for _ in range(512)]
r = [((x * y) % 3329) & 0xFFF for x, y in zip(a, b)]

# 保存为十六进制文件（每行3位，补零对齐）
def save_hex(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            # 格式化为3位十六进制，大写字母，补前导零
            f.write(f"{val:03X}\n")

save_hex(a, 'a.hex')
save_hex(b, 'b.hex')
save_hex(r, 'r.hex')

print("文件已生成：a.hex, b.hex, r.hex")