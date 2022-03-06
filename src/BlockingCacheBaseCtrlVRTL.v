//=========================================================================
// Baseline Blocking Cache Control
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_BASE_CTRL_V
`define LAB3_MEM_BLOCKING_CACHE_BASE_CTRL_V

`include "vc/mem-msgs.v"
`include "vc/assert.v"

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

`include "vc/regfiles.v"

module lab3_mem_BlockingCacheBaseCtrlVRTL
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

  // Tag Array Enables
  output logic                        tag_array_ren,
  output logic                        tag_array_wen,
  
  // Data Aray Enables
  output logic                        data_array_ren,
  output logic                        data_array_wen,
  output logic [15:0]                 data_array_wben,

  // Cache Response Message
  output logic  [2:0]                 cacheresp_type,
  output logic [1:0]                  cacheresp_hit,
  input logic tag_match,

  // Memory Response Message
  output logic  [2:0]                 memreq_type,

  input logic  [2:0]                  cachereq_type,
  input logic  [abw-1:0]              cachereq_addr            

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

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Implement control unit
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  // Reset State Logix 
  always_ff @(posedge clk) begin
    if (reset)begin
      state_reg <= STATE_IDLE;
    end
    else begin
      state_reg <= state_next;
    end
  end

  // Valid Bit
  logic [idw-1:0] valid_read_addr;
  assign valid_read_addr = cachereq_addr[idw+3+p_idx_shamt:4+p_idx_shamt];

  logic valid_write_en;
  logic [idw-1:0] valid_write_addr;
  assign valid_write_addr = cachereq_addr[idw+3+p_idx_shamt:4+p_idx_shamt];

  logic valid_write_data;
  logic valid_read_data;
  // logic valid_write_en;

  vc_Regfile_1r1w #( 1, nbl ) valid_bit_regfile(
    .clk( clk ),
    .reset( reset ),
    .read_addr( valid_read_addr ),
    .read_data( valid_read_data ),
    .write_en( valid_write_en ),
    .write_addr( valid_write_addr ),
    .write_data( valid_write_data )
  );

  // Dirty Bit
  logic [idw-1:0] dirty_read_addr;
  assign dirty_read_addr = cachereq_addr[idw+3+p_idx_shamt:4+p_idx_shamt];

  logic dirty_write_en;
  logic [idw-1:0] dirty_write_addr;     // 4 + 3 + 0  
  assign dirty_write_addr = cachereq_addr[idw+3+p_idx_shamt:4+p_idx_shamt];

  logic dirty_write_data;
  logic dirty_read_data;

  vc_Regfile_1r1w #( 1, nbl ) dirty_bit_regfile(
    .clk( clk ),
    .reset( reset ),
    .read_addr( dirty_read_addr ),
    .read_data( dirty_read_data ),
    .write_en( dirty_write_en ),
    .write_addr( dirty_write_addr ),
    .write_data( dirty_write_data )
  );


  logic [3:0] state_next;
  logic [3:0] state_reg;

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
    input logic cs_tag_array_wen,
    input logic cs_data_array_ren,
    input logic cs_data_array_wen,
    input logic [15:0] cs_data_array_wben,
    input logic [2:0] cs_cacheresp_type,
    input logic [2:0] cs_memreq_type,
    input logic cs_valid_write_en,
    input logic cs_valid_write_data,
    input logic cs_dirty_write_en,
    input logic cs_dirty_write_data
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
    tag_array_wen = cs_tag_array_wen;
    data_array_ren = cs_data_array_ren;
    data_array_wen = cs_data_array_wen;
    data_array_wben = cs_data_array_wben;
    cacheresp_type = cs_cacheresp_type;
    memreq_type = cs_memreq_type;
    valid_write_en = cs_valid_write_en;
    valid_write_data = cs_valid_write_data;
    dirty_write_en = cs_dirty_write_en;
    dirty_write_data = cs_dirty_write_data;
  end
  endtask

  logic [2:0] rwm; // Read Word Mux 3-bit
  logic [1:0] rwm0; // Read Word Mux 2-bit
  assign rwm = { 1'b0, cachereq_addr[3:2] };
  assign rwm0 = cachereq_addr[3:2];
  logic [2:0] crt; // Cache Request Type
  assign crt = cachereq_type;

  logic [15:0] wb; // Select write location

  always_comb begin
    // Reset and Kepp hit logic
    if (reset) begin
      cacheresp_hit = 2'b0;
    end
    else begin
      cacheresp_hit = cacheresp_hit;
    end
    case( state_reg )
      STATE_IDLE: begin 
           //                                               *      * 
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | en    | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b1,  1'b0 , 1'b0, 1'b0 , 1'b1  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'd0  , 16'd0  ,  3'dx , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        if ( cachereq_val == 1'b1 ) begin // cachereq_val
          state_next = STATE_TAG_CHECK;
        end
        else begin
          state_next = STATE_IDLE;
        end
      end

      // cacheresp_hit/Miss only changes here
      STATE_TAG_CHECK: begin
           //                               *        *     *       *
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b1  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'dx , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        // Determine if there is a hit
        if ( valid_read_data == 1'b1 && tag_match == 1'b1 )begin
          cacheresp_hit = 2'b1; // Hit
        end
        else begin
          cacheresp_hit = 2'b0; // Miss
        end

        if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT ) begin // init transaction
          state_next = STATE_INIT_DATA_ACCESS;
        end
        else if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ && cacheresp_hit == 2'b1 ) begin // read & cacheresp_hit
          state_next = STATE_READ_DATA_ACCESS;
        end
        else if( cacheresp_hit == 2'b0 && dirty_read_data == 1'b1 ) begin // miss & dirty
          state_next = STATE_EVICT_PREPARE;
        end
        else if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE && cacheresp_hit == 2'b1 ) begin // write & cacheresp_hit
          state_next = STATE_WRITE_DATA_ACCESS;
        end
        else if( cacheresp_hit == 2'b0 && dirty_read_data == 1'b0 )begin // miss & not dirty
          state_next = STATE_REFILL_REQUEST;
        end
      end

      STATE_INIT_DATA_ACCESS: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'b0  ,  1'bx  , 3'b100, 1'b0 , 1'b1  , 1'b0  , 1'b1  ,16'hffff,  crt  , 3'dx ,  1'b1 ,  1'b1 ,  1'b1 , 1'b0 );
        state_next = STATE_WAIT;
      end

      STATE_READ_DATA_ACCESS: begin
           //
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b1 , 1'bx  ,  1'bx  , rwm  , 1'b1  , 1'b0  , 1'b1  , 1'b0  , 16'd0  ,  crt  , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        state_next = STATE_WAIT;
      end

      STATE_WRITE_DATA_ACCESS: begin
         case ( rwm0 )
           2'b00: wb = 16'h000f;
           2'b01: wb = 16'h00f0;
           2'b10: wb = 16'h0f00;
           2'b11: wb = 16'hf000;
         endcase
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b1 , 1'b0  ,  1'bx  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b1  ,   wb   ,  crt  , 3'dx ,  1'b0 ,  1'bx ,  1'b1 , 1'b1 );
        state_next = STATE_WAIT;
      end

      STATE_REFILL_REQUEST: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b1, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'b1  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'dx , 3'd0 ,  1'b1 ,  1'b0 ,  1'b0 , 1'bx );
        if(memreq_rdy == 1'b1) begin // memreq_rdy
          state_next = STATE_REFILL_WAIT;
        end
        else begin // not memreq_rdy
          state_next = STATE_REFILL_REQUEST;
        end
      end

      STATE_EVICT_PREPARE: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b1 , 1'b1 , 1'bx  ,  1'b0  , 3'bx , 1'b1  , 1'b0  , 1'b1  , 1'b0  , 16'd0  ,  3'dx , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        state_next = STATE_EVICT_REQUEST;
      end

      STATE_EVICT_REQUEST: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b1, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'b0  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'dx , 3'd1 ,  1'b1 ,  1'b0 ,  1'b1 , 1'b0 );
        if(memreq_rdy == 1'b1) begin // memreq_rdy
          state_next = STATE_EVICT_WAIT;
        end
        else begin // not memreq_rdy
          state_next = STATE_EVICT_REQUEST;
        end
      end

      STATE_EVICT_WAIT: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b1 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'dx , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        if(memresp_val == 1'b1) begin // memresp_val
          state_next = STATE_REFILL_REQUEST;
        end
        else begin // not memresp_val
          state_next = STATE_EVICT_WAIT;
        end
      end

      STATE_REFILL_WAIT: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b1 , 1'b0  , 1'b1 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'd1 , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        if(memresp_val == 1'b1) begin // memresp_val
          state_next = STATE_REFILL_UPDATE;
        end
        else begin // not memresp_val
          state_next = STATE_REFILL_WAIT;
        end
      end

      STATE_REFILL_UPDATE: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'b1  ,  1'bx  , 3'bx , 1'b0  , 1'b1  , 1'b0  , 1'b1  ,16'hffff,  3'dx , 3'dx ,  1'b1 ,  1'b1 ,  1'b1 , 1'b0 );
        if( cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ ) begin // read
          state_next = STATE_READ_DATA_ACCESS;
        end
        else begin // write: cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE
          state_next = STATE_WRITE_DATA_ACCESS;
        end
      end

      STATE_WAIT: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b1 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , rwm , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  crt  , 3'dx ,  1'b0 ,  1'bx ,  1'b0 , 1'bx );
        if (cacheresp_rdy == 1'b1) begin // cacheresp_rdy
          state_next = STATE_IDLE;
        end
        else begin
          state_next = STATE_WAIT;
        end
      end 
      default: begin
           // cache | cache | mem | mem  | cache | mem  | evict | read | write | memreq | read | tag   | tag   | data  | data  | data   | cache | mem  | valid | valid | dirty | dirty
           // req   | resp  | req | resp | req   | resp | addr  | data | data  | addr   | word | array | array | array | array | array  | resp  | req  | write | write | write | write
           // rdy   | val   | val | rdy  | en    | en   | reg   | reg  | mux   | mux    | mux  | ren   | wen   | ren   | wen   | wben   | type  | type | en    | data  | end   | data
           //       |       |     |      |       |      | en    | en   | sel   | sel    | sel  |       |       |       |       |        |       |      |       |       |       |
        set_cs( 1'b0,  1'b0 , 1'b0, 1'b0 , 1'b0  , 1'b0 ,  1'b0 , 1'b0 , 1'bx  ,  1'bx  , 3'bx , 1'b0  , 1'b0  , 1'b0  , 1'b0  , 16'd0  ,  3'dx , 3'dx ,  1'b0 ,  1'bx ,  1'bx , 1'bx );
      end
    endcase
  end

endmodule

`endif
