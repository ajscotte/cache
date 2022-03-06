//=========================================================================
// Baseline Blocking Cache Datapath
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_BASE_DPATH_V
`define LAB3_MEM_BLOCKING_CACHE_BASE_DPATH_V

`include "vc/mem-msgs.v"

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

`include "vc/regs.v"
`include "vc/muxes.v"
`include "vc/srams.v"
`include "vc/arithmetic.v"

module lab3_mem_BlockingCacheBaseDpathVRTL
#(
  parameter p_idx_shamt    = 0
)
(
  input  logic                        clk,
  input  logic                        reset,

  // Cache Request

  input  mem_req_4B_t                 cachereq_msg,

  // Cache Response

  output mem_resp_4B_t                cacheresp_msg,

  // Memory Request

  output mem_req_16B_t                memreq_msg,

  // Memory Response

  input  mem_resp_16B_t               memresp_msg,

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Define additional ports
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  // Enables

  input  logic                        cachereq_en,
  input  logic                        memresp_en,
  input  logic                        tag_array_ren,
  input  logic                        tag_array_wen,
  input  logic                        data_array_ren,
  input  logic                        data_array_wen,
  input  logic [15:0]                 data_array_wben,
  input  logic                        read_data_reg_en,
  input  logic                        evict_addr_reg_en,

  // Selects

  input  logic                        write_data_mux_sel,
  input  logic [2:0]                  read_word_mux_sel,
  input  logic                        memreq_addr_mux_sel,

  input  logic [2:0]                  cacheresp_type,
  input  logic [2:0]                  memreq_type,

  input  logic [1:0]                  cacheresp_hit,
  output logic [2:0]                  cachereq_type,
  output logic [31:0]                 cachereq_addr,
  output logic                        tag_match
);

  // local parameters not meant to be set from outside
  localparam size = 256;             // Cache size in bytes
  localparam dbw  = 32;              // Short name for data bitwidth
  localparam abw  = 32;              // Short name for addr bitwidth
  localparam o    = 8;               // Short name for opaque bitwidth
  localparam clw  = 128;             // Short name for cacheline bitwidth
  localparam nbl  = size*8/clw;      // Number of blocks in the cache
  localparam nby  = nbl;             // Number of blocks per way
  localparam idw  = $clog2(nby);     // Short name for index bitwidth
  localparam ofw  = $clog2(clw/8);   // Short name for the offset bitwidth
  // In this lab, to simplify things, we always use all bits except for the
  // offset in the tag, rather than storing the "normal" 24 bits. This way,
  // when implementing a multi-banked cache, we don't need to worry about
  // re-inserting the bank id into the address of a cacheline.
  localparam tgw  = abw - ofw;       // Short name for the tag bitwidth

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Implement data-path
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

// Cache Request Message
logic [2:0] cachereq_type_in;
assign cachereq_type_in = cachereq_msg.type_;

logic [7:0]  cachereq_opaque;
assign cachereq_opaque = cachereq_msg.opaque;

logic [31:0] cachereq_addr_in;
assign cachereq_addr_in = cachereq_msg.addr;

logic [1:0] cachereq_len;
assign cachereq_len = cachereq_msg.len;

logic [31:0] cachereq_data;
assign cachereq_data = cachereq_msg.data;

// Memory Response Message
logic [127:0] memresp_data;
assign memresp_data = memresp_msg.data;

logic [31:0] cache_data_reg_out;
logic [7:0] cachereq_opaque_reg_output;
logic [dbw-1:0] read_word_mux_out;
logic [idw-1:0] idx;
logic [abw-1:0] memreq_addr_out;
logic [clw-1:0] read_data_reg_output;

tag_array ta(
  .clk(clk),
  .reset(reset),
  .cachereq_type_in(cachereq_type_in),
  .cachereq_opaque(cachereq_opaque),
  .cachereq_addr_in(cachereq_addr_in),
  .cachereq_len(cachereq_len),
  .cachereq_data(cachereq_data),
  .cachereq_en(cachereq_en),
  .memresp_en(memresp_en),
  .tag_array_ren(tag_array_ren),
  .tag_array_wen(tag_array_wen),
  .evict_addr_reg_en(evict_addr_reg_en),
  .memreq_addr_mux_sel(memreq_addr_mux_sel),
  .cachereq_type(cachereq_type),
  .cachereq_addr(cachereq_addr),
  .tag_match(tag_match),
  .cache_data_reg_out(cache_data_reg_out),
  .idx(idx),
  .cachereq_opaque_reg_output(cachereq_opaque_reg_output),
  .memreq_addr_out(memreq_addr_out)
);

data_array da(
  .clk(clk),
  .reset(reset),
  .memresp_data(memresp_data),
  .memresp_en(memresp_en),
  .read_data_reg_en(read_data_reg_en),
  .write_data_mux_sel(write_data_mux_sel),
  .read_word_mux_sel(read_word_mux_sel),
  .cache_data_reg_out(cache_data_reg_out),
  .data_array_ren(data_array_ren),
  .data_array_wen(data_array_wen),
  .data_array_wben(data_array_wben),
  .idx(idx),
  .read_word_mux_out(read_word_mux_out),
  .read_data_reg_output(read_data_reg_output)
);

assign cacheresp_msg = { cacheresp_type, cachereq_opaque_reg_output, cacheresp_hit, 2'b0, read_word_mux_out}; 

assign memreq_msg = { memreq_type, 8'b0, memreq_addr_out, 4'b0, read_data_reg_output };

endmodule

`endif

module tag_array
#(
  parameter p_idx_shamt    = 0
)
(
  input logic        clk,
  input logic        reset,
  input logic [2:0]  cachereq_type_in,
  input logic [7:0]  cachereq_opaque,
  input logic [31:0] cachereq_addr_in,
  input logic [1:0]  cachereq_len,
  input logic [31:0] cachereq_data,
  input logic        cachereq_en,
  input logic        memresp_en,
  input logic        tag_array_ren,
  input logic        tag_array_wen,
  input logic        evict_addr_reg_en,
  input logic        memreq_addr_mux_sel,
  output logic [2:0]  cachereq_type,
  output logic [31:0] cachereq_addr,
  output logic        tag_match,
  output logic [31:0] cache_data_reg_out,
  output logic [3:0] idx,
  output logic [7:0] cachereq_opaque_reg_output,
  output logic [31:0] memreq_addr_out
);

  // local parameters not meant to be set from outside
  localparam size = 256;             // Cache size in bytes
  localparam dbw  = 32;              // Short name for data bitwidth
  localparam abw  = 32;              // Short name for addr bitwidth
  localparam o    = 8;               // Short name for opaque bitwidth
  localparam clw  = 128;             // Short name for cacheline bitwidth
  localparam nbl  = size*8/clw;      // Number of blocks in the cache
  localparam nby  = nbl;             // Number of blocks per way
  localparam idw  = $clog2(nby);     // Short name for index bitwidth
  localparam ofw  = $clog2(clw/8);   // Short name for the offset bitwidth
  // In this lab, to simplify things, we always use all bits except for the
  // offset in the tag, rather than storing the "normal" 24 bits. This way,
  // when implementing a multi-banked cache, we don't need to worry about
  // re-inserting the bank id into the address of a cacheline.
  localparam tgw  = abw - ofw;       // Short name for the tag bitwidth

  logic [o-1:0] cachereq_opaque_reg_output;
  vc_EnReg #( o ) cachereq_opaque_reg(
    .clk( clk ),                     // Clock Input
    .reset( reset ),                 // Sync Reset Input
    .en( cachereq_en ),
    .q( cachereq_opaque_reg_output ),// Data Output
    .d( cachereq_opaque )            // Data Input
  );

  logic [2:0] cachereq_type;
  vc_EnReg #( 3 ) cachereq_type_reg(
    .clk( clk ),           // Clock Input
    .reset( reset ),       // Sync Reset Input
    .en( cachereq_en ),
    .q( cachereq_type ),   // Data Output
    .d( cachereq_type_in ) // Data Input
  );

  logic [abw-1:0] cachereq_addr;
  vc_EnReg #( abw ) cachereq_addr_reg(
    .clk( clk ),               // Clock Input
    .reset( reset ),           // Sync Reset Input
    .en( cachereq_en ),
    .q( cachereq_addr ),  // Data Output
    .d( cachereq_addr_in )        // Data Input
  );

  logic [idw-1:0] idx;
  assign idx = cachereq_addr[idw + 3 + p_idx_shamt:4 + p_idx_shamt];

  logic [27:0] addr; //addr [31:4]
  assign addr = cachereq_addr[31:4];

  logic [31:0] cache_data_reg_out;
  vc_EnReg #( dbw ) cachereq_data_reg(
    .clk( clk ),                  // Clock Input
    .reset( reset ),              // Sync Reset Input
    .en( cachereq_en ),
    .q( cache_data_reg_out ),     // Data Output
    .d( cachereq_data )           // Data Input
  );

  // Tag Array
  logic [27:0] tag_array_out;
  vc_CombinationalBitSRAM_1rw #( 28 , nbl ) tag_array(
    .clk( clk ),
    .reset( reset ),
    .read_en( tag_array_ren ),
    .read_addr( idx ), // cachereq_addr -> idx
    .read_data( tag_array_out ),
    .write_en( tag_array_wen ),
    .write_addr( idx ), // cachereq_addr -> idx
    .write_data( addr )  // cachereq_addr -> addr[31:4]
  );

  vc_EqComparator #( 28 ) cmp(
    .in0( addr ), 
    .in1( tag_array_out ),
    .out( tag_match )
  );

  logic [31:0] mk_addr1;
  assign mk_addr1 = { tag_array_out, 4'b0000 };

  logic [31:0] mk_addr2;
  assign mk_addr2 = { addr, 4'b0000 };

  logic [abw-1:0] evict_addr_reg_out;
  vc_EnReg #( abw ) evict_addr_reg(
    .clk( clk ),                  // Clock Input
    .reset( reset ),              // Sync Reset Input
    .en( evict_addr_reg_en ),
    .q( evict_addr_reg_out ),     // Data Output
    .d( mk_addr1 )                 // Data Input
  );

  logic [abw-1:0] memreq_addr_out;
  vc_Mux2 #( abw ) memreq_addr_mux(
    .in0( evict_addr_reg_out ),
    .in1( mk_addr2 ), // mk addr out from cacherew addr reg
    .sel( memreq_addr_mux_sel ),
    .out( memreq_addr_out )
  ); 
  endmodule

  module data_array(
  input logic clk,
  input logic reset,
  input logic [127:0] memresp_data,
  input logic memresp_en,
  input logic read_data_reg_en,
  input logic write_data_mux_sel,
  input logic [2:0] read_word_mux_sel,
  input logic [31:0] cache_data_reg_out,
  input logic data_array_ren,
  input logic data_array_wen,
  input logic [15:0] data_array_wben,
  input logic [3:0] idx,
  output logic [31:0] read_word_mux_out,
  output logic [127:0] read_data_reg_output
);
  // local parameters not meant to be set from outside
  localparam size = 256;             // Cache size in bytes
  localparam dbw  = 32;              // Short name for data bitwidth
  localparam abw  = 32;              // Short name for addr bitwidth
  localparam o    = 8;               // Short name for opaque bitwidth
  localparam clw  = 128;             // Short name for cacheline bitwidth
  localparam nbl  = size*8/clw;      // Number of blocks in the cache
  localparam nby  = nbl;             // Number of blocks per way
  localparam idw  = $clog2(nby);     // Short name for index bitwidth
  localparam ofw  = $clog2(clw/8);   // Short name for the offset bitwidth
  // In this lab, to simplify things, we always use all bits except for the
  // offset in the tag, rather than storing the "normal" 24 bits. This way,
  // when implementing a multi-banked cache, we don't need to worry about
  // re-inserting the bank id into the address of a cacheline.
  localparam tgw  = abw - ofw;       // Short name for the tag bitwidth

  logic [clw-1:0] memresp_data_reg_out;
  vc_EnReg #( clw ) memresp_data_reg(
    .clk( clk ),   // Clock Input
    .reset( reset ), // Sync Reset Input
    .en( memresp_en ),
    .q( memresp_data_reg_out ),     // Data Output
    .d( memresp_data )      // Data Input
  );

  logic [127:0] replicate_cache_data_reg_out;
  assign replicate_cache_data_reg_out = {cache_data_reg_out, cache_data_reg_out, cache_data_reg_out, cache_data_reg_out};

  logic [clw-1:0] write_data_mux_out;
  vc_Mux2 #( clw ) write_data_mux(
    .in0( replicate_cache_data_reg_out ), // repl output
    .in1( memresp_data_reg_out ),
    .sel( write_data_mux_sel ),
    .out( write_data_mux_out )
  ); 

  logic [clw-1:0] data_array_out;
  vc_CombinationalSRAM_1rw #( clw, nbl ) data_array(
    .clk( clk ),
    .reset( reset ),
    .read_en( data_array_ren ),
    .read_addr( idx ), // cachereq_addr -> idx
    .read_data( data_array_out ),
    .write_en( data_array_wen ),
    .write_byte_en( data_array_wben ),
    .write_addr( idx ), // cachereq_addr -> idx
    .write_data( write_data_mux_out ) 
  );

  logic [clw-1:0] read_data_reg_output;
  vc_EnReg #( clw ) read_data_reg(
    .clk( clk ),   // Clock Input
    .reset( reset ), // Sync Reset Input
    .en( read_data_reg_en ),
    .q( read_data_reg_output ),     // Data Output
    .d( data_array_out )      // Data Input
  );

  logic [dbw-1:0] read_word_mux_out;
  vc_Mux5 #( dbw ) read_word_mux(
    .in3( read_data_reg_output[127:96] ),
    .in2( read_data_reg_output[95:64] ),
    .in1( read_data_reg_output[63:32] ),
    .in0( read_data_reg_output[31:0] ),
    .in4( 32'b0 ),
    .sel( read_word_mux_sel ),
    .out( read_word_mux_out )
  ); 
endmodule