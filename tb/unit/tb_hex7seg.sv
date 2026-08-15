`timescale 1ns/1ps
module tb_hex7seg;
    logic [3:0] value;
    logic [7:0] segments_n;
    hex7seg dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_hex7seg: %s", msg); $fatal(1); end
    endtask

    initial begin
        value = 4'h0; #1; if (segments_n !== 8'b1100_0000) fail("0 decode wrong");
        value = 4'hA; #1; if (segments_n !== 8'b1000_1000) fail("A decode wrong");
        value = 4'hF; #1; if (segments_n !== 8'b1000_1110) fail("F decode wrong");
        $display("PASS tb_hex7seg"); $finish;
    end
endmodule
