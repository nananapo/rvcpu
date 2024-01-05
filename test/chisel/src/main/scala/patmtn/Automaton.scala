package patmtn

import chisel3._
import chisel3.util._
import scala.collection.mutable.Map

// isSelectedReplaceableを置き換え、最終的にisSelectedInnerにisSelectedReplacableを接続する
sealed abstract class StateConnection(val fromState: State) {
  private[patmtn] def getFlattenNextStates() : Set[State]
  // Boolは、今のところその辺が選択されているかどうかを表すWire
  private[patmtn] def getReplaceableNextStates() : Seq[(Set[State], () => Bool, (Bool) => Unit)]
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder]
  // isSelectedに対してvalidFlagを適用する
  private[patmtn] def applyStateValidFlag(flag : Bool) : Unit
  // 設定を終了して、isSelectedを完全に使えるようにする
  private[patmtn] def finishConfigure() : Unit
  protected def checkStates(nexts : Seq[Set[State]]) : Unit = {
    for (states <- nexts) {
      for (s <- states) {
        if (s == null) throw new RuntimeException("state cannot be null")
        if (!s.canBeUsedAsTransitionTarget) throw new RuntimeException(s"state(${s.name}) cannnot be used as transiton target")
      }
    }
  } 
}

class NoCondConnection(module: PipelineAutomatonModule, fromState : State, val nextStates : Set[State]) extends StateConnection(fromState) {
  checkStates(Seq(nextStates))

  private var isSelectedReplaceable = Wire(Bool())
  isSelectedReplaceable := true.B
  private val isSelectedInner = Wire(Bool())
  val isSelected = Wire(Bool())
  isSelected := isSelectedInner

  def this(module: PipelineAutomatonModule, fromState: State, nextState : State) = this(module, fromState, Set(nextState))
  private[patmtn] def getFlattenNextStates() : Set[State] = nextStates
  private[patmtn] def getReplaceableNextStates() : Seq[(Set[State], () => Bool, (Bool) => Unit)] = {
    return Seq((nextStates, () => isSelectedReplaceable, t => isSelectedReplaceable = t))
  }
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder] = Set()

  private var stateValidFlagIsApplied = false
  private[patmtn] def applyStateValidFlag(flag : Bool) : Unit = {
    if (stateValidFlagIsApplied) throw new RuntimeException("statevalidflag is already applied")
    stateValidFlagIsApplied = true
    val rep = Wire(Bool())
    rep := isSelectedReplaceable && flag
    isSelectedReplaceable = rep
  }
  private var isFinishedCofiguring = false
  private[patmtn] def finishConfigure() : Unit = {
    if (isFinishedCofiguring) throw new RuntimeException("")
    isSelectedInner := isSelectedReplaceable
  }
}

class BranchConnection(module: PipelineAutomatonModule, fromState : State, val cond : StateData[Bool], val statesIfTrue : Set[State], val statesIfFalse : Set[State]) extends StateConnection(fromState) {
  if (cond == null) throw new RuntimeException("argument is null")
  checkStates(Seq(statesIfTrue, statesIfFalse))

  private[patmtn] val generatedCondWire : Bool = cond.generateWire(fromState)

  private var isSelectedReplaceable = Map[Boolean, Bool]()
  isSelectedReplaceable(true) = generatedCondWire === true.B
  isSelectedReplaceable(false) = generatedCondWire === false.B

  private val isSelectedInner = Map[Boolean, Bool](true -> Wire(Bool()), false -> Wire(Bool()))
  val isSelected = Map[Boolean, Bool](true -> Wire(Bool()), false -> Wire(Bool()))
  for (v <- Seq(true, false)) isSelected(v) := isSelectedInner(v)

  private[patmtn] def getFlattenNextStates() : Set[State] = statesIfTrue ++ statesIfFalse
  private[patmtn] def getReplaceableNextStates() : Seq[(Set[State], () => Bool, (Bool) => Unit)] = {
    return Seq(
      (statesIfTrue, () => isSelectedReplaceable(true), t => isSelectedReplaceable(true) = t),
      (statesIfFalse, () => isSelectedReplaceable(false), t => isSelectedReplaceable(false) = t)
    )
  }
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder] = cond.getDependencyVariables()

  private var stateValidFlagIsApplied = false
  private[patmtn] def applyStateValidFlag(flag : Bool) : Unit = {
    if (stateValidFlagIsApplied) throw new RuntimeException("statevalidflag is already applied")
    stateValidFlagIsApplied = true
    for (v <- Seq(true, false)) isSelectedReplaceable(v) = isSelectedReplaceable(v) && flag
  }
  private var isFinishedCofiguring = false
  private[patmtn] def finishConfigure() : Unit = {
    if (isFinishedCofiguring) throw new RuntimeException("")
    isSelectedInner(true) := isSelectedReplaceable(true)
    isSelectedInner(false) := isSelectedReplaceable(false)
  }
}

sealed abstract class TransitionArbiter {
  private[patmtn] def arbiteredStates : Set[(State, State)] // from -> to
  // connのisSelectedReplaceableに対して、Arbiterのロジックを適用する
  private[patmtn] def applyArbiterLogic() : Unit
  // 設定を終了して、isSelectedを完全に使えるようにする
  private[patmtn] def finishConfigure() : Unit
}

class PriorityArbiter extends TransitionArbiter {
  // isSelectedValue <> isSelectedInner (<> isSelectedReplaceable)
  private[patmtn] var isSelectedReplaceable : Seq[Bool] = null
  private[patmtn] var isSelectedInner : Seq[Bool] = null
  private var isSelectedValue : Seq[Bool] = null

  def isSelected : Seq[Bool] = isSelectedValue

  private[patmtn] var arbiterTuples : Seq[(State, State)] = null
  private[patmtn] def arbiteredStates : Set[(State, State)] = {
    var set = Set[(State, State)]()
    for (s <- arbiterTuples) set += s
    return set
  }

  // TODO genericsがコンパイル時に消えるので、どうにか型を変えた
  def this(from : State, seq : Seq[State]) = {
    this()
    arbiterTuples = seq.map(s => (from, s))
    configureWire()
  }

  def this(seq : Seq[(State, State)]) = {
    this()
    arbiterTuples = seq
    configureWire()
  }

  private def configureWire() : Unit = {
    isSelectedValue = arbiterTuples.map(_=>Wire(Bool()))
    isSelectedInner = arbiterTuples.map(_=>Wire(Bool()))
    for (i <- 0 until arbiterTuples.length) isSelectedValue(i) := isSelectedInner(i)
  }

  private[patmtn] def applyArbiterLogic() : Unit = {
    val wires = Map[(State, State), Set[(() => Bool, Bool => Unit)]]()
    for (atuple <- arbiterTuples) {
      val from = atuple._1
      val target = atuple._2
      wires((from, target)) = Set()
      for (ntuple <- from.conn.get.getReplaceableNextStates()) {
        val ns = ntuple._1
        val getter = ntuple._2
        val setter = ntuple._3
        if (ns.contains(target)) {
          wires((from, target)) += ((getter, setter))
        }
      }
    }

    var w = false.B
    for (i <- 0 until arbiterTuples.length) {
      val aw = w
      for ((g, _) <- wires(arbiterTuples(i)))
        w = w | g()
      // すでに優先順位が高いワイヤがtrueになっていたら、falseにする
      for ((g, s) <- wires(arbiterTuples(i)))
         s(Mux(aw, false.B, g()))
    }
  }
  private[patmtn] def finishConfigure() : Unit = {
    for (i <- 0 until arbiterTuples.length) {
      isSelectedInner(i) := isSelectedReplaceable(i)
    }
  }
}

// Variableのbase, Variableの演算の結果になる型
abstract class StateData[T <: Data] {
  def +(operand : StateData[T]) : StateData[T] = {
    return new MathOpStateData[T, T](MathOp.ADD, operand, this)
  }
  def +(operand : T) : StateData[T] = {
    return new MathOpStateData[T, T](MathOp.ADD, new RawStateData(operand), this)
  }
  def >(operand : StateData[T]) : StateData[Bool] = {
    return new MathOpStateData[T, Bool](MathOp.GREATER, operand, this)
  }
  def >(operand : T) : StateData[Bool] = {
    return new MathOpStateData[T, Bool](MathOp.GREATER, new RawStateData(operand), this)
  }
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder]
  // stateにおける存在チェックは行わない
  private[patmtn] def generateWire(state: State) : T
}

class RawStateData[T <: Data](val data : T) extends StateData[T] {
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder] = Set()
  private[patmtn] def generateWire(state: State) : T = data
}

object MathOp {
  final val ADD = 0
  final val SUB = 1
  final val GREATER = 2
}

class MathOpStateData[T <: Data, R <: Data](val op : Int, val source1 : StateData[T], val source2 : StateData[T]) extends StateData[R] {
  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder] = source1.getDependencyVariables() ++ source2.getDependencyVariables()
  private[patmtn] def generateWire(state: State) : R = op match {
    case MathOp.ADD => source1.generateWire(state) match {
      case u : UInt => (u + source2.generateWire(state).asInstanceOf[UInt]).asInstanceOf[R]
      case _ => ???
    }
    case MathOp.SUB => ???
    case MathOp.GREATER => ???
  }
}

sealed trait VariableTypeHolder {
  val name : String
  private[patmtn] def getUsingStates() : Set[State]
  private[patmtn] def checkAssignedDataVariableIsExistInState() : Unit
  private[patmtn] def generateRegisterAt(state : State) : Unit
  private[patmtn] def generateMoveDataLogicAt(stateAt : State, fromStates : Set[State]) : Unit
}

class Variable[T <: Data](module : PipelineAutomatonModule, val name : String, tfac: () => T, ifac: () => T) extends StateData[T] with VariableTypeHolder {
  private[patmtn] val dataWithState = Map[State, (T, AssignableVariable[T])]()

  // propagatedVariablesがリセットされるので、内部で読んではいけない
  def at(state: State) : AssignableVariable[T] = {
    // stateにVariableが存在するかを確かめる
    if (module.option.checkVariableExistWhenVariableAt) {
      module.propagateVariable(false)
      if (!state.contains(this))
        throw new RuntimeException(s"variable($name) is not found at state(${state.name}).")
      module.resetPropagatedVariables()
    }
    generateRegisterAt(state)
    // レジスタを生成し、AssignableVariableを返す
    return dataWithState(state)._2
  }

  private[patmtn] def getDependencyVariables() : Set[VariableTypeHolder] = Set(this)
  private[patmtn] def generateWire(state: State) : T = {
    generateRegisterAt(state)
    return dataWithState(state)._2.reg
  }

  private[patmtn] def getUsingStates() : Set[State] = {
    return dataWithState.keySet.toSet
  }

  private[patmtn] def getAssignableVariables() : Set[AssignableVariable[T]] = {
    var r = Set[AssignableVariable[T]]()
    for (s <- dataWithState) {
      r += s._2._2
    }
    return r
  }

  private[patmtn] def generateRegisterAt(state : State) : Unit = {
    if (!dataWithState.contains(state)) {
      val reg = RegInit(ifac())
      val wire = Wire(tfac())
      wire := reg
      dataWithState(state) = (reg, new AssignableVariable[T](module, state, wire))
    }
  }

  private[patmtn] def checkAssignedDataVariableIsExistInState() : Unit = {
    for (av <- getAssignableVariables()) { 
      av.checkAssignedDataVariableIsExist()
    }
  }

  private[patmtn] def generateMoveDataLogicAt(stateAt : State, fromStates : Set[State]) : Unit = {
    var seq = Seq[(Bool, T)]()
    var allOr = false.B
    for (f <- fromStates) {
      var moveValid = false.B
      for (ntuple <- f.conn.get.getReplaceableNextStates()) {
        val nexts = ntuple._1
        val getter = ntuple._2
        if (nexts.contains(stateAt))
          moveValid = moveValid | getter()
      }
      val assignable = dataWithState(f)._2
      val data = assignable.generatedWire.getOrElse(assignable.reg)
      seq :+= ((moveValid, data))
      allOr = allOr | moveValid
    }
    val register = dataWithState(stateAt)._1
    seq :+= ((!allOr, register)) // 維持するMux
    register := Mux1H(seq)
  }
}

class AssignableVariable[T <: Data](module : PipelineAutomatonModule, val stateAt : State, val reg : T) {
  // このregはWireであり、すでにレジスタにつながっている
  private[patmtn] var assignData : Option[StateData[T]] = None
  private[patmtn] var generatedWire : Option[T] = None
  def :=(operand: StateData[T]) : Unit = {
    if (!assignData.isEmpty) throw new RuntimeException("variable is already assigned")
    assignData = Some(operand)
    // 右辺に使うVariableが存在するか確かめる
    if (module.option.checkVariableExistWhenVariableAssign) {
      module.propagateVariable(false)
      checkAssignedDataVariableIsExist()
      module.resetPropagatedVariables()
    }
    generatedWire = Some(assignData.get.generateWire(stateAt))
  }
  def :=(operand: T) : Unit = this.:=(new RawStateData(operand))
  def checkAssignedDataVariableIsExist() : Unit = {
    if (assignData.isEmpty) return
    for (v <- assignData.get.getDependencyVariables()) {
      if (!stateAt.contains(v) && !stateAt.vardefs.contains(v))
        throw new RuntimeException(s"variable(${v.name}) is not found at state(${stateAt.name})")
    }
  }
}

class State(module : PipelineAutomatonModule, val name : String) {
  protected[patmtn] val validReg = RegInit(false.B)
  protected[patmtn] val validInner = Wire(Bool())
  val valid = Wire(Bool())
  valid := validInner

  protected[patmtn] val isNewReg = RegInit(false.B)
  protected[patmtn] val isNewInner = Wire(Bool())
  val isNew = Wire(Bool())
  isNew := isNewInner

  private[patmtn] var conn : Option[StateConnection] = None
  private[patmtn] var entryArbiter : Option[TransitionArbiter] = None

  private[patmtn] var vardefs = Set[VariableTypeHolder]() // defines
  private[patmtn] var varrets = Set[VariableTypeHolder]() // retires

  // propagateされたVariable
  private[patmtn] var propagatedVariables = Set[VariableTypeHolder]()

  protected[patmtn] def canBeUsedAsTransitionTarget : Boolean = true

  // 条件のない遷移を設定
  // nullで終了
  def transition(nextStates : Set[State]) : StateConnection = {
    if (!conn.isEmpty) throw new RuntimeException("connection is alraedy set")
    conn = Some(new NoCondConnection(module, this, nextStates))
    checkOnSetTransition()
    return conn.get
  }

  def transition(nextState : State) : StateConnection = transition(Set(nextState))

  def transition(cond: StateData[Bool], statesIfTrue: Set[State], statesIfFalse: Set[State]) : StateConnection = {
    if (!conn.isEmpty) throw new RuntimeException("connection is alraedy set")
    conn = Some(new BranchConnection(module, this, cond, statesIfTrue, statesIfFalse))
    checkOnSetTransition()
    return conn.get
  }

  def transition(cond: StateData[Bool], stateIfTrue: State, stateIfFalse: State) : StateConnection = transition(cond, Set(stateIfTrue), Set(stateIfFalse))
  def transition(cond: Bool, stateIfTrue: State, stateIfFalse: State) : StateConnection = transition(new RawStateData[Bool](cond), stateIfTrue, stateIfFalse)
  def transition(cond: Bool, statesIfTrue: Set[State], statesIfFalse: Set[State]) : StateConnection = transition(new RawStateData[Bool](cond), statesIfTrue, statesIfFalse)

  protected def checkOnSetTransition() : Unit = {
    module.propagateVariable(false) // 変数を遷移させて、すぐにエラーを発見する
    validateSelfLoop()
    validateVariableExist()
    module.resetPropagatedVariables()
  }

  def setEntryArbiter(arbiter: TransitionArbiter) : Unit = {
    if (!entryArbiter.isEmpty) throw new RuntimeException("entry arbiter is already set")
    entryArbiter = Some(arbiter)
    for (t <- arbiter.arbiteredStates) {
      if (t._1 != this) throw new RuntimeException(s"fromState of entryArbiter is not State($name), not State(${t._1.name})")
    }
  }

  def createVariable[T <: Data](name : String, tfac : () => T, ifac : () => T) : Variable[T] = {
    val variable = new Variable[T](module, name, tfac, ifac)
    vardefs += variable
    validateSelfLoop()
    return variable
  }

  def retireVariable[T <: Data](variable : Variable[T]) : Unit = {
    if (varrets.contains(variable)) throw new RuntimeException(s"retirement of variable(${variable.name}) is already registered")
    if (vardefs.contains(variable)) throw new RuntimeException(s"there are retirement and definition of variable(${variable.name}) in one state($name)")
    // 変数を遷移させて、そもそもpropagateされるかどうかを確かめる。
    if (module.option.allowVariableRetireWithoutVariable) {
      println(s"Warning : variable(${variable.name}) is not found at state($name)")
    } else {
      module.propagateVariable(false)
      if (!propagatedVariables.contains(variable)) {
        throw new RuntimeException(s"variable(${variable.name}) is not found at state($name)")
      }
      module.resetPropagatedVariables()
    }
    // リタイアリストに追加
    varrets += variable
    // 変数を遷移させて、これによって変数が参照できなくなるかを調べる
    if (module.option.checkVariableExistWhenRetireVariable) {
      module.propagateVariable(false)
      module.checkAssignedVariableExist()
      module.resetPropagatedVariables()
    }
  }

  // 変数がこのStatrに存在するかを返す
  // propagateしないと機能しないので注意
  private[patmtn] def contains(v : VariableTypeHolder) = propagatedVariables.contains(v) || vardefs.contains(v)

  // return : 変更されたかどうか
  private[patmtn] def propagateVariable() : Boolean = {
    if (conn.isEmpty) return false

    var flag = false
    for (s <- conn.get.getFlattenNextStates()) {
      // 定義を伝播させる
      for (v <- vardefs) {
        if (!s.propagatedVariables.contains(v)) {
          flag = true
          s.propagatedVariables += v
        }
      }
      // 変数を伝播させる (retireする変数を除く)
      for (v <- propagatedVariables.filterNot(varrets.contains(_))) {
        if (s.vardefs.contains(v)) throw new RuntimeException("variable propagation has reached variable's definition state")
        if (!s.propagatedVariables.contains(v)) {
          flag = true
          s.propagatedVariables += v
        }
      }
    }
    return flag
  }

  private[patmtn] def setupValidFlag() : Unit = {
    validInner := validReg
    conn.get.applyStateValidFlag(validInner)
    isNewInner := validReg & isNewReg
  }

  private[patmtn] def validateFields() : Unit = {
    if (conn.isEmpty) throw new RuntimeException(s"connection of state($name) is not set")
  }

  // 自己ループが存在する場合、変数宣言が含まれないことを確認する
  private[patmtn] def validateSelfLoop() : Unit = {
    if (conn.isEmpty) return
    if (!conn.get.getFlattenNextStates().contains(this)) return
    if (vardefs.size != 0)
      throw new RuntimeException("state with self loop must not have variable definition")
  }

  private[patmtn] def validateVariableExist() : Unit = {
    // atのチェック
    for (v <- vardefs) {
      for (us <- v.getUsingStates()) {
        if (!us.contains(v))
          throw new RuntimeException(s"variable(${v.name}) is not found in state(${us.name})")
      }
      v.checkAssignedDataVariableIsExistInState()
    }
    // 辺の条件のチェック
    if (!conn.isEmpty) {
      for (v <- conn.get.getDependencyVariables()) {
        // vardefにある場合、まだ値が定まっていないので使用できない
        if (vardefs.contains(v))
          throw new RuntimeException(s"variable(${v.name}) is not defined at state(${name}) but you cannnot use it in defined state")
        // propagateされていないなら存在しない
        if (!propagatedVariables.contains(v))
          throw new RuntimeException(s"variable(${v.name}) is not found in state(${name})")
      }
    }
  }

  private[patmtn] def generateAllVariableRegisters() : Unit = {
    for (v <- propagatedVariables) {
      v.generateRegisterAt(this)
    }
  }

  private[patmtn] def printInfo() : Unit = {
    println("---------------")
    println("name: " + name)
    println("prop: " + propagatedVariables.map(_.name).mkString(","))
    println("defs: " + vardefs.map(_.name).mkString(","))
  }
}

class InitialState(module : PipelineAutomatonModule, name: String, private[patmtn] var req_ready : Bool, private[patmtn] val req_valid : Bool) extends State(module, name) {
  req_ready := validReg === false.B
  private[patmtn] override def setupValidFlag() : Unit = {
    validInner := validReg || req_valid
    conn.get.applyStateValidFlag(validInner)
    isNewInner := (validReg & isNewReg) | (req_ready & req_valid)
  }
}
class EndState(module : PipelineAutomatonModule, name : String) extends State(module, name) {
  // TODO チェック関数が副作用を持っているのをどうにかする
  private var usedAsTarget = false
  protected[patmtn] override def canBeUsedAsTransitionTarget : Boolean = {
    if (usedAsTarget) return false
    usedAsTarget = true
    return true
  }
  private[patmtn] override def setupValidFlag() : Unit = {
    validInner := false.B
    isNewInner := false.B
  }
  protected override def checkOnSetTransition() : Unit = {
    throw new RuntimeException("transition from endState is not allowed")
  }
}

class GenerateOption {
  // 使用されていないレジスタを削除するかどうか
  // falseの場合、ステートが合流(同時に合流するわけではない場合)するとき、変数が未定義となってしまいエラーが出る可能性がある
  // 例:   A(def a)  → C
  //       B(def b) →↑
  // このとき、Cにはaもbもあるが、aはAからきた場合にしかないし、bはBから来た場合にしかない。
  // 未使用のレジスタを削除するとき、C以降(C含む)でaとbを使用していない場合にはaとbレジスタはCで定義されない。
  // そのため、a, bの値がCで未定義になることはなく、エラーは発生しない。未使用のレジスタを削除する場合は、値が未定義となるのでエラーが発生する。
  var removeUnusedRegister = true
  // ステートへの到達可能性チェックを行い、InitialStateから遷移できないstateを削除するかどうか
  // reachできない場合、warningを発生させる
  var allowUnreachableState = true
  // transitionが設定されていない場合、endへの遷移に置き換えるかどうか
  // falseの場合、例外が発生
  var setNotSetTransitionToEndTransition = false
  // endに到達しないステートを許容するかどうか
  // falseの場合、例外。trueの場合、
  var allowUnreachEndState = false
  // stateからvariableをretireさせるときに、variableが存在しなくてもエラーを出さない
  // ただし、Warningは出る
  var allowVariableRetireWithoutVariable = true
  // Variable.atを使うとき、変数がstateに存在するかどうかをチェックする
  // 使うときにチェックするかどうかの設定であって、使えないのに使っていても例外が発生しなくするものではない
  var checkVariableExistWhenVariableAt = true
  // Variable.:=を使うとき、右辺の変数がstateに存在するかどうかをチェックする
  // 使うときにチェックするかどうかの設定であって、使えないのに使っていても例外が発生しなくするものではない
  var checkVariableExistWhenVariableAssign = true
  // state.retireVariableするとき、それによって既存の式(atを使うもの、atに代入するもの)に利用されている変数が使えなくなるかチェックする
  // 使うときにチェックするかどうかの設定であって、使えないのに使っていても例外が発生しなくするものではない
  var checkVariableExistWhenRetireVariable = true
  // 実行時デバッグログを表示するかどうか
  var printRuntimeDebugLog = false
}

trait PipelineAutomatonModule extends Module {
  self: Module =>

  private var generated = false
  private var initialStates = Set[InitialState]()
  private var allStates = Set[State]()
  protected[patmtn] var option = new GenerateOption()
  private var resourceArbiters = Set[TransitionArbiter]()
  private var allEndState = Set[EndState]()

  protected def endState : EndState = {
    val e = new EndState(this, "end_" + allEndState.size)
    allEndState += e
    return e
  }

  def createInitialState(name : String, ready : Bool, valid : Bool) : InitialState = {
    val state = new InitialState(self, name, ready, valid)
    initialStates += state
    allStates += state
    return state
  }
  def createState(name : String) : State = {
    val state = new State(self, name)
    allStates += state
    return state
  }

  def registerResource(arbiter: TransitionArbiter) : TransitionArbiter = {
    if (resourceArbiters.contains(arbiter)) throw new RuntimeException("this arbiter is already registered")
    resourceArbiters += arbiter
    return arbiter
  }

  private[patmtn] def propagateVariable(reset : Boolean) : Unit = {
    var flag = true
    while (flag) {
      flag = false
      for (s <- allStates) {
        flag = flag | s.propagateVariable()
      }
    }
    if (reset) resetPropagatedVariables()
  }

  private[patmtn] def resetPropagatedVariables() : Unit = {
    for (s <- allStates) s.propagatedVariables = Set()
  }

  private def getReachableEndStates() : Set[State] = {
    var endStates = Set[State]()
    var arrivedStates = Set[State]()
    for (initial <- initialStates) {
      arrivedStates += initial
      var queue = Set[State](initial)
      while (queue.size > 0) {
        var newQueue = Set[State]()
        for (s <- queue) {
          for (ns <- s.conn.get.getFlattenNextStates()) {
            if (ns.isInstanceOf[EndState]) {
              endStates += ns
            } else {
              if (!arrivedStates.contains(ns)) {
                arrivedStates += ns
                if (!newQueue.contains(ns)) newQueue += ns
              }
            }
          }
        }
        queue = newQueue
      }
    }
    return endStates
  }

  private def getReversedConnections() : Map[State, Set[State]] = {
    var revConn = Map[State, Set[State]]()
    for (s <- allStates) revConn(s) = Set()
    for (s <- allStates) {
      for (ns <- s.conn.get.getFlattenNextStates()) {
        if (!revConn.contains(ns)) revConn(ns) = Set()
        revConn(ns) += s
      }
    }
    return revConn
  }

  private def reachCheck() : Unit = {
    // InitialStateからすべてのステートに到達可能であることを確認する
    var arrivedStates = Set[State]()
    for (initial <- initialStates) {
      arrivedStates += initial
      var queue = Set[State](initial)
      while (queue.size > 0) {
        var newQueue = Set[State]()
        for (s <- queue) {
          for (ns <- s.conn.get.getFlattenNextStates()) {
            if (!ns.isInstanceOf[EndState] && !arrivedStates.contains(ns)) {
              arrivedStates += ns
              newQueue += ns
            }
          }
        }
        queue = newQueue
      }
    }
    // 警告を出して、allStatesから削除する
    if (allStates.size != arrivedStates.size) {
      var unreachableStates = Set[State]()
      for (s <- allStates) {
        if (!arrivedStates.contains(s)) {
          unreachableStates += s
          if (!option.allowUnreachableState)
            throw new RuntimeException(s"Warning : state(${s.name}) unreachable")
        }
      }
      allStates = allStates.filterNot(unreachableStates.contains(_))
    }
    // すべてのステートからEndに到達可能であることを確認する
    if (!option.allowUnreachEndState) {
      arrivedStates = Set()
      val endStates = getReachableEndStates()
      val revConn = getReversedConnections()
      for (initial <- endStates) {
        var queue = Set[State](initial)
        while (queue.size > 0) {
          var newQueue = Set[State]()
          for (s <- queue) {
            for (ns <- revConn(s)) {
              if (!arrivedStates.contains(ns)) {
                arrivedStates += ns
                newQueue += ns
              }
            }
          }
          queue = newQueue
        }
      }
      if (allStates.size != arrivedStates.size) {
        var stateNames = Set[String]()
        for (s <- allStates) {
          if (!arrivedStates.contains(s))  stateNames += s.name
        }
        throw new RuntimeException(s"state(${stateNames.mkString(",")}) cannot reach end state. if you want to allow, set option.allowUnreachEndState to true")
      }
    }
  }

  // variableがstateで使用できることを確認する
  private[patmtn] def checkAssignedVariableExist() : Unit = for (s <- allStates)  s.validateVariableExist()

  private def removeUnusedRegisters() : Unit = {
    var regUseMap = Map[State, Set[VariableTypeHolder]]()
    for (s <- allStates) regUseMap(s) = Set()
    for (s <- allStates) {
      for (v <- s.vardefs) {
        for (us <- v.getUsingStates()) {
          regUseMap(us) += v
        }
      }
    }
    // 最後に利用されたところでレジスタを削除する
    // つまり、使用されたところからさかのぼり、定義で削除する
    var regMap = regUseMap
    var ruv = getReversedConnections()
    var updated = true
    while (updated) {
      updated = false
      for (s <- allStates) {
        for (ns <- ruv(s)) {
          regUseMap(ns) ++= regUseMap(s).filterNot(v => s.vardefs.contains(v) || regUseMap(ns).contains(v))
        }
      }
    }
    for (s <- allStates) {
      s.propagatedVariables = regMap(s).filterNot(s.vardefs.contains(_))
    }
  }

  private def checkUndefinedValueRegister() : Unit = {
    // 変数Aが存在しないステートから、変数Aの定義場所ではないが変数Aが存在しているステートへの遷移
    // が存在しないことを確認する
    // TODO 合体transition
    for (s <- allStates) {
      for (ns <- s.conn.get.getFlattenNextStates().filterNot(_.isInstanceOf[EndState])) {
        for (v <- ns.propagatedVariables) {
          if (!s.contains(v)) throw new RuntimeException(s"value of variable(${v.name}) is undefined at transition state(${s.name}) to state(${ns.name})")
        }
      }
    }
  }

  // TODO removeされたとき、一致しなくてエラーが出る
  private def checkEntryArbiterIsSet() : Unit = {
    val indict = Map[State, Set[State]]()
    for (s <- allStates) indict(s) = Set()
    for (s <- allStates) {
      for (ns <- s.conn.get.getFlattenNextStates()) {
        if (!ns.isInstanceOf[EndState]) indict(ns) = indict(ns) + s
      }
    }
    for (s <- allStates) {
      if (indict(s).size > 1) {
        if (s.entryArbiter.isEmpty)
          throw new RuntimeException(s"entryArbiter is not set on State(${s.name}). It must include {${indict(s).map(_.name).mkString(",")}}")
        val diff = indict(s) &~ s.entryArbiter.get.arbiteredStates.map(t => t._2)
        if (diff.size != 0)
          throw new RuntimeException(s"entryArbiter must include {${diff.mkString(",")}}")
      }
    }
  }

  private def setupStateValid() : Unit = {
    for (s <- allStates)
      s.setupValidFlag()
    for (s <- allEndState)
      s.setupValidFlag()
  }

  private def applyEntryArbiters() : Unit = {
    for (s <- allStates.filterNot(_.entryArbiter.isEmpty)) {
      s.entryArbiter.get.applyArbiterLogic()
    }
  }

  private def applyResourceArbiters() : Unit = {
    for (a <- resourceArbiters) {
      a.applyArbiterLogic()
    }
  }

  // ストールを考慮した移動判定ロジックを生成
  private def generateSelectMovableStateLogic() : Unit = {
    // 閉路を検知しておく
    def rec(at: State, arrived: Set[State], history: Seq[State]) : Set[Set[State]] = {
      if (at.isInstanceOf[EndState] || at.conn.isEmpty) return Set()
      var results = Set[Set[State]]()
      for (next <- at.conn.get.getFlattenNextStates()) {
        if (arrived.contains(next)) {
          // loop
          results += history.slice(history.indexOf(next), history.length).toSet
        } else {
          results ++= rec(next, arrived + next, history :+ next)
        }
      }
      return results
    }

    var loops = Set[Set[State]]()
    val stateLoops = Map[State, Set[Set[State]]]()
    // initialStatesからたどって到達できるループしか検知しない
    for (initial <- initialStates) {
      loops ++= rec(initial, Set[State](initial), Seq[State](initial))
    }
    for (s <- allStates) stateLoops(s) = loops.filter(_.contains(s))

    val stateWillMoveWires = Map[State, Bool]()
    for (s <- allStates) stateWillMoveWires(s) = Wire(Bool())
    var replaceQueue = Seq[(Bool, Bool => Unit)]()

    // 移動判定ロジックを生成
    for (s <- allStates) {
      if (stateLoops(s).size == 0) {
        var moveW = false.B
        for (ntuple <- s.conn.get.getReplaceableNextStates()) {
          val nexts = ntuple._1
          val getter = ntuple._2
          val setter = ntuple._3
          var w = getter()
          for (n <- nexts.filterNot(_.isInstanceOf[EndState])) {
            w = w && (!n.valid || stateWillMoveWires(n))
          }
          moveW = moveW | w
          replaceQueue :+= ((w, setter))
        }
        stateWillMoveWires(s) := moveW
      } else {
        // TODO ループの時
        ???
      }
    }

    // replaceableを置き換え
    for (q <- replaceQueue) q._2(q._1)
  }

  private def generateAllRegisters() : Unit = {
    for (s <- allStates)
      s.generateAllVariableRegisters()
  }

  private def generateMoveDataLogic() : Unit = {
    val rev = getReversedConnections()
    for (s <- allStates) {
      // validとis_newを作る
      var willIn = false.B
      for (rs <- rev(s)) {
        for (ntuple <- rs.conn.get.getReplaceableNextStates()) {
          val nexts = ntuple._1
          if (nexts.contains(s)) {
            val getter = ntuple._2
            willIn = willIn | getter()
          }
        }
      }
      var willMove = false.B
      for (ntuple <- s.conn.get.getReplaceableNextStates()) {
        val getter = ntuple._2
        willMove = willMove | getter()
      }
      s.validReg := willIn | (s.valid & !willMove)
      s.isNewReg := willIn
      
      // 変数の移動を作る
      for (v <- s.propagatedVariables) {
        v.generateMoveDataLogicAt(s, rev(s))
      }
    }
  }

  private def finishConfigure() : Unit = {
    for (a <- resourceArbiters) a.finishConfigure()
    for (a <- allStates.filterNot(_.conn.isEmpty)) a.conn.get.finishConfigure()
  }

  def generatePipeline() : Unit = {
    if (generated) throw new RuntimeException("generatePipeline is called twice")
    if (initialStates.size == 0) throw new RuntimeException("initial state is not found")

    // ステートのチェック
    for (s <- allStates) {
      // transitionが設定されていないものはendStateにつなぐ
      if (option.setNotSetTransitionToEndTransition && s.conn.isEmpty) {
        s.transition(endState)
      }
      s.validateFields()
      s.validateSelfLoop()
    }
    // 到達可能性チェック→ステート削除
    reachCheck()

    // initialstateから変数を伝播させる
    propagateVariable(false)
    // 各ステートで使用している変数をチェックする
    checkAssignedVariableExist()
    // 使用していない変数を削除する
    if (option.removeUnusedRegister) removeUnusedRegisters()
    // 値が定まらないレジスタがないかどうかを確認する
    checkUndefinedValueRegister()

    // stateのvalidを生成する
    setupStateValid()
    // entry調停がすべてに対して設定されているかをチェックする
    checkEntryArbiterIsSet()
    // entry調停を生成する
    applyEntryArbiters()
    // resource調停を生成する
    applyResourceArbiters()

    // 移動ができるかを最終判定するロジックを生成する
    generateSelectMovableStateLogic()

    // TODO レジスタの初期値の取り扱い
    // TODO 初期化がない場合の定義場所移動

    // レジスタを生成する
    generateAllRegisters()
    // データをレジスタに格納するロジックを生成する
    generateMoveDataLogic()

    finishConfigure()
  }

  // TODO nameをprint可能なものにする
  def saveGraph(fileName : String) : Unit = {
    import java.io._

    var lines = Seq[String]()
    lines :+= "digraph pipeline {"

    // ノードの追加
    var createdStates = Set[State]()
    for (i <- initialStates) {
      var queue = Set[State](i)
      while (queue.size > 0) {
        var newQueue = Set[State]()
        for (s <- queue) {
          if (!createdStates.contains(s)) {
            var shape = if (s.isInstanceOf[EndState]) "doublecircle" else "circle"
            lines :+= s"${s.name} [shape=$shape];"
            createdStates += s
            if (!s.isInstanceOf[EndState]) {
              for (ns <- s.conn.get.getFlattenNextStates())
                if (!createdStates.contains(ns)) newQueue += ns
            }
          }
        }
        queue = newQueue
      }
    }

    // 辺の追加
    for (s <- createdStates.filterNot(_.conn.isEmpty)) {
      for (ns <- s.conn.get.getFlattenNextStates()) {
        lines :+= s"${s.name} -> ${ns.name}"
      }
    }

    lines :+= "}"

    val outputStream = new FileOutputStream(fileName)
    val writer = new OutputStreamWriter(outputStream, "UTF-8")
    writer.write(lines.mkString("\n"))
    writer.close
  }
}