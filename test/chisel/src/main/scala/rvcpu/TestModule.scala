package rvcpu

import chisel3._
import chisel3.util._
import svgen._
import svgen.BundleHelper._

class StructPortWrapperModule extends Module {
    class StructA extends Bundle {
        val value1 = UInt(8.W)
        val structInA = new Bundle { val value2 = UInt(16.W) }
    }
    class StructPortModuleIO extends Bundle {
        val structA = Output(new StructA)
    }
    
    private class StructPortBBModule extends BlackBox with HasBlackBoxResourceWithPortUsingStruct {
        class BBIO extends StructPortModuleIO {
            val clock   = Input(Clock())
            val reset   = Input(Reset())
        }
        val io = IO(new BBIO)
        setResource("StructPortModule", "/test.sv")
    }
    private val bb = Module(new StructPortBBModule)
    val io = IO(new StructPortModuleIO)

    bb.io.clock <> clock
    bb.io.reset <> reset
    io.unsafe :<>= bb.io.unsafe
    // (io:Record) :<>= bb.io.waiveWithout(io)
}