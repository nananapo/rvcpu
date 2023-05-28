from logutil import *
from copy import deepcopy

try:
    for (clock, numberData, textData) in readClockCycle():
        print("#", clock, "clock", "-" * 24)

        if IF_INST_ID not in numberData:
            # とりあえず終了ということにする
            break

        num_others = deepcopy(numberData)
        text_others = deepcopy(textData)

        stageDataList = []
        maxlen = 0

        for prefix, name in [
            (IF_INST_PREFIX, IFSTAGE_NAME),
            (ID_INST_PREFIX, IDSTAGE_NAME),
            (EXE_INST_PREFIX, EXESTAGE_NAME),
            (CSR_INST_PREFIX, CSRSTAGE_NAME),
            (MEM_INST_PREFIX, MEMSTAGE_NAME),
            (WB_INST_PREFIX, WBSTAGE_NAME)]:


            stripped_nums = dict()
            for key, (validnum, value, f) in numberData.items():
                if key.startswith(prefix):
                    del num_others[key]
                    stripped = key.removeprefix(prefix)
                    stripped_nums[stripped] = value
                    maxlen = max(maxlen, len(stripped))
            
            stripped_texts = dict()
            for key, value in textData.items():
                if key.startswith(prefix):
                    del text_others[key]
                    stripped = key.removeprefix(prefix)
                    stripped_texts[stripped] = value
                    maxlen = max(maxlen, len(stripped))
            
            stageDataList.append((name, stripped_nums, stripped_texts))

        for key, (validnum, value, f) in num_others.items():
            maxlen = max(maxlen, len(key))
        for key, value in text_others.items():
            maxlen = max(maxlen, len(key))

        for name, nums, texts in stageDataList:
            print(name, "Stage", "-" * 20)

            for key, value in nums.items():
                print(key, " " * (maxlen - len(key)), ":", value)
            for key, value in texts.items():
                print(key, " " * (maxlen - len(key)), ":", value)

        print("other", "-" * 20)
        for key, (validnum, value, f) in num_others.items():
            print(key, " " * (maxlen - len(key)), ":", value)
        for key, value in text_others.items():
            print(key, " " * (maxlen - len(key)), ":", value)
        
        print()
except:
    exit(-1)