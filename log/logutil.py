IF_INST_PREFIX      = "fetchstage."
ID_INST_PREFIX      = "decodestage."
EXE_INST_PREFIX     = "exestage."
MEM_INST_PREFIX     = "memstage."
CSR_INST_PREFIX     = "csrstage."
WB_INST_PREFIX      = "wbstage."

IF_INST_ID      = "fetchstage.inst_id"
ID_INST_ID      = "decodestage.inst_id"
EXE_INST_ID     = "exestage.inst_id"
MEM_INST_ID     = "memstage.inst_id"
CSR_INST_ID     = "csrstage.inst_id"
WB_INST_ID      = "wbstage.inst_id"

IFSTAGE_NAME    = "IF"
IDSTAGE_NAME    = "ID"
EXESTAGE_NAME   = "EXE"
MEMSTAGE_NAME   = "MEM"
CSRSTAGE_NAME   = "CSR"
WBSTAGE_NAME    = "WB"

IF_END_EVENT    = "fetchstage.instruction_fetched"
IF_OUT_PC       = "fetchstage.out.reg_pc"
IF_OUT_INST     = "fetchstage.out.inst"

# ログを1クロックサイクルごとのデータにまとめる
def readClockCycle():
    clockCount = None
    clockNumberData = dict()
    clockTextData = dict()

    started = False
    while True:
        line = None
        try:
            line = input()
        except:
            break
        line = line.removesuffix("\n")

        if line == "START_DEBUG_LOG":
            started = True
            continue
        if not started: continue
        
        lineData = line.split(",")
        if lineData[0] == "clock":
            """
            clock,count
            """
            if len(lineData) < 2: continue # ignore error
            if clockCount is not None:
                yield (clockCount, clockNumberData, clockTextData)
            clockNumberData = dict()
            clockTextData = dict()
            clockCount = int(lineData[1])
        elif lineData[0] == "data":
            """
            data,name,value 
            """
            if len(lineData) < 3: continue # ignore error
            num = lineData[2]
            if "x" not in num and "z" not in num:
                num = int(num, 2)
            clockNumberData[lineData[1]] = num
        elif lineData[0] == "info":
            """
            info,name,value
            """
            if len(lineData) < 2: continue # ignore error
            clockTextData[lineData[1]] = lineData[2]
    if clockCount is not None:
        yield (clockCount, clockNumberData, clockTextData)