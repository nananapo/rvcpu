package rvcpu

import chisel3._
import chisel3.util._

class DivWrapperModule (val width : Int) extends Module {
    class DivIO extends Bundle {
        val start       = Input(Bool())
        val ready       = Output(Bool())
        val valid       = Output(Bool())
        val is_signed   = Input(Bool())
        val dividend    = Input(SInt(width.W))
        val divisor     = Input(SInt(width.W))
        val quotient    = Output(SInt(width.W))
        val remainder   = Output(SInt(width.W))
    }

    class ALU_DivNbit extends BlackBox(Map(
        "SIZE" -> width
    )) with HasBlackBoxResource {
        class BBIO extends DivIO {
            val clk = Input(Clock())
        }
        val io = IO(new BBIO)
        addResource("/src/ALU_DivNbit.sv")
        addResource("/src/ALU_DivUnsignedNbit.sv")
    }

    private val bb = Module(new ALU_DivNbit)
    val io = IO(new DivIO)

    bb.io.clk <> clock
    io.unsafe :<>= bb.io.unsafe
}

class MultWrapperModule (val width : Int) extends Module {
    class MultIO extends Bundle {
        val start       = Input(Bool())
        val ready       = Output(Bool())
        val valid       = Output(Bool())
        val is_signed   = Input(Bool())
        val multiplicand= Input(SInt(width.W))
        val multiplier  = Input(SInt(width.W))
        val product     = Output(SInt((width * 2).W))
    }

    private class ALU_MultNbit extends BlackBox(Map(
        "SIZE" -> width
    )) with HasBlackBoxResource {
        class BBIO extends MultIO {
            val clk = Input(Clock())
        }
        val io = IO(new BBIO)
        addResource("/src/ALU_MultNbit.sv")
        addResource("/src/ALU_MultUnsignedNbit.sv")
    }

    private val bb = Module(new ALU_MultNbit)
    val io = IO(new MultIO)

    bb.io.clk <> clock
    io.unsafe :<>= bb.io.unsafe
}