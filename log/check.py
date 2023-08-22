from collections import defaultdict
from logutil import *

UPDATE_IO_PREFIX = "btb.update."
BRANCH_PR_PREFIX = "btb.pred."

WIDTH_PC = 5
WIDTH_HIST = 10

LOCAL_INITIAL_HISORY = 0
LOCAL_INITIAL_COUNTER = 0

def numprefix(data, prefix):
    pd = dict()
    for k, v in data.items():
        if k.startswith(prefix):
            pd[k[len(prefix):]] = v
    return pd

local_history = defaultdict(lambda:LOCAL_INITIAL_HISORY)
local_counters = defaultdict(lambda:LOCAL_INITIAL_COUNTER)
local_targets = dict()

def get_pc_data(pc):
    pc_index = pc & (2 ** 5 - 1)

    hist = local_history[pc_index]
    cindex =  (hist << WIDTH_PC) + pc_index
    
    count = local_counters[cindex]
    return (pc_index, cindex, hist, count)

def update_history(pc, target, taken):
    (pc_index, cindex, oldhist, oldcount) = get_pc_data(pc)

    shifthist = (oldhist << 1) & (2 ** 10 - 1)
    local_history[pc_index] = shifthist + int(taken)

    if not((oldcount == 3 and taken) or (oldcount == 0 and not taken)):
        local_counters[cindex] = oldcount + (1 if taken else -1)
    if taken:
        local_targets[pc_index] = target

# TODO failを消す
def predictate(pc):
    (pc_index, cindex, hist, count) = get_pc_data(pc)
    if count == 0 or count == 1:
        return pc + 4
    else:
        return local_targets[pc_index]

def printdebug(pc):
    (pi, ci, h, c) = get_pc_data(pc)
    print("--------")
    print(pi, ci, h, c)
    # print(bin(pi), bin(ci), bin(h), bin(c))

"""
def test():
    pc = 0b10111010
    printdebug(pc)

    update_history(pc, 0xffffffff, 1)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 1)
    update_history(pc, 0xffffffff, 1)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 0)
    update_history(pc, 0xffffffff, 1)

    printdebug(pc)

test()
"""

for (clock, allNumberData, allTextData) in readClockCycle(True):
    # 予測
    brdata = numprefix(allNumberData, BRANCH_PR_PREFIX)
    if "use_prediction" not in brdata:
        print("in clock", clock)
        print("Invalid Log")
        exit()
    
    if brdata["use_prediction"][1] == 1:
        pc = int(brdata["pc"][1][2:], 16)
        predpc_cpu = int(brdata["pred_pc"][1][2:], 16)
        predpc_sim = predictate(pc)
        
        if predpc_cpu != predpc_sim:
            print("in clock", clock)
            print("prediction fail :", hex(pc))
            print("expect : ", hex(predpc_sim))
            print("actual : ", hex(predpc_cpu))
            exit()
    
    # 更新
    upddata = numprefix(allNumberData, UPDATE_IO_PREFIX)
    if "valid" not in upddata:
        print("in clock", clock)
        print("Invalid Log")
        exit()
    
    if upddata["valid"][0] and upddata["valid"][1] == 1:
        pc = int(upddata["pc"][1][2:], 16)
        target = int(upddata["target"][1][2:], 16)
        taken = upddata["taken"][1] == 1
        update_history(pc, target, taken)

        # if get_pc_data(pc)[0] == get_pc_data(0x3be4)[0]:
        #     print(hex(pc), "->", hex(target))
        #     print("taken : ", taken)
        #     print(local_targets)
        #     printdebug(pc)

#"""
