`timescale 1ns / 1ps

module mul_tb();

parameter A_ADDR = "C:/Users/15661/Desktop/mul/data/a.hex";
parameter B_ADDR = "C:/Users/15661/Desktop/mul/data/b.hex";
parameter R_ADDR = "C:/Users/15661/Desktop/mul/data/r.hex";

reg                     clk                 ;
reg                     rst_n               ;

reg                     en      ;
reg     [11:0]          a       ;
reg     [11:0]          b       ;
wire                    busy    ;
wire                    done    ;
wire    [11:0]          r       ;

mul mul_test(
    .clk                (clk        ),
    .rst_n              (rst_n      ),
    .en                 (en         ),
    .a                  (a          ),
    .b                  (b          ),
    .busy               (busy       ),
    .done               (done       ),
    .r                  (r          )
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

always @ (posedge clk)begin
    if(!rst_n)begin
        en <= 1'b0;
        a <= 12'b0;
        b <= 12'b0;
        count <= 10'b0;
    end
    else begin
        en <= 1'b1;
        a <= a_data[count];
        b <= b_data[count];
        if(count >= 2'b11)begin
            if(r == r_data[count-2'b11])begin
                $display("Test %d Pass", count-2'b11);
            end
            else begin
                $display("Test %d Fail, a=%d, b=%d, r=%d, correct=%d", count-2'b11,a,b,r,r_data[count-2'b11]);
            end
        end
        count <= count + 1'b1;
    end
end

endmodule
