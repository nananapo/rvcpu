MEMORY_V_FILENAME = "../src/MemoryInterface.v"
REPLACE_WORD = "MEMORY_FILE_NAME"

# backup
memory_backup = ""
with open(MEMORY_V_FILENAME, "r", encoding='utf-8') as f:
    memory_backup = "".join(f.readlines())

from os import system

results = []
resultstatus = []
def test(filename):
    # replace
    memory_v_test = memory_backup.replace(REPLACE_WORD, filename)
    with open(MEMORY_V_FILENAME, "w", encoding='utf-8') as f:
        f.write(memory_v_test)
    # run test
    resultFileName = "../test/results/" + filename.replace("/","_") + ".txt"
    system("cd ../src/ && pwd && make d > " + resultFileName)

    with open(resultFileName, "r", encoding='utf-8') as f:
        result = "".join(f.readlines())
        if "Test passed" in result:
            results.append("PASS : "+ filename)
            resultstatus.append(True)
        else:
            results.append("FAIL : "+ filename)
            resultstatus.append(False)

while True:
    try:
        test(input())
    except Exception as e:
        if type(e) is EOFError:
            break
        print("Error occured", type(e))
        #print(e.message)
        break

results = sorted(results)

with open("results/result.txt", "w", encoding='utf-8') as f:
    f.write("STATUS : " + str(sum(resultstatus)) + " / " + str(len(resultstatus)) + "\n")
    f.write("\n".join(results))

# rollback
with open(MEMORY_V_FILENAME, "w", encoding='utf-8') as f:
    f.write(memory_backup)