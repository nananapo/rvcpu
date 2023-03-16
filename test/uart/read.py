import serial

p = input("input port : ")
if len(p) == 0:
    p = "COM4"
ser = serial.Serial(p, 115200)

def read1ByteInt():
    return ord(ser.read())

while True:
    i = read1ByteInt()
    c = chr(i)
    print(i, ":", c, bin(i))