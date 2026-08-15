module axis_calibration (
    input  logic clk,
    input  logic reset_n,
    input  logic in_valid,
    input  logic signed [15:0] sample_in,
    input  logic signed [15:0] offset,
    output logic out_valid,
    output logic signed [15:0] sample_out
);
    logic signed [16:0] difference;

    always_comb begin
        difference = {sample_in[15], sample_in} - {offset[15], offset};
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            out_valid  <= 1'b0;
            sample_out <= '0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                if (difference > 17'sd32767)
                    sample_out <= 16'sd32767;
                else if (difference < -17'sd32768)
                    sample_out <= -16'sd32768;
                else
                    sample_out <= difference[15:0];
            end
        end
    end
endmodule
