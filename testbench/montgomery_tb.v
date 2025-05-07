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
