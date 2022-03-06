//=========================================================================
// Alternative Blocking Cache Control Unit
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V

`include "vc/mem-msgs.v"
`include "vc/assert.v"

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include necessary files
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
`include "vc/regfiles.v"
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
