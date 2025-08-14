`define COMPRESS_OUT 1

module top (
    input  logic clk, // 50MHz
    input  logic rst_n,

    // I/Os
    input  logic [3:0] btn,
    output logic [7:0] led,

    // SPI Slave
    input  logic mosi,
    output logic miso,
    input  logic sck,
    input  logic cs,
    input  logic spi_rst,

    // Uart
    input  logic rxd,
    output logic txd,

    // I2S Microfone
    output logic i2s_clk,  // Clock do I2S
    output logic i2s_ws,   // Word Select do I2S
    output logic i2s_lr,   // Left/Right Select do I2S
    input  logic i2s_sd,   // Dados do I2S

    // Oled display
    output logic OLED_DC,
    output logic OLED_RST,
    output logic OLED_SCL,
    output logic OLED_SDA,

    // DRAM Interface
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
    logic locked, sys_clk_100mhz, initialized;

    clk_wiz_0 clk_wiz_0_inst (
        .clk_out1 (sys_clk_100mhz), // 100 MHz system clock
        .resetn   (rst_n),          // Active low reset
        .locked   (locked),         // Locked signal
        .clk_in1  (clk)             // System clock - 50 MHz
    );

    Rofofo #(
        .CLK_FREQ             (100_000_000),  // Frequência do clock do sistema
        .I2S_CLK_FREQ         (1_500_000),
        .FIFO_DEPTH           (128),
        .FIFO_WIDTH           (8),
        .DATA_SIZE            (24),
        .REDUCE_FACTOR        (2),
        .SIZE_FULL_COUNT      (6)
    ) u_Rofofo (
        .clk                  (sys_clk_100mhz),
        .rst_n                (rst_n),
        
        .mosi                 (mosi),
        .miso                 (miso),
        .cs                   (cs),
        .sck                  (sck),
 
        .i2s_clk              (i2s_clk),
        .i2s_ws               (i2s_ws),
        .i2s_lr               (i2s_lr),
        .i2s_sd               (i2s_sd),
 
        .full_count           (led[7:2]),
        .fifo_empty           (led[1]),
        .fifo_full            (led[0]),

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
    
endmodule
