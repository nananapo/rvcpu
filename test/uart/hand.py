import serial

ser = serial.Serial(input("input port : "), 115200)

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

while True:
    print("--------------------")
    is_write = read1ByteInt() == 1
    print("INST : ", "STORE" if is_write else "LOAD")

    addr = read4Byte()
    print("ADDR : ", format(addr, "08x"))

    if is_write:
        data = read4Byte()
        print("DATA : ", format(data, "08x"))
    else:
        data = None

        while True:
            data = []
            S = input("DATA : ")
            if len(S) != 8:
                print("size is not 8")
                continue
            
            for i in range(0, 8, 2):
                seed = "0123456789abcdef"
                if seed.find(S[i]) == -1:
                    print("invalid value" , S[i])
                    break
                if seed.find(S[i+1]) == -1:
                    print("invalid value" , S[i+1])
                    break
                h = 0
                h += seed.index(S[i]) * 16
                h += seed.index(S[i+1])
                data.append(h)
             
            if len(data) != 4:
                continue
            break
        sendIntArray(data)
        #print("Send", data)