.data
fmt_int: .string "%d"
fmt_spc: .string " "
fmt_nl:  .string "\n"

arr: .space 400       # input array
res: .space 400       # result array
stk: .space 400       # stack storing INDICES

.text
.globl main
main:
    addi sp, sp, -16
    sd ra, 0(sp)
    sd s0, 8(sp)

    # s0 = n = argc - 1
    addi s0, a0, -1

    mv t0, s0           # counter
    la t1, arr
    addi a1, a1, 8      # skip program name

read_loop:
    beqz t0, read_done

    addi sp, sp, -24
    sd a1, 0(sp)
    sd t0, 8(sp)
    sd t1, 16(sp)

    ld a0, 0(a1)
    call atoi

    ld a1, 0(sp)
    ld t0, 8(sp)
    ld t1, 16(sp)
    addi sp, sp, 24

    sw a0, 0(t1)        # arr[i] = atoi(argv[i+1])

    addi t1, t1, 4
    addi t0, t0, -1
    addi a1, a1, 8
    j read_loop

read_done:
    # initialise result array to -1
    la t1, res
    mv t0, s0
init_loop:
    beqz t0, init_done
    li t2, -1
    sw t2, 0(t1)
    addi t1, t1, 4
    addi t0, t0, -1
    j init_loop
init_done:

    la s1, arr          # s1 = arr base
    la s2, stk          # s2 = stack base (stores indices)
    la s3, res          # s3 = result base
    li s4, 0            # s4 = stack size

    # i = n-1 down to 0
    addi t4, s0, -1     # t4 = i = n-1

process:
    bltz t4, print      # if i < 0, done

    # while stack not empty AND arr[stack.top()] <= arr[i]: pop
    # actually pseudocode pops while arr[stack.top()] <= arr[i]
    # meaning keep only indices where arr[idx] > arr[i]

    # load arr[i]
    slli t0, t4, 2
    add t0, t0, s1
    lw t0, 0(t0)        # t0 = arr[i]

pop_loop:
    beqz s4, no_greater

    addi t1, s4, -1
    slli t1, t1, 2
    add t1, t1, s2
    lw t2, 0(t1)        # t2 = stack top INDEX

    # compute arr[t2]
    slli t3, t2, 2
    add t3, t3, s1
    lw t3, 0(t3)        # t3 = arr[stack.top()]

    bgt t3, t0, found   # if arr[top] > arr[i], found it
    addi s4, s4, -1     # else pop
    j pop_loop

no_greater:
    # result[i] = -1 (already initialised)
    j push_and_next

found:
    # result[i] = stack.top() = t2 (index)
    slli t1, t4, 2
    add t1, t1, s3
    sw t2, 0(t1)        # res[i] = top index

push_and_next:
    # push i onto stack
    slli t1, s4, 2
    add t1, t1, s2
    sw t4, 0(t1)        # stack[s4] = i
    addi s4, s4, 1

    addi t4, t4, -1     # i--
    j process

print:
    la s1, res
    mv t0, s0
    li t5, 0            # first element flag

print_loop:
    beqz t0, print_nl

    beqz t5, no_space   # skip space before first element

    addi sp, sp, -16
    sd t0, 0(sp)
    sd s1, 8(sp)
    la a0, fmt_spc
    call printf
    ld t0, 0(sp)
    ld s1, 8(sp)
    addi sp, sp, 16

no_space:
    li t5, 1

    addi sp, sp, -16
    sd t0, 0(sp)
    sd s1, 8(sp)
    lw a1, 0(s1)
    la a0, fmt_int
    call printf
    ld t0, 0(sp)
    ld s1, 8(sp)
    addi sp, sp, 16

    addi t0, t0, -1
    addi s1, s1, 4
    j print_loop

print_nl:
    la a0, fmt_nl
    call printf

    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    li a0, 0
    ret