from logutil import *

KANATA_VERSION  = "0004"

lastClock   = -1
last_if_id  = None
last_id_id  = None
last_exe_id = None
last_mem_id = None
last_csr_id = None
last_wb_id  = None

print("Kanata", KANATA_VERSION, sep="\t")

for (clock, numberData, textData) in readClockCycle():
    print("C", clock - lastClock, "# " + str(clock), sep="\t")

    if IF_INST_ID not in numberData:
        # とりあえず終了ということにする
        break

    # idを取得
    if_id_valid, if_id, _   = numberData[IF_INST_ID]
    id_id_valid, id_id, _   = numberData[ID_INST_ID]
    exe_id_valid, exe_id, _ = numberData[EXE_INST_ID]
    mem_id_valid, mem_id, _ = numberData[MEM_INST_ID]
    csr_id_valid, csr_id, _ = numberData[CSR_INST_ID]
    wb_id_valid, wb_id, _   = numberData[WB_INST_ID]

    # intではないならNoneにする
    if_id   = int(if_id[2:], 16)  if if_id_valid else None
    id_id   = int(id_id[2:], 16)  if id_id_valid else None
    exe_id  = int(exe_id[2:], 16) if exe_id_valid else None
    mem_id  = int(mem_id[2:], 16) if mem_id_valid else None
    csr_id  = int(csr_id[2:], 16) if csr_id_valid else None
    wb_id   = int(wb_id[2:], 16)  if wb_id_valid else None

    if if_id is not None:
        # 新しいidになったらフェッチを開始したことにする
        # -> 前のidでE
        # end eventがあったら、前のidでpcとinstをL

        # fetch start
        if last_if_id != if_id:
            # new id
            print("I", if_id, if_id, 0, sep="\t")
            print("S", if_id, 0, IFSTAGE_NAME, sep="\t")
            # stop last id
            if last_if_id is not None:
                print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")

        # fetch end
        if IF_END_EVENT in textData:
            # label last id
            rpc = numberData[IF_OUT_PC][1][2:]
            inst = numberData[IF_OUT_INST][1][2:]
            print("L", last_if_id, 0, "(" + hex(last_if_id) + ") " + rpc + " : " + inst, sep="\t")
    else:
        if last_if_id is not None:
            print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")

    # ID/EXE/MEM/CSR/WBはロジックを使いまわす
    # 新しいidになったら開始したことにする
    # -> 前のidでE
    for id, last_id, name in [
        (id_id, last_id_id, IDSTAGE_NAME),
        (exe_id, last_exe_id, EXESTAGE_NAME),
        (mem_id, last_mem_id, MEMSTAGE_NAME),
        (csr_id, last_csr_id, CSRSTAGE_NAME),
        (wb_id, last_wb_id, WBSTAGE_NAME) ]:

        if id is not None:
            if last_id != id:
                print("S", id, 0, name, sep="\t")
                if last_id is not None:
                    print("E", last_id, 0, name, sep="\t")
        else:
            if last_id is not None:
                print("E", last_id, 0, name, sep="\t")

    lastClock   = clock
    last_if_id  = if_id
    last_id_id  = id_id
    last_exe_id = exe_id
    last_mem_id = mem_id
    last_csr_id = csr_id
    last_wb_id  = wb_id