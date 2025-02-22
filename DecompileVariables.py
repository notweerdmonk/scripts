# Dump variables from .data segment to a C source file
#@author notweerdmonk
#@category Memory
#@keybinding 
#@menupath 
#@toolbar 


import ghidra.app.script.GhidraScript
import array
import struct

output_file = open("data_variables.c", "w")

def decode_barray(arr, type=bytearray):
    bytestr = []
    fmtstr = '<' + 'B' * len(arr)
    arr_bytes = struct.unpack(fmtstr, arr)

    last_byte = arr_bytes[-1]
    for byte in arr_bytes:
        if type == str:
            if byte > 0x80:
                bytestr.append('\\x' + hex(byte)[2:])
            elif byte == 0x5c: # \
                bytestr.append('\\\\')
            elif byte == 0xd:  # CR
                bytestr.append('\\n\\\n')
            elif byte == 0xa:  # LF
                bytestr.append('\\n\\\n')
            elif byte != 0x00:
                bytestr.append(chr(byte))

        else:
            bytestr.append(str(hex(byte)))
            if byte != last_byte:
                bytestr.append(", ")

    return ''.join(bytestr)

currentProgram = getCurrentProgram()
memory = currentProgram.getMemory()
symbol_table = currentProgram.getSymbolTable()

data_segment_name = ".data"
data_segment = None

for block in memory.getBlocks():
    if block.getName().startswith(data_segment_name):
        data_segment = block
        break

import re

if data_segment:
    start_address = data_segment.getStart()
    end_address = data_segment.getEnd()

    listing = currentProgram.getListing()

    for data in listing.getData(True):
        if start_address.compareTo(data.getMinAddress()) <= 0 and end_address.compareTo(data.getMaxAddress()) >= 0:

            symbol = symbol_table.getPrimarySymbol(data.getMinAddress())
            symbol_name = symbol.getName() if symbol else "DAT_" + str(data.getMinAddress())
            symbol_name = ''.join(map(lambda s: '_' if not re.match(r'^[a-zA-Z0-9_]$', s) else s, symbol_name))

            print(data.getDataType())
            print("Variable: {0}".format(symbol_name))
            print(" Address: {0}".format(data.getMinAddress()))
            #print(data.getLength())

            try:
                data_value = array.array('b', '\x00' * data.getLength())
                currentProgram.getMemory().getBytes(data.getMinAddress(),
                                                    data_value, 0, data.getLength())
                print(" String repr: {0}".format(data_value.tostring()))

                if isinstance(data.getDataType(), ghidra.program.model.data.IntegerDataType):
                    value = int.from_bytes(data_value, byteorder='little', signed=True)
                    output_file.write("int " + symbol_name + " = " + value + ";\n")
                elif isinstance(data.getDataType(), ghidra.program.model.data.CharDataType):
                    value = data_value
                    output_file.write("char " + symbol_name + " = " + value + ";\n")
                elif isinstance(data.getDataType(), ghidra.program.model.data.StringDataType):
                    value = decode_barray(data_value, str)
                    output_file.write('char ' + symbol_name + '[] = "' + value + '";\n')
                elif isinstance(data.getDataType(), ghidra.program.model.data.TerminatedStringDataType):
                    value = decode_barray(data_value, str)
                    output_file.write('char ' + symbol_name + '[] = "'
                                      + value.encode('utf-8') + '";\n')
                elif isinstance(data.getDataType(), ghidra.program.model.data.FloatDataType):
                    import struct
                    value = struct.unpack('<f', data_value[:4])[0]
                    output_file.write("float " + symbol_name + " = " + value + ";\n")
                elif isinstance(data.getDataType(), ghidra.program.model.data.DoubleDataType):
                    value = struct.unpack('<d', data_value[:8])[0]
                    output_file.write("double " + symbol_name + " = " + value + ";\n")
                else:
                    decoded_value = decode_barray(data_value)
                    output_file.write('unsigned char ' + symbol_name + '[] = {' + decoded_value + '};\n')

            except Exception as e:
                print("Error reading value" + str(e))

            print("-" * 40)

    output_file.close()
    print("C file generated successfully: generated_variables.c")


else:
    print("No .data segment found in the program.")
