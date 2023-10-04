package rvcpu

import chisel3._
import chiseltest._
import chisel3.experimental._
import org.scalatest.freespec.AnyFreeSpec
import chisel3.experimental.BundleLiterals._

class StructPortModuleTest extends AnyFreeSpec with ChiselScalatestTester {
  "value1 should 42" in {
    test(new StructPortWrapperModule).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
      // m.clock.step()
      m.io.structA.value1.expect(42.U)
    }
  }
  "value2 should 65535" in {
    test(new StructPortWrapperModule).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
      // m.clock.step()
      m.io.structA.structInA.value2.expect(65535.U)
    }
  }
}
