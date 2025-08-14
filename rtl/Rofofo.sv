`timescale 1ns/1ps

import mfcc_pkg::mfcc_data_t;

module Rofofo #(
    parameter int DATA_SIZE       = 24,
    parameter int REDUCE_FACTOR   = 2,
    parameter int FIFO_DEPTH      = 128 * 1024, // 128kB
    parameter int FIFO_WIDTH      = 8,
    parameter int CLK_FREQ        = 100_000_000,  // Frequência do clock do sistema
    parameter int SIZE_FULL_COUNT = 6,
    parameter int I2S_CLK_FREQ    = 1_500_000
) (
    input  logic clk,
    input  logic rst_n,

    input  logic mosi,
    output logic miso,
    input  logic cs,
    input  logic sck,

    output logic i2s_clk,
    output logic i2s_ws,
    output logic i2s_lr,
    input  logic i2s_sd,

    output logic [SIZE_FULL_COUNT-1:0] full_count,
    output logic fifo_empty,
    output logic fifo_full,

    // DRAM interface
    inout  logic [31:0] ddram_dq,
    inout  logic [3:0]  ddram_dqs_n,
    inout  logic [3:0]  ddram_dqs_p,
    output logic [14:0] ddram_a,
    output logic [2:0]  ddram_ba,
    output logic        ddram_ras_n,
    output logic        ddram_cas_n,
    output logic        ddram_we_n,
    output logic        ddram_reset_n,
    output logic [0:0]  ddram_clk_p,
    output logic [0:0]  ddram_clk_n,
    output logic [0:0]  ddram_cke,
    output logic [0:0]  ddram_cs_n,
    output logic [3:0]  ddram_dm,
    output logic [0:0]  ddram_odt
);

    logic [2:0] busy_sync;
    logic data_in_valid, busy, data_out_valid, busy_posedge;

    logic [7:0] spi_send_data;

    logic pcm_ready;
    logic [15:0] pcm_out;

    logic mfcc_done, start_mfcc;

    mfcc_data_t coeficientes [0:11];

    MFCC_Core #(
        .SAMPLE_WIDTH     (16),
        .NUM_COEFFICIENTS (12),
        .NUM_FILTERS      (40),
        .FRAME_SIZE       (400),
        .FRAME_MOVE       (160),
        .FFT_SIZE         (512),
        .PCM_FIFO_DEPTH   (16),
        .ALPHA            (31785) // Alpha em Q1.15 (0.97 ≈ 31785)
    ) uut (
        .clk          (clk),
        .rst_n        (rst_n),

        .pcm_in       (pcm_out),
        .pcm_ready_i  (pcm_ready),

        .start_i      (start_mfcc), // Inicia o processamento imediatamente
        .mfcc_done_o  (mfcc_done),
        .mfcc_data_o  (coeficientes)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            start_mfcc <= 0;
        end else begin
            start_mfcc <= mfcc_done;
        end
    end

    I2S #(
        .DATA_OUT_SIZE (16),
        .I2S_DATA_SIZE (DATA_SIZE),
        .CLK_FREQ      (CLK_FREQ),
        .I2S_CLK_FREQ  (I2S_CLK_FREQ),
        .REDUCE_FACTOR (REDUCE_FACTOR)
    ) u_i2s (
        .clk       (clk),
        .rst_n     (rst_n),

        .i2s_clk   (i2s_clk),
        .i2s_ws    (i2s_ws),
        .i2s_sd    (i2s_sd),

        .pcm_out   (pcm_out),
        .pcm_ready (pcm_ready)  // A cada 24_414Hz
    );

    SPI_Slave #(
        .SPI_BITS_PER_WORD (8),
        .SPI_MODE          (0)
    ) U1 (
        .clk            (clk),
        .rst_n          (rst_n),

        .sck            (sck),
        .cs             (cs),
        .mosi           (mosi),
        .miso           (miso),

        .data_in_valid  (data_in_valid),
        .data_out_valid (data_out_valid),
        .busy           (busy),

        .data_in        (spi_send_data),
        .data_out       ()
    );

    logic fifo_wr_en, fifo_rd_en;
    logic [7:0] fifo_read_data, fifo_write_data;

    fifo #(
        .DEPTH        (FIFO_DEPTH),
        .WIDTH        (FIFO_WIDTH)
    ) tx_fifo (
        .clk          (clk),
        .rst_n        (rst_n),

        .wr_en_i      (fifo_wr_en),
        .rd_en_i      (fifo_rd_en),

        .write_data_i (fifo_write_data),
        .full_o       (fifo_full),
        .empty_o      (fifo_empty),
        .read_data_o  (fifo_read_data)
    );

    logic [2:0] state_full;
    always_ff @(posedge clk) begin
        state_full <= {state_full[1:0], fifo_full};  // anterior atual tmp
    end

    logic posedge_full;
    assign posedge_full = ~state_full[2] & state_full[1];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            full_count <= '0;
        end else if (posedge_full) begin
            full_count <= full_count + 1;
        end
    end

    logic [15:0] freeze_byte;

    typedef enum logic [1:0] {
        IDLE,
        WRITE_FIRST_BYTE,
        WRITE_SECOND_BYTE
    } write_fifo_state_t;

    write_fifo_state_t write_fifo_state;

    always_ff @(posedge clk) begin
        fifo_wr_en <= 1'b0;

        if (!rst_n) begin
            write_fifo_state <= IDLE;
            freeze_byte      <= '0;
        end else begin
            case (write_fifo_state)
                IDLE: begin
                    if (mfcc_done && !fifo_full) begin
                        freeze_byte      <= coeficientes[11].mfcc_sample;
                        fifo_write_data  <= coeficientes[11].mfcc_sample[7:0];
                        fifo_wr_en       <= 1'b1;
                        write_fifo_state <= WRITE_FIRST_BYTE;
                    end else begin
                        fifo_wr_en <= 1'b0;
                    end
                end
                WRITE_FIRST_BYTE: begin
                    if (!fifo_full) begin
                        fifo_write_data  <= freeze_byte[15:8];
                        fifo_wr_en       <= 1'b1;
                        write_fifo_state <= WRITE_SECOND_BYTE;
                    end else begin
                        fifo_wr_en <= 1'b0;
                    end
                end
                WRITE_SECOND_BYTE: begin
                    write_fifo_state <= IDLE;
                end
                default: write_fifo_state <= IDLE;
            endcase
        end
    end

    logic write_back_fifo;

    // Leitura do FIFO
    always_ff @(posedge clk) begin
        fifo_rd_en <= 1'b0;

        if (!rst_n) begin
            data_in_valid   <= 1'b0;
            spi_send_data   <= '0;
            write_back_fifo <= 1'b0;
        end else begin
            if (busy_posedge) begin
                if (fifo_empty) begin
                    data_in_valid   <= 1'b1;
                end else begin
                    fifo_rd_en      <= 1'b1;
                    write_back_fifo <= 1'b1;
                end
            end else begin
                data_in_valid <= 1'b0;
            end

            if (write_back_fifo) begin
                fifo_rd_en      <= 1'b0;
                write_back_fifo <= 1'b0;
                spi_send_data   <= fifo_read_data;
                data_in_valid   <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            busy_sync <= 3'b000;
        end else begin
            busy_sync <= {busy_sync[1:0], busy};
        end
    end

    assign busy_posedge = (busy_sync[2:1] == 2'b01) ? 1'b1 : 1'b0;
    assign i2s_lr       = 0; // Não usado, mas necessário para o I2S

    logic [255: 0] write_data, read_data;
    logic [24:0] real_addr;
    logic [31:0] addr;
    logic cyc, stb, we, ack;

    Wrapper #(
        .SYS_CLK_FREQ         (100_000_000),
        .WORD_SIZE            (256),
        .ADDR_WIDTH           (25),
        .FIFO_DEPTH           (8)
    ) u_Wrapper (
        .sys_clk              (clk),                           // 1 bit
        .rst_n                (rst_n),                         // 1 bit
        .initialized          (initialized),                   // 1 bit

        .cyc_i                (cyc),                           // 1 bit
        .stb_i                (stb),                           // 1 bit
        .we_i                 (we),                            // 1 bit
        .addr_i               (addr),                          // 32 bits
        .data_i               (write_data),                    // 256 bits
        .data_o               (read_data),                     // 256 bits
        .ack_o                (ack),                           // 1 bit

        .ddram_dq             (ddram_dq),                      // 32 bits
        .ddram_dqs_n          (ddram_dqs_n),                   // 4 bits
        .ddram_dqs_p          (ddram_dqs_p),                   // 4
        .ddram_a              (ddram_a),                       // 15 bits
        .ddram_ba             (ddram_ba),                      // 3 bits
        .ddram_cas_n          (ddram_cas_n),                   // 1 bit
        .ddram_cke            (ddram_cke),                     // 1 bit
        .ddram_clk_n          (ddram_clk_n),                   // 1 bit
        .ddram_clk_p          (ddram_clk_p),                   // 1 bit
        .ddram_cs_n           (ddram_cs_n),                    // 1 bit
        .ddram_dm             (ddram_dm),                      // 4 bits
        .ddram_odt            (ddram_odt),                     // 1 bit
        .ddram_ras_n          (ddram_ras_n),                   // 1 bit
        .ddram_reset_n        (ddram_reset_n),                 // 1 bit
        .ddram_we_n           (ddram_we_n)                     // 1 bit
    );

    assign cyc = 0;
    assign stb = 0;

endmodule
