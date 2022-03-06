//-----------------------------------------------------------------------------
// BlockingCacheAltVRTL_0x2c17710888324bdd
//-----------------------------------------------------------------------------
// num_banks: 3
// dump-vcd: True
// verilator-xinit: zeros
`default_nettype none
module BlockingCacheAltVRTL_0x2c17710888324bdd
(
  input  wire [  76:0] cachereq_msg,
  output wire [   0:0] cachereq_rdy,
  input  wire [   0:0] cachereq_val,
  output wire [  46:0] cacheresp_msg,
  input  wire [   0:0] cacheresp_rdy,
  output wire [   0:0] cacheresp_val,
  input  wire [   0:0] clk,
  output wire [ 174:0] memreq_msg,
  input  wire [   0:0] memreq_rdy,
  output wire [   0:0] memreq_val,
  input  wire [ 144:0] memresp_msg,
  output wire [   0:0] memresp_rdy,
  input  wire [   0:0] memresp_val,
  input  wire [   0:0] reset
);

  // Imported Verilog source from:
  // /home/ajs667/ece4750/lab-group15/sim/lab3_mem/BlockingCacheAltVRTL.v

  lab3_mem_BlockingCacheAltVRTL#(
    .p_num_banks ( 3 )
  )  verilog_module
  (
    .cachereq_msg  ( cachereq_msg ),
    .cachereq_rdy  ( cachereq_rdy ),
    .cachereq_val  ( cachereq_val ),
    .cacheresp_msg ( cacheresp_msg ),
    .cacheresp_rdy ( cacheresp_rdy ),
    .cacheresp_val ( cacheresp_val ),
    .clk           ( clk ),
    .memreq_msg    ( memreq_msg ),
    .memreq_rdy    ( memreq_rdy ),
    .memreq_val    ( memreq_val ),
    .memresp_msg   ( memresp_msg ),
    .memresp_rdy   ( memresp_rdy ),
    .memresp_val   ( memresp_val ),
    .reset         ( reset )
  );

endmodule // BlockingCacheAltVRTL_0x2c17710888324bdd
`default_nettype wire

`line 1 "lab3_mem/BlockingCacheAltVRTL.v" 0
//=========================================================================
// Alternative Blocking Cache
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_V

`line 1 "vc/mem-msgs.v" 0
//========================================================================
// vc-mem-msgs : Memory Request/Response Messages
//========================================================================
// The memory request/response messages are used to interact with various
// memories. They are parameterized by the number of bits in the address,
// data, and opaque field.

`ifndef VC_MEM_MSGS_V
`define VC_MEM_MSGS_V

`line 1 "vc/trace.v" 0
//========================================================================
// Line Tracing
//========================================================================

`ifndef VC_TRACE_V
`define VC_TRACE_V

// NOTE: This macro is declared outside of the module to allow some vc
// modules to see it and use it in their own params. Verilog does not
// allow other modules to hierarchically reference the nbits localparam
// inside this module in constant expressions (e.g., localparams).

`define VC_TRACE_NCHARS 512
`define VC_TRACE_NBITS  512*8

module vc_Trace
(
  input logic clk,
  input logic reset
);

  integer len0;
  integer len1;
  integer idx0;
  integer idx1;

  // NOTE: If you change these, then you also need to change the
  // hard-coded constant in the declaration of the trace function at the
  // bottom of this file.
  // NOTE: You would also need to change the VC_TRACE_NBITS and
  // VC_TRACE_NCHARS macro at the top of this file.

  localparam nchars = 512;
  localparam nbits  = 512*8;

  // This is the actual trace storage used when displaying a trace

  logic [nbits-1:0] storage;

  // Meant to be accesible from outside module

  integer cycles_next = 0;
  integer cycles      = 0;

  // Get trace level from command line

  logic [3:0] level;

`ifndef VERILATOR
  initial begin
    if ( !$value$plusargs( "trace=%d", level ) ) begin
      level = 0;
    end
  end
`else
  initial begin
    level = 1;
  end
`endif // !`ifndef VERILATOR

  // Track cycle count

  always_ff @( posedge clk ) begin
    cycles <= ( reset ) ? 0 : cycles_next;
  end

  //----------------------------------------------------------------------
  // append_str
  //----------------------------------------------------------------------
  // Appends a string to the trace.

  task append_str
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    len0 = 1;
    while ( str[len0*8+:8] != 0 ) begin
      len0 = len0 + 1;
    end

    idx0 = trace[31:0];

    for ( idx1 = len0-1; idx1 >= 0; idx1 = idx1 - 1 )
    begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8 +: 8 ];
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_str_ljust
  //----------------------------------------------------------------------
  // Appends a left-justified string to the trace.

  task append_str_ljust
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    idx0 = trace[31:0];
    idx1 = nchars;

    while ( str[ idx1*8-1 -: 8 ] != 0 ) begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8-1 -: 8 ];
      idx0 = idx0 - 1;
      idx1 = idx1 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_chars
  //----------------------------------------------------------------------
  // Appends the given number of characters to the trace.

  task append_chars
  (
    inout logic   [nbits-1:0] trace,
    input logic         [7:0] char,
    input integer             num
  );
  begin

    idx0 = trace[31:0];

    for ( idx1 = 0;
          idx1 < num;
          idx1 = idx1 + 1 )
    begin
      trace[idx0*8+:8] = char;
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_val_str
  //----------------------------------------------------------------------
  // Append a string modified by val signal.

  task append_val_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( val )
      append_str( trace, str );
    else if ( !val )
      append_chars( trace, " ", len1 );
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

  //----------------------------------------------------------------------
  // val_rdy_str
  //----------------------------------------------------------------------
  // Append a string modified by val/rdy signals.

  task append_val_rdy_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic             rdy,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( rdy && val ) begin
      append_str( trace, str );
    end
    else if ( rdy && !val ) begin
      append_chars( trace, " ", len1 );
    end
    else if ( !rdy && val ) begin
      append_str( trace, "#" );
      append_chars( trace, " ", len1-1 );
    end
    else if ( !rdy && !val ) begin
      append_str( trace, "." );
      append_chars( trace, " ", len1-1 );
    end
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

endmodule

//------------------------------------------------------------------------
// VC_TRACE_NBITS_TO_NCHARS
//------------------------------------------------------------------------
// Macro to determine number of characters for a net

`define VC_TRACE_NBITS_TO_NCHARS( nbits_ ) ((nbits_+3)/4)

//------------------------------------------------------------------------
// VC_TRACE_BEGIN
//------------------------------------------------------------------------

//`define VC_TRACE_BEGIN                                                  \
//  export "DPI-C" task line_trace;                                       \
//  vc_Trace vc_trace(clk,reset);                                         \
//  task line_trace( inout bit [(512*8)-1:0] trace_str );

`ifndef VERILATOR
`define VC_TRACE_BEGIN                                                  \
  vc_Trace vc_trace(clk,reset);                                         \
                                                                        \
  task display_trace;                                                   \
  begin                                                                 \
                                                                        \
    if ( vc_trace.level > 0 ) begin                                     \
      vc_trace.storage[15:0] = vc_trace.nchars-1;                       \
                                                                        \
      line_trace( vc_trace.storage );                                   \
                                                                        \
      $write( "%4d: ", vc_trace.cycles );                               \
                                                                        \
      vc_trace.idx0 = vc_trace.storage[15:0];                           \
      for ( vc_trace.idx1 = vc_trace.nchars-1;                          \
            vc_trace.idx1 > vc_trace.idx0;                              \
            vc_trace.idx1 = vc_trace.idx1 - 1 )                         \
      begin                                                             \
        $write( "%s", vc_trace.storage[vc_trace.idx1*8+:8] );           \
      end                                                               \
      $write("\n");                                                     \
                                                                        \
    end                                                                 \
                                                                        \
    vc_trace.cycles_next = vc_trace.cycles + 1;                         \
                                                                        \
  end                                                                   \
  endtask                                                               \
                                                                        \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`else
`define VC_TRACE_BEGIN                                                  \
  export "DPI-C" task line_trace;                                       \
  vc_Trace vc_trace(clk,reset);                                         \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`endif

//------------------------------------------------------------------------
// VC_TRACE_END
//------------------------------------------------------------------------

`define VC_TRACE_END \
  endtask

`endif /* VC_TRACE_V */


`line 12 "vc/mem-msgs.v" 0

//========================================================================
// Memory Request Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// requests include an opaque field, the address, and the number of bytes
// to read, while write requests include an opaque field, the address,
// the number of bytes to write, and the actual data to write.
//
// Message Format:
//
//    3b    p_opaque_nbits  p_addr_nbits       calc   p_data_nbits
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field, address field, and data field. Note that the size of the length
// field is caclulated from the number of bits in the data field, and
// that the length field is expressed in _bytes_. If the value of the
// length field is zero, then the read or write should be for the full
// width of the data field.
//
// For example, if the opaque field is 8 bits, the address is 32 bits and
// the data is also 32 bits, then the message format is as follows:
//
//   76  74 73           66 65              34 33  32 31               0
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The length field is two bits. A length value of one means read or write
// a single byte, a length value of two means read or write two bytes, and
// so on. A length value of zero means read or write all four bytes. Note
// that not all memories will necessarily support any alignment and/or any
// value for the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [1:0]  len;
  logic [31:0] data;
} mem_req_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [3:0]  len;
  logic [127:0] data;
} mem_req_16B_t;

// memory request type values
`define VC_MEM_REQ_MSG_TYPE_READ     3'd0
`define VC_MEM_REQ_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_REQ_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_REQ_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_REQ_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_REQ_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_REQ_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Request Message: Trace message
//------------------------------------------------------------------------

module vc_MemReqMsg4BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_4B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_4B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemReqMsg16BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_16B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_16B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

//========================================================================
// Memory Response Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// responses include an opaque field, the actual data, and the number of
// bytes, while write responses currently include just the opaque field.
//
// Message Format:
//
//    3b    p_opaque_nbits   2b    calc   p_data_nbits
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field and data field. Note that the size of the length field is
// caclulated from the number of bits in the data field, and that the
// length field is expressed in _bytes_. If the value of the length field
// is zero, then the read or write should be for the full width of the
// data field.
//
// For example, if the opaque field is 8 bits and the data is 32 bits,
// then the message format is as follows:
//
//   46  44 43           36 35  34 33  32 31               0
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The length field is two bits. A length value of one means one byte was
// read, a length value of two means two bytes were read, and so on. A
// length value of zero means all four bytes were read. Note that not all
// memories will necessarily support any alignment and/or any value for
// the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [1:0]  len;
  logic [31:0] data;
} mem_resp_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [3:0]  len;
  logic [127:0] data;
} mem_resp_16B_t;

// Values for the type field

`define VC_MEM_RESP_MSG_TYPE_READ     3'd0
`define VC_MEM_RESP_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_RESP_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_RESP_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_RESP_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_RESP_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_RESP_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Response Message: Trace message
//------------------------------------------------------------------------

module vc_MemRespMsg4BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_4B_t  msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_4B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemRespMsg16BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_16B_t msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0] data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_16B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

`endif /* VC_MEM_MSGS_V */


`line 9 "lab3_mem/BlockingCacheAltVRTL.v" 0
`line 1 "vc/trace.v" 0
//========================================================================
// Line Tracing
//========================================================================

`ifndef VC_TRACE_V
`define VC_TRACE_V

// NOTE: This macro is declared outside of the module to allow some vc
// modules to see it and use it in their own params. Verilog does not
// allow other modules to hierarchically reference the nbits localparam
// inside this module in constant expressions (e.g., localparams).

`define VC_TRACE_NCHARS 512
`define VC_TRACE_NBITS  512*8

module vc_Trace
(
  input logic clk,
  input logic reset
);

  integer len0;
  integer len1;
  integer idx0;
  integer idx1;

  // NOTE: If you change these, then you also need to change the
  // hard-coded constant in the declaration of the trace function at the
  // bottom of this file.
  // NOTE: You would also need to change the VC_TRACE_NBITS and
  // VC_TRACE_NCHARS macro at the top of this file.

  localparam nchars = 512;
  localparam nbits  = 512*8;

  // This is the actual trace storage used when displaying a trace

  logic [nbits-1:0] storage;

  // Meant to be accesible from outside module

  integer cycles_next = 0;
  integer cycles      = 0;

  // Get trace level from command line

  logic [3:0] level;

`ifndef VERILATOR
  initial begin
    if ( !$value$plusargs( "trace=%d", level ) ) begin
      level = 0;
    end
  end
`else
  initial begin
    level = 1;
  end
`endif // !`ifndef VERILATOR

  // Track cycle count

  always_ff @( posedge clk ) begin
    cycles <= ( reset ) ? 0 : cycles_next;
  end

  //----------------------------------------------------------------------
  // append_str
  //----------------------------------------------------------------------
  // Appends a string to the trace.

  task append_str
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    len0 = 1;
    while ( str[len0*8+:8] != 0 ) begin
      len0 = len0 + 1;
    end

    idx0 = trace[31:0];

    for ( idx1 = len0-1; idx1 >= 0; idx1 = idx1 - 1 )
    begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8 +: 8 ];
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_str_ljust
  //----------------------------------------------------------------------
  // Appends a left-justified string to the trace.

  task append_str_ljust
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    idx0 = trace[31:0];
    idx1 = nchars;

    while ( str[ idx1*8-1 -: 8 ] != 0 ) begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8-1 -: 8 ];
      idx0 = idx0 - 1;
      idx1 = idx1 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_chars
  //----------------------------------------------------------------------
  // Appends the given number of characters to the trace.

  task append_chars
  (
    inout logic   [nbits-1:0] trace,
    input logic         [7:0] char,
    input integer             num
  );
  begin

    idx0 = trace[31:0];

    for ( idx1 = 0;
          idx1 < num;
          idx1 = idx1 + 1 )
    begin
      trace[idx0*8+:8] = char;
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_val_str
  //----------------------------------------------------------------------
  // Append a string modified by val signal.

  task append_val_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( val )
      append_str( trace, str );
    else if ( !val )
      append_chars( trace, " ", len1 );
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

  //----------------------------------------------------------------------
  // val_rdy_str
  //----------------------------------------------------------------------
  // Append a string modified by val/rdy signals.

  task append_val_rdy_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic             rdy,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( rdy && val ) begin
      append_str( trace, str );
    end
    else if ( rdy && !val ) begin
      append_chars( trace, " ", len1 );
    end
    else if ( !rdy && val ) begin
      append_str( trace, "#" );
      append_chars( trace, " ", len1-1 );
    end
    else if ( !rdy && !val ) begin
      append_str( trace, "." );
      append_chars( trace, " ", len1-1 );
    end
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

endmodule

//------------------------------------------------------------------------
// VC_TRACE_NBITS_TO_NCHARS
//------------------------------------------------------------------------
// Macro to determine number of characters for a net

`define VC_TRACE_NBITS_TO_NCHARS( nbits_ ) ((nbits_+3)/4)

//------------------------------------------------------------------------
// VC_TRACE_BEGIN
//------------------------------------------------------------------------

//`define VC_TRACE_BEGIN                                                  \
//  export "DPI-C" task line_trace;                                       \
//  vc_Trace vc_trace(clk,reset);                                         \
//  task line_trace( inout bit [(512*8)-1:0] trace_str );

`ifndef VERILATOR
`define VC_TRACE_BEGIN                                                  \
  vc_Trace vc_trace(clk,reset);                                         \
                                                                        \
  task display_trace;                                                   \
  begin                                                                 \
                                                                        \
    if ( vc_trace.level > 0 ) begin                                     \
      vc_trace.storage[15:0] = vc_trace.nchars-1;                       \
                                                                        \
      line_trace( vc_trace.storage );                                   \
                                                                        \
      $write( "%4d: ", vc_trace.cycles );                               \
                                                                        \
      vc_trace.idx0 = vc_trace.storage[15:0];                           \
      for ( vc_trace.idx1 = vc_trace.nchars-1;                          \
            vc_trace.idx1 > vc_trace.idx0;                              \
            vc_trace.idx1 = vc_trace.idx1 - 1 )                         \
      begin                                                             \
        $write( "%s", vc_trace.storage[vc_trace.idx1*8+:8] );           \
      end                                                               \
      $write("\n");                                                     \
                                                                        \
    end                                                                 \
                                                                        \
    vc_trace.cycles_next = vc_trace.cycles + 1;                         \
                                                                        \
  end                                                                   \
  endtask                                                               \
                                                                        \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`else
`define VC_TRACE_BEGIN                                                  \
  export "DPI-C" task line_trace;                                       \
  vc_Trace vc_trace(clk,reset);                                         \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`endif

//------------------------------------------------------------------------
// VC_TRACE_END
//------------------------------------------------------------------------

`define VC_TRACE_END \
  endtask

`endif /* VC_TRACE_V */


`line 10 "lab3_mem/BlockingCacheAltVRTL.v" 0

`line 1 "lab3_mem/BlockingCacheAltCtrlVRTL.v" 0
//=========================================================================
// Alternative Blocking Cache Control Unit
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V

`line 1 "vc/mem-msgs.v" 0
//========================================================================
// vc-mem-msgs : Memory Request/Response Messages
//========================================================================
// The memory request/response messages are used to interact with various
// memories. They are parameterized by the number of bits in the address,
// data, and opaque field.

`ifndef VC_MEM_MSGS_V
`define VC_MEM_MSGS_V

`line 1 "vc/trace.v" 0
//========================================================================
// Line Tracing
//========================================================================

`ifndef VC_TRACE_V
`define VC_TRACE_V

// NOTE: This macro is declared outside of the module to allow some vc
// modules to see it and use it in their own params. Verilog does not
// allow other modules to hierarchically reference the nbits localparam
// inside this module in constant expressions (e.g., localparams).

`define VC_TRACE_NCHARS 512
`define VC_TRACE_NBITS  512*8

module vc_Trace
(
  input logic clk,
  input logic reset
);

  integer len0;
  integer len1;
  integer idx0;
  integer idx1;

  // NOTE: If you change these, then you also need to change the
  // hard-coded constant in the declaration of the trace function at the
  // bottom of this file.
  // NOTE: You would also need to change the VC_TRACE_NBITS and
  // VC_TRACE_NCHARS macro at the top of this file.

  localparam nchars = 512;
  localparam nbits  = 512*8;

  // This is the actual trace storage used when displaying a trace

  logic [nbits-1:0] storage;

  // Meant to be accesible from outside module

  integer cycles_next = 0;
  integer cycles      = 0;

  // Get trace level from command line

  logic [3:0] level;

`ifndef VERILATOR
  initial begin
    if ( !$value$plusargs( "trace=%d", level ) ) begin
      level = 0;
    end
  end
`else
  initial begin
    level = 1;
  end
`endif // !`ifndef VERILATOR

  // Track cycle count

  always_ff @( posedge clk ) begin
    cycles <= ( reset ) ? 0 : cycles_next;
  end

  //----------------------------------------------------------------------
  // append_str
  //----------------------------------------------------------------------
  // Appends a string to the trace.

  task append_str
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    len0 = 1;
    while ( str[len0*8+:8] != 0 ) begin
      len0 = len0 + 1;
    end

    idx0 = trace[31:0];

    for ( idx1 = len0-1; idx1 >= 0; idx1 = idx1 - 1 )
    begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8 +: 8 ];
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_str_ljust
  //----------------------------------------------------------------------
  // Appends a left-justified string to the trace.

  task append_str_ljust
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    idx0 = trace[31:0];
    idx1 = nchars;

    while ( str[ idx1*8-1 -: 8 ] != 0 ) begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8-1 -: 8 ];
      idx0 = idx0 - 1;
      idx1 = idx1 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_chars
  //----------------------------------------------------------------------
  // Appends the given number of characters to the trace.

  task append_chars
  (
    inout logic   [nbits-1:0] trace,
    input logic         [7:0] char,
    input integer             num
  );
  begin

    idx0 = trace[31:0];

    for ( idx1 = 0;
          idx1 < num;
          idx1 = idx1 + 1 )
    begin
      trace[idx0*8+:8] = char;
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_val_str
  //----------------------------------------------------------------------
  // Append a string modified by val signal.

  task append_val_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( val )
      append_str( trace, str );
    else if ( !val )
      append_chars( trace, " ", len1 );
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

  //----------------------------------------------------------------------
  // val_rdy_str
  //----------------------------------------------------------------------
  // Append a string modified by val/rdy signals.

  task append_val_rdy_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic             rdy,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( rdy && val ) begin
      append_str( trace, str );
    end
    else if ( rdy && !val ) begin
      append_chars( trace, " ", len1 );
    end
    else if ( !rdy && val ) begin
      append_str( trace, "#" );
      append_chars( trace, " ", len1-1 );
    end
    else if ( !rdy && !val ) begin
      append_str( trace, "." );
      append_chars( trace, " ", len1-1 );
    end
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

endmodule

//------------------------------------------------------------------------
// VC_TRACE_NBITS_TO_NCHARS
//------------------------------------------------------------------------
// Macro to determine number of characters for a net

`define VC_TRACE_NBITS_TO_NCHARS( nbits_ ) ((nbits_+3)/4)

//------------------------------------------------------------------------
// VC_TRACE_BEGIN
//------------------------------------------------------------------------

//`define VC_TRACE_BEGIN                                                  \
//  export "DPI-C" task line_trace;                                       \
//  vc_Trace vc_trace(clk,reset);                                         \
//  task line_trace( inout bit [(512*8)-1:0] trace_str );

`ifndef VERILATOR
`define VC_TRACE_BEGIN                                                  \
  vc_Trace vc_trace(clk,reset);                                         \
                                                                        \
  task display_trace;                                                   \
  begin                                                                 \
                                                                        \
    if ( vc_trace.level > 0 ) begin                                     \
      vc_trace.storage[15:0] = vc_trace.nchars-1;                       \
                                                                        \
      line_trace( vc_trace.storage );                                   \
                                                                        \
      $write( "%4d: ", vc_trace.cycles );                               \
                                                                        \
      vc_trace.idx0 = vc_trace.storage[15:0];                           \
      for ( vc_trace.idx1 = vc_trace.nchars-1;                          \
            vc_trace.idx1 > vc_trace.idx0;                              \
            vc_trace.idx1 = vc_trace.idx1 - 1 )                         \
      begin                                                             \
        $write( "%s", vc_trace.storage[vc_trace.idx1*8+:8] );           \
      end                                                               \
      $write("\n");                                                     \
                                                                        \
    end                                                                 \
                                                                        \
    vc_trace.cycles_next = vc_trace.cycles + 1;                         \
                                                                        \
  end                                                                   \
  endtask                                                               \
                                                                        \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`else
`define VC_TRACE_BEGIN                                                  \
  export "DPI-C" task line_trace;                                       \
  vc_Trace vc_trace(clk,reset);                                         \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`endif

//------------------------------------------------------------------------
// VC_TRACE_END
//------------------------------------------------------------------------

`define VC_TRACE_END \
  endtask

`endif /* VC_TRACE_V */


`line 12 "vc/mem-msgs.v" 0

//========================================================================
// Memory Request Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// requests include an opaque field, the address, and the number of bytes
// to read, while write requests include an opaque field, the address,
// the number of bytes to write, and the actual data to write.
//
// Message Format:
//
//    3b    p_opaque_nbits  p_addr_nbits       calc   p_data_nbits
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field, address field, and data field. Note that the size of the length
// field is caclulated from the number of bits in the data field, and
// that the length field is expressed in _bytes_. If the value of the
// length field is zero, then the read or write should be for the full
// width of the data field.
//
// For example, if the opaque field is 8 bits, the address is 32 bits and
// the data is also 32 bits, then the message format is as follows:
//
//   76  74 73           66 65              34 33  32 31               0
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The length field is two bits. A length value of one means read or write
// a single byte, a length value of two means read or write two bytes, and
// so on. A length value of zero means read or write all four bytes. Note
// that not all memories will necessarily support any alignment and/or any
// value for the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [1:0]  len;
  logic [31:0] data;
} mem_req_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [3:0]  len;
  logic [127:0] data;
} mem_req_16B_t;

// memory request type values
`define VC_MEM_REQ_MSG_TYPE_READ     3'd0
`define VC_MEM_REQ_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_REQ_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_REQ_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_REQ_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_REQ_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_REQ_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Request Message: Trace message
//------------------------------------------------------------------------

module vc_MemReqMsg4BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_4B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_4B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemReqMsg16BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_16B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_16B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

//========================================================================
// Memory Response Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// responses include an opaque field, the actual data, and the number of
// bytes, while write responses currently include just the opaque field.
//
// Message Format:
//
//    3b    p_opaque_nbits   2b    calc   p_data_nbits
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field and data field. Note that the size of the length field is
// caclulated from the number of bits in the data field, and that the
// length field is expressed in _bytes_. If the value of the length field
// is zero, then the read or write should be for the full width of the
// data field.
//
// For example, if the opaque field is 8 bits and the data is 32 bits,
// then the message format is as follows:
//
//   46  44 43           36 35  34 33  32 31               0
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The length field is two bits. A length value of one means one byte was
// read, a length value of two means two bytes were read, and so on. A
// length value of zero means all four bytes were read. Note that not all
// memories will necessarily support any alignment and/or any value for
// the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [1:0]  len;
  logic [31:0] data;
} mem_resp_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [3:0]  len;
  logic [127:0] data;
} mem_resp_16B_t;

// Values for the type field

`define VC_MEM_RESP_MSG_TYPE_READ     3'd0
`define VC_MEM_RESP_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_RESP_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_RESP_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_RESP_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_RESP_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_RESP_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Response Message: Trace message
//------------------------------------------------------------------------

module vc_MemRespMsg4BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_4B_t  msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_4B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemRespMsg16BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_16B_t msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0] data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_16B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

`endif /* VC_MEM_MSGS_V */


`line 9 "lab3_mem/BlockingCacheAltCtrlVRTL.v" 0
`line 1 "vc/assert.v" 0
//========================================================================
// vc-Assert
//========================================================================

`ifndef VC_ASSERT_V
`define VC_ASSERT_V

//------------------------------------------------------------------------
// VC_PROPAGATE_X
//------------------------------------------------------------------------

`define VC_PROPAGATE_X( i_, o_ )                                        \
  if ((|(i_ ^ i_)) == 1'b0);                                            \
  else                                                                  \
    o_ = o_ + 1'bx

//------------------------------------------------------------------------
// VC_ASSERT
//------------------------------------------------------------------------

`define VC_ASSERT( expr_ )                                              \
  if ( expr_ );                                                         \
  else begin                                                            \
    $display( "\n VC_ASSERT FAILED\n  - assertion       :%s\n  - module instance : %m\n  - time            : %0d\n", \
              "expr_", $time );                                         \
    $finish;                                                            \
  end                                                                   \
  if (1)

//------------------------------------------------------------------------
// VC_ASSERT_FAIL
//------------------------------------------------------------------------

`define VC_ASSERT_FAIL( msg_ )                                         \
  $display( "\n VC_ASSERT FAILED\n  - assertion       :%s\n  - module instance : %m\n  - time            : %0d\n", \
            msg_, $time );                                             \
  $finish;                                                             \
  if (1)

//------------------------------------------------------------------------
// VC_ASSERT_NOT_X
//------------------------------------------------------------------------

`define VC_ASSERT_NOT_X( net_ )                                         \
  if ((|(net_ ^ net_)) == 1'b0);                                        \
  else begin                                                            \
    $display( "\n VC_ASSERT FAILED\n  - assertion that net not contain X's failed\n  - module instance : %m\n  - net             :%s\n  - time            : %0d\n", \
              "net_", $time );                                          \
    $finish;                                                            \
  end                                                                   \
  if (1)

`endif /* VC_ASSERT_V */


`line 10 "lab3_mem/BlockingCacheAltCtrlVRTL.v" 0

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
`line 1 "vc/regfiles.v" 0
//========================================================================
// Verilog Components: Register Files
//========================================================================

`ifndef VC_REGFILES_V
`define VC_REGFILES_V

//------------------------------------------------------------------------
// 1r1w register file
//------------------------------------------------------------------------

module vc_Regfile_1r1w
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries)
)(
  input  logic                    clk,
  input  logic                    reset,

  // Read port (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr,
  output logic [p_data_nbits-1:0] read_data,

  // Write port (sampled on the rising clock edge)

  input  logic                    write_en,
  input  logic [c_addr_nbits-1:0] write_addr,
  input  logic [p_data_nbits-1:0] write_data
);

  logic [p_data_nbits-1:0] rfile[p_num_entries-1:0];

  // Combinational read

  assign read_data = rfile[read_addr];

  // Write on positive clock edge

  always_ff @( posedge clk )
    if ( write_en )
      rfile[write_addr] <= write_data;

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( write_en );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */

endmodule

//------------------------------------------------------------------------
// 1r1w register file with reset
//------------------------------------------------------------------------

module vc_ResetRegfile_1r1w
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,
  parameter p_reset_value = 0,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries)
)(
  input  logic                    clk,
  input  logic                    reset,

  // Read port (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr,
  output logic [p_data_nbits-1:0] read_data,

  // Write port (sampled on the rising clock edge)

  input  logic                    write_en,
  input  logic [c_addr_nbits-1:0] write_addr,
  input  logic [p_data_nbits-1:0] write_data
);

  logic [p_data_nbits-1:0] rfile[p_num_entries-1:0];

  // Combinational read

  assign read_data = rfile[read_addr];

  // Write on positive clock edge. We have to use a generate statement to
  // allow us to include the reset logic for each individual register.

  genvar i;
  generate
    for ( i = 0; i < p_num_entries; i = i+1 )
    begin : wport
      always_ff @( posedge clk )
        if ( reset )
          rfile[i] <= p_reset_value;
        else if ( write_en && (i[c_addr_nbits-1:0] == write_addr) )
          rfile[i] <= write_data;
    end
  endgenerate

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( write_en );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */

endmodule

//------------------------------------------------------------------------
// 2r1w register file
//------------------------------------------------------------------------

module vc_Regfile_2r1w
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries)
)(
  input  logic                   clk,
  input  logic                   reset,

  // Read port 0 (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr0,
  output logic [p_data_nbits-1:0] read_data0,

  // Read port 1 (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr1,
  output logic [p_data_nbits-1:0] read_data1,

  // Write port (sampled on the rising clock edge)

  input  logic                    write_en,
  input  logic [c_addr_nbits-1:0] write_addr,
  input  logic [p_data_nbits-1:0] write_data
);

  logic [p_data_nbits-1:0] rfile[p_num_entries-1:0];

  // Combinational read

  assign read_data0 = rfile[read_addr0];
  assign read_data1 = rfile[read_addr1];

  // Write on positive clock edge

  always_ff @( posedge clk )
    if ( write_en )
      rfile[write_addr] <= write_data;

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( write_en );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */

endmodule

//------------------------------------------------------------------------
// 2r2w register file
//------------------------------------------------------------------------

module vc_Regfile_2r2w
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries)
)(
  input  logic                    clk,
  input  logic                    reset,

  // Read port 0 (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr0,
  output logic [p_data_nbits-1:0] read_data0,

  // Read port 1 (combinational read)

  input  logic [c_addr_nbits-1:0] read_addr1,
  output logic [p_data_nbits-1:0] read_data1,

  // Write port (sampled on the rising clock edge)

  input  logic                    write_en0,
  input  logic [c_addr_nbits-1:0] write_addr0,
  input  logic [p_data_nbits-1:0] write_data0,

  // Write port (sampled on the rising clock edge)

  input  logic                    write_en1,
  input  logic [c_addr_nbits-1:0] write_addr1,
  input  logic [p_data_nbits-1:0] write_data1
);

  logic [p_data_nbits-1:0] rfile[p_num_entries-1:0];

  // Combinational read

  assign read_data0 = rfile[read_addr0];
  assign read_data1 = rfile[read_addr1];

  // Write on positive clock edge

  always_ff @( posedge clk ) begin

    if ( write_en0 )
      rfile[write_addr0] <= write_data0;

    if ( write_en1 )
      rfile[write_addr1] <= write_data1;

  end

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( write_en0 );
      `VC_ASSERT_NOT_X( write_en1 );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's.

      if ( write_en0 ) begin
        `VC_ASSERT_NOT_X( write_addr0 );
        `VC_ASSERT( write_addr0 < p_num_entries );
      end

      if ( write_en1 ) begin
        `VC_ASSERT_NOT_X( write_addr1 );
        `VC_ASSERT( write_addr1 < p_num_entries );
      end

      // It is invalid to use the same write address for both write ports

      if ( write_en0 && write_en1 ) begin
        `VC_ASSERT( write_addr0 != write_addr1 );
      end

    end
  end
  */

endmodule

//------------------------------------------------------------------------
// Register file specialized for r0 == 0
//------------------------------------------------------------------------

module vc_Regfile_2r1w_zero
(
  input  logic        clk,
  input  logic        reset,

  input  logic  [4:0] rd_addr0,
  output logic [31:0] rd_data0,

  input  logic  [4:0] rd_addr1,
  output logic [31:0] rd_data1,

  input  logic        wr_en,
  input  logic  [4:0] wr_addr,
  input  logic [31:0] wr_data
);

  // these wires are to be hooked up to the actual register file read
  // ports

  logic [31:0] rf_read_data0;
  logic [31:0] rf_read_data1;

  vc_Regfile_2r1w
  #(
    .p_data_nbits  (32),
    .p_num_entries (32)
  )
  rfile
  (
    .clk         (clk),
    .reset       (reset),
    .read_addr0  (rd_addr0),
    .read_data0  (rf_read_data0),
    .read_addr1  (rd_addr1),
    .read_data1  (rf_read_data1),
    .write_en    (wr_en),
    .write_addr  (wr_addr),
    .write_data  (wr_data)
  );

  // we pick 0 value when either read address is 0
  assign rd_data0 = ( rd_addr0 == 5'd0 ) ? 32'd0 : rf_read_data0;
  assign rd_data1 = ( rd_addr1 == 5'd0 ) ? 32'd0 : rf_read_data1;

endmodule

`endif /* VC_REGFILES_V */


`line 15 "lab3_mem/BlockingCacheAltCtrlVRTL.v" 0
module lab3_mem_BlockingCacheAltCtrlVRTL
#(
  parameter p_idx_shamt    = 0
)
(
  input  logic                        clk,
  input  logic                        reset,

  // Cache Request

  input  logic                        cachereq_val,
  output logic                        cachereq_rdy,

  // Cache Response

  output logic                        cacheresp_val,
  input  logic                        cacheresp_rdy,

  // Memory Request

  output logic                        memreq_val,
  input  logic                        memreq_rdy,

  // Memory Response

  input  logic                        memresp_val,
  output logic                        memresp_rdy,

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Define additional ports
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  // Register Enables
  output logic                        cachereq_en,
  output logic                        memresp_en,
  output logic                        evict_addr_reg_en,
  output logic                        read_data_reg_en,
                        

  // Mux Selects
  output logic                        write_data_mux_sel,
  output logic                        memreq_addr_mux_sel,
  output logic [2:0]                  read_word_mux_sel,
  output logic                        way_sel, // New or Updated

  // Tag Array Enables
  output logic                        tag_array_ren,
  output logic                        tag_array_wen0, // New or Updated
  output logic                        tag_array_wen1, // New or Updated
  
  // Data Aray Enables
  output logic                        data_array_ren,
  output logic                        data_array_wen,
  output logic [15:0]                 data_array_wben,

  // Cache Response Message
  output logic [2:0]                  cacheresp_type,
  output logic [1:0]                  cacheresp_hit,
  input  logic                        tag_match0, // New or Updated
  input  logic                        tag_match1, // New or Updated

  // Memory Response Message
  output logic [2:0]                  memreq_type,

  input  logic [2:0]                  cachereq_type,
  input  logic [abw-1:0]              cachereq_addr            

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

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Implement control unit
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  // Reset the Cache State when Reset is High
  always_ff @(posedge clk) begin
    if (reset)begin
      state_reg <= STATE_IDLE;
    end
    else begin
      state_reg <= state_next;
    end
  end

  // assigning values for writing to valid bits 
  logic valid_write_en0; // Way 0 Enable

  logic valid_write_en1; // Way 1 Enable
  
  logic [idw-1:0] idx;   // Index of the cacheline
  
  assign idx = cachereq_addr[idw+3+p_idx_shamt:4+p_idx_shamt];

  logic valid_write_data; // Valid data write (is is valid now or not)
  logic valid_read_data0; // Read the valid bit at specific index in way 0
  
  logic valid_write_data1; // Valid data write (is is valid now or not)
  logic valid_read_data1; // Read the valid bit at specific index in way 0

  // register files for tracking way0 and way1 valid bits 
  vc_Regfile_1r1w #( 1, nby ) valid_bit_regfile0(
    .clk( clk ),
    .reset( reset ),
    .read_addr( idx ),
    .read_data( valid_read_data0 ),
    .write_en( valid_write_en0 ),
    .write_addr( idx ),
    .write_data( valid_write_data )
  );

  vc_Regfile_1r1w #( 1, nby ) valid_bit_regfile1(
    .clk( clk ),
    .reset( reset ),
    .read_addr( idx ),
    .read_data( valid_read_data1 ),
    .write_en( valid_write_en1 ),
    .write_addr( idx ),
    .write_data( valid_write_data )
  );

  logic dirty_write_data; // Is the bit at that index now dirty or not
  logic dirty_read_data0; // Read specific index dirty bit
  logic dirty_write_en0; // Write to way 0 dirty bit
  
  logic dirty_write_data1; // Is the bit at that index now dirty or not
  logic dirty_read_data1; // Read specific index dirty bit
  logic dirty_write_en1; // Write to way 1 dirty bit
// dirty bit register files for way0 and way1  
  vc_Regfile_1r1w #( 1, nby ) dirty_bit_regfile0(
    .clk( clk ),
    .reset( reset ),
    .read_addr( idx ),
    .read_data( dirty_read_data0 ),
    .write_en( dirty_write_en0 ),
    .write_addr( idx ),
    .write_data( dirty_write_data )
  );

  vc_Regfile_1r1w #( 1, nby ) dirty_bit_regfile1(
    .clk( clk ),
    .reset( reset ),
    .read_addr( idx ),
    .read_data( dirty_read_data1 ),
    .write_en( dirty_write_en1 ),
    .write_addr( idx ),
    .write_data( dirty_write_data )
  );

  //lru reg file to keep track of least recently used way for each idx
    logic             lru_read_data; // Read LRU bit at that index
    logic             lru_write_data; // Write to that specifc LRU bit
    logic             lru_write_en; // Enable LRU to write specific bit
  vc_Regfile_1r1w #( 1, nby ) lru_reg_file(
    .clk( clk ),
    .reset( reset ),
    .read_addr( idx ),
    .read_data( lru_read_data ),
    .write_en( lru_write_en ),
    .write_addr( idx ),
    .write_data( lru_write_data )
  );
  
  
  logic [3:0] state_next; // The next state in the FSM
  logic [3:0] state_reg;  // Current State in the FSM

  localparam STATE_IDLE              = 4'b0000; // 0
  localparam STATE_TAG_CHECK         = 4'b0001; // 1
  localparam STATE_INIT_DATA_ACCESS  = 4'b0010; // 2
  localparam STATE_READ_DATA_ACCESS  = 4'b0011; // 3
  localparam STATE_WRITE_DATA_ACCESS = 4'b0100; // 4
  localparam STATE_REFILL_REQUEST    = 4'b0101; // 5
  localparam STATE_EVICT_PREPARE     = 4'b0110; // 6
  localparam STATE_EVICT_REQUEST     = 4'b0111; // 7
  localparam STATE_EVICT_WAIT        = 4'b1000; // 8
  localparam STATE_REFILL_WAIT       = 4'b1001; // 9 
  localparam STATE_REFILL_UPDATE     = 4'b1010; // 10
  localparam STATE_WAIT              = 4'b1011; // 11

  // Set specific wires being controlled by the FSM
  task set_cs(
    input logic cs_cachereq_rdy,
    input logic cs_cacheresp_val,
    input logic cs_memreq_val,
    input logic cs_memresp_rdy,
    input logic cs_cachereq_en,
    input logic cs_memresp_en,
    input logic cs_evict_addr_reg_en,
    input logic cs_read_data_reg_en,
    input logic cs_write_data_mux_sel,
    input logic cs_memreq_addr_mux_sel,
    input logic [2:0] cs_read_word_mux_sel,
    input logic cs_tag_array_ren,   
    input logic cs_data_array_ren,
    input logic cs_data_array_wen,
    input logic [15:0] cs_data_array_wben,
    input logic [2:0] cs_cacheresp_type,
    input logic [2:0] cs_memreq_type,
    input logic cs_valid_write_data,
    input logic cs_dirty_write_data,
    input logic cs_lru_write_en
  );
  begin
    cachereq_rdy = cs_cachereq_rdy;
    cacheresp_val = cs_cacheresp_val;
    memreq_val = cs_memreq_val;
    memresp_rdy = cs_memresp_rdy;
    cachereq_en = cs_cachereq_en;
    memresp_en = cs_memresp_en;
    evict_addr_reg_en = cs_evict_addr_reg_en;
    read_data_reg_en = cs_read_data_reg_en;
    write_data_mux_sel = cs_write_data_mux_sel;
    memreq_addr_mux_sel = cs_memreq_addr_mux_sel;
    read_word_mux_sel = cs_read_word_mux_sel;
    tag_array_ren = cs_tag_array_ren;
    data_array_ren = cs_data_array_ren;
    data_array_wen = cs_data_array_wen;
    data_array_wben = cs_data_array_wben;
    cacheresp_type = cs_cacheresp_type;
    memreq_type = cs_memreq_type;
    valid_write_data = cs_valid_write_data;
    dirty_write_data = cs_dirty_write_data;
    lru_write_en     = cs_lru_write_en;
  end
  endtask

  logic [2:0] rwm; // Read Word Mux 3-bit
  logic [1:0] rwm0; // Read Word Mux 2-bit
  assign rwm = { 1'b0, cachereq_addr[3:2] };
  assign rwm0 = cachereq_addr[3:2];
  logic [2:0] crt; // Cache Response Type
  assign crt = cachereq_type;

  logic [15:0] wb; // Which location to write in data array
  logic       whit0; // Way 0 Hit 
  logic       whit1; // Way 1 Hit

  // Register Enables all to 1's
  always_comb begin
    // Make sure hit is set each time and reset accordingly
    if (reset) begin
      cacheresp_hit = 2'b0;
    end
    else begin
      cacheresp_hit = cacheresp_hit;
    end
    case( state_reg )
      STATE_IDLE: begin 
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b1,  1'b0 , 1'b0, 1'b0 , 1'b1  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  ,  1'b0   , 16'd0 ,  3'dx    , 3'dx   ,  1'bx ,  1'bx  ,  1'b0 );
        if ( cachereq_val == 1'b1 ) begin // cachereq_val
          state_next = STATE_TAG_CHECK;
        end
        else begin
          state_next = STATE_IDLE;
        end
      end

      // cacheresp_hit/Miss only changes here
      STATE_TAG_CHECK: begin
      
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b1  , 1'b0  ,  1'b0   , 16'd0 ,  3'dx    , 3'dx   ,  1'bx ,  1'bx  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        // Hit in Way 0
        if ( valid_read_data0 && tag_match0 )begin
          cacheresp_hit = 2'b1;
          whit0         = 1'b1;
          whit1         = 1'b0;
        end
        // Hit in Way 1
        else if ( valid_read_data1 && tag_match1 )begin
          cacheresp_hit = 2'b1;
           whit1         = 1'b1;
           whit0         = 1'b0;
        end
        else begin
          cacheresp_hit = 2'b0;
          whit0         = 1'b0;
          whit1         = 1'b0;
        end

        if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT ) begin // init transaction
          state_next = STATE_INIT_DATA_ACCESS;
        end
        
        // Read & Hit
        else if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ && cacheresp_hit == 2'b1 ) begin // read & cacheresp_hit
          state_next = STATE_READ_DATA_ACCESS; 
        end

        // Write & Hit
        else if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE && cacheresp_hit == 2'b1 ) begin // write & cacheresp_hit
          state_next = STATE_WRITE_DATA_ACCESS;
        end

        else if( cacheresp_hit == 2'b0 && ((dirty_read_data0 == 1'b1 && lru_read_data == 1'b0) || (dirty_read_data1 == 1'b1 && lru_read_data == 1'b1)) ) begin // miss & dirty
          way_sel = lru_read_data; // Choose correct Way
          state_next = STATE_EVICT_PREPARE;
        end

        else if( cacheresp_hit == 2'b0 && ((dirty_read_data0 == 1'b0 && lru_read_data == 1'b0) || (dirty_read_data1 == 1'b0 && lru_read_data == 1'b1)) )begin // miss & not dirty
          way_sel = lru_read_data; // Choose correct Way
          state_next = STATE_REFILL_REQUEST;
        end
      end

      STATE_INIT_DATA_ACCESS: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'b0  ,  1'bx  , 3'b100 , 1'b0  , 1'b0  ,  1'b1 , 16'hffff ,  crt    , 3'dx   ,  1'b1 ,  1'b1  ,  1'b1 );
        
        if( lru_read_data ) begin
          way_sel = 1'b1; // Choose correct Way
          tag_array_wen1 = 1'b1;
          valid_write_en1 = 1'b1;
          dirty_write_en1 = 1'b1;
        end 
        else begin
          way_sel = 1'b0; // Choose correct Way
          tag_array_wen0 = 1'b1;
          valid_write_en0 = 1'b1;
          dirty_write_en0 = 1'b1;
        end
        lru_write_data = ~lru_read_data; // Update LRU
        state_next = STATE_WAIT;
      end

      STATE_READ_DATA_ACCESS: begin
            // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b1 , 1'bx  ,  1'bx  , rwm , 1'b1  , 1'b1  ,  1'b0     , 16'h0 ,  crt    , 3'dx   ,  1'bx ,  1'bx  ,  1'b1 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        if( whit0 == 1'b1  ) begin // add refill update path
          way_sel = 1'b0; // Choose correct Way
          lru_write_data = 1'b1;
        end else if (whit1 == 1'b1) begin// add refill update path
          way_sel = 1'b1; // Choose correct Way
          lru_write_data = 1'b0;
        end else if(lru_read_data == 1'b1) begin // Not a hit, go based of LRU
          way_sel = 1'b1; // Choose correct Way
          lru_write_data = 1'b0;
        end else begin // Not a hit, go based of LRU
          way_sel = 1'b0; // Choose correct Way
          lru_write_data = 1'b1;
        end
        state_next = STATE_WAIT;
      end
      STATE_WRITE_DATA_ACCESS: begin
          case ( rwm0 )
            2'b00: wb = 16'h000f;
            2'b01: wb = 16'h00f0;
            2'b10: wb = 16'h0f00;
            2'b11: wb = 16'hf000;
          endcase
              // cache | cache | mem | mem  | cache | mem  | evict| read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b1 , 1'b0  ,  1'bx  , 3'bx , 1'b0  , 1'b0  ,  1'b1   , wb    ,  crt     , 3'dx   ,  1'bx ,  1'b1  ,  1'b1 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        if( whit0 == 1'b1 ) begin
          way_sel = 1'b0;// Choose correct Way
          dirty_write_en0 = 1'b1; // Update Dirty Bit
          lru_write_data = 1'b1; // Update LRU
        end else if (whit1 == 1'b1) begin
          way_sel = 1'b1;// Choose correct Way
          dirty_write_en1 = 1'b1; // Update Dirty Bit 
          lru_write_data = 1'b0; // Update LRU
        end else if(lru_read_data == 1'b1) begin
          way_sel = 1'b1;// Choose correct Way
          dirty_write_en1 = 1'b1; // I added this to pass all staff tests!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
          lru_write_data = 1'b0; // Update LRU
        end else begin
          way_sel = 1'b0;// Choose correct Way
          dirty_write_en0 = 1'b1; //I added this to pass all staff tests!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
          lru_write_data = 1'b1; // Update LRU
        end
          state_next = STATE_WAIT;
      end

      STATE_REFILL_REQUEST: begin
            // cache | cache | mem | mem  | cache | mem  | evict| read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b1, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'b1  , 3'bx , 1'b0  , 1'b1  ,  1'b0   ,  16'd0   ,  3'dx     , 3'd0   ,  1'b0 ,  1'bx  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        if(memreq_rdy == 1'b1) begin // memreq_rdy
          if(lru_read_data == 1'b1) begin
            valid_write_en1 = 1'b1; // Update Valid
          end else begin
            valid_write_en0 = 1'b1; // Update Valid
          end
          state_next = STATE_REFILL_WAIT;
        end
        else begin // not memreq_rdy
          state_next = STATE_REFILL_REQUEST;
        end
      end

      STATE_EVICT_PREPARE: begin
      
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
       set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b1 , 1'b1 , 1'bx  ,  1'b0  , 3'bx , 1'b1  , 1'b1  ,  1'b0   ,  16'd0   ,  3'dx  ,  3'dx  ,  1'bx ,  1'bx  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        state_next = STATE_EVICT_REQUEST;
      end

      STATE_EVICT_REQUEST: begin
            // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
       set_cs( 1'b0,  1'b0 , 1'b1, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'b0  , 3'bx , 1'b0  , 1'b0  ,  1'b0   ,  16'd0   ,  3'dx  ,  3'd1  ,  1'b0 ,  1'b0  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;  
        if(memreq_rdy == 1'b1) begin // memreq_rdy
            state_next = STATE_EVICT_WAIT;
            if(lru_read_data == 1'b1) begin
              valid_write_en1 = 1'b1; // Update Valid
            end else begin
              valid_write_en0 = 1'b1; // Update Valid
            end
          end
          else begin // not memreq_rdy
            state_next = STATE_EVICT_REQUEST;
          end
      end

      STATE_EVICT_WAIT: begin
            // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b1 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'b0  , 3'bx , 1'b0  , 1'b0  ,  1'b0   ,  16'd0   ,  3'dx  ,  3'd1  ,  1'bx ,  1'bx  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
      
        if(memresp_val == 1'b1) begin // memresp_val
            state_next = STATE_REFILL_REQUEST;
          end
          else begin // not memresp_val
            state_next = STATE_EVICT_WAIT;
          end
      end

      STATE_REFILL_WAIT: begin
            // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b1 , 1'b0  , 1'b1 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  ,  1'b0   ,  16'd0   ,  3'd1  ,  3'dx  ,  1'bx ,  1'bx  ,  1'b0 );
        // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
        
        if(memresp_val == 1'b1) begin // memresp_val
            state_next = STATE_REFILL_UPDATE;
          end
          else begin // not memresp_val
            state_next = STATE_REFILL_WAIT;
          end
      end

      STATE_REFILL_UPDATE: begin
            // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
            // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
            // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
            //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'b1  ,  1'bx  , 3'bx , 1'b0  , 1'b0  ,  1'b1   , 16'hffff   ,  3'dx  ,  3'dx  ,  1'b1 ,  1'b0  ,  1'b0 );
       // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
          if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ ) begin // read
             if(lru_read_data == 1'b1) begin
                tag_array_wen1 = 1'b1; // Update Tag Array
                valid_write_en1 = 1'b1; // Update Valid
                dirty_write_en1 = 1'b1; // Update Dirty
             end else begin
                tag_array_wen0 = 1'b1; // Update Tag Array
                valid_write_en0 = 1'b1; // Update Valid
                dirty_write_en0 = 1'b1; // Update Dirty
            end
          state_next = STATE_READ_DATA_ACCESS;
        end
        else begin // write: cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE
             if(lru_read_data == 1'b1) begin
                tag_array_wen1 = 1'b1; // Update Tag Array
                valid_write_en1 = 1'b1; // Update Valid
                dirty_write_en1 = 1'b1;
             end else begin
                tag_array_wen0 = 1'b1; // Update Tag Array
                valid_write_en0 = 1'b1; // Update Valid
                dirty_write_en0 = 1'b1; // Update Dirty
            end
          state_next = STATE_WRITE_DATA_ACCESS;
        end
      end

      STATE_WAIT: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
       set_cs( 1'b0,  1'b1 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , rwm , 1'b0  , 1'b0  ,  1'b0   , 16'h0   ,  crt  ,  3'dx  ,  1'bx ,  1'bx  ,  1'b0 );
       // Update/Hold(ed) Bit Values
        tag_array_wen0 = 1'b0;
        valid_write_en0 = 1'b0;
        dirty_write_en0 = 1'b0;
        tag_array_wen1 = 1'b0;
        valid_write_en1 = 1'b0;
        dirty_write_en1 = 1'b0;
       
        if (cacheresp_rdy == 1'b1) begin // cacheresp_rdy
          state_next = STATE_IDLE;
        end
        else begin
          state_next = STATE_WAIT;
        end
      end 
      default: begin
             // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   |  data  |  data  | data  | cachresp | memreq | valid |  dirty | lru   |
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array |  array |  array | array | type     | type   | write |  write | write |
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   |  ren   |  wen   | wben  |          |        | data  |  data  | en    |
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |        |        |       |          |        |       |        |
       set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'b0  ,  1'bx  , 3'bx , 1'b0  , 1'b0  ,  1'b0   , 16'h0   ,  3'dx  ,  3'dx  ,  1'bx ,  1'bx  ,  1'b0 );
       // Update/Hold(ed) Bit Values
       tag_array_wen0 = 1'b0;
       valid_write_en0 = 1'b0;
       dirty_write_en0 = 1'b0;
       tag_array_wen1 = 1'b0;
       valid_write_en1 = 1'b0;
       dirty_write_en1 = 1'b0;
      end
    endcase
  end

endmodule

`endif

`line 12 "lab3_mem/BlockingCacheAltVRTL.v" 0
`line 1 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0
//=========================================================================
// Alternative Blocking Cache Datapath
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V

`line 1 "vc/mem-msgs.v" 0
//========================================================================
// vc-mem-msgs : Memory Request/Response Messages
//========================================================================
// The memory request/response messages are used to interact with various
// memories. They are parameterized by the number of bits in the address,
// data, and opaque field.

`ifndef VC_MEM_MSGS_V
`define VC_MEM_MSGS_V

`line 1 "vc/trace.v" 0
//========================================================================
// Line Tracing
//========================================================================

`ifndef VC_TRACE_V
`define VC_TRACE_V

// NOTE: This macro is declared outside of the module to allow some vc
// modules to see it and use it in their own params. Verilog does not
// allow other modules to hierarchically reference the nbits localparam
// inside this module in constant expressions (e.g., localparams).

`define VC_TRACE_NCHARS 512
`define VC_TRACE_NBITS  512*8

module vc_Trace
(
  input logic clk,
  input logic reset
);

  integer len0;
  integer len1;
  integer idx0;
  integer idx1;

  // NOTE: If you change these, then you also need to change the
  // hard-coded constant in the declaration of the trace function at the
  // bottom of this file.
  // NOTE: You would also need to change the VC_TRACE_NBITS and
  // VC_TRACE_NCHARS macro at the top of this file.

  localparam nchars = 512;
  localparam nbits  = 512*8;

  // This is the actual trace storage used when displaying a trace

  logic [nbits-1:0] storage;

  // Meant to be accesible from outside module

  integer cycles_next = 0;
  integer cycles      = 0;

  // Get trace level from command line

  logic [3:0] level;

`ifndef VERILATOR
  initial begin
    if ( !$value$plusargs( "trace=%d", level ) ) begin
      level = 0;
    end
  end
`else
  initial begin
    level = 1;
  end
`endif // !`ifndef VERILATOR

  // Track cycle count

  always_ff @( posedge clk ) begin
    cycles <= ( reset ) ? 0 : cycles_next;
  end

  //----------------------------------------------------------------------
  // append_str
  //----------------------------------------------------------------------
  // Appends a string to the trace.

  task append_str
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    len0 = 1;
    while ( str[len0*8+:8] != 0 ) begin
      len0 = len0 + 1;
    end

    idx0 = trace[31:0];

    for ( idx1 = len0-1; idx1 >= 0; idx1 = idx1 - 1 )
    begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8 +: 8 ];
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_str_ljust
  //----------------------------------------------------------------------
  // Appends a left-justified string to the trace.

  task append_str_ljust
  (
    inout logic [nbits-1:0] trace,
    input logic [nbits-1:0] str
  );
  begin

    idx0 = trace[31:0];
    idx1 = nchars;

    while ( str[ idx1*8-1 -: 8 ] != 0 ) begin
      trace[ idx0*8 +: 8 ] = str[ idx1*8-1 -: 8 ];
      idx0 = idx0 - 1;
      idx1 = idx1 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_chars
  //----------------------------------------------------------------------
  // Appends the given number of characters to the trace.

  task append_chars
  (
    inout logic   [nbits-1:0] trace,
    input logic         [7:0] char,
    input integer             num
  );
  begin

    idx0 = trace[31:0];

    for ( idx1 = 0;
          idx1 < num;
          idx1 = idx1 + 1 )
    begin
      trace[idx0*8+:8] = char;
      idx0 = idx0 - 1;
    end

    trace[31:0] = idx0;

  end
  endtask

  //----------------------------------------------------------------------
  // append_val_str
  //----------------------------------------------------------------------
  // Append a string modified by val signal.

  task append_val_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( val )
      append_str( trace, str );
    else if ( !val )
      append_chars( trace, " ", len1 );
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

  //----------------------------------------------------------------------
  // val_rdy_str
  //----------------------------------------------------------------------
  // Append a string modified by val/rdy signals.

  task append_val_rdy_str
  (
    inout logic [nbits-1:0] trace,
    input logic             val,
    input logic             rdy,
    input logic [nbits-1:0] str
  );
  begin

    len1 = 0;
    while ( str[len1*8+:8] != 0 ) begin
      len1 = len1 + 1;
    end

    if ( rdy && val ) begin
      append_str( trace, str );
    end
    else if ( rdy && !val ) begin
      append_chars( trace, " ", len1 );
    end
    else if ( !rdy && val ) begin
      append_str( trace, "#" );
      append_chars( trace, " ", len1-1 );
    end
    else if ( !rdy && !val ) begin
      append_str( trace, "." );
      append_chars( trace, " ", len1-1 );
    end
    else begin
      append_str( trace, "x" );
      append_chars( trace, " ", len1-1 );
    end

  end
  endtask

endmodule

//------------------------------------------------------------------------
// VC_TRACE_NBITS_TO_NCHARS
//------------------------------------------------------------------------
// Macro to determine number of characters for a net

`define VC_TRACE_NBITS_TO_NCHARS( nbits_ ) ((nbits_+3)/4)

//------------------------------------------------------------------------
// VC_TRACE_BEGIN
//------------------------------------------------------------------------

//`define VC_TRACE_BEGIN                                                  \
//  export "DPI-C" task line_trace;                                       \
//  vc_Trace vc_trace(clk,reset);                                         \
//  task line_trace( inout bit [(512*8)-1:0] trace_str );

`ifndef VERILATOR
`define VC_TRACE_BEGIN                                                  \
  vc_Trace vc_trace(clk,reset);                                         \
                                                                        \
  task display_trace;                                                   \
  begin                                                                 \
                                                                        \
    if ( vc_trace.level > 0 ) begin                                     \
      vc_trace.storage[15:0] = vc_trace.nchars-1;                       \
                                                                        \
      line_trace( vc_trace.storage );                                   \
                                                                        \
      $write( "%4d: ", vc_trace.cycles );                               \
                                                                        \
      vc_trace.idx0 = vc_trace.storage[15:0];                           \
      for ( vc_trace.idx1 = vc_trace.nchars-1;                          \
            vc_trace.idx1 > vc_trace.idx0;                              \
            vc_trace.idx1 = vc_trace.idx1 - 1 )                         \
      begin                                                             \
        $write( "%s", vc_trace.storage[vc_trace.idx1*8+:8] );           \
      end                                                               \
      $write("\n");                                                     \
                                                                        \
    end                                                                 \
                                                                        \
    vc_trace.cycles_next = vc_trace.cycles + 1;                         \
                                                                        \
  end                                                                   \
  endtask                                                               \
                                                                        \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`else
`define VC_TRACE_BEGIN                                                  \
  export "DPI-C" task line_trace;                                       \
  vc_Trace vc_trace(clk,reset);                                         \
  task line_trace( inout bit [(512*8)-1:0] trace_str );
`endif

//------------------------------------------------------------------------
// VC_TRACE_END
//------------------------------------------------------------------------

`define VC_TRACE_END \
  endtask

`endif /* VC_TRACE_V */


`line 12 "vc/mem-msgs.v" 0

//========================================================================
// Memory Request Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// requests include an opaque field, the address, and the number of bytes
// to read, while write requests include an opaque field, the address,
// the number of bytes to write, and the actual data to write.
//
// Message Format:
//
//    3b    p_opaque_nbits  p_addr_nbits       calc   p_data_nbits
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field, address field, and data field. Note that the size of the length
// field is caclulated from the number of bits in the data field, and
// that the length field is expressed in _bytes_. If the value of the
// length field is zero, then the read or write should be for the full
// width of the data field.
//
// For example, if the opaque field is 8 bits, the address is 32 bits and
// the data is also 32 bits, then the message format is as follows:
//
//   76  74 73           66 65              34 33  32 31               0
//  +------+---------------+------------------+------+------------------+
//  | type | opaque        | addr             | len  | data             |
//  +------+---------------+------------------+------+------------------+
//
// The length field is two bits. A length value of one means read or write
// a single byte, a length value of two means read or write two bytes, and
// so on. A length value of zero means read or write all four bytes. Note
// that not all memories will necessarily support any alignment and/or any
// value for the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [1:0]  len;
  logic [31:0] data;
} mem_req_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [31:0] addr;
  logic [3:0]  len;
  logic [127:0] data;
} mem_req_16B_t;

// memory request type values
`define VC_MEM_REQ_MSG_TYPE_READ     3'd0
`define VC_MEM_REQ_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_REQ_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_REQ_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_REQ_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_REQ_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_REQ_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Request Message: Trace message
//------------------------------------------------------------------------

module vc_MemReqMsg4BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_4B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_4B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemReqMsg16BTrace
(
  input logic         clk,
  input logic         reset,
  input logic         val,
  input logic         rdy,
  input mem_req_16B_t  msg
);

  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [31:0]  addr;
  assign addr   = msg.addr;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits = $bits(mem_req_16B_t);
  localparam c_read      = `VC_MEM_REQ_MSG_TYPE_READ;
  localparam c_write     = `VC_MEM_REQ_MSG_TYPE_WRITE;
  localparam c_write_init  = `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( msg.type_ === `VC_MEM_REQ_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( msg.type_ )
        c_read     : type_str = "rd";
        c_write    : type_str = "wr";
        c_write_init : type_str = "wn";
        default    : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( vc_trace.level == 1 ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 2 ) begin
      $sformat( str, "%s:%x", type_str, msg.addr );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_read ) begin
        $sformat( str, "%s:%x:%x %s", type_str, msg.opaque, msg.addr,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x:%x", type_str, msg.opaque, msg.addr, msg.data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

//========================================================================
// Memory Response Message
//========================================================================
// Memory request messages can either be for a read or write. Read
// responses include an opaque field, the actual data, and the number of
// bytes, while write responses currently include just the opaque field.
//
// Message Format:
//
//    3b    p_opaque_nbits   2b    calc   p_data_nbits
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The message type is parameterized by the number of bits in the opaque
// field and data field. Note that the size of the length field is
// caclulated from the number of bits in the data field, and that the
// length field is expressed in _bytes_. If the value of the length field
// is zero, then the read or write should be for the full width of the
// data field.
//
// For example, if the opaque field is 8 bits and the data is 32 bits,
// then the message format is as follows:
//
//   46  44 43           36 35  34 33  32 31               0
//  +------+---------------+------+------+------------------+
//  | type | opaque        | test | len  | data             |
//  +------+---------------+------+------+------------------+
//
// The length field is two bits. A length value of one means one byte was
// read, a length value of two means two bytes were read, and so on. A
// length value of zero means all four bytes were read. Note that not all
// memories will necessarily support any alignment and/or any value for
// the length field.
//
// The opaque field is reserved for use by a specific implementation. All
// memories should guarantee that every response includes the opaque
// field corresponding to the request that generated the response.

//------------------------------------------------------------------------
// Memory Request Struct: Using a packed struct to represent the message
//------------------------------------------------------------------------
typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [1:0]  len;
  logic [31:0] data;
} mem_resp_4B_t;

typedef struct packed {
  logic [2:0]  type_;
  logic [7:0]  opaque;
  logic [1:0]  test;
  logic [3:0]  len;
  logic [127:0] data;
} mem_resp_16B_t;

// Values for the type field

`define VC_MEM_RESP_MSG_TYPE_READ     3'd0
`define VC_MEM_RESP_MSG_TYPE_WRITE    3'd1

// write no-refill
`define VC_MEM_RESP_MSG_TYPE_WRITE_INIT 3'd2
`define VC_MEM_RESP_MSG_TYPE_AMO_ADD    3'd3
`define VC_MEM_RESP_MSG_TYPE_AMO_AND    3'd4
`define VC_MEM_RESP_MSG_TYPE_AMO_OR     3'd5
`define VC_MEM_RESP_MSG_TYPE_X          3'dx

//------------------------------------------------------------------------
// Memory Response Message: Trace message
//------------------------------------------------------------------------

module vc_MemRespMsg4BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_4B_t  msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [1:0]   len;
  assign len    = msg.len;
  logic [31:0]  data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_4B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {8{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

module vc_MemRespMsg16BTrace
(
  input logic          clk,
  input logic          reset,
  input logic          val,
  input logic          rdy,
  input mem_resp_16B_t msg
);

  // unpack message fields -- makes them visible in gtkwave
  logic [2:0]   type_;
  assign type_  = msg.type_;
  logic [7:0]   opaque;
  assign opaque = msg.opaque;
  logic [1:0]   test;
  assign test   = msg.test;
  logic [3:0]   len;
  assign len    = msg.len;
  logic [127:0] data;
  assign data   = msg.data;

  // Short names

  localparam c_msg_nbits  = $bits(mem_resp_16B_t);
  localparam c_read       = `VC_MEM_RESP_MSG_TYPE_READ;
  localparam c_write      = `VC_MEM_RESP_MSG_TYPE_WRITE;
  localparam c_write_init = `VC_MEM_RESP_MSG_TYPE_WRITE_INIT;

  // Line tracing

  logic [8*2-1:0] type_str;
  logic [`VC_TRACE_NBITS-1:0] str;

  `VC_TRACE_BEGIN
  begin

    // Convert type into a string

    if ( type_ === `VC_MEM_RESP_MSG_TYPE_X )
      type_str = "xx";
    else begin
      case ( type_ )
        c_read       : type_str = "rd";
        c_write      : type_str = "wr";
        c_write_init : type_str = "wn";
        default      : type_str = "??";
      endcase
    end

    // Put together the trace string

    if ( (vc_trace.level == 1) || (vc_trace.level == 2) ) begin
      $sformat( str, "%s", type_str );
    end
    else if ( vc_trace.level == 3 ) begin
      if ( type_ == c_write || type_ == c_write_init ) begin
        $sformat( str, "%s:%x %s", type_str, opaque,
                  {32{" "}} );
      end
      else
        $sformat( str, "%s:%x:%x", type_str, opaque, data );
    end

    // Trace with val/rdy signals

    vc_trace.append_val_rdy_str( trace_str, val, rdy, str );

  end
  `VC_TRACE_END

endmodule

`endif /* VC_MEM_MSGS_V */


`line 9 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
`line 1 "vc/regs.v" 0
//========================================================================
// Verilog Components: Registers
//========================================================================

// Note that we place the register output earlier in the port list since
// this is one place we might actually want to use positional port
// binding like this:
//
//  logic [p_nbits-1:0] result_B;
//  vc_Reg#(p_nbits) result_AB( clk, result_B, result_A );

`ifndef VC_REGS_V
`define VC_REGS_V

//------------------------------------------------------------------------
// Postive-edge triggered flip-flop
//------------------------------------------------------------------------

module vc_Reg
#(
  parameter p_nbits = 1
)(
  input  logic               clk, // Clock input
  output logic [p_nbits-1:0] q,   // Data output
  input  logic [p_nbits-1:0] d    // Data input
);

  always_ff @( posedge clk )
    q <= d;

endmodule

//------------------------------------------------------------------------
// Postive-edge triggered flip-flop with reset
//------------------------------------------------------------------------

module vc_ResetReg
#(
  parameter p_nbits       = 1,
  parameter p_reset_value = 0
)(
  input  logic               clk,   // Clock input
  input  logic               reset, // Sync reset input
  output logic [p_nbits-1:0] q,     // Data output
  input  logic [p_nbits-1:0] d      // Data input
);

  always_ff @( posedge clk )
    q <= reset ? p_reset_value : d;

endmodule

//------------------------------------------------------------------------
// Postive-edge triggered flip-flop with enable
//------------------------------------------------------------------------

module vc_EnReg
#(
  parameter p_nbits = 1
)(
  input  logic               clk,   // Clock input
  input  logic               reset, // Sync reset input
  output logic [p_nbits-1:0] q,     // Data output
  input  logic [p_nbits-1:0] d,     // Data input
  input  logic               en     // Enable input
);

  always_ff @( posedge clk )
    if ( en )
      q <= d;

  // Assertions

  `ifndef SYNTHESIS

  /*
  always_ff @( posedge clk )
    if ( !reset )
      `VC_ASSERT_NOT_X( en );
  */

  `endif /* SYNTHESIS */

endmodule

//------------------------------------------------------------------------
// Postive-edge triggered flip-flop with enable and reset
//------------------------------------------------------------------------

module vc_EnResetReg
#(
  parameter p_nbits       = 1,
  parameter p_reset_value = 0
)(
  input  logic               clk,   // Clock input
  input  logic               reset, // Sync reset input
  output logic [p_nbits-1:0] q,     // Data output
  input  logic [p_nbits-1:0] d,     // Data input
  input  logic               en     // Enable input
);

  always_ff @( posedge clk )
    if ( reset || en )
      q <= reset ? p_reset_value : d;

  // Assertions

  `ifndef SYNTHESIS

  /*
  always_ff @( posedge clk )
    if ( !reset )
      `VC_ASSERT_NOT_X( en );
  */

  `endif /* SYNTHESIS */

endmodule

`endif /* VC_REGS_V */


`line 14 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0
`line 1 "vc/muxes.v" 0
//========================================================================
// Verilog Components: Muxes
//========================================================================

`ifndef VC_MUXES_V
`define VC_MUXES_V

//------------------------------------------------------------------------
// 2 Input Mux
//------------------------------------------------------------------------

module vc_Mux2
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1,
  input  logic               sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      1'd0 : out = in0;
      1'd1 : out = in1;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 3 Input Mux
//------------------------------------------------------------------------

module vc_Mux3
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2,
  input  logic         [1:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      2'd0 : out = in0;
      2'd1 : out = in1;
      2'd2 : out = in2;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 4 Input Mux
//------------------------------------------------------------------------

module vc_Mux4
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2, in3,
  input  logic         [1:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      2'd0 : out = in0;
      2'd1 : out = in1;
      2'd2 : out = in2;
      2'd3 : out = in3;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 5 Input Mux
//------------------------------------------------------------------------

module vc_Mux5
#(
 parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2, in3, in4,
  input  logic         [2:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      3'd0 : out = in0;
      3'd1 : out = in1;
      3'd2 : out = in2;
      3'd3 : out = in3;
      3'd4 : out = in4;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 6 Input Mux
//------------------------------------------------------------------------

module vc_Mux6
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2, in3, in4, in5,
  input  logic         [2:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      3'd0 : out = in0;
      3'd1 : out = in1;
      3'd2 : out = in2;
      3'd3 : out = in3;
      3'd4 : out = in4;
      3'd5 : out = in5;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 7 Input Mux
//------------------------------------------------------------------------

module vc_Mux7
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2, in3, in4, in5, in6,
  input  logic         [2:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      3'd0 : out = in0;
      3'd1 : out = in1;
      3'd2 : out = in2;
      3'd3 : out = in3;
      3'd4 : out = in4;
      3'd5 : out = in5;
      3'd6 : out = in6;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

//------------------------------------------------------------------------
// 8 Input Mux
//------------------------------------------------------------------------

module vc_Mux8
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
  input  logic         [2:0] sel,
  output logic [p_nbits-1:0] out
);

  always_comb
  begin
    case ( sel )
      3'd0 : out = in0;
      3'd1 : out = in1;
      3'd2 : out = in2;
      3'd3 : out = in3;
      3'd4 : out = in4;
      3'd5 : out = in5;
      3'd6 : out = in6;
      3'd7 : out = in7;
      default : out = {p_nbits{1'bx}};
    endcase
  end

endmodule

`endif /* VC_MUXES_V */


`line 15 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0
`line 1 "vc/srams.v" 0
//========================================================================
// Verilog Components: SRAMs
//========================================================================

`ifndef VC_SRAMS_V
`define VC_SRAMS_V

//------------------------------------------------------------------------
// 1rw Combinational Bit-level SRAM
//------------------------------------------------------------------------

module vc_CombinationalBitSRAM_1rw
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries)
)(
  input  logic                     clk,
  input  logic                     reset,

  // Read port (combinational read)

  input  logic                     read_en,
  input  logic [c_addr_nbits-1:0]  read_addr,
  output logic [p_data_nbits-1:0]  read_data,

  // Write port (sampled on the rising clock edge)

  input  logic                     write_en,
  input  logic [c_addr_nbits-1:0]  write_addr,
  input  logic [p_data_nbits-1:0]  write_data
);

  logic [p_data_nbits-1:0] mem[p_num_entries-1:0];

  // Combinational read. We ensure the read data is all X's if we are
  // doing a write because we are modeling an SRAM with a single
  // read/write port (i.e., not a dual ported SRAM). We also ensure the
  // read data is all X's if the read is not enable at all to avoid
  // (potentially) incorrectly assuming the SRAM latches the read data.

  /* verilator lint_off WIDTH */

  always_comb begin
    if ( read_en )
      read_data = mem[read_addr];
    else
      read_data = 'hx;
  end

  /* verilator lint_on WIDTH */

  always_ff @(posedge clk) begin
    if (write_en)
      mem[write_addr] = write_data;
  end

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( read_en );
      `VC_ASSERT_NOT_X( write_en );

      // There is only one port. You can only do a read OR a write.

      `VC_ASSERT( !(read_en && write_en) );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's. Write byte
      // enables also cannot be X.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT_NOT_X( write_byte_en );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */
  
endmodule

//------------------------------------------------------------------------
// 1rw Combinational SRAM
//------------------------------------------------------------------------

module vc_CombinationalSRAM_1rw
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries),
  parameter c_data_nbytes = (p_data_nbits+7)/8 // $ceil(p_data_nbits/8)
)(
  input  logic                     clk,
  input  logic                     reset,

  // Read port (combinational read)

  input  logic                     read_en,
  input  logic [c_addr_nbits-1:0]  read_addr,
  output logic [p_data_nbits-1:0]  read_data,

  // Write port (sampled on the rising clock edge)

  input  logic                     write_en,
  input  logic [c_data_nbytes-1:0] write_byte_en,
  input  logic [c_addr_nbits-1:0]  write_addr,
  input  logic [p_data_nbits-1:0]  write_data
);

  logic [p_data_nbits-1:0] mem[p_num_entries-1:0];

  // Combinational read. We ensure the read data is all X's if we are
  // doing a write because we are modeling an SRAM with a single
  // read/write port (i.e., not a dual ported SRAM). We also ensure the
  // read data is all X's if the read is not enable at all to avoid
  // (potentially) incorrectly assuming the SRAM latches the read data.

  /* verilator lint_off WIDTH */

  always_comb begin
    if ( read_en )
      read_data = mem[read_addr];
    else
      read_data = 'hx;
  end

  /* verilator lint_on WIDTH */

  // Inspired by http://www.xilinx.com/support/documentation/sw_manuals/xilinx11/xst.pdf, page 159

  genvar i;
  generate
    for ( i = 0; i < c_data_nbytes; i = i + 1 )
    begin : test
      always_ff @( posedge clk ) begin
        if ( write_en && write_byte_en[i] )
          mem[write_addr][ (i+1)*8-1 : i*8 ] <= write_data[ (i+1)*8-1 : i*8 ];
      end
    end
  endgenerate

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( read_en );
      `VC_ASSERT_NOT_X( write_en );

      // There is only one port. You can only do a read OR a write.

      `VC_ASSERT( !(read_en && write_en) );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's. Write byte
      // enables also cannot be X.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT_NOT_X( write_byte_en );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */
  
endmodule

//------------------------------------------------------------------------
// 1rw Synchronous SRAM
//------------------------------------------------------------------------

module vc_SynchronousSRAM_1rw
#(
  parameter p_data_nbits  = 1,
  parameter p_num_entries = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits  = $clog2(p_num_entries),
  parameter c_data_nbytes = (p_data_nbits+7)/8 // $ceil(p_data_nbits/8)
)(
  input  logic                     clk,
  input  logic                     reset,

  // Read port (synchronous read)

  input  logic                     read_en,
  input  logic [c_addr_nbits-1:0]  read_addr,
  output logic [p_data_nbits-1:0]  read_data,

  // Write port (sampled on the rising clock edge)

  input  logic                     write_en,
  input  logic [c_data_nbytes-1:0] write_byte_en,
  input  logic [c_addr_nbits-1:0]  write_addr,
  input  logic [p_data_nbits-1:0]  write_data
);

  logic [p_data_nbits-1:0] mem[p_num_entries-1:0];

  // Combinational read. We ensure the read data is all X's if we are
  // doing a write because we are modeling an SRAM with a single
  // read/write port (i.e., not a dual ported SRAM). We also ensure the
  // read data is all X's if the read is not enable at all to avoid
  // (potentially) incorrectly assuming the SRAM latches the read data.

  always_ff @( posedge clk ) begin
    if ( read_en )
      read_data <= mem[read_addr];
    else
      read_data <= 'hx;
  end

  // Inspired by http://www.xilinx.com/support/documentation/sw_manuals/xilinx11/xst.pdf, page 159

  genvar i;
  generate
    for ( i = 0; i < c_data_nbytes; i = i + 1 )
    begin : test
      always_ff @( posedge clk ) begin
        if ( write_en && write_byte_en[i] )
          mem[write_addr][ (i+1)*8-1 : i*8 ] <= write_data[ (i+1)*8-1 : i*8 ];
      end
    end
  endgenerate

  // Assertions

  /*
  always_ff @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( read_en );
      `VC_ASSERT_NOT_X( write_en );

      // There is only one port. You can only do a read OR a write.

      `VC_ASSERT( !(read_en && write_en) );

      // If write_en is one, then write address better be less than the
      // number of entries and definitely cannot be X's. Write byte
      // enables also cannot be X.

      if ( write_en ) begin
        `VC_ASSERT_NOT_X( write_addr );
        `VC_ASSERT_NOT_X( write_byte_en );
        `VC_ASSERT( write_addr < p_num_entries );
      end

    end
  end
  */

endmodule

`endif /* VC_SRAMS_V */


`line 16 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0
`line 1 "vc/arithmetic.v" 0
//========================================================================
// Verilog Components: Arithmetic Components
//========================================================================

`ifndef VC_ARITHMETIC_V
`define VC_ARITHMETIC_V

//------------------------------------------------------------------------
// Adders
//------------------------------------------------------------------------

module vc_Adder
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  input  logic               cin,
  output logic [p_nbits-1:0] out,
  output logic               cout
);

  // We need to convert cin into a 32-bit value to
  // avoid verilator warnings

  assign {cout,out} = in0 + in1 + {{(p_nbits-1){1'b0}},cin};

endmodule

module vc_SimpleAdder
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  output logic [p_nbits-1:0] out
);

  assign out = in0 + in1;

endmodule

//------------------------------------------------------------------------
// Subtractor
//------------------------------------------------------------------------

module vc_Subtractor
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  output logic [p_nbits-1:0] out
);

  assign out = in0 - in1;

endmodule

//------------------------------------------------------------------------
// Incrementer
//------------------------------------------------------------------------

module vc_Incrementer
#(
  parameter p_nbits     = 1,
  parameter p_inc_value = 1
)(
  input  logic [p_nbits-1:0] in,
  output logic [p_nbits-1:0] out
);

  assign out = in + p_inc_value;

endmodule

//------------------------------------------------------------------------
// ZeroExtender
//------------------------------------------------------------------------

module vc_ZeroExtender
#(
  parameter p_in_nbits  = 1,
  parameter p_out_nbits = 8
)(
  input  logic [p_in_nbits-1:0]  in,
  output logic [p_out_nbits-1:0] out
);

  assign out = { {( p_out_nbits - p_in_nbits ){1'b0}}, in };

endmodule

//------------------------------------------------------------------------
// SignExtender
//------------------------------------------------------------------------

module vc_SignExtender
#(
 parameter p_in_nbits = 1,
 parameter p_out_nbits = 8
)
(
  input  logic [p_in_nbits-1:0]  in,
  output logic [p_out_nbits-1:0] out
);

  assign out = { {(p_out_nbits-p_in_nbits){in[p_in_nbits-1]}}, in };

endmodule

//------------------------------------------------------------------------
// ZeroComparator
//------------------------------------------------------------------------

module vc_ZeroComparator
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in,
  output logic               out
);

  assign out = ( in == {p_nbits{1'b0}} );

endmodule

//------------------------------------------------------------------------
// EqComparator
//------------------------------------------------------------------------

module vc_EqComparator
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  output logic               out
);

  assign out = ( in0 == in1 );

endmodule

//------------------------------------------------------------------------
// LtComparator
//------------------------------------------------------------------------

module vc_LtComparator
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  output logic               out
);

  assign out = ( in0 < in1 );

endmodule

//------------------------------------------------------------------------
// GtComparator
//------------------------------------------------------------------------

module vc_GtComparator
#(
  parameter p_nbits = 1
)(
  input  logic [p_nbits-1:0] in0,
  input  logic [p_nbits-1:0] in1,
  output logic               out
);

  assign out = ( in0 > in1 );

endmodule

//------------------------------------------------------------------------
// LeftLogicalShifter
//------------------------------------------------------------------------

module vc_LeftLogicalShifter
#(
  parameter p_nbits       = 1,
  parameter p_shamt_nbits = 1 )
(
  input  logic       [p_nbits-1:0] in,
  input  logic [p_shamt_nbits-1:0] shamt,
  output logic       [p_nbits-1:0] out
);

  assign out = ( in << shamt );

endmodule

//------------------------------------------------------------------------
// RightLogicalShifter
//------------------------------------------------------------------------

module vc_RightLogicalShifter
#(
  parameter p_nbits       = 1,
  parameter p_shamt_nbits = 1
)(
  input  logic       [p_nbits-1:0] in,
  input  logic [p_shamt_nbits-1:0] shamt,
  output logic       [p_nbits-1:0] out
);

  assign out = ( in >> shamt );

endmodule

`endif /* VC_ARITHMETIC_V */


`line 17 "lab3_mem/BlockingCacheAltDpathVRTL.v" 0

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

`line 13 "lab3_mem/BlockingCacheAltVRTL.v" 0

// Note on p_num_banks:
// In a multi-banked cache design, cache lines are interleaved to
// different cache banks, so that consecutive cache lines correspond to a
// different bank. The following is the addressing structure in our
// four-banked data caches:
//
// +--------------------------+--------------+--------+--------+--------+
// |        22b               |     4b       |   2b   |   2b   |   2b   |
// |        tag               |   index      |bank idx| offset | subwd  |
// +--------------------------+--------------+--------+--------+--------+
//
// We will compose a four-banked cache in lab5, the multi-core lab

module lab3_mem_BlockingCacheAltVRTL
#(
  parameter p_num_banks    = 0               // Total number of cache banks
)
(
  input  logic           clk,
  input  logic           reset,

  // Cache Request

  input  mem_req_4B_t    cachereq_msg,
  input  logic           cachereq_val,
  output logic           cachereq_rdy,

  // Cache Response

  output mem_resp_4B_t   cacheresp_msg,
  output logic           cacheresp_val,
  input  logic           cacheresp_rdy,

  // Memory Request

  output mem_req_16B_t   memreq_msg,
  output logic           memreq_val,
  input  logic           memreq_rdy,

  // Memory Response

  input  mem_resp_16B_t  memresp_msg,
  input  logic           memresp_val,
  output logic           memresp_rdy
);

  localparam size = 256; // Number of bytes in the cache
  localparam dbw  = 32;  // Short name for data bitwidth
  localparam abw  = 32;  // Short name for addr bitwidth
  localparam clw  = 128; // Short name for cacheline bitwidth

  // calculate the index shift amount based on number of banks

  localparam c_idx_shamt = $clog2( p_num_banks );

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Define wires
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  logic cachereq_en;
  logic memresp_en;
  logic tag_array_ren;
  logic tag_array_wen0;
  logic tag_array_wen1;
  logic data_array_ren;
  logic read_data_reg_en;
  logic evict_addr_reg_en;
  logic write_data_mux_sel;
  logic [2:0] read_word_mux_sel;
  logic memreq_addr_mux_sel;
  logic [2:0] cacheresp_type;
  logic [2:0] memreq_type;
  logic [2:0] cachereq_type;
  logic [31:0] cachereq_addr;
  logic [1:0] cacheresp_hit;
  logic [15:0] data_array_wben;
  logic tag_match0;
  logic tag_match1;
  logic way_sel;
  logic data_array_wen;
  
  //----------------------------------------------------------------------
  // Control
  //----------------------------------------------------------------------

  lab3_mem_BlockingCacheAltCtrlVRTL
  #(
    .p_idx_shamt            (c_idx_shamt)
  )
  ctrl
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_val      (cachereq_val),
   .cachereq_rdy      (cachereq_rdy),

   // Cache Response

   .cacheresp_val     (cacheresp_val),
   .cacheresp_rdy     (cacheresp_rdy),

   // Memory Request

   .memreq_val        (memreq_val),
   .memreq_rdy        (memreq_rdy),

   // Memory Response

   .memresp_val       (memresp_val),
   .memresp_rdy       (memresp_rdy),

   //'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
   // LAB TASK: Connect control unit
   //'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

   // Register Enables
   .cachereq_en(cachereq_en),
   .memresp_en(memresp_en),
   .evict_addr_reg_en(evict_addr_reg_en),
   .read_data_reg_en(read_data_reg_en),

   // Mux Selects
   .write_data_mux_sel(write_data_mux_sel),
   .memreq_addr_mux_sel(memreq_addr_mux_sel),
   .read_word_mux_sel(read_word_mux_sel),
   .way_sel(way_sel),

   // Tag Array Enables
   .tag_array_ren(tag_array_ren),
   .tag_array_wen0(tag_array_wen0),
   .tag_array_wen1(tag_array_wen1),
   // Data Aray Enables
   .data_array_ren(data_array_ren),
   .data_array_wen(data_array_wen),
   .data_array_wben(data_array_wben),

   // Cache Response Message
   .cacheresp_type(cacheresp_type),
   .cacheresp_hit(cacheresp_hit),

   // Memory Response Message
   .memreq_type(memreq_type),

   .cachereq_type(cachereq_type),
   .cachereq_addr(cachereq_addr),
   .tag_match0(tag_match0),
   .tag_match1(tag_match1)

  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  lab3_mem_BlockingCacheAltDpathVRTL
  #(
    .p_idx_shamt            (c_idx_shamt)
  )
  dpath
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_msg      (cachereq_msg),

   // Cache Response

   .cacheresp_msg     (cacheresp_msg),

   // Memory Request

   .memreq_msg        (memreq_msg),

   // Memory Response

   .memresp_msg       (memresp_msg),

   //'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
   // LAB TASK: Connect data path 
   //'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
   
   // Enables
  .cachereq_en(cachereq_en),
  .memresp_en(memresp_en),
  .tag_array_ren(tag_array_ren),
  .tag_array_wen0(tag_array_wen0),
  .tag_array_wen1(tag_array_wen1),
  .data_array_ren(data_array_ren),
  .data_array_wen(data_array_wen),
  .data_array_wben(data_array_wben),
  .read_data_reg_en(read_data_reg_en),
  .evict_addr_reg_en(evict_addr_reg_en),

  // Selects
  .write_data_mux_sel(write_data_mux_sel),
  .read_word_mux_sel(read_word_mux_sel),
  .memreq_addr_mux_sel(memreq_addr_mux_sel),

  .cacheresp_type(cacheresp_type),
  .memreq_type(memreq_type),

  .cachereq_type(cachereq_type),
  .cachereq_addr(cachereq_addr),
  .tag_match0(tag_match0),
  .tag_match1(tag_match1),
  .cacheresp_hit(cacheresp_hit),
  .way_sel(way_sel)

  );


  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------
  vc_MemReqMsg4BTrace cachereq_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (cachereq_val),
    .rdy   (cachereq_rdy),
    .msg   (cachereq_msg)
  );

  vc_MemRespMsg4BTrace cacheresp_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (cacheresp_val),
    .rdy   (cacheresp_rdy),
    .msg   (cacheresp_msg)
  );

  vc_MemReqMsg16BTrace memreq_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (memreq_val),
    .rdy   (memreq_rdy),
    .msg   (memreq_msg)
  );

  vc_MemRespMsg16BTrace memresp_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (memresp_val),
    .rdy   (memresp_rdy),
    .msg   (memresp_msg)
  );

  logic [`VC_TRACE_NBITS-1:0] str;
  `VC_TRACE_BEGIN
begin
    case ( ctrl.state_reg )

      ctrl.STATE_IDLE:                   vc_trace.append_str( trace_str, "(I )" );
      ctrl.STATE_TAG_CHECK:              vc_trace.append_str( trace_str, "(TC)" );
      ctrl.STATE_INIT_DATA_ACCESS:       vc_trace.append_str( trace_str, "(IN)" );
      ctrl.STATE_WAIT:                   vc_trace.append_str( trace_str, "(W )" );
      ctrl.STATE_READ_DATA_ACCESS:       vc_trace.append_str( trace_str, "(RD)" );
      ctrl.STATE_WRITE_DATA_ACCESS:      vc_trace.append_str( trace_str, "(WD)" );
      ctrl.STATE_EVICT_PREPARE:          vc_trace.append_str( trace_str, "(EP)" );
      ctrl.STATE_EVICT_REQUEST:          vc_trace.append_str( trace_str, "(ER)" );
      ctrl.STATE_EVICT_WAIT:             vc_trace.append_str( trace_str, "(EW)" );
      ctrl.STATE_REFILL_REQUEST:         vc_trace.append_str( trace_str, "(RR)" );
      ctrl.STATE_REFILL_WAIT:            vc_trace.append_str( trace_str, "(RW)" );
      ctrl.STATE_REFILL_UPDATE:          vc_trace.append_str( trace_str, "(RU)" );
      default:                           vc_trace.append_str( trace_str, "(? )" );

    endcase

    //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    // LAB TASK: Add line tracing
    //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  end
  `VC_TRACE_END
endmodule

`endif
