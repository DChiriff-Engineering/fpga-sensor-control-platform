`timescale 1ns/1ps
module vga_timing_640x480 (
    input  logic clk,
    input  logic reset_n,
    input  logic pixel_ce,
    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y,
    output logic active_video,
    output logic hsync_n,
    output logic vsync_n,
    output logic frame_start
);
    localparam logic [9:0] H_VISIBLE    = 10'd640;
    localparam logic [9:0] H_SYNC_START = 10'd656;
    localparam logic [9:0] H_SYNC_END   = 10'd752;
    localparam logic [9:0] H_TOTAL_LAST = 10'd799;

    localparam logic [9:0] V_VISIBLE    = 10'd480;
    localparam logic [9:0] V_SYNC_START = 10'd490;
    localparam logic [9:0] V_SYNC_END   = 10'd492;
    localparam logic [9:0] V_TOTAL_LAST = 10'd524;

    logic [9:0] h_count;
    logic [9:0] v_count;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            h_count     <= 10'd0;
            v_count     <= 10'd0;
            frame_start <= 1'b0;
        end else begin
            frame_start <= 1'b0;
            if (pixel_ce) begin
                if (h_count == H_TOTAL_LAST) begin
                    h_count <= 10'd0;
                    if (v_count == V_TOTAL_LAST) begin
                        v_count     <= 10'd0;
                        frame_start <= 1'b1;
                    end else begin
                        v_count <= v_count + 1'b1;
                    end
                end else begin
                    h_count <= h_count + 1'b1;
                end
            end
        end
    end

    always_comb begin
        pixel_x      = h_count;
        pixel_y      = v_count;
        active_video = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
        hsync_n      = !((h_count >= H_SYNC_START) &&
                         (h_count < H_SYNC_END));
        vsync_n      = !((v_count >= V_SYNC_START) &&
                         (v_count < V_SYNC_END));
    end
endmodule
