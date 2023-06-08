import sys

MEMORY_V_FILENAME = "../src/MemoryInterface.sv"
REPLACE_WORD = "MEMORY_FILE_NAME"
MAKE_COMMAND_IVERILOG = "make riscv-tests"
MAKE_COMMAND_VERILATOR = "make dvrv"

# backup
memory_backup = ""
with open(MEMORY_V_FILENAME, "r", encoding='utf-8') as f:
    memory_backup = "".join(f.readlines())

from os import system
import os

results = []
resultstatus = []
def test(makecmd, filename):
    # replace
    memory_v_test = memory_backup.replace(REPLACE_WORD, filename)
    with open(MEMORY_V_FILENAME, "w", encoding='utf-8') as f:
        f.write(memory_v_test)
    # run test
    resultFileName = "../test/results/" + filename.replace("/","_") + ".txt"
    system("cd ../src/ && " + makecmd + " > " + resultFileName)

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

for fileName in os.listdir("riscv-tests/"):
    if not fileName.endswith(".aligned"):
        continue
    if len(args) == 0 or fileName.find(args[0]) != -1:
        test(MAKE_COMMAND_VERILATOR if verilator_mode else MAKE_COMMAND_IVERILOG, fileName)

results = sorted(results)

successCount = str(sum(resultstatus))
statusText = "Test Result : " + successCount + " / " + str(len(resultstatus))

with open("results/result.txt", "w", encoding='utf-8') as f:
    f.write(statusText + "\n")
    f.write("\n".join(results))

# rollback
with open(MEMORY_V_FILENAME, "w", encoding='utf-8') as f:
    f.write(memory_backup)

print(statusText)