from logutil import *

for (clock, allNumberData, allTextData) in readClockCycle(True):

    (prefix, name) = (WB_INST_PREFIX, WBSTAGE_NAME)
    id = prefix + "pc"
    if id not in allNumberData:
        continue
    if not allNumberData[id][0]:
        continue
    pc = allNumberData[id][1]
    print(name, pc)

    for (k, v) in filter_prefix(allNumberData, "core.regfile").items():
        print(k, v[1])    