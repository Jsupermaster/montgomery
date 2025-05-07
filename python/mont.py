import gmpy2
def extended_gcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        gcd, x1, y1 = extended_gcd(b % a, a)
        x = y1 - (b // a) * x1
        y = x1
        return (gcd, x, y)

def compute_montgomery_params(N, R):
    gcd, x, y = extended_gcd(R, N)
    assert gcd == 1, "R and N must be coprime"

    # R^{-1} 是 x 在模 N 下的正数形式
    R_inv = x % N

    # N' 是 -y 在模 R 下的正数形式（即 -y ≡ N^{-1} mod R）
    N_prime = (-y) % R

    return R_inv, N_prime

def montgomery_reduce(X, N, N_prime):
    m = (X * N_prime) & 4095
    y = (X + m * N) >> 12
    return int(y) if y < N else int(y - N)

def montgomery_multiply(a, b, N, N_prime, R_sq_modN):
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

N = 3329
R = 4096
a, b = 512, 612

# R_inv, N_prime = compute_montgomery_params(N, R)
# print("R_inv = ",R_inv)
# print("N_prime = ", N_prime)
N_prime = 3327
# R_sq_modN = (R * R) % N
# print("R_sq_modN = ", R_sq_modN)
R_sq_modN = 2385
# 手动实现
result = montgomery_multiply(a, b, N, N_prime, R_sq_modN)
print(f"手动实现结果: {result}")

# 使用 % 验证
expected = (a * b) % N
print(f"理论结果: {expected}")