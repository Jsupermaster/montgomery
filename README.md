# 取模运算的算法分析

|     算法     | 适用位宽 |   延迟    | 资源消耗 |     适用场景      |
| :----------: | :------: | :-------: | :------: | :---------------: |
| 直接乘法取模 |  <12位   |   1周期   |    高    |  小位宽快速验证   |
| 蒙哥马利乘法 |  >256位  | 10-20周期 |    中    | 密码学（RSA/ECC） |
|  巴雷特约减  | 可变位宽 |  多周期   |   中高   |     动态模数      |
|    查表法    |   <8位   |   1周期   |   极高   |  超低延迟小数据   |
|  迭代加法法  | 12-32位  |   N周期   |    低    |  资源敏感型设计   |
| 混合位宽分解 | 16-64位  |  4-8周期  |    中    |  平衡速度与面积   |

## 直接乘法取模

直接在代码中使用%号取模，由编译器进行优化。这样的方法被禁止使用。

## 蒙哥马利乘法

蒙哥马利乘法是一种高效计算模乘 (*A*×*B*)mod*N* 的算法，**核心思想是通过数值域转换和移位操作，避免传统模运算中的高成本除法**。它在密码学（如RSA、ECC）和大数运算中广泛应用，尤其适合硬件实现。

###  **1.核心优势**

- **避免除法**：通过预计算和位操作替代除法，硬件实现更高效。
- **流水线友好**：多步骤迭代可拆分为流水级，提升吞吐量。
- **适合大数运算**：时间复杂度为 *O*(*k*)（k为位宽），优于传统 *O*($k^2$)。

### **2. 数学基础与域转换**

- **蒙哥马利域定义**：
  - 选择基数 *R*=2*k*（*k* 是模数 *N* 的位宽，且 *R*>*N*）。
  - 普通数值 *a* 转换为蒙哥马利域：Mont(*a*)=*a*×*R*mod*N*。
  - **逆转换**：Mont−1(*a*mont)=*a*mont×*R*−1mod*N*。
- **域内乘法**：
  - 若 *A*mont=Mont(*A*)，*B*mont=Mont(*B*)，
  - 则 *A*mont×*B*mont×*R*−1mod*N*=Mont(*A*×*B*)。

### **3. 蒙哥马利约减（Montgomery Reduction）**

约减操作将中间乘积转换为蒙哥马利域形式，无需直接计算除法。

- **输入**：*T*=*A*×*B*（普通乘积，位宽 2*k*）。
- **目标**：计算 Redc(*T*)=*T*×*R*−1mod*N*。

##### **步骤**：

1. **预计算参数**：
   - 计算 *N*′ 满足 *N*×*N*′≡−1mod*R*。可通过扩展欧几里得算法求解。
2. **计算中间值**：
   - *m*=(*T*mod*R*)×*N*′mod*R*
   - *t*=(*T*+*m*×*N*)/*R*
3. **结果修正**：
   - 若 *t*≥*N*，则 *t*=*t*−*N*
   - 最终 Redc(*T*)=*t*

##### **数学验证**：

- *T*+*m*×*N*≡*T*+(*T*mod*R*)×*N*′×*N*≡0mod*R*，因此除以 *R* 是整数除法。
- *t*×*R*≡*T*mod*N*，即 *t*=*T*×*R*−1mod*N*。

### **4. 蒙哥马利乘法完整流程**

以计算 *A*×*B*mod*N* 为例：

1. **预处理**：
   - 转换输入到蒙哥马利域：*A*mont=Mont(*A*)=(*A*×*R*)mod*N**B*mont=Mont(*B*)=(*B*×*R*)mod*N*
2. **域内乘法**：
   - 计算 *T*=*A*mont×*B*mont
3. **约减操作**：
   - 应用蒙哥马利约减：*t*=Redc(*T*)=(*A*×*B*)×*R*mod*N*
4. **逆转换**（若需普通结果）：
   - 再次约减：Redc(*t*)=(*A*×*B*)mod*N*

### 5.python实现

有一些参数是预计算出来的。蒙哥马利约简需要的N'，可以通过拓展欧几里得算法求解贝祖方程预先得到，它只取决于模数N和选取的R。

给定模数N=3329，R是唯一确定的数值4096，据此可以直接计算出N'=3327，这个数值无需每次计算。

因此，使用蒙哥马利算法取模的过程如下：

```python
def montgomery_multiply(a, b, N, N_prime, R):
    # 转换到蒙哥马利域
    a_mont = (a * R) % N
    b_mont = (b * R) % N
    # 计算乘积并约减
    X = a_mont * b_mont
    X1 = montgomery_reduce(X, R, N, N_prime)
    y = montgomery_reduce(X1, R, N, N_prime)
    return int(y)
```

其中蒙哥马利约简的算法如下：

```python
def montgomery_reduce(X, R, N, N_prime):
    m = (X * N_prime) % R
    y = (X + m * N) / R
    return y if y < N else y - N
```

接着，开始进行代码优化。目标是在算法中完全去除%的存在。

首先是将a和b转换到蒙哥马利域，这个过程也可以使用预计算的方法消除取模运算，即先计算出$R^2 mod N$，再计算$A1 = a * (R^2 mod N)$之后通过蒙哥马利约简有$a_{mont} = reduce(A1)$

```python
def montgomery_multiply(a, b, N, N_prime, R, R_sq_modN):
    # 转换到蒙哥马利域
    A1 = a * R_sq_modN
    a_mont = montgomery_reduce(A1, R, N, N_prime)
    B1 = b * R_sq_modN
    b_mont = montgomery_reduce(B1, R, N, N_prime)
    # 计算乘积并约减
    X = a_mont * b_mont
    X1 = montgomery_reduce(X, R, N, N_prime)
    y = montgomery_reduce(X1, R, N, N_prime)
    return int(y)
```

蒙哥马利约简中，可以使用位掩码(按位与)代替取模运算，使用右移运算代替除法运算。

```python
def montgomery_reduce(X, R, N, N_prime):
    m = (X * N_prime) & 4095
    y = (X + m * N) >> 12
    return int(y) if y < N else int(y - N)
```

# verilog实现

## 直接使用%和*的实现

如果直接使用%和*，那么这个实现非常简单：

```
module mul(
    input           clk     ,
    input           rst_n   ,
    input           en      ,
    input   [11:0]  a       ,
    input   [11:0]  b       ,
    output          busy    ,
    output          done    ,
    output  [11:0]  r       
);

reg     [23:0]      result_mul  ;
reg     [11:0]      result_mod  ;   
reg                 done_r      ;

always @(posedge clk) begin
    if(!rst_n)begin
        result_mul <= 24'b0;
        result_mod <= 12'b0;
    end
    else begin
        if(en)begin
            result_mul <= a * b;
            result_mod <= result_mul % 3329;
            done_r <= en;
        end
    end
end

assign done = done_r;
assign busy = en;
assign r = result_mod;

endmodule
```

## 使用蒙哥马利算法实现

基于上面的分析，蒙哥马利算法中，N_prime，R_sq_modN可以直接作为已知值给出。

先设计的是蒙哥马利约简过程。我们使用python生成测试数据，使用verilog编写这个模块的代码与textbench，逐一进行结果比较。

### 确定位宽

输入a和b都是12bit，R_sq_modN=2385，则它的位宽是取2的对数向上取整，即12位；那么A1应该取24位；N的位宽是12位，R是13位。

首先分析第一次约简调用，这里的X等于A1或B1，最大位宽为24位：

```python
m = (X * N_prime) & 4095
```

X的位宽是24位，N_prime是12位，二者相乘的位宽需要36位；但位掩码操作在硬件上的实现就是截取低12位，因此直接令m的位宽为12位即可。

```python
y = (X + m * N) >> 12
```

m是12位，N是12位，它们的乘积是24位；X是24位，它们的和是25位；右移12位是13位。

```python
a_mont = montgomery_reduce(A1, R, N, N_prime)
```

因此，a_mont是13位。

```
X = a_mont * b_mont
```

这里X的最大位宽是26位。第二次约简，X是这里的X，因此约简模块的输入X位宽应至少是26位；这样计算出来的a_mont会是15位，但由于前面已经分析了a_mont的实际值不会超过13位，因此这里对其取低13位即可。

```python
X1 = montgomery_reduce(X, R, N, N_prime)
```

这里X1输出的位宽是输入位宽X为26位时的位宽，因此是15位。

```python
y = montgomery_reduce(X1, R, N, N_prime)
```

这里的y位宽是输入位宽X为15时的位宽，因此是13位，也只取低13位即可。

### montgomery_reduce

经过以上的分析，我们已经确定了这个模块所需的输入输出端口以及它们的位宽。模块定义如下：

```verilog
module montgomery_reduce #(
    parameter [11:0]    N = 3329        ,
    parameter [12:0]    R = 12          ,
    parameter [12:0]    N_prime = 3327  
)
(
    input                   clk     ,
    input                   rst_n   ,
    input                   en      ,
    input    [25:0]         X       , 
    output   [14:0]         y       ,
    output                  valid
);
```

分三个周期完成运算，需要给X打两拍：

```verilog
reg     [25:0]      X_delay_1       ;
reg     [25:0]      X_delay_2       ;

always@(posedge clk)begin
    if(!rst_n)begin
        X_delay_1 <= 26'b0;
        X_delay_2 <= 26'b0;
    end
    else begin
        X_delay_1 <= X;
        X_delay_2 <= X_delay_1;
    end
end

reg     [11:0]      m               ;
reg     [23:0]      m_mul_N         ;
reg     [26:0]      X_plus_mul      ;
reg     [14:0]      result_reduce   ;

always@(posedge clk)begin
    if(!rst_n)begin
        m <= 12'b0;
        m_mul_N <= 24'b0;
        X_plus_mul <= 27'b0;
        result_reduce <= 15'b0;
    end
    else if(en)begin
        m <= X * N_prime;
        m_mul_N <= m * N;
        X_plus_mul <= X_delay_2 + m_mul_N;
        result_reduce <= X_plus_mul >> 12;
    end
end

reg  [3:0]   valid_delay_reg ;     //存放脉冲在传输过程的临时数据  

always @(posedge clk)begin	
    if(!rst_n)
        valid_delay_reg <= 4'd0;
    else if(en == 1'b1)//脉冲输入信号到来
        valid_delay_reg <= {valid_delay_reg[2:0],en};
    else
        valid_delay_reg <= {valid_delay_reg[2:0],1'b0};       //每隔一个时钟周期，前移一位
end

assign valid = valid_delay_reg[3] ;        //间隔数个周期后，从高位输出   
assign y = (result_reduce < N) ? result_reduce : result_reduce - N;
```

### montgomery_multiply

经过以上的分析与计算，我们能够确认端口输入输出信号：

