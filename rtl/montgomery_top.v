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