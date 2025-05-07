# 取模运算的算法分析

|     算法     | 适用位宽 |   延迟    | 资源消耗 |     适用场景      |
| :----------: | :------: | :-------: | :------: | :---------------: |
| 直接乘法取模 |  <12位   |   1周期   |    高    |  小位宽快速验证   |
| 蒙哥马利乘法 |  >256位  | 10-20周期 |    中    | 密码学（RSA/ECC） |
|  巴雷特约减  | 可变位宽 |  多周期   |   中高   |     动态模数      |
|    查表法    |   <8位   |   1周期   |   极高   |  超低延迟小数据   |
|  迭代加法法  | 12-32位  |   N周期   |    低    |  资源敏感型设计   |
| 混合位宽分解 | 16-64位  |  4-8周期  |    中    |  平衡速度与面积   |

## 蒙哥马利算法

蒙哥马利算法是一种高效计算模乘 (*A*×*B*)mod*N* 的算法，**核心思想是通过数值域转换和移位操作，避免传统模运算中的高成本除法**。它在密码学（如RSA、ECC）和大数运算中广泛应用，尤其适合硬件实现。

### 1.蒙哥马利算法原理

蒙哥马利算法主要分为蒙哥马利乘法和蒙哥马利约简。算法的流程如下：

#### 1.1 寻找满足条件的R

假设输入的数据为a,b，模数为N，则首先找到一个数R，它满足如下条件：

1. $R = 2^k > N;N < 2^{k+1}$,即R是2的幂次方，且是满足比N大的最小幂次方；
2. $gcd(R, N) = 1$，即R与N互质。

#### 1.2 将输入数据转换到蒙哥马利域

定义公式  $a_{mont} = (a \times R) mod N$  为蒙哥马利变换，$a_{mont}$是$a$对应的蒙哥马利域的值。同理，也将b转换到蒙哥马利域得到$b_{mont}$

#### 1.3 计算蒙哥马利域乘积

计算  $X = a_{mont} \times b_{mont}$  ，定义这个乘积是蒙哥马利域乘积。要理解这样为什么可以计算出它的模，要准备下面的公式推导：

$(a \times b) mod N = ((a mod N)\times(b mod N)mod N)$，这个公式称为模运算的分配律；

根据模的性质可得：$(a mod N) mod N = a mod N$，即连续对同一模数取模，第二次以后的结果是不变的。

$X = a_{mont} \times b_{mont} = ((a \times R) mod N) \times ((b \times R) mod N) = (abR^2)modN$

因此只要从$X$中约简掉一个R即可得到原式的蒙哥马利域结果$(a \times b)Rmod N$。

#### 1.4 蒙哥马利约简

蒙哥马利约简的过程就是从X中除掉R的过程，但大数除法会消耗很多的资源，因此通过以下的算法计算。

由于$R = 2^k$，$\frac{X}{R} = X >> k$。

但满足这个等式的条件是：X是R的整数倍。实际上不可能总是满足这个条件，但可以构造出来一个新的$X' = j * R$，j是非0正整数。

因此需要找到一个$m$，使得$X + mN = j * R$。

于是问题转换为了求解一个m，满足上面的式子。引入拓展欧几里得算法，求解以下贝祖方程：

$N*N' + R*R^{-1} = 1$

通过迭代算法，可以求得$N'$和$R^{-1}$，这个值计算出来之后就可以当作已知值来用。之后，使用如下公式，用$N'$算出$m$：

$m = (X \times N') mod R$

计算出m后，即可得到蒙哥马利约简的结果y：

$y = (X + m * N)/R$，这个值需要与N做一次比较，小于N则直接输出，大于N则减掉一次N。

#### 1.5 计算模值

定义蒙哥马利约简函数为$reduce(X)$，则对蒙哥马利乘积进行一次约简，获得蒙哥马利域的结果，再进行一次约简可获得实数域结果。即：

$result = reduce(reduce(X))$

### 2.python实现

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

reg  [3:0]   valid_delay_reg;  

always @(posedge clk)begin	
    if(!rst_n)
        valid_delay_reg <= 4'd0;
    else if(en == 1'b1)
        valid_delay_reg <= {valid_delay_reg[2:0],en};
    else
        valid_delay_reg <= {valid_delay_reg[2:0],1'b0};
end

assign valid = valid_delay_reg[3];  

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
    else if(en || valid_delay_reg[2])begin
        m <= X * N_prime;
        m_mul_N <= m * N;
        X_plus_mul <= X_delay_2 + m_mul_N;
        result_reduce <= X_plus_mul >> R;
    end
end

assign y = (result_reduce < N) ? result_reduce : result_reduce - N;
```

### montgomery_multiply

经过以上的分析与计算，我们能够确认端口输入输出信号：

```verilog
module montgomery_multiply #(
    parameter [11:0]    N = 3329        ,
    parameter [12:0]    R = 12          ,
    parameter [12:0]    N_prime = 3327  ,
    parameter [12:0]    R_sq_modN = 2385
)
(
    input                   clk     ,
    input                   rst_n   ,
    input                   en      ,
    input    [11:0]         a       ,
    input    [11:0]         b       ,
    output   [11:0]         result  ,
    output                  valid
);
```

同时计算$a_{mont}$和$b_{mont}$，之后依次计算两次约简结果：

```verilog
reg     [23:0]              A1;
reg     [23:0]              B1;
wire    [14:0]              a_mont;
wire    [14:0]              b_mont;
wire                        a_mont_valid;
wire                        b_mont_valid;

reg  [3:0]   en_delay_reg ;
wire         en_delay_1;

always @(posedge clk)begin	
    if(!rst_n)
        en_delay_reg <= 4'd0;
    else if(en == 1'b1)
        en_delay_reg <= {en_delay_reg[2:0],en};
    else
        en_delay_reg <= {en_delay_reg[2:0],1'b0};
end

assign en_delay_1 = en_delay_reg[0] ;

always@(posedge clk)begin
    if(!rst_n)begin
        A1 <= 24'b0;
        B1 <= 24'b0;
    end
    else if(en)begin
        A1 <= a * R_sq_modN;
        B1 <= b * R_sq_modN;
    end
end

montgomery_reduce #(
    .N          (N),
    .R          (R),
    .N_prime    (N_prime)
)
montgomery_reduce_A1
(
    .clk     (clk           ),
    .rst_n   (rst_n         ),
    .en      (en_delay_1    ),
    .X       ({2'b0, A1}    ), 
    .y       (a_mont        ),
    .valid   (a_mont_valid  )
);

montgomery_reduce #(
    .N          (N),
    .R          (R),
    .N_prime    (N_prime)
)
montgomery_reduce_B1
(
    .clk     (clk           ),
    .rst_n   (rst_n         ),
    .en      (en_delay_1    ),
    .X       ({2'b0, B1}    ), 
    .y       (b_mont        ),
    .valid   (b_mont_valid  )
);

reg         [25:0]      X_mul_ab;
reg                     X_mul_ab_valid;

always@(posedge clk)begin
    if(!rst_n)begin 
        X_mul_ab <= 26'b0;
        X_mul_ab_valid <= 1'b0;
    end
    else if(a_mont_valid & b_mont_valid)begin
        X_mul_ab <= a_mont * b_mont;
        X_mul_ab_valid <= a_mont_valid && b_mont_valid;
    end
    else begin 
        X_mul_ab_valid <= a_mont_valid && b_mont_valid;
    end
end

wire     [14:0]     X_out;
wire                X_out_valid;

montgomery_reduce #(
    .N          (N),
    .R          (R),
    .N_prime    (N_prime)
)
montgomery_reduce_X
(
    .clk     (clk           ),
    .rst_n   (rst_n         ),
    .en      (X_mul_ab_valid),
    .X       (X_mul_ab      ), 
    .y       (X_out         ),
    .valid   (X_out_valid   )
);

wire     [14:0]     X1_out;
wire                X1_out_valid;

montgomery_reduce #(
    .N          (N),
    .R          (R),
    .N_prime    (N_prime)
)
montgomery_reduce_X1
(
    .clk     (clk           ),
    .rst_n   (rst_n         ),
    .en      (X_out_valid   ),
    .X       ({11'b0, X_out}), 
    .y       (X1_out        ),
    .valid   (X1_out_valid  )
);

assign result = X1_out;
assign valid = X1_out_valid;
```

### 顶层模块

顶层模块中主要是例化以下乘法模块：

```verilog
module montgomery_top#(
    parameter [11:0]    N = 3329        ,
    parameter [12:0]    R = 12          ,
    parameter [12:0]    N_prime = 3327  ,
    parameter [12:0]    R_sq_modN = 2385
)
(
    input           clk     ,
    input           rst_n   ,
    input           en      ,
    input   [11:0]  a       ,
    input   [11:0]  b       ,
    output          busy    ,
    output          done    ,
    output  [11:0]  r       
);

montgomery_multiply #(
    .N          (N          ),
    .R          (R          ),
    .N_prime    (N_prime    ),
    .R_sq_modN  (R_sq_modN  )
)
u_montgomery_multiply
(
    .clk     (clk       ),
    .rst_n   (rst_n     ),
    .en      (en        ),
    .a       (a         ),
    .b       (b         ),
    .result  (r         ),
    .valid   (done      )
);

assign busy = en || done;

endmodule
```

### testbench

```verilog
`timescale 1ns / 1ps

module montgomery_tb();

parameter A_ADDR = "C:/Users/Jonemaster/Desktop/montgomery/data/a.hex";
parameter B_ADDR = "C:/Users/Jonemaster/Desktop/montgomery/data/b.hex";
parameter R_ADDR = "C:/Users/Jonemaster/Desktop/montgomery/data/r.hex";

reg                     clk                 ;
reg                     rst_n               ;

reg                     en      ;
reg     [11:0]          a       ;
reg     [11:0]          b       ;
wire                    busy    ;
wire                    done    ;
wire    [11:0]          r       ;

montgomery_top montgomery_top_test
(
    .clk     (clk           ),
    .rst_n   (rst_n         ),
    .en      (en            ),
    .a       (a             ),
    .b       (b             ),
    .busy    (busy          ),
    .done    (done          ),
    .r       (r             )
);

reg     [11:0]   a_data [511:0];
reg     [11:0]   b_data [511:0];
reg     [11:0]   r_data [511:0];

initial begin
    $readmemh(A_ADDR, a_data);
    $readmemh(B_ADDR, b_data);
    $readmemh(R_ADDR, r_data);
end

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
end

reg     [9:0]   count;
reg     [9:0]   count_1;

always @ (posedge clk)begin 
    if(!rst_n)begin  
        en <= 1'b0;
        a <= 12'b0;
        b <= 12'b0;
        count <= 10'b0;
    end
    else begin
        if(count == 10'd512)begin
            en <= 1'b0;
            a <= 12'b0;
            b <= 12'b0;
        end
        else begin 
            en <= 1'b1;
            a <= a_data[count];
            b <= b_data[count];
            count <= count + 1'b1;
        end
    end
end

always @ (posedge clk)begin
    if(!rst_n)begin
        count_1 <= 10'b0;
    end
    else if(done)begin
        if(count_1 == 10'd511)begin
            if(r == r_data[count_1])begin
                $display("Test %d Pass", count_1+1'b1);
            end
            else begin
                $display("Test %d Fail, a=%d, b=%d, r=%d, correct=%d", count_1+1'b1, a_data[count_1], b_data[count_1], r, r_data[count_1]);
            end
            $display("Test Finish.");
            $finish;
        end
        else begin
            count_1 <= count_1 + 1'b1;
            if(r == r_data[count_1])begin
                $display("Test %d Pass", count_1+1'b1);
            end
            else begin
                $display("Test %d Fail, a=%d, b=%d, r=%d, correct=%d", count_1+1'b1, a_data[count_1], b_data[count_1], r, r_data[count_1]);
            end
        end
    end
end

endmodule

```

