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
    if_id   = numberData[IF_INST_ID]
    id_id   = numberData[ID_INST_ID]
    exe_id  = numberData[EXE_INST_ID]
    mem_id  = numberData[MEM_INST_ID]
    csr_id  = numberData[CSR_INST_ID]
    wb_id   = numberData[WB_INST_ID]

    # intではないならNoneにする
    if_id   = if_id  if type(if_id ) is int else None
    id_id   = id_id  if type(id_id ) is int else None
    exe_id  = exe_id if type(exe_id) is int else None
    mem_id  = mem_id if type(mem_id) is int else None
    csr_id  = csr_id if type(csr_id) is int else None
    wb_id   = wb_id  if type(wb_id ) is int else None

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
            print("L", last_if_id, 0, textData[IF_OUT_PC] + " : " + textData[IF_OUT_INST], sep="\t")
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