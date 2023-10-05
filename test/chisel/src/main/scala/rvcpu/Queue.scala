package rvcpu

import chisel3._
import chisel3.util._

class SyncQueueWrapperModule(val dataSize : Int, val queueWidth : Int) extends Module{

    class SyncQueueIO extends Bundle {
        val kill = Input(Bool())
        val wready = Output(Bool())
        val wvalid = Input(Bool())
        val wdata = Input(UInt(dataSize.W))
        val rready = Input(Bool())
        val rvalid = Output(Bool())
        val rdata = Output(UInt(dataSize.W))
    }

    private class SyncQueue extends BlackBox(Map(
        "DATA_SIZE" -> dataSize,
        "WIDTH" -> queueWidth
    )) with HasBlackBoxResource {
        class BBIO extends SyncQueueIO {
            val clk = Input(Clock())
        }
        val io = IO(new BBIO)
        addResource("/src/SyncQueue.sv")
    }

    private val bb = Module(new SyncQueue)
    val io = IO(new SyncQueueIO)

    bb.io.clk <> clock
    io.unsafe :<>= bb.io.unsafe
}
