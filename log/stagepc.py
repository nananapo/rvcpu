from logutil import *

for (clock, allNumberData, allTextData) in readClockCycle(True):
    # print(clock)
    for (prefix, name) in [
        #(ID_INST_PREFIX, IDSTAGE_NAME),
        #(DS_INST_PREFIX, DSSTAGE_NAME),
        #(EXE_INST_PREFIX, EXESTAGE_NAME),
        #(MEM_INST_PREFIX, MEMSTAGE_NAME),
        #(CSR_INST_PREFIX, CSRSTAGE_NAME),
        (WB_INST_PREFIX, WBSTAGE_NAME) ]:
        id = prefix + "pc"
        if id not in allNumberData:
            continue
        if not allNumberData[id][0]:
            continue
        pc = allNumberData[id][1]
        print(name, pc)