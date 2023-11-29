package rvcpu

import chisel3._
import chisel3.util._
import svgen._

// TODO wbをテストする
class MemL2DCacheWrapperModule(val xlen : Int, val cacheWidth : Int) extends Module {
  class MemL2DCacheIO(xlen : Int) extends Bundle {
      val dreq_in             = new CacheReq(xlen)
      val dresp_in            = new CacheResp(xlen)
      val busreq              = Flipped(new MemBusReq(xlen))
      val busresp             = Flipped(new MemBusResp(xlen))
      val do_writeback        = Input(Bool())
      val is_writebacked_all  = Output(Bool())
  }
  private class MemL2DCacheBlackBox extends BlackBox(Map("CACHE_WIDTH" -> cacheWidth)) with HasBlackBoxResourceWithPortUsingStruct {
      class BBIO extends MemL2DCacheIO(xlen) {
          val clk = Input(Clock())
      }
      val io = IO(new BBIO)
      addDependency("/src/pkg_all.svh")
      setResource("MemL2DCache", "/src/MemL2DCache.sv")
  }

  val io = IO(new MemL2DCacheIO(xlen))
  private val bb = Module(new MemL2DCacheBlackBox)

  bb.io.clk <> clock
  io.unsafe :<>= bb.io.unsafe
}

class MemL2DCacheTestModule(val memfileName : String, val mem_width : Int, val addr_width : Int, val delay : Int, val cacheWidth : Int) extends Module{
  val xlen = addr_width

  class MemL2DCacheTestIO extends Bundle {
    val req                 = new CacheReq(xlen)
    val resp                = new CacheResp(xlen)
    val do_writeback        = Input(Bool())
    val is_writebacked_all  = Output(Bool())
  }
  val io = IO(new MemL2DCacheTestIO)

  val mem = Module(new MemoryWrapperModule(memfileName, mem_width, addr_width, delay))
  val cache = Module(new MemL2DCacheWrapperModule(xlen, cacheWidth))

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