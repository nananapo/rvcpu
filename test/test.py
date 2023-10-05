import sys

TESTS_PATH = "riscv-tests/"
MAKE_COMMAND_IVERILOG = "make riscv-tests"
MAKE_COMMAND_VERILATOR = "make dvrv "

from os import system
import os

os.makedirs("../test/results", exist_ok=True)

results = []
resultstatus = []
def test(makecmd, filename):
    # run test
    resultFileName = "../test/results/" + filename.replace("/","_") + ".txt"
    cmd = "cd ../src/ && " + makecmd + " > " + resultFileName
    # print(cmd)
    system(cmd)

    with open(resultFileName, "r") as f:
        result = "".join(f.readlines())
        if "Test passed" in result:
            results.append("PASS : "+ filename)
            resultstatus.append(True)
            print("PASS : "+ filename)
        else:
            results.append("FAIL : "+ filename)
            resultstatus.append(False)
            print("FAIL : "+ filename)

args = sys.argv[1:]
verilator_mode = False
if len(args) >= 1 and args[0] == "-v":
    verilator_mode = True
    args = args[1:]

for fileName in sorted(os.listdir(TESTS_PATH)):
    if not fileName.endswith(".aligned"):
        continue
    abpath = os.getcwd() + "/" + TESTS_PATH + "/" + fileName

    if len(args) == 0 or fileName.find(args[0]) != -1:
        mcmd = MAKE_COMMAND_VERILATOR if verilator_mode else MAKE_COMMAND_IVERILOG
        option = " OPTION=\"-DPRED_TBC -DMEMORY_DELAY=0 -DMEM_FILE=\\\\\\\""+abpath+"\\\\\\\"\""
        test(mcmd + option, fileName)

results = sorted(results)

successCount = str(sum(resultstatus))
statusText = "Test Result : " + successCount + " / " + str(len(resultstatus))

with open("results/result.txt", "w", encoding='utf-8') as f:
    f.write(statusText + "\n")
    f.write("\n".join(results))

print(statusText)

if sum(resultstatus) != len(resultstatus):
    exit(1)