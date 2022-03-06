#=========================================================================
# BlockingCacheFL_test.py
#=========================================================================
from __future__ import print_function

import pytest
import random
import struct
import math

random.seed(0xa4e28cc2)

from pymtl      import *
from pclib.test import mk_test_case_table, run_sim
from pclib.test import TestSource
from pclib.test import TestMemory

from pclib.ifcs import MemMsg,    MemReqMsg,    MemRespMsg
from pclib.ifcs import MemMsg4B,  MemReqMsg4B,  MemRespMsg4B
from pclib.ifcs import MemMsg16B, MemReqMsg16B, MemRespMsg16B

from TestCacheSink   import TestCacheSink
from lab3_mem.BlockingCacheFL import BlockingCacheFL

# We define all test cases here. They will be used to test _both_ FL and
# RTL models.
#
# Notice the difference between the TestHarness instances in FL and RTL.
#
# class TestHarness( Model ):
#   def __init__( s, src_msgs, sink_msgs, stall_prob, latency,
#                 src_delay, sink_delay, CacheModel, check_test, dump_vcd )
#
# The last parameter of TestHarness, check_test is whether or not we
# check the test field in the cacheresp. In FL model we don't care about
# test field and we set cehck_test to be False because FL model is just
# passing through cachereq to mem, so all cachereq sent to the FL model
# will be misses, whereas in RTL model we must set check_test to be True
# so that the test sink will know if we hit the cache properly.

#-------------------------------------------------------------------------
# TestHarness
#-------------------------------------------------------------------------
class TestHarness( Model ):

  def __init__( s, src_msgs, sink_msgs, stall_prob, latency,
                src_delay, sink_delay,
                CacheModel, num_banks, check_test, dump_vcd ):

    # Messge type
    cache_msgs = MemMsg4B()
    mem_msgs   = MemMsg16B()

    # Instantiate models
    s.src   = TestSource   ( cache_msgs.req,  src_msgs,  src_delay  )
    s.cache = CacheModel   ( num_banks = num_banks )
    s.mem   = TestMemory   ( mem_msgs, 1, stall_prob, latency )
    s.sink  = TestCacheSink( cache_msgs.resp, sink_msgs, sink_delay, check_test )

    # Dump VCD
    if dump_vcd:
      s.cache.vcd_file = dump_vcd

    # Connect
    s.connect( s.src.out,       s.cache.cachereq  )
    s.connect( s.sink.in_,      s.cache.cacheresp )

    s.connect( s.cache.memreq,  s.mem.reqs[0]     )
    s.connect( s.cache.memresp, s.mem.resps[0]    )

  def load( s, addrs, data_ints ):
    for addr, data_int in zip( addrs, data_ints ):
      data_bytes_a = bytearray()
      data_bytes_a.extend( struct.pack("<I",data_int) )
      s.mem.write_mem( addr, data_bytes_a )

  def done( s ):
    return s.src.done and s.sink.done

  def line_trace( s ):
    return s.src.line_trace() + " " + s.cache.line_trace() + " " \
         + s.mem.line_trace() + " " + s.sink.line_trace()

#-------------------------------------------------------------------------
# make messages
#-------------------------------------------------------------------------
def req( type_, opaque, addr, len, data ):
  msg = MemReqMsg4B()

  if   type_ == 'rd': msg.type_ = MemReqMsg.TYPE_READ
  elif type_ == 'wr': msg.type_ = MemReqMsg.TYPE_WRITE
  elif type_ == 'in': msg.type_ = MemReqMsg.TYPE_WRITE_INIT

  msg.addr   = addr
  msg.opaque = opaque
  msg.len    = len
  msg.data   = data
  return msg

def resp( type_, opaque, test, len, data ):
  msg = MemRespMsg4B()

  if   type_ == 'rd': msg.type_ = MemRespMsg.TYPE_READ
  elif type_ == 'wr': msg.type_ = MemRespMsg.TYPE_WRITE
  elif type_ == 'in': msg.type_ = MemRespMsg.TYPE_WRITE_INIT

  msg.opaque = opaque
  msg.len    = len
  msg.test   = test
  msg.data   = data
  return msg

#----------------------------------------------------------------------
# Test Case: read hit path
#----------------------------------------------------------------------
# The test field in the response message: 0 == MISS, 1 == HIT
def read_hit_1word_clean( base_addr ):
  return [
    #    type  opq  addr      len data                type  opq  test len data
    req( 'in', 0x0, base_addr, 0, 0xdeadbeef ), resp( 'in', 0x0, 0,   0,  0          ),
    req( 'rd', 0x1, base_addr, 0, 0          ), resp( 'rd', 0x1, 1,   0,  0xdeadbeef ),
  ]

#----------------------------------------------------------------------
# Test Case: read hit path
#----------------------------------------------------------------------
# The test field in the response message: 0 == MISS, 1 == HIT
def read_hit_1word_dirty( base_addr ):
  return [
    #    type  opq  addr      len data                type  opq  test len data
    req( 'in', 0x0, base_addr, 0, 0xdeadbeef ), resp( 'in', 0x0, 0,   0,  0          ),
    req( 'wr', 0x1, base_addr, 0, 0x12345678 ), resp( 'wr', 0x1, 1,   0,  0          ),
    req( 'rd', 0x2, base_addr, 0, 0          ), resp( 'rd', 0x2, 1,   0,  0x12345678 ),
  ]

#----------------------------------------------------------------------
# Test Case: read hit path -- for set-associative cache
#----------------------------------------------------------------------
# This set of tests designed only for alternative design
# The test field in the response message: 0 == MISS, 1 == HIT
def read_hit_associative( base_addr ):
  return [
    #    type  opq  addr       len data                type  opq  test len data
    req( 'wr', 0x0, 0x00000000, 0, 0xdeadbeef ), resp( 'wr', 0x0, 0,   0,  0          ),
    req( 'wr', 0x1, 0x00001000, 0, 0x12345678 ), resp( 'wr', 0x1, 0,   0,  0          ),
    req( 'rd', 0x2, 0x00000000, 0, 0          ), resp( 'rd', 0x2, 1,   0,  0xdeadbeef ),
    req( 'rd', 0x3, 0x00001000, 0, 0          ), resp( 'rd', 0x3, 1,   0,  0x12345678 ),
  ]

#----------------------------------------------------------------------
# Test Case: read hit path -- for direct-mapped cache
#----------------------------------------------------------------------
# This set of tests designed only for baseline design
def read_hit_direct_mapped( base_addr ):
  return [
    #    type  opq  addr       len data                type  opq  test len data
    req( 'wr', 0x0, 0x00000000, 0, 0xdeadbeef ), resp( 'wr', 0x0, 0,   0,  0          ),
    req( 'wr', 0x1, 0x00000080, 0, 0x12345678 ), resp( 'wr', 0x1, 0,   0,  0          ),
    req( 'rd', 0x2, 0x00000000, 0, 0          ), resp( 'rd', 0x2, 1,   0,  0xdeadbeef ),
    req( 'rd', 0x3, 0x00000080, 0, 0          ), resp( 'rd', 0x3, 1,   0,  0x12345678 ),
  ]

#-------------------------------------------------------------------------
# Test Case: write hit path
#-------------------------------------------------------------------------
def write_hit_1word_clean( base_addr ):
  return [
    #    type  opq   addr      len data               type  opq   test len data
    req( 'in', 0x00, base_addr, 0, 0x0a0b0c0d ), resp('in', 0x00, 0,   0,  0          ), # write word  0x00000000
    req( 'wr', 0x01, base_addr, 0, 0xbeeeeeef ), resp('wr', 0x01, 1,   0,  0          ), # write word  0x00000000
    req( 'rd', 0x02, base_addr, 0, 0          ), resp('rd', 0x02, 1,   0,  0xbeeeeeef ), # read  word  0x00000000
  ]

#-------------------------------------------------------------------------
# Test Case: write hit path
#-------------------------------------------------------------------------
def write_hit_1word_dirty( base_addr ):
  return [
    #    type  opq   addr      len data               type  opq   test len data
    req( 'in', 0x00, base_addr, 0, 0x0a0b0c0d ), resp('in', 0x00, 0,   0,  0          ), # write word  0x00000000
    req( 'wr', 0x01, base_addr, 0, 0xbeeeeeef ), resp('wr', 0x01, 1,   0,  0          ), # write word  0x00000000
    req( 'wr', 0x02, base_addr, 0, 0xdeadbeef ), resp('wr', 0x02, 1,   0,  0          ), # write word  0x00000000
    req( 'rd', 0x03, base_addr, 0, 0          ), resp('rd', 0x03, 1,   0,  0xdeadbeef ), # read  word  0x00000000
  ]

#-------------------------------------------------------------------------
# Test Case: read miss path
#-------------------------------------------------------------------------
def read_miss_1word_msg( base_addr ):
  return [
    #    type  opq   addr      len  data       type  opq test len  data
    req( 'rd', 0x00, 0x00000000, 0, 0 ), resp('rd', 0x00, 0, 0, 0xdeadbeef ), # read word  0x00000000
    req( 'rd', 0x01, 0x00000004, 0, 0 ), resp('rd', 0x01, 1, 0, 0x12345678 ), # read word  0x00000004
  ]

# Data to be loaded into memory before running the test
def read_miss_1word_mem( base_addr ):
  return [
    # addr      data (in int)
    0x00000000, 0xdeadbeef,
    0x00000004, 0x12345678,
  ]


#-------------------------------------------------------------------------
# Test Case: write miss path (no eviction)
#-------------------------------------------------------------------------
def write_miss_1word_msg( base_addr ):
    return [
    #    type  opq   addr      len  data               type  opq test len  data
    req( 'wr', 0x00, 0x00000000, 0, 0xdeadbeef ), resp('wr', 0x00, 0, 0,          0 ), # read word  0x00000000
    req( 'wr', 0x01, 0x00000004, 0, 0x12345678 ), resp('wr', 0x01, 1, 0,          0 ), # read word  0x00000004
    req( 'rd', 0x02, 0x00000004, 0, 0          ), resp('rd', 0x02, 1, 0, 0x12345678 ), # read word  0x00000004

  ]

# Data to be loaded into memory before running the test
def write_miss_1word_mem( base_addr ):
  return [
    # addr      data (in int)
    0x00000000, 0x11111111,
    0x00000004, 0x22222222,
  ]

#-------------------------------------------------------------------------
# Testing Random addresses and data values
#-------------------------------------------------------------------------
def random_addr_and_data ( base_addr ):
  for i in range(100):
    addr = random.randint(0, 127000)
    data = random.randint(0, 10000)
    return[
      req( 'wr', 0x00, addr, 0, data ), resp('wr', 0x00, 0, 0,          0 ),
      req( 'rd', 0x00, addr, 0, 0          ), resp('rd', 0x00, 1, 0, data ),
    ]

#-------------------------------------------------------------------------
# Test Case: read miss with refill and eviction
#-------------------------------------------------------------------------
def read_miss_1word_msg_evict( base_addr ):
  return [
    #    type  opq   addr      len  data               type  opq test len  data
    req( 'wr', 0x00, 0x00000000, 0, 0xdeadbeef ), resp('wr', 0x00, 0, 0,          0 ),
    req( 'rd', 0x01, 0x00000100, 0, 0          ), resp('rd', 0x01, 0, 0, 0x12345678 ),
    req( 'wr', 0x02, 0x00000100, 0, 0xdeadbeef ), resp('wr', 0x02, 1, 0,          0 ),
    req( 'rd', 0x03, 0x00000100, 0, 0          ), resp('rd', 0x03, 1, 0, 0xdeadbeef ),
  ]

def read_miss_1word_evict_mem( base_addr ):
  return [
    # addr      data (in int)
    0x00000100, 0x12345678,
  ]

#-------------------------------------------------------------------------
# Test Case: write miss with refill and eviction
#-------------------------------------------------------------------------
def write_miss_1word_msg_evict( base_addr ):
  return [
    #    type  opq   addr      len  data               type  opq test len  data
    req( 'wr', 0x00, 0x00000000, 0, 0xdeadbeef ), resp('wr', 0x00, 0, 0,          0 ),
    req( 'wr', 0x01, 0x00000100, 0, 0x12345678 ), resp('wr', 0x01, 0, 0,          0 ), # Same index, different tag, first line must be evicted
    req( 'rd', 0x02, 0x00000100, 0, 0          ), resp('rd', 0x02, 1, 0, 0x12345678 ),
  ]

def write_miss_1word_evict_mem( base_addr ):
  return [
    # addr      data (in int)
    0x00000100, 0x12345678,
  ]

#-------------------------------------------------------------------------
# Test Case: conflict miss
#-------------------------------------------------------------------------
def read_conflict_miss( base_addr ):
  return [
    #    type  opq   addr      len  data     type  opq test len  data
    req( 'rd', 0x00, 0x00000000, 0, 0), resp('rd', 0x00, 0, 0, 0xdeadbeef ),
    req( 'rd', 0x01, 0x00000100, 0, 0), resp('rd', 0x01, 0, 0, 0x12345678 ),
    req( 'rd', 0x02, 0x00000000, 0, 0), resp('rd', 0x02, 0, 0, 0xdeadbeef ),
    req( 'rd', 0x04, 0x00000100, 0, 0), resp('rd', 0x04, 0, 0, 0x12345678 ),

  ]

def read_conflict_miss_mem( base_addr ):
  return [
    # addr      data (in int)
    0x00000000, 0xdeadbeef,
    0x00000004, 0xffffffff,
    0x00000008, 0xffffffff,
    0x0000000c, 0xffffffff,
    0x00000100, 0x12345678,
    0x00000104, 0xffffffff,
    0x00000108, 0xffffffff,
    0x0000010c, 0xffffffff,
  ]

def read_capacity_miss( base_addr ):
  return [
    #    type  opq   addr      len  data     type  opq  test len  data
    req( 'rd', 0x00, 0x00000000, 0, 0), resp('rd', 0x00, 0, 0, 0xdeadbeef ),
    req( 'rd', 0x01, 0x00000010, 0, 0), resp('rd', 0x01, 0, 0, 0x12345678 ),
    req( 'rd', 0x02, 0x00000020, 0, 0), resp('rd', 0x02, 0, 0, 0x12345678 ),
    req( 'rd', 0x03, 0x00000030, 0, 0), resp('rd', 0x03, 0, 0, 0x12345678 ),
    req( 'rd', 0x04, 0x00000040, 0, 0), resp('rd', 0x04, 0, 0, 0x12345678 ),
    req( 'rd', 0x05, 0x00000050, 0, 0), resp('rd', 0x05, 0, 0, 0x12345678 ),
    req( 'rd', 0x06, 0x00000060, 0, 0), resp('rd', 0x06, 0, 0, 0x12345678 ),
    req( 'rd', 0x07, 0x00000070, 0, 0), resp('rd', 0x07, 0, 0, 0x12345678 ),
    req( 'rd', 0x08, 0x00000080, 0, 0), resp('rd', 0x08, 0, 0, 0x87654321 ),
    req( 'rd', 0x09, 0x00000090, 0, 0), resp('rd', 0x09, 0, 0, 0x87654321 ),
    req( 'rd', 0x0a, 0x000000a0, 0, 0), resp('rd', 0x0a, 0, 0, 0x87654321 ),
    req( 'rd', 0x0b, 0x000000b0, 0, 0), resp('rd', 0x0b, 0, 0, 0x87654321 ),
    req( 'rd', 0x0c, 0x000000c0, 0, 0), resp('rd', 0x0c, 0, 0, 0x87654321 ),
    req( 'rd', 0x0d, 0x000000d0, 0, 0), resp('rd', 0x0d, 0, 0, 0x87654321),
    req( 'rd', 0x0e, 0x000000e0, 0, 0), resp('rd', 0x0e, 0, 0, 0x87654321),
    req( 'rd', 0x0f, 0x000000f0, 0, 0), resp('rd', 0x0f, 0, 0, 0x87654321),
    req( 'rd', 0x00, 0x00000100, 0, 0), resp('rd', 0x00, 0, 0, 0x12345678 ),
  ]

def read_capacity_miss_mem( base_addr ):
  return [
    # address   data (in int)
    0x00000000, 0xdeadbeef,
    0x00000100, 0x12345678,
    0x00000010, 0x12345678,
    0x00000020, 0x12345678,
    0x00000030, 0x12345678,
    0x00000040, 0x12345678,
    0x00000050, 0x12345678,
    0x00000060, 0x12345678,
    0x00000070, 0x12345678,
    0x00000080, 0x87654321,
    0x00000090, 0x87654321,
    0x000000a0, 0x87654321,
    0x000000b0, 0x87654321,
    0x000000c0, 0x87654321,
    0x000000d0, 0x87654321,
    0x000000e0, 0x87654321,
    0x000000f0, 0x87654321,
  ]

#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Direct-mapped Cache
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
def read_miss_no_evict_direct_mapped_msg(base_addr):
    return [
        #    type  opq   addr      len  data      type  opq test len  data
        req('rd', 0x00, 0x00000100, 0, 0),   resp('rd', 0x00, 0, 0, 0xdeadbeef),  # read word  0x00000100
        req('rd', 0x01, 0x00000400, 0, 0),   resp('rd', 0x01, 0, 0, 0x12345678),  # read word  0x00000500
    ]
def read_miss_no_evict_direct_mapped_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef,
        0x00000400, 0x12345678,
    ]

def read_miss_evict_direct_mapped_msg(base_addr):
    return [
        #    type  opq   addr      len  data     type  opq test len  data
        req('rd', 0x00, 0x00000100, 0, 0),   resp('rd', 0x00, 0, 0, 0xdeadbeef),  # read word  0x00000100
        req('wr', 0x01, 0x00000108, 0, 0x1), resp('wr', 0x01, 1, 0, 0),           # write word 0x00000104
        req('rd', 0x02, 0x00000400, 0, 0),   resp('rd', 0x02, 0, 0, 0x12345678),  # read word  0x00000500
        req('rd', 0x03, 0x00000108, 0, 0),   resp('rd', 0x03, 0, 0, 0x1),         # read word  0x00000104
    ]
def read_miss_evict_direct_mapped_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef,
        0x00000108, 0x00020000,
        0x00000400, 0x12345678,
    ]

def write_miss_no_evict_direct_mapped_msg(base_addr):
    return [
        #    type  opq   addr      len  data      type  opq   test len  data
        req('rd', 0x00, 0x00000100, 0, 0),   resp('rd', 0x00, 0,   0,   0xdeadbeef),  # read word  0x00000100
        req('wr', 0x01, 0x00000400, 0, 0x1), resp('wr', 0x01, 0,   0,   0),           # write word  0x00000500
        req('rd', 0x02, 0x00000400, 0, 0),   resp('rd', 0x02, 1,   0,  0x1),          # read word  0x00000100
    ]
def write_miss_no_evict_direct_mapped_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef
    ]

def write_miss_evict_direct_mapped_msg(base_addr):
    return [
        #    type  opq   addr      len  data      type  opq   test len  data
        req('rd', 0x00, 0x00000100, 0, 0),   resp('rd', 0x00, 0,   0,   0xdeadbeef),  # read word  0x00000100
        req('wr', 0x01, 0x00000108, 0, 0x1), resp('wr', 0x01, 1,   0,   0),           # write word  0x00000104
        req('wr', 0x02, 0x00000400, 0, 0x3), resp('wr', 0x02, 0,   0,   0),           # write word  0x00000400
        req('rd', 0x03, 0x00000400, 0, 0),   resp('rd', 0x03, 1,   0,   0x3),         # read word  0x00000400
        req('rd', 0x04, 0x00000108, 0, 0),   resp('rd', 0x04, 0,   0,   0x1),         # read word  0x00000104
    ]
def write_miss_evict_direct_mapped_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef
    ]


#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Associative
#'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
def read_miss_no_evict_associative_msg(base_addr):
    return [
        #    type  opq   addr      len  data     type  opq test len  data
        req('rd', 0x00, 0x00000100, 0, 0),  resp('rd', 0x00, 0, 0, 0xdeadbeef),  # read word  0x00000100
        req('rd', 0x01, 0x00000200, 0, 0),  resp('rd', 0x01, 0, 0, 0x12345678),  # read word  0x00000200
        req('rd', 0x02, 0x00000204, 0, 0),  resp('rd', 0x02, 1, 0, 0xaaaaaaaa),  # read word  0x00000204
        req('rd', 0x03, 0x00000300, 0, 0),  resp('rd', 0x03, 0, 0, 0x87654321),  # read word  0x00000300
    ]

# Data to be loaded into memory before running the test
def read_miss_no_evict_associative_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef,
        0x00000200, 0x12345678,
        0x00000204, 0xaaaaaaaa,
        0x00000300, 0x87654321,
    ]

def read_miss_evict_associative_msg(base_addr):
    return [
        #    type  opq   addr      len  data      type  opq test len  data
        req('rd', 0x00, 0x00000100, 0, 0),   resp('rd', 0x00, 0, 0, 0xdeadbeef),  # read word  0x00000100
        req('rd', 0x01, 0x00000200, 0, 0),   resp('rd', 0x01, 0, 0, 0x12345678),  # read word  0x00000200
        req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),           # write word 0x00000104
        req('rd', 0x03, 0x0000020c, 0, 0),   resp('rd', 0x03, 1, 0, 0x87654321),  # read word  0x0000020c
    ]

def LRU_test(base_addr):
    return [
      # req('rd', 0x02, 0x00000104, 0, 0),   resp('rd', 0x02, 1, 0, 0x1),
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 0, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
    ]


def LRU_test_more_complex(base_addr):
    return [
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 0, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x04, 0x0000010c, 0, 0x2), resp('rd', 0x04, 1, 0, 0),  # write word  0x0000010c
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x02, 0x00000104, 0, 0x1), resp('rd', 0x02, 1, 0, 0),  # write word  0x00000104
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
      req('wr', 0x03, 0x00000108, 0, 0x3), resp('rd', 0x03, 1, 0, 0),  # write word  0x00000108
    ]

# Data to be loaded into memory before running the test
def read_miss_evict_associative_mem(base_addr):
    return [
        # addr      data (in int)
        0x00000100, 0xdeadbeef,
        0x00000200, 0x12345678,
        0x0000020c, 0x87654321,
        0x00000104, 0x1,
        0x00000108, 0x3,
        0x0000010c, 0x2,
    ]

#----------------------------------------------------------------------
# Banked cache test
#----------------------------------------------------------------------
# The test field in the response message: 0 == MISS, 1 == HIT

# This test case is to test if the bank offset is implemented correctly.
#
# The idea behind this test case is to differentiate between a cache
# with no bank bits and a design has one/two bank bits by looking at cache
# request hit/miss status.


#-------------------------------------------------------------------------
# Test table for generic test
#-------------------------------------------------------------------------
test_case_table_generic = mk_test_case_table([
  ( "msg_func                 mem_data_func                                        nbank   stall lat src sink"),
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      0,    0.0,  0,  0,  0    ],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       0,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_4bank" ,  read_hit_1word_clean,        None,                      4,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      0,    0.0,  0,  0,  0    ],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      0,    0.0,  0,  0,  0    ],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      0,    0.0,  0,  0,  0    ],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      0,    0.0,  0,  0,  0    ],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 0,    0.0,  0,  0,  0    ],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      0,    0.0,  0,  0,  0    ],
  [ "random_addr_and_data" ,  random_addr_and_data,        None,                      0,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_hit_1word_4bank" ,  read_hit_1word_clean,        None,                      4,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      0,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  # Bank 1
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      1,    0.0,  0,  0,  0    ],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       1,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      1,    0.0,  0,  0,  0    ],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      1,    0.0,  0,  0,  0    ],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      1,    0.0,  0,  0,  0    ],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      1,    0.0,  0,  0,  0    ],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 1,    0.0,  0,  0,  0    ],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      1,    0.0,  0,  0,  0    ],
  [ "random_addr_and_data" ,  random_addr_and_data,        None,                      1,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      1,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  # Bank 2
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      2,    0.0,  0,  0,  0    ],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       2,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      2,    0.0,  0,  0,  0    ],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      2,    0.0,  0,  0,  0    ],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      2,    0.0,  0,  0,  0    ],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      2,    0.0,  0,  0,  0    ],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 2,    0.0,  0,  0,  0    ],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      2,    0.0,  0,  0,  0    ],
  [ "random_addr_and_data" ,  random_addr_and_data,        None,                      2,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      2,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  # Bank 3
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      3,    0.0,  0,  0,  0    ],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       3,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      3,    0.0,  0,  0,  0    ],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      3,    0.0,  0,  0,  0    ],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      3,    0.0,  0,  0,  0    ],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      3,    0.0,  0,  0,  0    ],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 3,    0.0,  0,  0,  0    ],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      3,    0.0,  0,  0,  0    ],
  [ "random_addr_and_data" ,  random_addr_and_data,        None,                      3,    0.0,  0,  0,  0    ],
  [ "read_hit_1word_clean" ,  read_hit_1word_clean,        None,                      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word" ,       read_miss_1word_msg,         read_miss_1word_mem,       3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_hit_1word_dirty" ,  read_hit_1word_dirty ,       None,                      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word_dirty" , write_hit_1word_dirty,       None,                      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word" ,      write_miss_1word_msg,        write_miss_1word_mem,      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_hit_1word" ,       write_hit_1word_clean,       None,                      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "read_miss_1word_evict" , read_miss_1word_msg_evict,   read_miss_1word_evict_mem, 3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
  [ "write_miss_1word_evict" ,write_miss_1word_msg_evict,  None,                      3,    random.random(),  0,  random.randint(0,50),  random.randint(0,50)],
]) 

@pytest.mark.parametrize( **test_case_table_generic )
def test_generic( test_params, dump_vcd ):
  msgs = test_params.msg_func( 0 )
  if test_params.mem_data_func != None:
    mem = test_params.mem_data_func( 0 )
  # Instantiate testharness
  harness = TestHarness( msgs[::2], msgs[1::2],
                         test_params.stall, test_params.lat,
                         test_params.src, test_params.sink,
                         BlockingCacheFL, test_params.nbank,
                         False, dump_vcd )
  # Load memory before the test
  if test_params.mem_data_func != None:
    harness.load( mem[::2], mem[1::2] )
  # Run the test
  run_sim( harness, dump_vcd )

#-------------------------------------------------------------------------
# Test table for set-associative cache (alternative design)
#-------------------------------------------------------------------------
test_case_table_set_assoc = mk_test_case_table([
  ("msg_func                            mem_data_func                                                            nbank stall lat src sink"),
  [ "read_hit_associative",              read_hit_associative,                None,                                0,    0.0,  0,  0,  0],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  0,    0.0,  0,  0,  0],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     0,    0.0,  0,  0,  0],
  [ "read_capacity_miss",                read_capacity_miss,                  read_capacity_miss_mem,              0,    0.0,  0,  0,  0],
  [ "LRU_test",                          LRU_test,                            None,                                0,    0.0,  0,  0,  0],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                0,    0.0,  0,  0,  0],
  [ "read_hit_associative",              read_hit_associative,                None,                                0,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  0,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     0,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test",                          LRU_test,                            None,                                0,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                0,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  # Bank 1
  [ "read_hit_associative",              read_hit_associative,                None,                                1,    0.0,  0,  0,  0],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  1,    0.0,  0,  0,  0],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     1,    0.0,  0,  0,  0],
  [ "read_capacity_miss",                read_capacity_miss,                  read_capacity_miss_mem,              1,    0.0,  0,  0,  0],
  [ "LRU_test",                          LRU_test,                            None,                                1,    0.0,  0,  0,  0],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                1,    0.0,  0,  0,  0],
  [ "read_hit_associative",              read_hit_associative,                None,                                1,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  1,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     1,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test",                          LRU_test,                            None,                                1,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                1,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  # Bank 2
  [ "read_hit_associative",              read_hit_associative,                None,                                2,    0.0,  0,  0,  0],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  2,    0.0,  0,  0,  0],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     2,    0.0,  0,  0,  0],
  [ "read_capacity_miss",                read_capacity_miss,                  read_capacity_miss_mem,              2,    0.0,  0,  0,  0],
  [ "LRU_test",                          LRU_test,                            None,                                2,    0.0,  0,  0,  0],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                2,    0.0,  0,  0,  0],
  [ "read_hit_associative",              read_hit_associative,                None,                                2,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  2,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     2,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test",                          LRU_test,                            None,                                2,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                2,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  # Bank 3
  [ "read_hit_associative",              read_hit_associative,                None,                                3,    0.0,  0,  0,  0],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  3,    0.0,  0,  0,  0],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     3,    0.0,  0,  0,  0],
  [ "read_capacity_miss",                read_capacity_miss,                  read_capacity_miss_mem,              3,    0.0,  0,  0,  0],
  [ "LRU_test",                          LRU_test,                            None,                                3,    0.0,  0,  0,  0],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                3,    0.0,  0,  0,  0],
  [ "read_hit_associative",              read_hit_associative,                None,                                3,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_no_evict_associative",    read_miss_no_evict_associative_msg,  read_miss_no_evict_associative_mem,  3,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "read_miss_evict_associative",       read_miss_evict_associative_msg,     read_miss_evict_associative_mem,     3,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test",                          LRU_test,                            None,                                3,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
  [ "LRU_test_more_complex",             LRU_test_more_complex,               None,                                3,   random.random(),  0, random.randint(0,50), random.randint(0,50)],
])

@pytest.mark.parametrize( **test_case_table_set_assoc )
def test_set_assoc( test_params, dump_vcd ):
  msgs = test_params.msg_func( 0 )
  if test_params.mem_data_func != None:
    mem  = test_params.mem_data_func( 0 )
  # Instantiate testharness
  harness = TestHarness( msgs[::2], msgs[1::2],
                         test_params.stall, test_params.lat,
                         test_params.src, test_params.sink,
                         BlockingCacheFL, test_params.nbank,
                         False, dump_vcd )
  # Load memory before the test
  if test_params.mem_data_func != None:
    harness.load( mem[::2], mem[1::2] )
  # Run the test
  run_sim( harness, dump_vcd )


#-------------------------------------------------------------------------
# Test table for direct-mapped cache (baseline design)
#-------------------------------------------------------------------------
test_case_table_dir_mapped = mk_test_case_table([
  ("msg_func                              mem_data_func                                                                   nbank stall lat src sink"),
 [ "read_hit_direct_mapped",              read_hit_direct_mapped,                  None,                                   0,    0.0,  0,  0,  0],
 [ "read_miss_no_evict_direct_mapped",    read_miss_no_evict_direct_mapped_msg,    read_miss_no_evict_direct_mapped_mem,   0,    0.0,  0,  0,  0],
 [ "read_miss_evict_direct_mapped",       read_miss_evict_direct_mapped_msg,       read_miss_evict_direct_mapped_mem,      0,    0.0,  0,  0,  0],
 [ "write_miss_no_evict_direct_mapped",   write_miss_no_evict_direct_mapped_msg,   write_miss_no_evict_direct_mapped_mem,  0,    0.0,  0,  0,  0],
 [ "write_miss_evict_direct_mapped",      write_miss_evict_direct_mapped_msg,      write_miss_evict_direct_mapped_mem,     0,    0.0,  0,  0,  0],
 [ "read_conflict_miss",                  read_conflict_miss,                      read_conflict_miss_mem,                 0,    0.0,  0,  0,  0],
 [ "read_capacity_miss",                  read_capacity_miss,                      read_capacity_miss_mem,                 0,    0.0,  0,  0,  0],
 [ "LRU_test",                            LRU_test,                                None,                                   0,    0.0,  0,  0,  0],
 [ "LRU_test_more_complex",               LRU_test_more_complex,                   None,                                   0,    0.0,  0,  0,  0],
 [ "read_hit_direct_mapped",              read_hit_direct_mapped,                  None,                                   0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "read_miss_no_evict_direct_mapped",    read_miss_no_evict_direct_mapped_msg,    read_miss_no_evict_direct_mapped_mem,   0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "read_miss_evict_direct_mapped",       read_miss_evict_direct_mapped_msg,       read_miss_evict_direct_mapped_mem,      0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "write_miss_no_evict_direct_mapped",   write_miss_no_evict_direct_mapped_msg,   write_miss_no_evict_direct_mapped_mem,  0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "write_miss_evict_direct_mapped",      write_miss_evict_direct_mapped_msg,      write_miss_evict_direct_mapped_mem,     0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "read_conflict_miss",                  read_conflict_miss,                      read_conflict_miss_mem,                 0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "read_capacity_miss",                  read_capacity_miss,                      read_capacity_miss_mem,                 0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "LRU_test",                            LRU_test,                                None,                                   0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
 [ "LRU_test_more_complex",               LRU_test_more_complex,                   None,                                   0,  random.random(),  0,  random.randint(0,50), random.randint(0,50)],
])

@pytest.mark.parametrize( **test_case_table_dir_mapped )
def test_dir_mapped( test_params, dump_vcd ):
  msgs = test_params.msg_func( 0 )
  if test_params.mem_data_func != None:
    mem  = test_params.mem_data_func( 0 )
  # Instantiate testharness
  harness = TestHarness( msgs[::2], msgs[1::2],
                         test_params.stall, test_params.lat,
                         test_params.src, test_params.sink,
                         BlockingCacheFL, test_params.nbank,
                         False, dump_vcd )
  # Load memory before the test
  if test_params.mem_data_func != None:
    harness.load( mem[::2], mem[1::2] )
  # Run the test
  run_sim( harness, dump_vcd )