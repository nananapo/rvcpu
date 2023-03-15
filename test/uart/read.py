import serial

ser = serial.Serial(input("input port : "), 9600)

def read1ByteInt():
    return ord(ser.read())

while True:
    i = read1ByteInt()
    c = chr(i)
    print(i, ":", c)