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

endmodule
