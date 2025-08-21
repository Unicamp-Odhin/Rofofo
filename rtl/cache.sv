module Cache #(
    parameter WORD_SIZE  = 256,
    parameter CACHE_SIZE = 8192
    parameter ADDR_WIDTH = 32
) (
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic                     cpu_cyc_i,
    input  logic                     cpu_stb_i,
    input  logic                     cpu_we_i,
    output logic                     cpu_ack_o,
    input  logic [ADDR_WIDTH - 1: 0] cpu_addr_i,
    input  logic  [WORD_SIZE - 1: 0] cpu_mosi_i,
    output logic  [WORD_SIZE - 1: 0] cpu_miso_o,

    output logic                     mem_cyc_o,
    output logic                     mem_stb_o,
    output logic                     mem_we_o,
    input  logic                     mem_ack_i,
    output logic [ADDR_WIDTH - 1: 0] mem_addr_o,
    output logic  [WORD_SIZE - 1: 0] mem_mosi_o,
    input  logic  [WORD_SIZE - 1: 0] mem_miso_i
);

    localparam BLOCK_SIZE  = WORD_SIZE;
    localparam NUM_BYTES   = WORD_SIZE / 8;
    localparam CACHE_LINES = CACHE_SIZE / NUM_BYTES;
    localparam INDEX_BITS  = $clog2(CACHE_LINES);
    localparam OFFSET_BITS = $clog2(NUM_BYTES);
    localparam TAG_BITS    = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    typedef logic [WORD_SIZE - 1:0] cache_block_t;
    typedef logic [TAG_BITS  - 1:0] cache_tag_t;

    cache_block_t cache_data  [0:CACHE_LINES - 1];
    cache_tag_t   cache_tag   [0:CACHE_LINES - 1];
    logic         cache_valid [0:CACHE_LINES - 1];

    logic hit, i_hit, request;
    logic miss_finished, write_through;

    integer i;

    logic [INDEX_BITS - 1:0] index;
    logic [TAG_BITS   - 1:0] tag;

    assign index   = cpu_addr_i[OFFSET_BITS    +: INDEX_BITS]; // Slice crescente
    assign tag     = cpu_addr_i[ADDR_WIDTH - 1 -: TAG_BITS];   // Slice decrescente de ADDR_WIDTH - 1 até ADDR_WIDTH - 1 - TAG_BITS
    assign i_hit   = cache_valid[index] && (cache_tag[index] == tag);
    assign request = cpu_cyc_i && cpu_stb_i;
    assign hit     = i_hit && request && !cpu_we_i;

    always_ff @(posedge clk) begin : CACHE_LOGIC
        miss_finished <= 1'b0;

        if (!rst_n) begin
            write_through <= 1'b0;
            miss_finished <= 1'b0;
            //cache_valid   <= '{default: 1'b0}; // Inicializa todas as posições como inválidas
            for (i = 0; i < (CACHE_SIZE/4); i++) begin
                cache_valid[i] <= 1'b0;
            end
        end else begin 
            if (mem_ack_i && !we_i && !hit && request) begin
                cache_valid [index] <= 1'b1;
                cache_tag   [index] <= tag;
                cache_data  [index] <= mem_miso_i;
                miss_finished       <= 1'b1;
            end
            if (cpu_we_i && request) begin
                cache_valid [index] <= 1'b1;
                cache_tag   [index] <= tag;
                cache_data  [index] <= cpu_mosi_i;
                write_through       <= 1'b1;
            end
            if (write_through && mem_ack_i) begin
                miss_finished <= 1'b1;
                write_through <= 1'b0;
            end
        end
    end

    assign mem_addr_o = cpu_addr_i;
    assign mem_we_o   = write_through;
    assign mem_mosi_o = cpu_mosi_i;
    assign mem_cyc_o  = write_through | !hit;
    assign mem_stb_o  = write_through | !hit;

    // Saídas
    assign cpu_ack_o  = hit | miss_finished;
    assign cpu_data_o = cache_data[index];

endmodule