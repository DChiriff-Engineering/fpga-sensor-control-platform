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
    localparam integer H_VISIBLE = 640;
    localparam integer H_FRONT   = 16;
    localparam integer H_SYNC    = 96;
    localparam integer H_BACK    = 48;
    localparam integer H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam integer V_VISIBLE = 480;
    localparam integer V_FRONT   = 10;
    localparam integer V_SYNC    = 2;
    localparam integer V_BACK    = 33;
    localparam integer V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

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
                if (h_count == H_TOTAL - 1) begin
                    h_count <= 10'd0;
                    if (v_count == V_TOTAL - 1) begin
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
        hsync_n      = !((h_count >= H_VISIBLE + H_FRONT) &&
                         (h_count <  H_VISIBLE + H_FRONT + H_SYNC));
        vsync_n      = !((v_count >= V_VISIBLE + V_FRONT) &&
                         (v_count <  V_VISIBLE + V_FRONT + V_SYNC));
    end
endmodule
