module adxl345_controller #(
    parameter integer STARTUP_CYCLES = 50_000,
    parameter integer TIMEOUT_CYCLES = 5_000
) (
    input  logic clk,
    input  logic reset_n,
    input  logic sample_request,

    output logic initialized,
    output logic sensor_error,
    output logic controller_busy,
    output logic signed [15:0] accel_x,
    output logic signed [15:0] accel_y,
    output logic signed [15:0] accel_z,
    output logic sample_valid,

    output logic       cs_n,
    output logic       spi_start,
    output logic [7:0] spi_tx_byte,
    input  logic [7:0] spi_rx_byte,
    input  logic       spi_busy,
    input  logic       spi_done
);
    localparam logic [7:0] ADXL_DEVID_EXPECTED = 8'hE5;
    localparam logic [7:0] REG_DEVID           = 8'h00;
    localparam logic [7:0] REG_BW_RATE         = 8'h2C;
    localparam logic [7:0] REG_POWER_CTL       = 8'h2D;
    localparam logic [7:0] REG_DATA_FORMAT     = 8'h31;
    localparam logic [7:0] REG_DATAX0          = 8'h32;

    localparam logic [7:0] DATA_FORMAT_VALUE   = 8'h09; // full resolution, +/-4 g, 4-wire SPI
    localparam logic [7:0] BW_RATE_VALUE       = 8'h0A; // 100 Hz output data rate
    localparam logic [7:0] POWER_CTL_VALUE     = 8'h08; // measurement mode

    typedef enum logic [4:0] {
        ST_BOOT,
        ST_DEVID_CMD_START,
        ST_DEVID_CMD_WAIT,
        ST_DEVID_DATA_START,
        ST_DEVID_DATA_WAIT,
        ST_DEVID_CHECK,
        ST_CFG_CMD_START,
        ST_CFG_CMD_WAIT,
        ST_CFG_DATA_START,
        ST_CFG_DATA_WAIT,
        ST_CFG_NEXT,
        ST_IDLE,
        ST_READ_CMD_START,
        ST_READ_CMD_WAIT,
        ST_READ_DATA_START,
        ST_READ_DATA_WAIT,
        ST_ERROR
    } state_t;

    state_t state;

    localparam integer STARTUP_WIDTH = (STARTUP_CYCLES <= 1) ? 1 : $clog2(STARTUP_CYCLES);
    localparam integer TIMEOUT_WIDTH = (TIMEOUT_CYCLES <= 1) ? 1 : $clog2(TIMEOUT_CYCLES);

    logic [STARTUP_WIDTH-1:0] startup_count;
    logic [TIMEOUT_WIDTH-1:0] timeout_count;
    logic [1:0] cfg_index;
    logic [2:0] read_index;
    logic [7:0] devid_value;
    logic [7:0] data_bytes [0:5];

    logic [7:0] cfg_reg;
    logic [7:0] cfg_value;

    always_comb begin
        case (cfg_index)
            2'd0: begin cfg_reg = REG_DATA_FORMAT; cfg_value = DATA_FORMAT_VALUE; end
            2'd1: begin cfg_reg = REG_BW_RATE;     cfg_value = BW_RATE_VALUE;     end
            default: begin cfg_reg = REG_POWER_CTL; cfg_value = POWER_CTL_VALUE; end
        endcase
    end

    always_comb begin
        controller_busy = (state != ST_IDLE) && (state != ST_ERROR);
    end

    task automatic enter_error;
        begin
            sensor_error <= 1'b1;
            initialized  <= 1'b0;
            cs_n         <= 1'b1;
            state        <= ST_ERROR;
        end
    endtask

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state          <= ST_BOOT;
            startup_count  <= '0;
            timeout_count  <= '0;
            cfg_index      <= '0;
            read_index     <= '0;
            devid_value    <= 8'h00;
            initialized    <= 1'b0;
            sensor_error   <= 1'b0;
            accel_x        <= '0;
            accel_y        <= '0;
            accel_z        <= '0;
            sample_valid   <= 1'b0;
            cs_n           <= 1'b1;
            spi_start      <= 1'b0;
            spi_tx_byte    <= 8'h00;
            for (integer i = 0; i < 6; i = i + 1) begin
                data_bytes[i] <= 8'h00;
            end
        end else begin
            spi_start    <= 1'b0;
            sample_valid <= 1'b0;

            case (state)
                ST_BOOT: begin
                    if (STARTUP_CYCLES <= 1 || startup_count == STARTUP_CYCLES - 1) begin
                        startup_count <= '0;
                        cs_n          <= 1'b0;
                        state         <= ST_DEVID_CMD_START;
                    end else begin
                        startup_count <= startup_count + 1'b1;
                    end
                end

                ST_DEVID_CMD_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= 8'h80 | REG_DEVID; // read, single byte
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_DEVID_CMD_WAIT;
                    end
                end

                ST_DEVID_CMD_WAIT: begin
                    if (spi_done) begin
                        timeout_count <= '0;
                        state         <= ST_DEVID_DATA_START;
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_DEVID_DATA_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= 8'h00;
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_DEVID_DATA_WAIT;
                    end
                end

                ST_DEVID_DATA_WAIT: begin
                    if (spi_done) begin
                        devid_value   <= spi_rx_byte;
                        cs_n          <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_DEVID_CHECK;
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_DEVID_CHECK: begin
                    if (devid_value == ADXL_DEVID_EXPECTED) begin
                        cfg_index <= 2'd0;
                        cs_n      <= 1'b0;
                        state     <= ST_CFG_CMD_START;
                    end else begin
                        enter_error();
                    end
                end

                ST_CFG_CMD_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= cfg_reg; // write command: bit7=0
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_CFG_CMD_WAIT;
                    end
                end

                ST_CFG_CMD_WAIT: begin
                    if (spi_done) begin
                        timeout_count <= '0;
                        state         <= ST_CFG_DATA_START;
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_CFG_DATA_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= cfg_value;
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_CFG_DATA_WAIT;
                    end
                end

                ST_CFG_DATA_WAIT: begin
                    if (spi_done) begin
                        cs_n          <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_CFG_NEXT;
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_CFG_NEXT: begin
                    if (cfg_index == 2'd2) begin
                        initialized <= 1'b1;
                        state       <= ST_IDLE;
                    end else begin
                        cfg_index <= cfg_index + 1'b1;
                        cs_n      <= 1'b0;
                        state     <= ST_CFG_CMD_START;
                    end
                end

                ST_IDLE: begin
                    cs_n <= 1'b1;
                    if (sample_request) begin
                        read_index <= 3'd0;
                        cs_n       <= 1'b0;
                        state      <= ST_READ_CMD_START;
                    end
                end

                ST_READ_CMD_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= 8'hC0 | REG_DATAX0; // read + multi-byte + address
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_READ_CMD_WAIT;
                    end
                end

                ST_READ_CMD_WAIT: begin
                    if (spi_done) begin
                        timeout_count <= '0;
                        state         <= ST_READ_DATA_START;
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_READ_DATA_START: begin
                    if (!spi_busy) begin
                        spi_tx_byte   <= 8'h00;
                        spi_start     <= 1'b1;
                        timeout_count <= '0;
                        state         <= ST_READ_DATA_WAIT;
                    end
                end

                ST_READ_DATA_WAIT: begin
                    if (spi_done) begin
                        data_bytes[read_index] <= spi_rx_byte;
                        timeout_count          <= '0;
                        if (read_index == 3'd5) begin
                            accel_x      <= $signed({data_bytes[1], data_bytes[0]});
                            accel_y      <= $signed({data_bytes[3], data_bytes[2]});
                            accel_z      <= $signed({spi_rx_byte, data_bytes[4]});
                            sample_valid <= 1'b1;
                            cs_n         <= 1'b1;
                            state        <= ST_IDLE;
                        end else begin
                            read_index <= read_index + 1'b1;
                            state      <= ST_READ_DATA_START;
                        end
                    end else if (TIMEOUT_CYCLES <= 1 || timeout_count == TIMEOUT_CYCLES - 1) begin
                        enter_error();
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_ERROR: begin
                    cs_n <= 1'b1;
                end

                default: enter_error();
            endcase
        end
    end
endmodule
