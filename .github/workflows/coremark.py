import subprocess

def get_lines(cmd):
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    while True:
        line = proc.stdout.readline()
        if line:
            yield line
        if not line and proc.poll() is not None:
            break

startCount = 0
for line in get_lines(cmd='cd ../../src && timeout 1800 obj_dir/Vtest_verilator'):
    print(line, end="")
    if "Correct operation validated" in line:
        exit(0)
    if "start" in line:
        startCount += 1
        if startCount == 2:
            exit(1)
exit(1)