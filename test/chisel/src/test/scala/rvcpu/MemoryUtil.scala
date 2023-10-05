package rvcpu

trait MemoryUtil {
  def changeEndian(str : String) = {
    val num = BigInt(str, 16)
    (num >> 24) % 256 | ((num >> 16) % 256 << 8) |
    ((num >> 8) % 256 << 16) | ((num % 256) << 24)
  }
}