package rvcpu

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.io.Source
import scala.util.Random

class MemDCacheSpec extends AnyFreeSpec with ChiselScalatestTester with MemoryUtil {
  val path = os.pwd / os.RelPath("src/test/resources/bin/add.bin")
  val xlen = 32
  val memWidth = 16
  val randomAccsessCount = 4096
  val randomWriteCount = 4096

  for (delay <- 0 to 8) {
    for (cacheWidth <- 2 to 8) {
      s"DCache($cacheWidth) should read correct data sequentially from Memory($delay delay)" in {
        test(new MemDCacheTestModule(path.toString, memWidth, xlen, delay, cacheWidth)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
          m.io.do_writeback.poke(0.B)
          m.io.req.wmask.poke(0.B)

          var addr = 0
          for (line <- Source.fromFile(path.toString).getLines()) {
            val expectData = changeEndian(line)

            // Request
            m.io.req.ready.expect(true.B)
            m.io.req.valid.poke(true.B)
            m.io.req.addr.poke(addr.U)
            m.io.req.wen.poke(false.B)
            m.io.req.wdata.poke(0.U)
            // wait
            m.clock.step()
            while (m.io.resp.valid.peek().litValue == 0) {
              m.clock.step()
            }
            // Check
            m.io.resp.valid.expect(true.B)
            m.io.resp.error.expect(false.B)
            m.io.resp.rdata.expect(expectData.U)
            addr += 4
          }
        }
      }

      s"DCache($cacheWidth) should be able to random access data from Memory($delay delay)" in {
        test(new MemDCacheTestModule(path.toString, memWidth, xlen, delay, cacheWidth)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
          m.io.do_writeback.poke(0.B)
          m.io.req.wmask.poke(0.B)

          val lines = Source.fromFile(path.toString).getLines().toSeq
          val r = new Random
          for (_ <- 0 until randomAccsessCount) {
            val addr = r.nextInt(lines.size) * 4
            val expectData = changeEndian(lines(addr / 4))

            // Request
            m.io.req.ready.expect(true.B)
            m.io.req.valid.poke(true.B)
            m.io.req.addr.poke(addr.U)
            m.io.req.wen.poke(false.B)
            m.io.req.wdata.poke(0.U)
            // wait
            m.clock.step()
            while (m.io.resp.valid.peek().litValue == 0) {
              m.clock.step()
            }
            // Check
            m.io.resp.valid.expect(true.B)
            m.io.resp.error.expect(false.B)
            m.io.resp.rdata.expect(expectData.U)
          }
        }
      }
      
      s"DCache($cacheWidth) sequential write and read test to Memory($delay delay)" in {
        test(new MemDCacheTestModule(path.toString, memWidth, xlen, delay, cacheWidth)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
          m.io.do_writeback.poke(0.B)
          m.io.req.wmask.poke(0.B)

          val r = new Random
          val rdata = Range(0, randomWriteCount).map(_ => r.nextInt(1 << 30).U)

          // sequential write
          for (addr <- 0 until 4 * rdata.size by 4) {
            // Request
            m.io.req.ready.expect(true.B)
            m.io.req.valid.poke(true.B)
            m.io.req.addr.poke(addr.U)
            m.io.req.wen.poke(true.B)
            m.io.req.wdata.poke(rdata(addr / 4))
            // wait
            m.clock.step()
            while (m.io.resp.valid.peek().litValue == 0) {
              m.clock.step()
            }
            m.io.resp.error.expect(false.B)
          }

          // sequential read (check)
          for (addr <- 0 until 4 * rdata.size by 4) {
            val expectData = rdata(addr / 4)
            // Request
            m.io.req.ready.expect(true.B)
            m.io.req.valid.poke(true.B)
            m.io.req.addr.poke(addr.U)
            m.io.req.wen.poke(false.B)
            m.io.req.wdata.poke(0.U)
            // wait
            m.clock.step()
            while (m.io.resp.valid.peek().litValue == 0) {
              m.clock.step()
            }
            m.io.resp.valid.expect(true.B)
            m.io.resp.error.expect(false.B)
            m.io.resp.rdata.expect(expectData)
          }
        }
      }
    }

    s"DCache should raise error when read address is out of Memory($delay delay) range" in {
      test(new MemDCacheTestModule(path.toString, memWidth, xlen, delay, 4)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        m.io.do_writeback.poke(0.B)
        m.io.req.wmask.poke(0.B)

        var addr = 1 << memWidth
        // Request
        m.io.req.ready.expect(true.B)
        m.io.req.valid.poke(true.B)
        m.io.req.addr.poke(addr.U)
        m.io.req.wen.poke(false.B)
        m.io.req.wdata.poke(0.U)
        // wait
        m.clock.step()
        while (m.io.resp.valid.peek().litValue == 0) {
          m.clock.step()
        }
        // Check
        m.io.resp.valid.expect(true.B)
        m.io.resp.error.expect(true.B)
      }
    }
  }
}