#=======================================================================
# VBlockingCacheAltVRTL_0x7023474b19b819c4_v.py
#=======================================================================
# This wrapper makes a Verilator-generated C++ model appear as if it
# were a normal PyMTL model.

import os

from pymtl import *
from cffi  import FFI

#-----------------------------------------------------------------------
# BlockingCacheAltVRTL_0x7023474b19b819c4
#-----------------------------------------------------------------------
class BlockingCacheAltVRTL_0x7023474b19b819c4( Model ):
  id_ = 0

  def __init__( s ):

    # initialize FFI, define the exposed interface
    s.ffi = FFI()
    s.ffi.cdef('''
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

      } VBlockingCacheAltVRTL_0x7023474b19b819c4_t;

      VBlockingCacheAltVRTL_0x7023474b19b819c4_t * create_model( const char * );
      void destroy_model( VBlockingCacheAltVRTL_0x7023474b19b819c4_t *);
      void eval( VBlockingCacheAltVRTL_0x7023474b19b819c4_t * );
      void trace( VBlockingCacheAltVRTL_0x7023474b19b819c4_t *, char * );

    ''')

    # Import the shared library containing the model. We defer
    # construction to the elaborate_logic function to allow the user to
    # set the vcd_file.

    s._ffi = s.ffi.dlopen('./libBlockingCacheAltVRTL_0x7023474b19b819c4_v.so')

    # dummy class to emulate PortBundles
    class BundleProxy( PortBundle ):
      flip = False

    # define the port interface
    s.memresp = BundleProxy()
    s.memresp._ports = []
    from pclib.ifcs.MemMsg import MemRespMsg
    s.memresp.msg = InPort( MemRespMsg(8, 128) )
    s.memresp._ports.append( s.memresp.msg )
    s.memresp.msg.name = 'msg'
    s.memresp.rdy = OutPort( 1 )
    s.memresp._ports.append( s.memresp.rdy )
    s.memresp.rdy.name = 'rdy'
    s.memresp.val = InPort( 1 )
    s.memresp._ports.append( s.memresp.val )
    s.memresp.val.name = 'val'
    s.memreq = BundleProxy()
    s.memreq._ports = []
    from pclib.ifcs.MemMsg import MemReqMsg
    s.memreq.msg = OutPort( MemReqMsg(8, 32, 128) )
    s.memreq._ports.append( s.memreq.msg )
    s.memreq.msg.name = 'msg'
    s.memreq.rdy = InPort( 1 )
    s.memreq._ports.append( s.memreq.rdy )
    s.memreq.rdy.name = 'rdy'
    s.memreq.val = OutPort( 1 )
    s.memreq._ports.append( s.memreq.val )
    s.memreq.val.name = 'val'
    s.cacheresp = BundleProxy()
    s.cacheresp._ports = []
    from pclib.ifcs.MemMsg import MemRespMsg
    s.cacheresp.msg = OutPort( MemRespMsg(8, 32) )
    s.cacheresp._ports.append( s.cacheresp.msg )
    s.cacheresp.msg.name = 'msg'
    s.cacheresp.rdy = InPort( 1 )
    s.cacheresp._ports.append( s.cacheresp.rdy )
    s.cacheresp.rdy.name = 'rdy'
    s.cacheresp.val = OutPort( 1 )
    s.cacheresp._ports.append( s.cacheresp.val )
    s.cacheresp.val.name = 'val'
    s.cachereq = BundleProxy()
    s.cachereq._ports = []
    from pclib.ifcs.MemMsg import MemReqMsg
    s.cachereq.msg = InPort( MemReqMsg(8, 32, 32) )
    s.cachereq._ports.append( s.cachereq.msg )
    s.cachereq.msg.name = 'msg'
    s.cachereq.rdy = OutPort( 1 )
    s.cachereq._ports.append( s.cachereq.rdy )
    s.cachereq.rdy.name = 'rdy'
    s.cachereq.val = InPort( 1 )
    s.cachereq._ports.append( s.cachereq.val )
    s.cachereq.val.name = 'val'
    s.reset = InPort( 1 )
    s.clk = InPort( 1 )

    # increment instance count
    BlockingCacheAltVRTL_0x7023474b19b819c4.id_ += 1

    # Defer vcd dumping until later
    s.vcd_file = None

    # Buffer for line tracing
    s._line_trace_str = s.ffi.new("char[512]")
    s._convert_string = s.ffi.string

  def __del__( s ):
    s._ffi.destroy_model( s._m )

  def elaborate_logic( s ):

    # Give verilator_vcd_file a slightly different name so PyMTL .vcd and
    # Verilator .vcd can coexist

    verilator_vcd_file = ""
    if s.vcd_file:
      filen, ext         = os.path.splitext( s.vcd_file )
      verilator_vcd_file = '{}.verilator{}{}'.format(filen, s.id_, ext)

    # Construct the model.

    s._m = s._ffi.create_model( s.ffi.new("char[]", verilator_vcd_file) )

    @s.combinational
    def logic():

      # set inputs
      s._m.memresp_msg[0] = s.memresp.msg[0:32]
      s._m.memresp_msg[1] = s.memresp.msg[32:64]
      s._m.memresp_msg[2] = s.memresp.msg[64:96]
      s._m.memresp_msg[3] = s.memresp.msg[96:128]
      s._m.memresp_msg[4] = s.memresp.msg[128:145]
      s._m.memresp_val[0] = s.memresp.val
      s._m.memreq_rdy[0] = s.memreq.rdy
      s._m.cacheresp_rdy[0] = s.cacheresp.rdy
      s._m.cachereq_msg[0] = s.cachereq.msg[0:32]
      s._m.cachereq_msg[1] = s.cachereq.msg[32:64]
      s._m.cachereq_msg[2] = s.cachereq.msg[64:77]
      s._m.cachereq_val[0] = s.cachereq.val
      s._m.reset[0] = s.reset

      # execute combinational logic
      s._ffi.eval( s._m )

      # set outputs
      # FIXME: currently write all outputs, not just combinational outs
      s.memresp.rdy.value = s._m.memresp_rdy[0]
      s.memreq.msg[0:32].value = s._m.memreq_msg[0]
      s.memreq.msg[32:64].value = s._m.memreq_msg[1]
      s.memreq.msg[64:96].value = s._m.memreq_msg[2]
      s.memreq.msg[96:128].value = s._m.memreq_msg[3]
      s.memreq.msg[128:160].value = s._m.memreq_msg[4]
      s.memreq.msg[160:175].value = s._m.memreq_msg[5]
      s.memreq.val.value = s._m.memreq_val[0]
      s.cacheresp.msg.value = s._m.cacheresp_msg[0]
      s.cacheresp.val.value = s._m.cacheresp_val[0]
      s.cachereq.rdy.value = s._m.cachereq_rdy[0]

    @s.posedge_clk
    def tick():

      s._m.clk[0] = 0
      s._ffi.eval( s._m )
      s._m.clk[0] = 1
      s._ffi.eval( s._m )

      # double buffer register outputs
      # FIXME: currently write all outputs, not just registered outs
      s.memresp.rdy.next = s._m.memresp_rdy[0]
      s.memreq.msg[0:32].next = s._m.memreq_msg[0]
      s.memreq.msg[32:64].next = s._m.memreq_msg[1]
      s.memreq.msg[64:96].next = s._m.memreq_msg[2]
      s.memreq.msg[96:128].next = s._m.memreq_msg[3]
      s.memreq.msg[128:160].next = s._m.memreq_msg[4]
      s.memreq.msg[160:175].next = s._m.memreq_msg[5]
      s.memreq.val.next = s._m.memreq_val[0]
      s.cacheresp.msg.next = s._m.cacheresp_msg[0]
      s.cacheresp.val.next = s._m.cacheresp_val[0]
      s.cachereq.rdy.next = s._m.cachereq_rdy[0]

  def line_trace( s ):
    if 1:
      s._ffi.trace( s._m, s._line_trace_str )
      return s._convert_string( s._line_trace_str )
    else:
      return ""

