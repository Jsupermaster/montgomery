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
