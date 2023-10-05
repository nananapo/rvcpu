package rvcpu

import chisel3._
import chisel3.util._
import svgen._
import svgen.BundleHelper._

class MemoryWrapperModule(val memfileName : String, val mem_width : Int, val addr_width : Int, val delay : Int) extends Module {
    class MemoryIO extends Bundle{
        val req_ready   = Output(Bool())
        val req_valid   = Input(Bool())
        val req_addr    = Input(UInt(addr_width.W))
        val req_wen     = Input(Bool())
        val req_wdata   = Input(UInt(32.W))
        val resp_valid  = Output(Bool())
        val resp_error  = Output(Bool())
        val resp_addr   = Output(UInt(addr_width.W))
        val resp_rdata  = Output(UInt(32.W))
    }

    private class Memory extends BlackBox(Map(
        "FILEPATH" -> memfileName,
        "MEM_WIDTH" -> mem_width,
        "ADDR_WIDTH" -> addr_width,
        "DELAY_CYCLE" -> delay
    )) with HasBlackBoxResource {
        class BBIO extends MemoryIO {
            val clk = Input(Clock())
        }
        val io = IO(new BBIO)
        addResource("/src/Memory.sv")
    }

    private val bb = Module(new Memory)
    val io = IO(new MemoryIO)

    bb.io.clk <> clock
    io.unsafe :<>= bb.io.unsafe
}