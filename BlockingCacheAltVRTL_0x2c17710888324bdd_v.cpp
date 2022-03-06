//======================================================================
// VBlockingCacheAltVRTL_0x2c17710888324bdd_v.cpp
//======================================================================
// This wrapper exposes a C interface to CFFI so that a
// Verilator-generated C++ model can be driven from Python.
//

#include "obj_dir_BlockingCacheAltVRTL_0x2c17710888324bdd/VBlockingCacheAltVRTL_0x2c17710888324bdd.h"
#include "stdio.h"
#include "stdint.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// set to true when VCD tracing is enabled in Verilator
#define DUMP_VCD 1

// set to true when Verilog module has line tracing
#define VLINETRACE 1

#if VLINETRACE
#include "obj_dir_BlockingCacheAltVRTL_0x2c17710888324bdd/VBlockingCacheAltVRTL_0x2c17710888324bdd__Syms.h"
#include "svdpi.h"
#endif

//----------------------------------------------------------------------
// CFFI Interface
//----------------------------------------------------------------------
// simulation methods and model interface ports exposed to CFFI

extern "C" {
  typedef struct {

    // Exposed port interface
    unsigned int * memresp_msg;
  unsigned char * memresp_val;
  unsigned char * memreq_rdy;
  unsigned char * cacheresp_rdy;
  unsigned int * cachereq_msg;
  unsigned char * cachereq_val;
  unsigned char * reset;
  unsigned char * clk;
  unsigned char * memresp_rdy;
  unsigned int * memreq_msg;
  unsigned char * memreq_val;
  unsigned long * cacheresp_msg;
  unsigned char * cacheresp_val;
  unsigned char * cachereq_rdy;

    // Verilator model
    void * model;

    // VCD state
    int _vcd_en;

    // VCD tracing helpers
    #if DUMP_VCD
    void *        tfp;
    unsigned int  trace_time;
    unsigned char prev_clk;
    #endif

  } VBlockingCacheAltVRTL_0x2c17710888324bdd_t;

  // Exposed methods
  VBlockingCacheAltVRTL_0x2c17710888324bdd_t * create_model( const char * );
  void destroy_model( VBlockingCacheAltVRTL_0x2c17710888324bdd_t *);
  void eval( VBlockingCacheAltVRTL_0x2c17710888324bdd_t * );

  #if VLINETRACE
  void trace( VBlockingCacheAltVRTL_0x2c17710888324bdd_t *, char * );
  #endif
}

//----------------------------------------------------------------------
// sc_time_stamp
//----------------------------------------------------------------------
// Must be defined so the simulator knows the current time. Called by
// $time in Verilog. See:
// http://www.veripool.org/projects/verilator/wiki/Faq

vluint64_t g_main_time = 0;

double sc_time_stamp()
{
  return g_main_time;
}

//----------------------------------------------------------------------
// create_model()
//----------------------------------------------------------------------
// Construct a new verilator simulation, initialize interface signals
// exposed via CFFI, and setup VCD tracing if enabled.

VBlockingCacheAltVRTL_0x2c17710888324bdd_t * create_model( const char *vcd_filename ) {

  VBlockingCacheAltVRTL_0x2c17710888324bdd_t * m;
  VBlockingCacheAltVRTL_0x2c17710888324bdd   * model;

  Verilated::randReset( 0 );

  m     = (VBlockingCacheAltVRTL_0x2c17710888324bdd_t *) malloc( sizeof(VBlockingCacheAltVRTL_0x2c17710888324bdd_t) );
  model = new VBlockingCacheAltVRTL_0x2c17710888324bdd();

  m->model = (void *) model;

  // Enable tracing. We have added a feature where if the vcd_filename is
  // '' then we don't do any VCD dumping even if DUMP_VCD is true.

  m->_vcd_en = 0;
  #if DUMP_VCD
  if ( strlen( vcd_filename ) != 0 ) {
    m->_vcd_en = 1;
    Verilated::traceEverOn( true );
    VerilatedVcdC * tfp = new VerilatedVcdC();

    model->trace( tfp, 99 );
    tfp->spTrace()->set_time_resolution( "10ps" );
    tfp->open( vcd_filename );

    m->tfp        = (void *) tfp;
    m->trace_time = 0;
    m->prev_clk   = 0;
  }
  #endif

  // initialize exposed model interface pointers
  m->memresp_msg = model->memresp_msg;
  m->memresp_val = &model->memresp_val;
  m->memreq_rdy = &model->memreq_rdy;
  m->cacheresp_rdy = &model->cacheresp_rdy;
  m->cachereq_msg = model->cachereq_msg;
  m->cachereq_val = &model->cachereq_val;
  m->reset = &model->reset;
  m->clk = &model->clk;
  m->memresp_rdy = &model->memresp_rdy;
  m->memreq_msg = model->memreq_msg;
  m->memreq_val = &model->memreq_val;
  m->cacheresp_msg = &model->cacheresp_msg;
  m->cacheresp_val = &model->cacheresp_val;
  m->cachereq_rdy = &model->cachereq_rdy;

  return m;
}

//----------------------------------------------------------------------
// destroy_model()
//----------------------------------------------------------------------
// Finalize the Verilator simulation, close files, call destructors.

void destroy_model( VBlockingCacheAltVRTL_0x2c17710888324bdd_t * m ) {

  VBlockingCacheAltVRTL_0x2c17710888324bdd * model = (VBlockingCacheAltVRTL_0x2c17710888324bdd *) m->model;

  // finalize verilator simulation
  model->final();

  #if DUMP_VCD
  if ( m->_vcd_en ) {
    printf("DESTROYING %d\n", m->trace_time );
    VerilatedVcdC * tfp = (VerilatedVcdC *) m->tfp;
    tfp->close();
  }
  #endif

  // TODO: this is probably a memory leak!
  //       But pypy segfaults if uncommented...
  //delete model;

}

//----------------------------------------------------------------------
// eval()
//----------------------------------------------------------------------
// Simulate one time-step in the Verilated model.

void eval( VBlockingCacheAltVRTL_0x2c17710888324bdd_t * m ) {

  VBlockingCacheAltVRTL_0x2c17710888324bdd * model = (VBlockingCacheAltVRTL_0x2c17710888324bdd *) m->model;

  // evaluate one time step
  model->eval();

  #if DUMP_VCD
  if ( m->_vcd_en ) {

    // update simulation time only on clock toggle
    if (m->prev_clk != model->clk) {
      m->trace_time += 50;
      g_main_time += 50;
    }
    m->prev_clk = model->clk;

    // dump current signal values
    VerilatedVcdC * tfp = (VerilatedVcdC *) m->tfp;
    tfp->dump( m->trace_time );
    tfp->flush();

  }
  #endif

}

//----------------------------------------------------------------------
// trace()
//----------------------------------------------------------------------
// Note that we assume a trace string buffer of 512 characters. This is
// assumed in a couple of places, including the Python wrapper template
// and the Verilog vc/trace.v code. So if we change it, we need to change
// it everywhere.

#if VLINETRACE
void trace( VBlockingCacheAltVRTL_0x2c17710888324bdd_t * m, char* str ) {

  VBlockingCacheAltVRTL_0x2c17710888324bdd * model = (VBlockingCacheAltVRTL_0x2c17710888324bdd *) m->model;

  const int nchars = 512;
  const int nwords = nchars/4;

  uint32_t words[nwords];
  words[0] = nchars-1;

  // Setup scope for accessing the line tracing function throug DPI.
  // Note, I tried using just this:
  //
  //  svSetScope( svGetScopeFromName("TOP.v.verilog_module") );
  //
  // but it did not seem to work. We would see correct line tracing for
  // the first test case but not any of the remaining tests cases. After
  // digging around a bit, it seemed like the line_trace task was still
  // associated with the very first model as opposed to the newly
  // instantiated models. Directly setting the scope seemed to fix
  // this issue.

  svSetScope( &model->__VlSymsp->__Vscope_v__verilog_module );
  model->line_trace( words );

  // Note that the way the line tracing works, the line tracing function
  // will store how the last character used in the line trace in the
  // first element of the word array. The line tracing functions store
  // the line trace starting from the most-signicant character due to the
  // way that Verilog handles strings.

  int nchar_last  = words[0];
  int nchars_used = ( nchars - 1 - nchar_last );

  // We subtract since one of the words (i.e., 4 characters) is for
  // storing the nchars_used.

  assert ( nchars_used < (nchars - 4) );

  // Now we need to iterate from the most-significant character to the
  // last character written by the line tracing functions and copy these
  // characters into the given character array. So we are kind of
  // flipping the order of the characters due to the different between
  // how Verilog and C handle strings.

  int j = 0;
  for ( int i = nchars-1; i > nchar_last; i-- ) {
    char c = static_cast<char>( words[i/4] >> (8*(i%4)) );
    str[j] = c;
    j++;
  }
  str[j] = '\0';

}
#endif

