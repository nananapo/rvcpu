import sys
from os import system
import os

TESTS_PATH = "riscv-tests/"
MAKE_COMMAND_IVERILOG = "make -C ../src/ riscv-tests"
MAKE_COMMAND_VERILATOR = "make -C ../src/ dvrv "

VERILATOR_MODE = False
NODEBUG_MODE = False
XZSTOP_MODE = False


os.makedirs("../test/results", exist_ok=True)

results = []
resultstatus = []
def test(makecmd, filename):
    # run test
    resultFileName = "../test/results/" + filename.replace("/","_") + ".txt"
    cmd = makecmd + " > " + resultFileName
    # print(cmd)
    ret = system(cmd)
    if ret == 0:
        results.append("PASS : "+ filename)
        resultstatus.append(True)
        print("PASS : "+ filename)
    else:
        results.append("FAIL : "+ filename)
        resultstatus.append(False)
        print("FAIL : "+ filename)

args = sys.argv[1:]
def procarg():
    global args, VERILATOR_MODE, NODEBUG_MODE, XZSTOP_MODE
    cont = True
    while cont:
        cont = False
        if len(args) >= 1 and args[0] == "-v":
            VERILATOR_MODE = True
            args = args[1:]
            cont = True
        if len(args) >= 1 and args[0] == "-nodebug":
            NODEBUG_MODE = True
            args = args[1:]
            cont = True
        if len(args) >= 1 and args[0] == "-xzstop":
            XZSTOP_MODE = True
            args = args[1:]
            cont = True
procarg()

for fileName in sorted(os.listdir(TESTS_PATH)):
    if not fileName.endswith(".aligned"):
        continue
    abpath = os.getcwd() + "/" + TESTS_PATH + "/" + fileName

    if len(args) == 0 or fileName.find(args[0]) != -1:
        mcmd = MAKE_COMMAND_VERILATOR if VERILATOR_MODE else MAKE_COMMAND_IVERILOG
        options = []
        options.append("-DPRED_TBC")
        options.append("-DMEMORY_DELAY=0")
        if XZSTOP_MODE:
            options.append("-DXZSTOP")
        options.append("-DMEM_FILE=\\\\\\\""+abpath+"\\\\\\\"")
        if not NODEBUG_MODE:
            options.append("-DPRINT_DEBUGINFO")
        options.append("-DEND_CLOCK_COUNT=500000")
        options.append("-DDETECT_ABNORMAL_STALL")
        test(mcmd + " OPTION=\"" + " ".join(options) + "\"", fileName)

results = sorted(results)

successCount = str(sum(resultstatus))
statusText = "Test Result : " + successCount + " / " + str(len(resultstatus))

with open("results/result.txt", "w", encoding='utf-8') as f:
    f.write(statusText + "\n")
    f.write("\n".join(results))

print(statusText)

if sum(resultstatus) != len(resultstatus):
    exit(1)