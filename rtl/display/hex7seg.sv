module hex7seg (
    input  logic [3:0] value,
    output logic [7:0] segments_n
);
    // Active-low DE10-Lite convention: {DP,G,F,E,D,C,B,A}.
    always_comb begin
        case (value)
            4'h0: segments_n = 8'b1100_0000;
            4'h1: segments_n = 8'b1111_1001;
            4'h2: segments_n = 8'b1010_0100;
            4'h3: segments_n = 8'b1011_0000;
            4'h4: segments_n = 8'b1001_1001;
            4'h5: segments_n = 8'b1001_0010;
            4'h6: segments_n = 8'b1000_0010;
            4'h7: segments_n = 8'b1111_1000;
            4'h8: segments_n = 8'b1000_0000;
            4'h9: segments_n = 8'b1001_0000;
            4'hA: segments_n = 8'b1000_1000;
            4'hB: segments_n = 8'b1000_0011;
            4'hC: segments_n = 8'b1100_0110;
            4'hD: segments_n = 8'b1010_0001;
            4'hE: segments_n = 8'b1000_0110;
            4'hF: segments_n = 8'b1000_1110;
            default: segments_n = 8'hFF;
        endcase
    end
endmodule
