from logutil import *

UPDATE_IO_PREFIX = "btb.update."

for (clock, allNumberData, allTextData) in readClockCycle(True):
    upddata = dict()
    for k, v in allNumberData.items():
        if k.startswith(UPDATE_IO_PREFIX):
            upddata[k[len(UPDATE_IO_PREFIX):]] = v
    if "valid" not in upddata:
        print("Invalid Log")
        exit()
    # 更新
    if upddata["valid"][0] and upddata["valid"][1] == 1:
        print(clock)
        print(hex(upddata["pc"][1]), "->", hex(upddata["target"][1]))
        print("fail : ", upddata["fail"][1], ", taken : ", upddata["taken"][1])