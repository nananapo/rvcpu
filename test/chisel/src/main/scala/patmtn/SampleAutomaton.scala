package patmtn

import chisel3._


class PipelineTest1Module extends Module with PipelineAutomatonModule {
  val io = IO(new Bundle {
    val req_ready = Output(Bool())
    val req_valid = Input(Bool())
    val req_value = Input(UInt(32.W))
    val resp_valid = Output(Bool())
    val resp_value = Output(UInt(32.W))
  })

  /*
    In -> 1 -> 2 -> 3 -> End
  */

  val state1 = createInitialState("state1", io.req_ready, io.req_valid) // get value, go state2
  val state2 = createState("state2") // value <= value + 1, go state3
  val state3 = createState("state3") // go end

  val dataA = state1.createVariable("dataA", () => UInt(32.W), () => 0.U(32.W))
  dataA at state1 := io.req_value
  state1.transition(state2)

  val dataB = state2.createVariable("dataB", () => UInt(32.W), () => 0.U(32.W))
  dataB at state2 := dataA + 1.U
  state2.transition(state3)

  // val counter = RegInit(0.U(32.W))
  // counter := counter + 1.U

  // printf("%d ---------\n", counter)
  // printf("s1.valid      : %b\n", state1.valid)
  // printf("s1.req_ready  : %b\n", io.req_ready)
  // printf("s1.req_valid  : %b\n", io.req_valid)
  // printf("s1.req_value  : %d\n", io.req_value)

  // printf("s2.valid      : %b\n", state2.valid)
  // printf("s2.value      : %d\n", dataA.at(state2).reg)

  // printf("s3.valid      : %b\n", state3.valid)
  // printf("s3.value      : %d\n", dataB.at(state3).reg)

  io.resp_valid := state3.valid
  io.resp_value := dataB.at(state3).reg
  state3.transition(endState)

  generatePipeline()
}

class PipelineTest2Module extends Module with PipelineAutomatonModule {
  val io = IO(new Bundle {
    val req_ready = Output(Bool())
    val req_valid = Input(Bool())
    val req_value = Input(UInt(32.W))
    val resp_valid = Output(Bool())
    val resp_value = Output(UInt(32.W))
  })

  //            4 -> End
  //            ↑
  // In -> 1 -> 2 -> 3
  //            ↑    ↓
  //            <-----

  val state1 = createInitialState("state1", io.req_ready, io.req_valid) // get value, go state2
  val state2 = createState("state2") // value > 5 ? go state4 : go state3
  val state3 = createState("state3") // value <= value + 1, go state2
  val state4 = createState("state4") // resp = value, go end

  val dataA = state1.createVariable("dataA", () => UInt(32.W), () => 0.U(32.W))
  val dataB = state1.createVariable("dataB", () => UInt(32.W), () => 0.U(32.W))

  dataA at state1 := io.req_value
  dataB at state1 := 0.U
  val br1 = state1.transition(state2)

  val br2 = state2.transition(dataB >= 5.U, state4, state3)
  
  dataA at state3 := dataA + 1.U
  dataB at state3 := dataB + 1.U
  val br3 = state3.transition(state2)

  state2.setEntryArbiter(new PriorityArbiter(state2, Seq(state3, state1))) // state3が優先する

  io.resp_valid := state4.valid
  io.resp_value := dataA.at(state4).reg
  state4.transition(endState)


  val counter = RegInit(0.U(32.W))
  counter := counter + 1.U
  
  // printf("%d ---------\n", counter)
  // printf("s1.valid      : %b\n", state1.valid)
  // printf("s1.req_ready  : %b\n", io.req_ready)
  // printf("s1.req_valid  : %b\n", io.req_valid)
  // printf("s1.req_value  : %d\n", io.req_value)
  // printf("s1.to2        : %b\n", br1.isSelected)

  // printf("s2.valid      : %b\n", state2.valid)
  // printf("s2.dataA      : %d\n", dataA.at(state2).reg)
  // printf("s2.dataB      : %d\n", dataB.at(state2).reg)
  // printf("s2.to3        : %b\n", br2.isSelected(false))
  // printf("s2.to4        : %b\n", br2.isSelected(true))

  // printf("s3.valid      : %b\n", state3.valid)
  // printf("s3.dataA      : %d\n", dataA.at(state3).reg)
  // printf("s3.dataB      : %d\n", dataB.at(state3).reg)
  // printf("s3.to2        : %b\n", br3.isSelected)

  // printf("s4.valid      : %b\n", state4.valid)
  // printf("s4.dataA      : %d\n", dataA.at(state4).reg)
  // printf("s4.dataB      : %d\n", dataB.at(state3).reg)

  generatePipeline()
}

// TODO リソース調停テスト
// TODO arbiterの優先順位を指定できるようにする
// TODO atを書くのが面倒なので、atをスキップできるブロックを作れるようにしたい