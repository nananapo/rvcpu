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

KANATA_VERSION  = "0004"

IF_INST_ID      = "fetchstage.inst_id"
ID_INST_ID      = "decodestage.inst_id"
EXE_INST_ID     = "exestage.inst_id"
MEM_INST_ID     = "memstage.inst_id"
CSR_INST_ID     = "csrstage.inst_id"
WB_INST_ID      = "wbstage.inst_id"

IF_END_EVENT    = "fetchstage.instruction_fetched"
IF_OUT_PC       = "fetchstage.out.reg_pc"
IF_OUT_INST     = "fetchstage.out.inst"

IFSTAGE_NAME    = "IF"
IDSTAGE_NAME    = "ID"
EXESTAGE_NAME   = "EXE"
MEMSTAGE_NAME   = "MEM"
CSRSTAGE_NAME   = "CSR"
WBSTAGE_NAME    = "WB"

lastClock   = -1
last_if_id  = None
last_id_id  = None
last_exe_id = None
last_mem_id = None
last_csr_id = None
last_wb_id  = None

print("Kanata", KANATA_VERSION, sep="\t")

for (clock, numberData, textData) in readClockCycle():
    print("C", clock - lastClock, sep="\t")

    # idを取得
    if_id   = numberData[IF_INST_ID]
    id_id   = numberData[ID_INST_ID]
    exe_id  = numberData[EXE_INST_ID]
    mem_id  = numberData[MEM_INST_ID]
    csr_id  = numberData[CSR_INST_ID]
    wb_id   = numberData[WB_INST_ID]

    # intではないならNoneにする
    if_id   = if_id  if type(if_id ) is int else None
    id_id   = id_id  if type(id_id ) is int else None
    exe_id  = exe_id if type(exe_id) is int else None
    mem_id  = mem_id if type(mem_id) is int else None
    csr_id  = csr_id if type(csr_id) is int else None
    wb_id   = wb_id  if type(wb_id ) is int else None

    if if_id is not None:
        # 新しいidになったらフェッチを開始したことにする
        # -> 前のidでE
        # end eventがあったら、前のidでpcとinstをL

        # fetch start
        if last_if_id != if_id:
            # new id
            print("I", if_id, if_id, 0, sep="\t")
            print("S", if_id, 0, IFSTAGE_NAME, sep="\t")
            # stop last id
            if last_if_id is not None:
                print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")

        # fetch end
        if IF_END_EVENT in textData:
            # label last id
            print("L", last_if_id, 0, textData[IF_OUT_PC] + " : " + IF_OUT_INST, sep="\t")
    else:
        if last_if_id is not None:
            print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")

    # ID/EXE/MEM/CSR/WBはロジックを使いまわす
    # 新しいidになったら開始したことにする
    # -> 前のidでE
    for id, last_id, name in [
        (id_id, last_id_id, IDSTAGE_NAME),
        (exe_id, last_exe_id, EXESTAGE_NAME),
        (mem_id, last_mem_id, MEMSTAGE_NAME),
        (csr_id, last_csr_id, CSRSTAGE_NAME),
        (wb_id, last_wb_id, WBSTAGE_NAME) ]:

        if id is not None:
            if last_id != id:
                print("S", id, 0, name, sep="\t")
                if last_id is not None:
                    print("E", last_id, 0, name, sep="\t")
        else:
            if last_id is not None:
                print("E", last_id, 0, name, sep="\t")

    lastClock   = clock
    last_if_id  = if_id
    last_id_id  = id_id
    last_exe_id = exe_id
    last_mem_id = mem_id
    last_csr_id = csr_id
    last_wb_id  = wb_id