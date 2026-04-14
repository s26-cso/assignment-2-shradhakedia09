[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)



### Q3 PART A
1) Identified binary architecture 

I had some problems with my riscv setup.
```bash
file ./target_shradhakedia09
```
Finding: ELF 64-bit RISC-V binary, statically linked, not stripped

2) Dissembled main fucniton
```bash
riscv64-linux-gnu-objdump -d ./target_shradhakedia09 | grep -A 50 "<main>"
```
Finding: The wprkflow of the program:

         1) Takes input via scanf
         
         2)Compares it with a stored string using strcmp
         
         3)Prints pass/fail message
        
3) Dumped read only data section
```bash
readelf -p .rodata ./target_shradhakedia09
```
Finding: Found the password stored in plaintext: nJuqiSORt2NMPi1Qu5YjJJey98MIhzvFCUF0WSK5HPk=

4) Verified the pwd:
```bash
echo "nJuqiSORt2NMPi1Qu5YjJJey98MIhzvFCUF0WSK5HPk=" | qemu-riscv64-static ./target_shradhakedia09
```

op: You have passed!



### Q3 PART B
1) Identified Vulnerability
```bash
riscv64-linux-gnu-objdump -d ./target_shradhakedia09 | grep -A 50 "<main>"
```

Finding: Program uses gets() which has no bounds checking

104d0: addi sp,sp,-304    # 304 byte buffer allocated
104d8: jalr _IO_gets      # gets() called - VULNERABLE!



2) Understood stack layout:

High Address

return address <- 8 bytes (we overwrite this!)

saved s0 <- 8 bytes

304 byte buf <- our input goes here

Low Address

3) FOund target address:
``` bash
# .pass block is at 0x104e8
000000000104e8 <.pass>:
    jalr _IO_printf    # prints "You have passed!"
```

4) Made payload:

[304 bytes 'A'] : fills buffer 

[8 bytes 'B']  : overwrites s0

[0x104e8 little endian]: return address

```bash
python3 -c "
import sys
# Adjust offset (e.g., 72 bytes) based on your analysis
padding = b'A' * 72
# Add return address or target bytes
payload = padding + b'\x42\x42\x42\x42'
sys.stdout.buffer.write(payload)
" > payload
```


5) Testing payload:
```bash
qemu-riscv64 ./target_shradhakedia09 < payload
# "You have passed!" is printed amongst others
```