`timescale 1ns / 1ps

module montgomery_reduce_tb();

parameter X_ADDR = "C:/Users/15661/Desktop/mul/data/X.hex";
parameter y_ADDR = "C:/Users/15661/Desktop/mul/data/y.hex";

reg                     clk                 ;
reg                     rst_n               ;

reg                     en                  ;
reg    [25:0]           X                   ; 
wire   [14:0]           y                   ;
wire                    valid               ;

montgomery_reduce montgomery_reduce_test
(
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .en         (en         ),
    .X          (X          ), 
    .y          (y          ),
    .valid      (valid      )
);

reg     [25:0]   X_data [511:0];
reg     [14:0]   y_data [511:0];

initial begin
    $readmemh(X_ADDR, X_data);
    $readmemh(y_ADDR, y_data);
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
        X <= 26'b0;
        count <= 10'b0;
        count_1 <= 10'b0;
    end
    else begin
        en <= 1'b1;
        X <= X_data[count];
        if(valid)begin
            if(count_1 == 10'd512)begin
                $display("Test Finish.");
                $finish;
            end
            else begin
                count_1 <= count_1 + 1'b1;
                if(y == y_data[count_1])begin
                    $display("Test %d Pass", count_1+1'b1);
                end
                else begin
                    $display("Test %d Fail, X=%d, y=%d, correct=%d", count_1+1'b1, X_data[count_1], y, y_data[count_1]);
                end
            end
        end
        count <= count + 1'b1;
    end
end

endmodule
