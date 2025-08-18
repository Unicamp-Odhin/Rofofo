module Cache #(
    parameter WORD_SIZE  = 256,
    parameter CACHE_SIZE = 8192
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    wishbone_0_cyc_i,
    input  logic                    wishbone_0_stb_i,
    input  logic                    wishbone_0_we_i,
    output logic                    wishbone_0_ack_o,
    input  logic             [31:0] wishbone_0_addr_i,
    input  logic [WORD_SIZE - 1: 0] wishbone_0_mosi_i,
    output logic [WORD_SIZE - 1: 0] wishbone_0_miso_o,

    input  logic                    wishbone_1_cyc_i,
    input  logic                    wishbone_1_stb_i,
    input  logic                    wishbone_1_we_i,
    output logic                    wishbone_1_ack_o,
    input  logic             [31:0] wishbone_1_addr_i,
    input  logic [WORD_SIZE - 1: 0] wishbone_1_mosi_i,
    output logic [WORD_SIZE - 1: 0] wishbone_1_miso_o,

    input  logic                    wishbone_2_cyc_i,
    input  logic                    wishbone_2_stb_i,
    input  logic                    wishbone_2_we_i,
    output logic                    wishbone_2_ack_o,
    input  logic             [31:0] wishbone_2_addr_i,
    input  logic [WORD_SIZE - 1: 0] wishbone_2_mosi_i,
    output logic [WORD_SIZE - 1: 0] wishbone_2_miso_o,

    output logic                    memory_cyc_o,
    output logic                    memory_stb_o,
    output logic                    memory_we_o,
    input  logic                    memory_ack_i,
    output logic             [31:0] memory_addr_o,
    output logic [WORD_SIZE - 1: 0] memory_mosi_o,
    input  logic [WORD_SIZE - 1: 0] memory_miso_i
);
    
    localparam BLOCK_SIZE = WORD_SIZE;
    localparam NUM_BYTES   = WORD_SIZE / 8;
    localparam ADDR_WIDTH  = $clog2(CACHE_SIZE);
    localparam TAG_SIZE    = 32 - ADDR_WIDTH;
    localparam OFFSET_SIZE = $clog2(NUM_BYTES);
    localparam CACHE_DEPTH = CACHE_SIZE / NUM_BYTES;

    typedef logic [BLOCK_SIZE - 1:0] cache_block_t;
    typedef logic [TAG_SIZE   - 1:0] cache_tag_t;

    cache_block_t cache_data  [0 : CACHE_DEPTH-1];
    cache_tag_t   cache_tag   [0 : CACHE_DEPTH-1];
    logic         cache_valid [0 : CACHE_DEPTH-1];

    always_ff @(posedge clk) begin : CACHE_LOGIC
        if(!rst_n) begin
            cache_valid <= '{default: 0};
        end else begin
            
        end
    end

    assign memory_stb_o = 0;
    assign memory_cyc_o = 0;
endmodule
