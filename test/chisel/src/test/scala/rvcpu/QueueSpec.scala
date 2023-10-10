package rvcpu

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.util.Random
import scala.math.pow

class QueueSpec extends AnyFreeSpec with ChiselScalatestTester {
  for (size <- Range(0, 16)) {
    s"SyncQueue(32, $size) should not accept data when queue is full" in {
      test(new SyncQueueWrapperModule(32, size)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        // initial check
        m.io.wready.expect(true.B)
        m.io.rvalid.expect(false.B)

        // enqueue
        m.io.rready.poke(false.B)
        m.io.wvalid.poke(true.B)
        m.io.wdata.poke(0x7fffffff.U)
        m.clock.step()

        // enqueue
        for (i <- 0 until pow(2, size).intValue - 2) {
          m.io.wready.expect(true.B)
          m.io.rvalid.expect(true.B)
          m.clock.step()
        }

        // check full
        m.io.wready.expect(false.B)
        m.io.rvalid.expect(true.B)
      }
    }
    s"SyncQueue(32, $size) should provide all data" in {
      test(new SyncQueueWrapperModule(32, size)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>

        val random = new Random
        val randomData = Range(1, pow(2, size).intValue - 1).map(_ => random.nextInt(1 << 30).U)

        // init
        m.io.rready.poke(false.B)

        // enqueue
        for (value <- randomData) {
          m.io.wvalid.poke(true.B)
          m.io.wdata.poke(value)
          m.clock.step()
        }
        m.io.wvalid.poke(false.B)

        // dequeue
        for (value <- randomData) {
          m.io.rready.poke(true.B)
          m.io.rvalid.expect(true.B)
          m.io.rdata.expect(value)
          m.clock.step()
        }
        m.io.rvalid.expect(false.B)
      }
    }
  }
  for (size <- Range(2, 16)) {
    s"SyncQueue(32, $size) should provide rdata when wvalid = 1" in {
      test(new SyncQueueWrapperModule(32, size)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
        val random = new Random
        val randomData = Range(0, pow(2, size + 1).intValue - 1).map(_ => random.nextInt(1 << 30).U)

        // init
        m.io.wvalid.poke(true.B)
        m.io.wdata.poke(randomData(0))
        m.clock.step()

        // enqueue
        for (i <- 1 until randomData.size) {
          m.io.wready.expect(true.B)
          m.io.rvalid.expect(true.B)
          m.io.rdata.expect(randomData(i-1))

          m.io.wdata.poke(randomData(i))
          m.io.rready.poke(true.B)
          m.clock.step()
        }
      }
    }

  }
}