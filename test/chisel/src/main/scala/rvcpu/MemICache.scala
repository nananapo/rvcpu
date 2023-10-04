package rvcpu

import chisel3._
import chisel3.util._
import svgen._

class MemICacheWrapperModule(val xlen : Int, val cacheWidth : Int) extends Module {
  class MemICacheIO(xlen : Int) extends Bundle {
      val ireq_in = new CacheReq(xlen)
      val iresp_in= new CacheResp(xlen)
      val busreq  = Flipped(new MemBusReq(xlen))
      val busresp = Flipped(new MemBusResp(xlen))
  }
  private class MemICacheBlackBox extends BlackBox(Map("CACHE_WIDTH" -> cacheWidth)) with HasBlackBoxResourceWithPortUsingStruct {
      class BBIO extends MemICacheIO(xlen) {
          val clk = Input(Clock())
      }
      val io = IO(new BBIO)
      addResource("/src/basic.svh")
      addResource("/src/memoryinterface.svh")
      setResource("MemICache", "/src/MemICache.sv")
  }

  val io = IO(new MemICacheIO(xlen))
  private val bb = Module(new MemICacheBlackBox)

  bb.io.clk <> clock
  io.unsafe :<>= bb.io.unsafe
}

class MemICacheTestModule(val memfileName : String, val mem_width : Int, val addr_width : Int, val delay : Int, val cacheWidth : Int) extends Module{
  val xlen = addr_width

  class MemICacheTestIO extends Bundle {
    val req = new CacheReq(xlen)
    val resp =  new CacheResp(xlen)
  }
  val io = IO(new MemICacheTestIO)

  val mem = Module(new MemoryWrapperModule(memfileName, mem_width, addr_width, delay))
  val cache = Module(new MemICacheWrapperModule(xlen, cacheWidth))

  mem.io.req_ready  <> cache.io.busreq.ready
  mem.io.req_valid  <> cache.io.busreq.valid
  mem.io.req_addr   <> cache.io.busreq.addr
  mem.io.req_wen    <> cache.io.busreq.wen
  mem.io.req_wdata  <> cache.io.busreq.wdata

  mem.io.resp_valid <> cache.io.busresp.valid
  mem.io.resp_error <> cache.io.busresp.error
  mem.io.resp_addr  <> cache.io.busresp.addr
  mem.io.resp_rdata <> cache.io.busresp.rdata

  cache.io.ireq_in  <> io.req
  cache.io.iresp_in <> io.resp

  mem.clock   := clock
  mem.reset   := reset
  cache.clock := clock
  cache.reset := reset
}