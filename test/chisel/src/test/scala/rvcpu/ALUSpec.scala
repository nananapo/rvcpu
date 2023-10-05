package rvcpu

import chisel3._
import chiseltest._
import org.scalatest.freespec.AnyFreeSpec
import scala.util.Random

// TODO Add unsigned Test
class ALUSpec extends AnyFreeSpec with ChiselScalatestTester {

  val randomTestCount = 1000
  val maxDelay = 64

  def calcDiv(m : DivWrapperModule, is_signed : Boolean, dividend : Int, divisor : Int, expQuotient : Int, expRemainder : Int) = {
    m.io.ready.expect(true.B)
    m.io.start.poke(true.B)
    m.io.is_signed.poke(true.B)
    m.io.dividend.poke(dividend.S)
    m.io.divisor.poke(divisor.S)

    var count = 0
    while (m.io.valid.peek().litValue == 0) {
      if (count + 1 == maxDelay)
        m.io.valid.expect(true.B)
      m.clock.step()
      count += 1
    }

    m.io.quotient.expect(expQuotient.S)
    m.io.remainder.expect(expRemainder.S)
    
    m.clock.step()
  }

  def calcMul(m : MultWrapperModule, is_signed : Boolean, multiplicand : BigInt, multiplier : BigInt, product : BigInt) = {
    m.io.ready.expect(true.B)
    m.io.start.poke(true.B)
    m.io.is_signed.poke(true.B)
    m.io.multiplicand.poke(multiplicand.S)
    m.io.multiplier.poke(multiplier.S)

    var count = 0
    while (m.io.valid.peek().litValue == 0) {
      if (count + 1 == maxDelay)
        m.io.valid.expect(true.B)
      m.clock.step()
      count += 1
    }

    m.io.product.expect(product.S)
    
    m.clock.step()
  }

  // TODO chiseltestのサンプルを参考に再利用する
  def randomDivTest(m : DivWrapperModule, aPositive : Boolean, bPositive : Boolean) : Unit = {
    val r = new Random
    for (line <- 0 until randomTestCount) {
      val a = r.nextInt(Integer.MAX_VALUE) * (if (aPositive) 1 else -1)
      var b = r.nextInt(Integer.MAX_VALUE) * (if (bPositive) 1 else -1)
      if (b == 0) b = 1;
      calcDiv(m, true, a, b, a / b, a % b)
      // println(a, b, a / b, a % b)
    }
  }

  def randomMulTest(m : MultWrapperModule, signed : Boolean, aPositive : Boolean, bPositive : Boolean) : Unit = {
    val r = new Random
    for (line <- 0 until randomTestCount) {
      val a = BigInt(r.nextInt(Integer.MAX_VALUE) * (if (aPositive) 1 else -1))
      var b = BigInt(r.nextInt(Integer.MAX_VALUE) * (if (bPositive) 1 else -1))
      calcMul(m, signed, a, b, a * b)
      // println(a, b, a * b)
    }
  }

  for ((a, b) <- Seq((true, true), (true, false), (false, true), (false, false))) {
    val as = if (a) "+" else "-"
    val bs = if (b) "+" else "-"
    s"Div(32, signed) should calculate ($as / $bs) correctly." in {
      test(new DivWrapperModule(32)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m => randomDivTest(m, a, b) }
    }
    s"Mul(32, signed) should calculate ($as * $bs) correctly." in {
      test(new MultWrapperModule(32)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m => randomMulTest(m, true, a, b) }
    }
  }

  s"Mul(32, unsigned) should calculate correctly." in {
    test(new MultWrapperModule(32)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m => randomMulTest(m, false, true, true) }
  }

  s"Div(32, signed) : the result of division by zero is correct" in {
    test(new DivWrapperModule(32)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m => 
      val r = Random
      for (_ <- 0 to randomTestCount) {
        val v = r.nextInt(Integer.MAX_VALUE)
        calcDiv(m, true, v, 0, -1, v) 
      } 
    }
  }

  s"Div(32, signed) : the result of overflow is correct" in {
    test(new DivWrapperModule(32)).withAnnotations(Seq(VerilatorBackendAnnotation)) { m => 
      calcDiv(m, true, -2147483648, -1, -2147483648, 0) 
    }
  }
}