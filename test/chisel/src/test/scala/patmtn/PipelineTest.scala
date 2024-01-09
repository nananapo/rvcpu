package patmtn

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.util.Random
import scala.collection.View
import scala.math

class PipelineTest extends AnyFreeSpec with ChiselScalatestTester {

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
  
    def goldenModel(value : BigInt) : BigInt = value + 1
  }

  implicit class ExtendPT2M(val self: PipelineTest2Module) {
    def initialCheck() : Unit = {
      self.io.req_ready.expect(true.B)
      self.io.resp_valid.expect(false.B)
    }
    def expectRespInvalid() : Unit = {
      self.io.resp_valid.expect(false.B)
    }
    def expectRespValid(value : BigInt) : Unit = {
      self.io.resp_valid.expect(true.B)
      self.io.resp_value.expect(value.U)
    }
    // validならチェック。一致したらtrue, validではないならfalse
    def maybeRespValid(value: BigInt) : Boolean = {
      if (respIsValid) {
        self.io.resp_value.expect(value.U)
        return true
      }
      return false
    }
    def respIsValid : Boolean = self.io.resp_valid.peek().litValue == 1
    def isReady : Boolean = self.io.req_ready.peek().litValue == 1

    def setRequest(value : BigInt) : Unit = {
      self.io.req_valid.poke(true.B)
      self.io.req_value.poke(value.U)
    }

    def resetRequest() : Unit = {
      self.io.req_valid.poke(false.B)
      val random = new Random()
      self.io.req_value.poke(random.nextInt(10000000))
    }

    def goldenModel(value : BigInt) : BigInt = value + 5
  }

  def nonZeroDigit: Char = Random.between(49, 58).toChar
  def digit: Char = Random.between(48, 58).toChar
  def randomNumber(length: Int): BigInt = {
    require(length > 0, "length must be strictly positive")
    val digits = View(nonZeroDigit) ++ View.fill(length - 1)(digit)
    BigInt(digits.mkString)
  }

  "pipelinetest1 should peocess one data" in {
    test(new PipelineTest1Module).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
      m.saveGraph("output/mygraph.dot")
      val value = 111
      m.io.req_valid.poke(true.B)
      m.io.req_value.poke(value.U)
      m.initialCheck()
      m.clock.step()

      while (!m.respIsValid) m.clock.step()
      m.expectRespValid(m.goldenModel(value))
    }
  }

  "pipelinetest1 random test" in {
    test(new PipelineTest1Module).withAnnotations(Seq(VerilatorBackendAnnotation)) { m =>
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

      for (v <- testSet) {
        m.io.req_ready.expect(true.B)
        if (v.isEmpty) {
          m.io.req_valid.poke(false.B)
        } else {
          m.io.req_valid.poke(true.B)
          m.io.req_value.poke(v.get.U)
        }
        if (m.respIsValid) {
          if (onlyValues.length == 0) m.io.resp_valid.expect(false.B)
          m.expectRespValid(m.goldenModel(onlyValues(0)))
          onlyValues = onlyValues.slice(1, onlyValues.length)
        }
        m.clock.step()
      }

      m.io.req_valid.poke(false.B)

      while (onlyValues.length > 0) {
        if (m.respIsValid) {
          m.expectRespValid(m.goldenModel(onlyValues(0)))
          onlyValues = onlyValues.slice(1, onlyValues.length)
        }
        m.clock.step()
      }
    }
  }

  "pipelinetest2 should process one data" in {
    test(new PipelineTest2Module()).withAnnotations(Seq(VerilatorBackendAnnotation)) {m => 
      m.io.req_valid.poke(false.B)
      m.io.req_value.poke(0.U)
      m.io.resp_valid.expect(false.B)
      m.clock.setTimeout(20)
      m.clock.step()

      val value = 37
      
      m.io.req_ready.expect(true.B)
      m.io.resp_valid.expect(false.B)
      m.io.req_valid.poke(true.B)
      m.io.req_value.poke(value.U)
      m.clock.step()
      m.io.req_valid.poke(false.B)

      while (!m.respIsValid)
        m.clock.step()

      m.io.resp_valid.expect(true.B)
      m.io.resp_value.expect(m.goldenModel(value))
    }
  }

  "pipelinetest2 should process 2 value " in {
    test(new PipelineTest2Module()).withAnnotations(Seq(VerilatorBackendAnnotation)) {m => 
      m.saveGraph("output/mygraph.dot")
      m.io.req_valid.poke(false.B)
      m.io.req_value.poke(0.U)
      m.clock.setTimeout(100000)
      m.initialCheck()
      m.clock.step()

      val testSet = Seq(100, 37)

      m.io.req_ready.expect(true.B)
      m.setRequest(testSet(0))
      m.clock.step()

      m.io.req_ready.expect(true.B)
      m.setRequest(testSet(1))
      m.clock.step()
      m.resetRequest()

      while (!m.respIsValid) m.clock.step()
      m.expectRespValid(m.goldenModel(testSet(0)))

      m.clock.step()

      while (!m.respIsValid) m.clock.step()
      m.expectRespValid(m.goldenModel(testSet(1)))
    }
  }


  "pipelinetest2 should process 3 value " in {
    test(new PipelineTest2Module()).withAnnotations(Seq(VerilatorBackendAnnotation)) {m => 
      m.saveGraph("output/2.dot")
      m.io.req_valid.poke(false.B)
      m.io.req_value.poke(0.U)
      m.clock.setTimeout(40)
      m.initialCheck()
      m.clock.step()

      val testSet = Seq(100, 37, 329)

      for (v <- testSet) {
        m.io.req_ready.expect(true.B)
        m.setRequest(v)
        m.clock.step()
      }

      m.io.req_valid.poke(false.B)
      m.io.req_ready.expect(false.B)

      for (v <- testSet) {
        while (!m.respIsValid) m.clock.step()
        m.expectRespValid(m.goldenModel(v))
        m.clock.step()  
      }
    }
  }

  "pipelinetest2 should process random test " in {
    test(new PipelineTest2Module()).withAnnotations(Seq(VerilatorBackendAnnotation)) {m => 
      m.saveGraph("output/2.dot")
      m.io.req_valid.poke(false.B)
      m.io.req_value.poke(0.U)
      m.clock.setTimeout(100000)
      m.initialCheck()
      m.clock.step()

      val testSize = 16666
      val source = new Random()
      val testSet = Seq.range(0, testSize).map(v => randomNumber(7))

      var ri = 0
      for (v <- testSet) {
        while (!m.isReady) {
          m.io.req_valid.poke(false.B)
          if (m.maybeRespValid(m.goldenModel(testSet(ri)))) ri+=1
          m.clock.step()
        }
        m.setRequest(v)
        if (m.maybeRespValid(m.goldenModel(testSet(ri)))) ri+=1
        m.clock.step()
      }
      m.io.req_valid.poke(false.B)
      while (ri < testSize) {
        if (m.maybeRespValid(m.goldenModel(testSet(ri)))) ri+=1
        m.clock.step()
      }
    }
  }
}