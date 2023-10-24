import sys

args = sys.argv[1:]
bigendian = True
if len(args) >= 1 and args[0] == "-b":
    bigendian = False
    args = args[1:]

FILE_NAME = input()

allbytes = []
with open(FILE_NAME, "rb") as f:
    allbytes = f.read()

all = []
for b in allbytes:
    all.append(format(b, '02x'))

all += ["00"] * (4 - len(all) % 4)

aligned = []
for i in range(0, len(all), 4):
    if bigendian:
        aligned.append(all[i] + all[i+1] + all[i+2] + all[i+3] + "\n")
    else:
        aligned.append(all[i+3] + all[i+2] + all[i+1] + all[i] + "\n")

with open(FILE_NAME + ".aligned", "w") as f:
    f.writelines(aligned)