.section .data
lbuf:   .byte 0              # 1 byte buffer for left character
rbuf:   .byte 0              # 1 byte buffer for right character
                             # only 1 byte buffers bcz we only store ONE char at a time (O(1) space!)
                             
ymsg:   .asciz "Yes\n"       # printed if palindrome
nmsg:   .asciz "No\n"        # printed if not palindrome
fname:  .asciz "input.txt"   # file we are reading from

.section .text
.globl _start

_start:
    # opening the file "input.txt"
    li a0, -100        # AT_FDCWD: use current directory
    la a1, fname       # a1 = pointer to "input.txt"
    li a2, 0           # O_RDONLY: open for reading only
    li a3, 0           # no special permissions needed
    li a7, 56          # syscall 56 = openat
    ecall
    mv s1, a0          # s1 = file descriptor (ID number for opened file)

    # getting file size by seeking to the end
    mv a0, s1          # file descriptor
    li a1, 0           # offset = 0
    li a2, 2           # SEEK_END: go to end of file
    li a7, 62          # syscall 62 = lseek
    ecall
    mv s2, a0          # s2 = file size (position at end = size)

    beqz s2, is_palindrome  # empty file is a palindrome, nothing to check

    # checking if last character is a newline, if so ignore it
    mv a0, s1
    addi a1, s2, -1    # going to last character (size-1)
    li a2, 0           # SEEK_SET: go to exact position
    li a7, 62          # lseek
    ecall

    mv a0, s1
    la a1, rbuf        # reading into rbuf
    li a2, 1           # reading exactly 1 byte
    li a7, 63          # syscall 63 = read
    ecall

    la t3, rbuf        # loading address of rbuf
    lbu t4, 0(t3)      # t4 = last character we just read
    li t5, 10          # 10 = ASCII value of '\n'
    beq t4, t5, trim   # branch if last char IS newline
    j setup            # not newline so skip ahead

trim:
    addi s2, s2, -1    # last char is newline so reducing size by 1
    beqz s2, is_palindrome  # if file was only a newline its a palindrome
    j setup

setup:
    li s3, 0           # s3 = left pointer, starts at beginning (index 0)
    addi s4, s2, -1    # s4 = right pointer, starts at end (index size-1)
                       # e.g for "racecar"(size=7): s3=0, s4=6

check:
    bge s3, s4, is_palindrome  # if pointers met or crossed, we checked everything so its a palindrome

check_left:
    # reading left character
    mv a0, s1          # file descriptor
    mv a1, s3          # seeking to left pointer position
    li a2, 0           # SEEK_SET
    li a7, 62          # lseek
    ecall

    mv a0, s1
    la a1, lbuf        # reading into lbuf(left buffer)
    li a2, 1           # reading 1 byte
    li a7, 63          # read syscall
    ecall

check_right:
    # reading right character
    mv a0, s1          # file descriptor
    mv a1, s4          # seeking to right pointer position
    li a2, 0           # SEEK_SET
    li a7, 62          # lseek
    ecall

    mv a0, s1
    la a1, rbuf        # reading into rbuf(right buffer)
    li a2, 1           # reading 1 byte
    li a7, 63          # read syscall
    ecall

    # comparing left and right characters
    la t3, lbuf
    lbu t4, 0(t3)      # t4 = left character
    la t3, rbuf
    lbu t5, 0(t3)      # t5 = right character
    bne t4, t5, not_palindrome  # if left != right, not a palindrome

    # moving pointers inward
    addi s3, s3, 1     # left pointer moves right
    addi s4, s4, -1    # right pointer moves left
    j check            # checking next pair of characters

is_palindrome:
    li s5, 1           # s5=1 means yes its a palindrome
    j done

not_palindrome:
    li s5, 0           # s5=0 means no its not a palindrome
    j done

done:
    mv a0, s1          # closing the file
    li a7, 57          # syscall 57 = close
    ecall

    beqz s5, write_no  # if s5=0 print No

write_yes:
    li a0, 1           # stdout
    la a1, ymsg        # "Yes\n"
    li a2, 4           # 4 bytes (Y,e,s,\n)
    li a7, 64          # syscall 64 = write
    ecall
    j exit_prog

write_no:
    li a0, 1           # stdout
    la a1, nmsg        # "No\n"
    li a2, 3           # 3 bytes (N,o,\n)
    li a7, 64          # syscall 64 = write
    ecall

exit_prog:
    li a0, 0           # exit code 0
    li a7, 93          # syscall 93 = exit
    ecall