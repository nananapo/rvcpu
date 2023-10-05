package svgen

import chisel3._

object BundleHelper {
  implicit class WeaveSelector(record: Record) {
    def waiveWithout(that : Record) : chisel3.connectable.Connectable[Record] = {
      val elems = record.elements.keys.filter(n => !that.elements.contains(n)).toSeq
      if (elems.size == 0) {
        throw new chisel3.ChiselException("record must differ from parameter")
      }
      elems.foldLeft(record.waive(_.elements(elems(0))))((a, e) => a.waive(_.elements(e)))
    }  
  }
}