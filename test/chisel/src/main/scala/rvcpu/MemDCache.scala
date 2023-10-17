package rvcpu

import chisel3._
import chisel3.util._
import svgen._

// TODO wbをテストする
class MemDCacheWrapperModule(val xlen : Int, val cacheWidth : Int) extends Module {
  class MemDCacheIO(xlen : Int) extends Bundle {
      val dreq_in             = new CacheReq(xlen)
      val dresp_in            = new CacheResp(xlen)
      val busreq              = Flipped(new MemBusReq(xlen))
      val busresp             = Flipped(new MemBusResp(xlen))
      val do_writeback        = Input(Bool())
      val is_writebacked_all  = Output(Bool())
  }
  private class MemDCacheBlackBox extends BlackBox(Map("CACHE_WIDTH" -> cacheWidth)) with HasBlackBoxResourceWithPortUsingStruct {
      class BBIO extends MemDCacheIO(xlen) {
          val clk = Input(Clock())
      }
      val io = IO(new BBIO)
      addResource("/src/basic.svh")
      addResource("/src/memoryinterface.svh")
      setResource("MemDCache", "/src/MemDCache.sv")
  }

  val io = IO(new MemDCacheIO(xlen))
  private val bb = Module(new MemDCacheBlackBox)

  bb.io.clk <> clock
  io.unsafe :<>= bb.io.unsafe
}

class MemDCacheTestModule(val memfileName : String, val mem_width : Int, val addr_width : Int, val delay : Int, val cacheWidth : Int) extends Module{
  val xlen = addr_width

  class MemDCacheTestIO extends Bundle {
    val req                 = new CacheReq(xlen)
    val resp                = new CacheResp(xlen)
    val do_writeback        = Input(Bool())
    val is_writebacked_all  = Output(Bool())
  }
  val io = IO(new MemDCacheTestIO)

  val mem = Module(new MemoryWrapperModule(memfileName, mem_width, addr_width, delay))
  val cache = Module(new MemDCacheWrapperModule(xlen, cacheWidth))

  mem.io.req_ready  <> cache.io.busreq.ready
  mem.io.req_valid  <> cache.io.busreq.valid
  mem.io.req_addr   <> cache.io.busreq.addr
  mem.io.req_wen    <> cache.io.busreq.wen
  mem.io.req_wdata  <> cache.io.busreq.wdata

  mem.io.resp_valid <> cache.io.busresp.valid
  mem.io.resp_error <> cache.io.busresp.error
  mem.io.resp_addr  <> cache.io.busresp.addr
  mem.io.resp_rdata <> cache.io.busresp.rdata

  cache.io.dreq_in            <> io.req
  cache.io.dresp_in           <> io.resp
  cache.io.do_writeback       <> io.do_writeback
  cache.io.is_writebacked_all <> io.is_writebacked_all

  mem.clock   := clock
  mem.reset   := reset
  cache.clock := clock
  cache.reset := reset
}