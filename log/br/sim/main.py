import sys
import os.path
import "inst.py"
import "run.py"

if len(sys.argv) != 2:
    print("python3", sys.argv[0], "[memory file]")
    exit()

filename = sys.argv[1]

if not os.path.isfile(filename):
    print("メモリファイルが見つかりませんでした")
    exit()

memory = [0] * 4 * (2 ** 20)
with open(filename, mode="rb") as f:
    binary = f.read()
    for i in range(0, len(binary), 4):
        memory[i+0] = binary[i+3]
        memory[i+1] = binary[i+2]
        memory[i+2] = binary[i+1]
        memory[i+3] = binary[i+0]

def readmem(addr):
    return  (memory[addr] << 24) + \
            (memory[addr + 1] << 16) + \
            (memory[addr + 2] << 8) + \
            (memory[addr + 3])

def exec(inst):
    binst = bin(2**32 + inst)[3:]
    opcode = int(binst[25:32], 2)
    funct7 = int(binst[0:7], 2)
    funct3 = int(binst[17:20], 2)

    #imm_i = int(binst[0:12], 2)
    #imm_s = int(binst[0:8] + binst[])

    match opcode:
        case INST_LOAD_OP:
            match funct3:
                case INST_LB_F3:
                    run_lb()
        case INST_STORE_OP:

regfile    = [0] * 32
regfile[1] = 2048
pc = 0

while True:
    inst = readmem(pc)
    print(hex(pc), ":", hex(inst))
    exec(inst)
    pc += 4