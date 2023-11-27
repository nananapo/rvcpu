import sys
import io
import subprocess
import time

TEST_MODE       = False
USE_CACHE       = False
USE_O3_CACHE    = True
memory_delay    = 0 # TODO

# get_linesで利用する
READ_CHAR_MODE = 0

# read params
args = sys.argv[1:]
for arg in args:
    if arg == "-t":
        TEST_MODE = True
    if arg == "-c":
        USE_CACHE = True
    if arg == "-o":
        USE_O3_CACHE = False
    if arg == "-o3":
        USE_O3_CACHE = True

if TEST_MODE:
    print("This is Test mode")

def get_lines(cmd):
    global READ_CHAR_MODE
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    while True:
        if READ_CHAR_MODE:
            line = proc.stdout.read(1)
        else:
            line = proc.stdout.readline()
        if line:
            yield line
        if not line and proc.poll() is not None:
            break

makecmd = ""
makecmd += "make -C ../src dv OPTION=\""

# default config
makecmd += "-DFAST_UART"
makecmd += "-DPRED_LOCAL "
makecmd += "-DMEMORY_WIDTH=28 "
makecmd += "-DMEMORY_DELAY=" + str(memory_delay) + " "
makecmd += "-DDETECT_ABNORMAL_STALL "
makecmd += "-DABNORMAL_STOP_THRESHOLD=" + str(100000 * (memory_delay+1)) + " "

# param config
makecmd += "-DMEM_FILE=\\\\\\\""
if USE_CACHE:
    if USE_O3_CACHE:
        makecmd += "../test/xv6asm/o3/kernel.bin.aligned"
    else:
        makecmd += "../test/xv6asm/o/kernel.bin.aligned"
else:
    makecmd += "../xv6/kernel/kernel.bin.aligned"
makecmd += "\\\\\\\" "
makecmd += "-DEDISK_FILEPATH=\\\\\\\""
if USE_CACHE:
    makecmd += "../test/xv6asm/fs.img.aligned"
else:
    makecmd += "../xv6/fs.img.aligned"
makecmd += "\\\\\\\" "

# end command
makecmd += "\""

time_start = time.time()

test_status = 0
for line in get_lines(cmd=makecmd):
    print(line, end="")
    if not TEST_MODE: continue
    if test_status == 0 and "xv6 kernel is booting" in line:
        test_status = 1
        print("tester: DETECT BOOT MESSAGE")
    if test_status == 1 and "init: starting sh" in line:
        test_status = 2
        print("tester: DETECT START SH MESSAGE")
        READ_CHAR_MODE = 1 # $は改行がないので1文字ずつモードに移行
    if test_status == 2 and "$" in line:
        test_status = 3
        time_end = time.time()
        print("tester: TEST SUCCESS!")
        print("TIME:", time_end - time_start)
        exit()
exit(1)