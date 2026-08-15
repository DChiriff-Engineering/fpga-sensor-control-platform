module de10_lite_smoke_top (
    input  logic       CLOCK_50,
    input  logic [1:0] KEY,
    input  logic [9:0] SW,
    output logic [9:0] LEDR
);
    // Deliberately minimal first-hardware milestone: every switch maps to its LED.
    // CLOCK_50 and KEY are retained as named board ports for toolchain/pin validation.
    always_comb begin
        LEDR = SW;
    end
endmodule
