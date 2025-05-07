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

endmodule
