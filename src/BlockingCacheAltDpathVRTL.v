//=========================================================================
// Alternative Blocking Cache Datapath
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V

`include "vc/mem-msgs.v"

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
`include "vc/regs.v"
`include "vc/muxes.v"
`include "vc/srams.v"
`include "vc/arithmetic.v"

module lab3_mem_BlockingCacheAltDpathVRTL
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

  input logic cachereq_en,
  input logic memresp_en,
  input logic tag_array_ren,
  input logic tag_array_wen0,
  input logic tag_array_wen1,
  input logic data_array_ren,
  input logic data_array_wen,
  input logic [15:0] data_array_wben,
  input logic read_data_reg_en,
  input logic evict_addr_reg_en,

  // Selects

  input logic write_data_mux_sel,
  input logic [2:0] read_word_mux_sel,
  input logic memreq_addr_mux_sel,
  input logic way_sel,

  input logic [2:0] cacheresp_type,
  input logic [2:0] memreq_type,

  output logic [2:0] cachereq_type,
  output logic [31:0] cachereq_addr,
  output logic tag_match0,
  output logic tag_match1,
  input  logic [1:0] cacheresp_hit
);

  // local parameters not meant to be set from outside
  localparam size = 256;             // Cache size in bytes
  localparam dbw  = 32;              // Short name for data bitwidth
  localparam abw  = 32;              // Short name for addr bitwidth
  localparam o    = 8;               // Short name for opaque bitwidth
  localparam clw  = 128;             // Short name for cacheline bitwidth
  localparam nbl  = size*8/clw;      // Number of blocks in the cache
  localparam nby  = nbl/2;             // Number of blocks per way
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

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// Cache and Memory Struct Unpack
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

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// Module Tag Array
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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

// Tag Arrays
logic [27:0] tag_array_out0;
vc_CombinationalBitSRAM_1rw #( 28 , nby ) tag_array0(
  .clk( clk ),
  .reset( reset ),
  .read_en( tag_array_ren ),// want the same read so they can happen at the same time
  .read_addr( idx ), // cachereq_addr -> idx
  .read_data( tag_array_out0 ),// output of the tag array
  .write_en( tag_array_wen0 ),//writes way0 tag
  .write_addr( idx ), // cachereq_addr -> idx
  .write_data( addr )  // cachereq_addr -> addr[31:4]// should be the same 
);
//add variable names in order to compile
logic [27:0] tag_array_out1;
vc_CombinationalBitSRAM_1rw #( 28 , nby ) tag_array1(
  .clk( clk ),
  .reset( reset ),
  .read_en( tag_array_ren ),// want the same read so they can happen at the same time
  .read_addr( idx ), // cachereq_addr -> idx
  .read_data( tag_array_out1 ),//output tag way 1
  .write_en( tag_array_wen1 ),//write enable tag way 1
  .write_addr( idx ), // cachereq_addr -> idx
  .write_data( addr )  // cachereq_addr -> addr[31:4]// should be the same 
);

//add variable names in order to compile
vc_EqComparator #( 28 ) cmp0(
  .in0( addr ), 
  .in1( tag_array_out0 ),
  .out( tag_match0 )//this is a new variable
);

//add variable names in order to compile
vc_EqComparator #( 28 ) cmp1(
  .in0( addr ), 
  .in1( tag_array_out1 ),
  .out( tag_match1 )//this is a new variable
);

logic [27:0] tag_array_out;
vc_Mux2 #( 28 ) tag_addr_out_mux(
  .in0( tag_array_out0 ),
  .in1( tag_array_out1 ), // mk addr out from cacherew addr reg
  .sel( way_sel ),
  .out( tag_array_out )
); 
// add a mux here in for mk_addr1 
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

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// Module Data Array
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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

//chooses the correct index based on the way that has been choosen
logic [3:0] way_data_idx;
vc_Mux2 #( 4 ) correct_data_idx_mux(
  .in0( {1'b0, idx } ), // repl output
  .in1( {1'b1, idx } ),
  .sel( way_sel ),
  .out( way_data_idx )
); 

logic [clw-1:0] data_array_out;
vc_CombinationalSRAM_1rw #( clw, nbl ) data_array(
  .clk( clk ),
  .reset( reset ),
  .read_en( data_array_ren ),
  .read_addr( way_data_idx ), // cachereq_addr -> idx
  .read_data( data_array_out ),
  .write_en( data_array_wen ),
  .write_byte_en( data_array_wben ),
  .write_addr( way_data_idx ), // cachereq_addr -> idx
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

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// Cache and Memory Struct Pack
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

assign cacheresp_msg = { cacheresp_type, cachereq_opaque_reg_output, cacheresp_hit, 2'b0, read_word_mux_out}; 

assign memreq_msg = { memreq_type, 8'b0, memreq_addr_out, 4'b0, read_data_reg_output };

endmodule

`endif
