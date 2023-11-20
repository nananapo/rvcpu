IF_INST_PREFIX      = "fetchstage."
ID_INST_PREFIX      = "decodestage."
DS_INST_PREFIX      = "datastage."
EXE_INST_PREFIX     = "exestage."
MEM_INST_PREFIX     = "memstage."
CSR_INST_PREFIX     = "csrstage."
WB_INST_PREFIX      = "wbstage."

ID_INST_ID      = "decodestage.inst_id"
DS_INST_ID      = "datastage.inst_id"
EXE_INST_ID     = "exestage.inst_id"
MEM_INST_ID     = "memstage.inst_id"
CSR_INST_ID     = "csrstage.inst_id"
WB_INST_ID      = "wbstage.inst_id"

IFSTAGE_NAME    = "IF"
IDSTAGE_NAME    = "ID"
DSSTAGE_NAME    = "DS"
EXESTAGE_NAME   = "EXE"
MEMSTAGE_NAME   = "MEM"
CSRSTAGE_NAME   = "CSR"
WBSTAGE_NAME    = "WB"

IF_FETCH_START  = "fetchstage.event.fetch_start"
IF_FETCH_END    = "fetchstage.event.fetch_end"
IF_INFO_PC      = "fetchstage.event.pc"
IF_INFO_INST    = "fetchstage.event.inst"

IF_BRANCH_HAZARD    = "fetchstage.event.branch_hazard"
ID_PIPELINE_FLUSH   = "decodestage.event.pipeline_flush"
DS_PIPELINE_FLUSH   = "datastage.event.pipeline_flush"
EXE_PIPELINE_FLUSH   = "exestage.event.pipeline_flush"
MEM_PIPELINE_FLUSH   = "memstage.event.pipeline_flush"

LOG_START_TAG = "START_DEBUG_LOG"

def filter_prefix(d, prefix):
    r = dict()
    for k in d.keys():
        if k.startswith(prefix):
            r[k] = d[k]
    return r

# ログを1クロックサイクルごとのデータにまとめる
def readClockCycle(bintoint = False):
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

        if not started:
            if line[:len(LOG_START_TAG)] == LOG_START_TAG:
                started = True
            continue
        
        lineData = line.split(",")
        if lineData[0] == "clock":
            """
            clock,count
            """
            if len(lineData) < 2: continue # ignore error
            clockCount = int(lineData[1])
            if clockCount is not None:
                yield (clockCount, clockNumberData, clockTextData)
            clockNumberData = dict()
            clockTextData = dict()
        elif lineData[0] == "data":
            """
            data,name,value 
            """
            if len(lineData) < 4: continue # ignore error TODO 報告
            f = lineData[2]
            num = lineData[3].strip()
            if "x" not in num and "z" not in num:
                if f == "b":
                    if bintoint:
                        num = int(num, 2)
                    else:
                        num = str(num)
                elif f == "d":
                    num = int(num, 2)
                elif f == "h":
                    hhh = hex(int(num, 2))[2:]
                    num = "0x" + "0" * max(0, len(num) // 4 - len(hhh)) + hhh
                else:
                    continue # TODO 報告
                num = (True, num, f)
            else:
                num = (False, num, f)
            clockNumberData[lineData[1]] = num
        elif lineData[0] == "info":
            """
            info,name,value
            """
            if len(lineData) < 2: continue # ignore error
            clockTextData[lineData[1]] = lineData[2]
    if clockCount is not None:
        yield (clockCount, clockNumberData, clockTextData)