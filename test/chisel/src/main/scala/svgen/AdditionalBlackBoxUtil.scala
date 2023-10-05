package svgen

import chisel3._
import chisel3.experimental.{ChiselAnnotation, IntParam, StringParam}
import firrtl.transforms.{BlackBoxInlineAnno, BlackBoxPathAnno, BlackBoxNotFoundException}
import firrtl.annotations.{ModuleName, CircuitName}
import logger.LazyLogging

// https://github.com/chipsalliance/chisel/blob/5.x/src/main/scala/chisel3/util/BlackBoxUtils.scala
private[svgen] object BlackBoxHelpers {
  implicit class BlackBoxInlineAnnoHelpers(anno: BlackBoxInlineAnno.type) extends LazyLogging {
    /** Generate a BlackBoxInlineAnno from a Java Resource and a module name. */
    def fromResource(resourceName: String, moduleName: ModuleName, nameAs : String) = try {
      val blackBoxFile = os.resource / os.RelPath(resourceName.dropWhile(_ == '/'))
      val contents = os.read(blackBoxFile)
      if (contents.size > BigInt(2).pow(20)) {
        val message =
          s"Black box resource $resourceName, which will be converted to an inline annotation, is greater than 1 MiB." +
            "This may affect compiler performance. Consider including this resource via a black box path."
        logger.warn(message)
      }

      if (nameAs == null)
        BlackBoxInlineAnno(moduleName, blackBoxFile.last, contents)
      else {
        val me = os.pwd + "/src/test/resources/" + resourceName
        BlackBoxPathAnno(moduleName, me)
      }
    } catch {
      case e: os.ResourceNotFoundException =>
        throw new BlackBoxNotFoundException(resourceName, e.getMessage)
    }
  }
}

import BlackBoxHelpers._

trait HasBlackBoxResourceWithPortUsingStruct extends BlackBox {
  self: BlackBox =>

  abstract class PortClass(val name : String)
  case class LogicPort(override val name : String, val width : Int) extends PortClass(name)
  case class StructPort(override val name : String, val members : Seq[PortClass]) extends PortClass(name)

  // 保存する型
  // https://github.com/chipsalliance/chisel/blob/5.x/core/src/main/scala/chisel3/internal/firrtl/Converter.scala
  // Clock,AsyncReset,ResetType,EnumType,UInt,SInt,Analog,Vec[_],Record
  // とりあえず Clock, Reset, UInt, Bundleだけ対応する
  // Bundleは再帰
  // return : Seq PortClass
  def getPorts(obj : Record) : Seq[PortClass] = {
    var results : Seq[PortClass] = Seq()

    def rec[T <: Object](cls : Class[T]) : Unit = {
      if (cls.getSuperclass() != classOf[Object])
        rec(cls.getSuperclass())
      for (field <- cls.getDeclaredFields()) {
        val name = field.getName()
        if (!name.contains("$")) {
          field.setAccessible(true)
          val value = field.get(obj)
          results = results :+ (value match {
            case c : Clock => new LogicPort(name, 1)
            case r : Reset => new LogicPort(name, 1)
            case u : UInt  => new LogicPort(name, u.getWidth)
            case s : SInt  => new LogicPort(name, s.getWidth)
            case b : Record=> new StructPort(name, getPorts(b))
            case other => null
          })
        }
      }
    }

    rec(obj.getClass())
    return results.filter(_ != null)
  }

  def getPortDefinitionInSystemVerilog(prefixName : Option[String], ports : Seq[PortClass]) : Seq[String] = {
    var results : Seq[String] = Seq()
    for (p <- ports) {
      val portName = prefixName.getOrElse("") + p.name
      p match {
        case LogicPort(_, 1) => 
          results = results :+ "inout wire logic " + portName
        case LogicPort(_, width) => 
          results = results :+ s"inout wire logic [${width-1}:0] $portName"
        case StructPort(_, members) => 
          results = results ++ getPortDefinitionInSystemVerilog(Option(portName + "_"), members)
      }
    }
    return results
  }

  // TODO membersでいい
  def getInstancePortInSystemVerilog(ports : Seq[PortClass]) : Seq[String] = {

    def getStructCode(prefixName : String, members : Seq[PortClass]) : String = {
      var results : Seq[String] = Seq()
      for (mem <- members) {
        val portName = prefixName + mem.name
        results = results :+ (mem match {
          case LogicPort(_, _)      => portName
          case StructPort(_, rmems) => "{\n" + getStructCode(portName + "_", rmems) + "\n}"
          case other => null
        })
      }
      return results.filter(_ != null).mkString(",")
    }

    var results : Seq[String] = Seq()
    for (p <- ports) {
      results = results :+ (p match {
          case LogicPort(name, _)     => "." + name + "(" + name + ")"
          case StructPort(name, mems) => {
            if (mems.size > 0) "." + p.name + "({\n" + getStructCode(name + "_", mems) + "\n})" else null
          }
          case other => null
      })
    }

    return results.filter(_ != null)
  }

  def getParameterDefinitionInSystemVerilog() : Iterable[String] = {
    params.map{ case (k, _) => s"parameter $k" }
  }

  def getInstanceParameterInSystemVerilog() : Iterable[String] = {
    params.map{ case (k, v) => 
      s".$k(" + (v match {
        case IntParam(value) => value
        case StringParam(value) => s"\"$value\""
        case other => "UNKNWON"
      }) + ")"
    }
  }

  // ファイルを読み込むアノテーションを追加する
  // nameAsで展開されるファイル名を指定できる
  def addResource(blackBoxResource: String, nameAs : String = null) : Unit = {
    val anno = new ChiselAnnotation {
      def toFirrtl = BlackBoxInlineAnno.fromResource(blackBoxResource, self.toNamed, nameAs)
    }
    chisel3.experimental.annotate(anno)
  }

  def setResource(moduleName: String, blackBoxResource: String, nameAs : String = null): Unit = {
    addResource(blackBoxResource, nameAs)

    // ioの存在チェック
    val fields = this.getClass().getDeclaredFields().filter(f => f.getName() == "io")
    if (fields.size != 1) {
      throw new chisel3.ChiselException("BlackBox must have a port named 'io'")
    }
    // ioがRecordである
    fields(0).setAccessible(true)
    if (!fields(0).get(self).isInstanceOf[Record]) {
      throw new chisel3.ChiselException("'io' must be Record type")
    }
    // ioを取得
    val io : Record = fields(0).get(self).asInstanceOf[Record]

    // ioの構造を取得
    val ports = getPorts(io)
    // モジュールの文字列を生成して、アノテーションを追加する
    val anno = new ChiselAnnotation {
      def toFirrtl() = {
        BlackBoxInlineAnno(new ModuleName(moduleName, new CircuitName(moduleName)), moduleName + ".g.sv",
        s"""
        |module ${self.toNamed.name}
        |${if (params.size > 0) "#(\n  " + getParameterDefinitionInSystemVerilog().mkString(",\n  ") + ") " else ""}
        |(
        |  ${getPortDefinitionInSystemVerilog(None, ports).mkString(",\n  ")}
        |);
        |  ${moduleName} #(
        |    ${getInstanceParameterInSystemVerilog().mkString(",\n    ")}
        |  ) inner (
        |${getInstancePortInSystemVerilog(ports).mkString(",\n")}
        |  );
        |endmodule""".stripMargin)
    }
    }
    chisel3.experimental.annotate(anno)
  }
}