package rvcpu

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.io.Source
import scala.util.Random

class MemorySpec extends AnyFreeSpec with ChiselScalatestTester with MemoryUtil {
  val path = os.pwd / os.RelPath("src/test/resources/bin/add.bin")
  val xlen = 64

  for (delay <- 0 to 1) {
    s"Memory should set reasonable initial output value with $delay delay" in {
      test(new MemoryWrapperModule(path.toString, 16, xlen, delay)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        m.io.req_ready.expect(true.B)
        m.io.resp_valid.expect(false.B)
        m.io.resp_error.expect(false.B)
      }
    }
  }

  for (delay <- 0 to 4) {
    s"Memory(16) should read data with $delay delay" in {
      test(new MemoryWrapperModule(path.toString, 16, xlen, delay)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        var addr = 0
        for (line <- Source.fromFile(path.toString).getLines()) {
          val expectData = changeEndian(line)
          // Request
          m.io.req_ready.expect(true.B)
          m.io.req_valid.poke(true.B)
          m.io.req_addr.poke(addr.U)
          m.io.req_wen.poke(false.B)
          // wait
          for (d <- 0 to delay) {
            m.clock.step()
            m.io.req_ready.expect((d == delay).B)
            m.io.resp_valid.expect((d == delay).B)
            m.io.resp_error.expect(false.B)
          }
          // Check
          m.io.resp_rdata.expect(expectData.U)
          m.io.resp_addr.expect(addr.U)
          addr += 4
        }
      }
    }
    s"Memory(16) should write and read random data with $delay delay" in {
      test(new MemoryWrapperModule(path.toString, 16, xlen, delay)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        var r = new Random
        for (_ <- 0 until 1000) {
          var addr = r.nextInt(1 << 15)
          var wdata = r.nextInt(1 << 30) 
          // write request
          m.io.req_ready.expect(true.B)
          m.io.req_valid.poke(true.B)
          m.io.req_addr.poke(addr.U)
          m.io.req_wen.poke(true.B)
          m.io.req_wdata.poke(wdata.U)
          // wait
          for (d <- 0 to delay) {
            m.clock.step()
            m.io.req_ready.expect((d == delay).B)
            m.io.resp_valid.expect((d == delay).B)
            m.io.resp_error.expect(false.B)
          }
          m.io.resp_addr.expect(addr.U)
          // read request
          m.io.req_ready.expect(true.B)
          m.io.req_valid.poke(true.B)
          m.io.req_addr.poke(addr.U)
          m.io.req_wen.poke(false.B)
          m.io.req_wdata.poke(wdata.U)
          // wait
          for (d <- 0 to delay) {
            m.clock.step()
            m.io.req_ready.expect((d == delay).B)
            m.io.resp_valid.expect((d == delay).B)
            m.io.resp_error.expect(false.B)
          }
          // check
          m.io.resp_addr.expect(addr.U)
          m.io.resp_rdata.expect(wdata.U)
          addr += 4
        } 
      }
    }
    s"Memory(16) should raise error when requested address is out of range with $delay delay" in {
      test(new MemoryWrapperModule(path.toString, 16, xlen, delay)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        val addr = BigInt("f0000000", 16);
        val wdata = 0;
        // write request
        m.io.req_ready.expect(true.B)
        m.io.req_valid.poke(true.B)
        m.io.req_addr.poke(addr.U)
        m.io.req_wen.poke(true.B)
        m.io.req_wdata.poke(wdata.U)
        // wait
        m.clock.step()
        m.io.resp_valid.expect(true.B)
        m.io.resp_error.expect(true.B)
        m.io.req_ready.expect(true.B)
        m.io.resp_addr.expect(addr.U)
        // read request
        m.io.req_valid.poke(true.B)
        m.io.req_addr.poke(addr.U)
        m.io.req_wen.poke(false.B)
        m.io.req_wdata.poke(wdata.U)
        // wait
        m.clock.step()
        m.io.resp_valid.expect(true.B)
        m.io.resp_error.expect(true.B)
        m.io.req_ready.expect(true.B)
        m.io.resp_addr.expect(addr.U)
      }
    }
  }
}