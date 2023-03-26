import serial
import sys

port = sys.argv[1] if len(sys.argv) > 1 else input("port : ")
memfileName = sys.argv[2] if len(sys.argv) > 2 else input("file : ")
memorySize = 1024 * 1024 * 8

ser = serial.Serial(port, 115200)

def read1ByteInt():
    return ord(ser.read())

def read4Byte():
    data = 0
    data += read1ByteInt() << 24
    data += read1ByteInt() << 16
    data += read1ByteInt() << 8
    data += read1ByteInt() << 0
    return data

def sendInt(b):
    ser.write(bytearray([b]))

def sendIntArray(b):
    for i in b:
        sendInt(i)

def hex2int(S):
    r = []
    for i in range(0, 8, 2):
        seed = "0123456789abcdef"
        h = 0
        h += seed.index(S[i]) * 16
        h += seed.index(S[i+1])
        r.append(h)
    return r

memory = []
with open(memfileName, "r") as f:
    for line in  f.readlines():
        ary = hex2int(line)
        memory.append(ary)

for i in range(memorySize // 4 - len(memory)):
    memory.append([255,255,255,255])

while True:
    is_write = read1ByteInt() == 1
    addr = read4Byte()
    if is_write:
        data = []
        data.append(read1ByteInt())
        data.append(read1ByteInt())
        data.append(read1ByteInt())
        data.append(read1ByteInt())
        memory[addr // 4] = data
        print(format(addr, "08x"), " <- ", format(data, "08x"))
    else:
        data = memory[addr // 4]
        print(format(addr, "08x"), " -> ", format(data, "08x"))
        sendIntArray(data)