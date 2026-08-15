module iir_lowpass_axis #(
    parameter integer IN_WIDTH    = 16,
    parameter integer FRAC_BITS   = 8,
    parameter integer ALPHA_SHIFT = 3,
    parameter integer ACC_WIDTH   = IN_WIDTH + FRAC_BITS + 2
) (
    input  logic clk,
    input  logic reset_n,
    input  logic in_valid,
    input  logic signed [IN_WIDTH-1:0] sample_in,
    output logic out_valid,
    output logic signed [IN_WIDTH-1:0] sample_out
);
    logic signed [ACC_WIDTH-1:0] accumulator;
    logic have_sample;

    logic signed [ACC_WIDTH-1:0] sample_extended;
    logic signed [ACC_WIDTH-1:0] target_fixed;
    logic signed [ACC_WIDTH-1:0] error_fixed;
    logic signed [ACC_WIDTH-1:0] correction;
    logic signed [ACC_WIDTH-1:0] next_accumulator;
    logic signed [ACC_WIDTH-1:0] next_output_scaled;

    always_comb begin
        sample_extended    = {{(ACC_WIDTH-IN_WIDTH){sample_in[IN_WIDTH-1]}}, sample_in};
        target_fixed       = sample_extended <<< FRAC_BITS;
        error_fixed        = target_fixed - accumulator;
        correction         = error_fixed >>> ALPHA_SHIFT;
        next_accumulator   = accumulator + correction;
        next_output_scaled = next_accumulator >>> FRAC_BITS;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= '0;
            have_sample <= 1'b0;
            out_valid   <= 1'b0;
            sample_out  <= '0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                if (!have_sample) begin
                    accumulator <= target_fixed;
                    sample_out  <= sample_in;
                    have_sample <= 1'b1;
                end else begin
                    accumulator <= next_accumulator;
                    sample_out  <= next_output_scaled[IN_WIDTH-1:0];
                end
            end
        end
    end
endmodule
