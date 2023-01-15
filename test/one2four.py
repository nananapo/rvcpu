FILE_NAME = "bin/rv32ui-p-add.hex"

all = []
with open(FILE_NAME, "r") as f:
    all = f.readlines()

for i in range(len(all) % 4):
    all.append("00")

all = list(map(lambda x:x.strip(), all))

aligned = []
for i in range(0, len(all), 4):
    aligned.append(all[i] + all[i+1] + all[i+2] + all[i+3] + "\n")

with open(FILE_NAME + ".aligned", "w") as f:
    f.writelines(aligned)