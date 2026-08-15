module triggered_circular_buffer #(
    parameter integer RECORD_WIDTH = 112,
    parameter integer DEPTH        = 256,
    parameter integer POST_SAMPLES = 64,
    parameter integer ADDR_WIDTH   = (DEPTH <= 2) ? 1 : $clog2(DEPTH),
    parameter integer COUNT_WIDTH  = $clog2(DEPTH + 1)
) (
    input  logic clk,
    input  logic reset_n,
    input  logic rearm,
    input  logic sample_valid,
    input  logic trigger,
    input  logic [RECORD_WIDTH-1:0] record_in,

    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [RECORD_WIDTH-1:0] rd_data,

    output logic [ADDR_WIDTH-1:0] write_ptr,
    output logic [ADDR_WIDTH-1:0] trigger_addr,
    output logic triggered,
    output logic frozen,
    output logic [COUNT_WIDTH-1:0] valid_record_count
);
    localparam integer POST_WIDTH = (POST_SAMPLES <= 1) ? 1 : $clog2(POST_SAMPLES + 1);

    logic [RECORD_WIDTH-1:0] memory [0:DEPTH-1];
    logic [POST_WIDTH-1:0] post_remaining;

    function automatic logic [ADDR_WIDTH-1:0] next_address(input logic [ADDR_WIDTH-1:0] address);
        begin
            if (address == DEPTH - 1)
                next_address = '0;
            else
                next_address = address + 1'b1;
        end
    endfunction

    always_ff @(posedge clk) begin
        rd_data <= memory[rd_addr];
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_ptr          <= '0;
            trigger_addr       <= '0;
            triggered          <= 1'b0;
            frozen             <= 1'b0;
            valid_record_count <= '0;
            post_remaining     <= '0;
        end else if (rearm) begin
            write_ptr          <= '0;
            trigger_addr       <= '0;
            triggered          <= 1'b0;
            frozen             <= 1'b0;
            valid_record_count <= '0;
            post_remaining     <= '0;
        end else if (sample_valid && !frozen) begin
            memory[write_ptr] <= record_in;
            if (valid_record_count < DEPTH)
                valid_record_count <= valid_record_count + 1'b1;

            if (!triggered && trigger) begin
                triggered    <= 1'b1;
                trigger_addr <= write_ptr;
                if (POST_SAMPLES == 0) begin
                    frozen         <= 1'b1;
                    post_remaining <= '0;
                end else begin
                    post_remaining <= POST_SAMPLES;
                end
            end else if (triggered) begin
                if (post_remaining <= 1) begin
                    post_remaining <= '0;
                    frozen         <= 1'b1;
                end else begin
                    post_remaining <= post_remaining - 1'b1;
                end
            end

            write_ptr <= next_address(write_ptr);
        end
    end
endmodule
