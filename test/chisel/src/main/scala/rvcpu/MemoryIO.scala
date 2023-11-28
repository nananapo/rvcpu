package rvcpu

import chisel3._
import chisel3.util._

class CacheReq(xlen : Int) extends Bundle {
    val ready   = Output(Bool())
    val valid   = Input(Bool())
    val addr    = Input(UInt(xlen.W))
    val wen     = Input(Bool())
    val wdata   = Input(UInt(32.W))
    val wmask   = Input(UInt(4.W))
    val pte     = Input(UInt(2.W))
}

class CacheResp(xlen : Int) extends Bundle {
    val valid   = Output(Bool())
    val error   = Output(Bool())
    val errty   = Output(Bool()) // false : ACCESS_FAULT , true : PAGE_FAULT
    val rdata   = Output(UInt(32.W))
}

class MemBusReq(xlen : Int) extends Bundle {
    val ready   = Output(Bool())
    val valid   = Input(Bool())
    val addr    = Input(UInt(xlen.W))
    val wen     = Input(Bool())
    val wdata   = Input(UInt(32.W))
}

class MemBusResp(xlen : Int) extends Bundle {
    val valid   = Output(Bool())
    val error   = Output(Bool())
    val addr    = Output(UInt(xlen.W))
    val rdata   = Output(UInt(32.W))
}