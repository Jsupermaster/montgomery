import random

def save_hex_3(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            # 格式化为3位十六进制，大写字母，补前导零
            f.write(f"{val:03X}\n")

def save_hex_4(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            # 格式化为3位十六进制，大写字母，补前导零
            f.write(f"{val:04X}\n")

def save_hex_7(data, filename):
    with open(filename, 'w') as f:
        for val in data:
            # 格式化为3位十六进制，大写字母，补前导零
            f.write(f"{val:07X}\n")

def montgomery_reduce(X, N, N_prime):
    m = (X * N_prime) & 4095
    print(m)
    print(m * N)
    y = (X + m * N) >> 12
    print(X + m * N)
    print(y)
    return int(y) if y < N else int(y - N)

def montgomery_multiply(a, b, N, N_prime, R, R_sq_modN):
    # 转换到蒙哥马利域
    A1 = a * R_sq_modN
    a_mont = montgomery_reduce(A1, N, N_prime)
    B1 = b * R_sq_modN
    b_mont = montgomery_reduce(B1, N, N_prime)
    # a_mont = (a * R) % N
    # b_mont = (b * R) % N
    # print("a_mont = ", a_mont)
    # print("b_mont = ", b_mont)
    # 计算乘积并约减
    X = a_mont * b_mont
    X1 = montgomery_reduce(X, N, N_prime)
    y = montgomery_reduce(X1, N, N_prime)
    return int(y)

def gen_reduce_data(N, N_prime):
    X = [random.randint(0, 0x3FFFFFF) for _ in range(512)]
    save_hex_7(X, 'X.hex')
    Y = [montgomery_reduce(x, N, N_prime) for x in X]
    save_hex_4(Y, 'y.hex')

def gen_mul_data():
    a = [random.randint(0, 0xFFF) for _ in range(512)]
    b = [random.randint(0, 0xFFF) for _ in range(512)]
    r = [((x * y) % 3329) & 0xFFF for x, y in zip(a, b)]
    save_hex_3(a, 'a.hex')
    save_hex_3(b, 'b.hex')
    save_hex_3(r, 'r.hex')

N = 3329
R = 4096
N_prime = 3327
R_sq_modN = 2385
X = 66270503
# gen_reduce_data(N, N_prime)
gen_mul_data()