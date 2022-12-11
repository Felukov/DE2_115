import serial

filename = "/home/fila/work/DE2_115/tbs/cpu86/snake/cstart.com"

s = serial.Serial("/dev/ttyUSB0", 115200)

with open(filename, mode="rb") as f:
    bytes_stream = f.read()

    #prefix
    b = 0x11
    s.write(b.to_bytes(1, byteorder='big'))
    b = 0x55
    s.write(b.to_bytes(1, byteorder='big'))

    #len
    b_len = len(bytes_stream)
    s.write(b_len.to_bytes(2, byteorder='big'))

    #program
    s.write(bytes_stream)
