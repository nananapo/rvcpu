package patmtn

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.util.Random
import scala.collection.View
import scala.math

class PipelineTest1 extends AnyFreeSpec with ChiselScalatestTester {

  implicit class ExtendPT1M(val self: PipelineTest1Module) {
    def initialCheck() : Unit = {
      self.io.req_ready.expect(true.B)
      self.io.resp_valid.expect(false.B)
    }
    def expectRespInvalid() : Unit = {
      self.io.resp_valid.expect(false.B)
    }
    def expectRespValid(value : BigInt) = {
      self.io.resp_valid.expect(true.B)
      self.io.resp_value.expect(value.U)
    }
    def respIsValid : Boolean = self.io.resp_valid.peek().litValue == 1
  }

  def nonZeroDigit: Char = Random.between(49, 58).toChar
  def digit: Char = Random.between(48, 58).toChar
  def randomNumber(length: Int): BigInt = {
    require(length > 0, "length must be strictly positive")
    val digits = View(nonZeroDigit) ++ View.fill(length - 1)(digit)
    BigInt(digits.mkString)
  }

  "pipelinetest1 random test" in {
    test(new PipelineTest1Module).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
      // m.saveGraph("output/mygraph.dot")
      m.io.req_valid.poke(false.B)
      m.io.req_value.poke(0.U)
      m.clock.setTimeout(100000)
      m.initialCheck()

      m.clock.step()
      val source = new Random()
      val testSet = Seq.range(0, 80000)
                        .map(_ => source.nextInt(100) < 20)
                        .map(v => if (v) None else Some(randomNumber(7)))
      var onlyValues = testSet.filterNot(_.isEmpty).map(_.get)

      // println(testSet)
      // println(onlyValues)

      for (v <- testSet) {
        // println(v)
        m.io.req_ready.expect(true.B)
        if (v.isEmpty) {
          m.io.req_valid.poke(false.B)
        } else {
          m.io.req_valid.poke(true.B)
          m.io.req_value.poke(v.get)
        }
        if (m.respIsValid) {
          // println("resp is valid")
          if (onlyValues.length == 0) m.io.resp_valid.expect(false.B)
          m.expectRespValid(onlyValues(0) + 1)
          onlyValues = onlyValues.slice(1, onlyValues.length)
        }
        m.clock.step()
      }

      m.io.req_valid.poke(false.B)

      while (onlyValues.length > 0) {
        if (m.respIsValid) {
          m.expectRespValid(onlyValues(0) + 1)
          onlyValues = onlyValues.slice(1, onlyValues.length)
        }
        m.clock.step()
      }
    }
  }
}