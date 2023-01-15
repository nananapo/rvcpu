FILE_NAME = input()

allbytes = []
with open(FILE_NAME, "rb") as f:
    allbytes = f.read()

all = []
for b in allbytes:
    all.append(format(b, '02x'))

aligned = []
for i in range(0, len(all), 4):
    aligned.append(all[i] + all[i+1] + all[i+2] + all[i+3] + "\n")

with open(FILE_NAME + ".aligned", "w") as f:
    f.writelines(aligned)