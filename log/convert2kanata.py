from logutil import *

KANATA_VERSION  = "0004"

lastClock   = -1
last_if_id  = None
last_id_id  = None
last_ds_id  = None
last_exe_id = None
last_mem_id = None
last_csr_id = None
last_wb_id  = None

# フェッチしたが、まだ使われていないID
fetched_unused_id = set()


print("Kanata", KANATA_VERSION, sep="\t")

RETIRED_ID_COUNTER = 0
def retire(id, type):
    global RETIRED_ID_COUNTER
    RETIRED_ID_COUNTER += 1
    print("R", id, RETIRED_ID_COUNTER, type, sep="\t")

for (clock, numberData, textData) in readClockCycle():
    print("C", clock - lastClock, "# " + str(clock), sep="\t")

    # IDがないなら終了
    if ID_INST_ID not in numberData:
        continue

    # idを取得
    id_id_valid, id_id, _   = numberData[ID_INST_ID]
    ds_id_valid, ds_id, _   = numberData[DS_INST_ID]
    exe_id_valid, exe_id, _ = numberData[EXE_INST_ID]
    mem_id_valid, mem_id, _ = numberData[MEM_INST_ID]
    csr_id_valid, csr_id, _ = numberData[CSR_INST_ID]
    wb_id_valid, wb_id, _   = numberData[WB_INST_ID]

    # intではないならNoneにする
    id_id   = int(id_id[2:], 16)  if id_id_valid else None
    ds_id   = int(ds_id[2:], 16)  if ds_id_valid else None
    exe_id  = int(exe_id[2:], 16) if exe_id_valid else None
    mem_id  = int(mem_id[2:], 16) if mem_id_valid else None
    csr_id  = int(csr_id[2:], 16) if csr_id_valid else None
    wb_id   = int(wb_id[2:], 16)  if wb_id_valid else None

    if IF_FETCH_END in textData:
        # label
        pc = numberData[IF_INFO_PC][1][2:]
        inst = numberData[IF_INFO_INST][1][2:]
        if last_if_id is not None:
            # おかしい
            print("L", last_if_id, 0, "(" + hex(last_if_id) + ") " + pc + " : " + inst, sep="\t")
            print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")
            # フェッチ済み命令IDsetに追加
            fetched_unused_id.add(last_if_id)
        last_if_id = None

    if IF_FETCH_START in numberData:
        if_id = int(numberData[IF_FETCH_START][1])
        print("I", if_id, if_id, 0, sep="\t")
        print("S", if_id, 0, IFSTAGE_NAME, sep="\t")

        if last_if_id is not None:
            print("E", last_if_id, 0, IFSTAGE_NAME, sep="\t")
            retire(last_if_id, 1)

        last_if_id = if_id

    # ID/EXE/MEM/CSR/WBはロジックを使いまわす
    # 新しいidになったら開始したことにする
    # -> 前のidでE
    for id, last_id, name in [
        (id_id, last_id_id, IDSTAGE_NAME),
        (ds_id, last_ds_id, DSSTAGE_NAME),
        (exe_id, last_exe_id, EXESTAGE_NAME),
        (mem_id, last_mem_id, MEMSTAGE_NAME),
        (csr_id, last_csr_id, CSRSTAGE_NAME),
        (wb_id, last_wb_id, WBSTAGE_NAME) ]:

        if id is not None:
            if id in fetched_unused_id:
                fetched_unused_id.remove(id)
            if last_id != id:
                print("S", id, 0, name, sep="\t")
                if last_id is not None:
                    print("E", last_id, 0, name, sep="\t")
        else:
            if last_id is not None:
                print("E", last_id, 0, name, sep="\t")

    # 分岐ハザードが起きた場合、キューにある命令を無効化する
    if IF_BRANCH_HAZARD in textData:
        for id in fetched_unused_id:
            retire(id, 1)
        fetched_unused_id.clear()
    
    # パイプラインフラッシュ
    if ID_PIPELINE_FLUSH in textData:
        if id_id is not None:
            retire(id_id, 1)
    if DS_PIPELINE_FLUSH in textData:
        if ds_id is not None:
            retire(ds_id, 1)
    if EXE_PIPELINE_FLUSH in textData:
        if exe_id is not None:
            retire(exe_id, 1)
    if MEM_PIPELINE_FLUSH in textData:
        if mem_id is not None:
            retire(mem_id, 1)

    lastClock   = clock
    last_id_id  = id_id
    last_ds_id  = ds_id
    last_exe_id = exe_id
    last_mem_id = mem_id
    last_csr_id = csr_id
    last_wb_id  = wb_id