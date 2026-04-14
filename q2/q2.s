.data
fmt_int: .string "%d"          # format string for printing an integer
fmt_spc: .string " "           # space separator between output numbers
fmt_nl:  .string "\n"          # newline at end of output

arr: .space 400       # input array (stores the IQ values, max 100 elements)
res: .space 400       # result array (stores next greater element INDEX for each position)
stk: .space 400       # stack storing INDICES (used for O(n) monotonic stack algorithm)

.text
.globl main
main:
    addi sp, sp, -16
    sd ra, 0(sp)                # saving return address
    sd s0, 8(sp)                # saving s0 (callee-saved)

    # s0 = n = argc - 1
    # argc includes program name, so actual number of elements is argc-1
    addi s0, a0, -1

    mv t0, s0           # t0 = counter (how many elements left to read)
    la t1, arr          # t1 = pointer to current position in arr
    addi a1, a1, 8      # skip program name (argv[0]), point to argv[1]

read_loop:
    beqz t0, read_done          # if counter == 0, done reading

    # saving registers before calling atoi (t-registers are caller-saved)
    addi sp, sp, -24
    sd a1, 0(sp)                # save argv pointer
    sd t0, 8(sp)                # save counter
    sd t1, 16(sp)               # save arr pointer

    ld a0, 0(a1)                # a0 = argv[i] (pointer to string)
    call atoi                   # convert string to integer, result in a0

    # restoring registers after atoi
    ld a1, 0(sp)
    ld t0, 8(sp)
    ld t1, 16(sp)
    addi sp, sp, 24

    sw a0, 0(t1)        # arr[i] = atoi(argv[i+1]), storing converted integer

    addi t1, t1, 4              # move arr pointer to next element (4 bytes per int)
    addi t0, t0, -1             # decrement counter
    addi a1, a1, 8              # move to next argv pointer (8 bytes per pointer)
    j read_loop

read_done:
    # initialise result array to -1
    # -1 means "no greater element exists to the right"
    la t1, res                  # t1 = pointer to result array
    mv t0, s0                   # t0 = counter
init_loop:
    beqz t0, init_done          # if counter == 0, done initialising
    li t2, -1
    sw t2, 0(t1)                # res[i] = -1 (default: no greater element)
    addi t1, t1, 4              # move to next element
    addi t0, t0, -1             # decrement counter
    j init_loop
init_done:

    la s1, arr          # s1 = arr base address
    la s2, stk          # s2 = stack base address (stack stores indices, not values)
    la s3, res          # s3 = result base address
    li s4, 0            # s4 = stack size (starts empty)

    # i = n-1 down to 0
    # we traverse RIGHT TO LEFT so that when we check the stack,
    # it already contains info about elements to our right
    addi t4, s0, -1     # t4 = i = n-1 (starting from last element)

process:
    bltz t4, print      # if i < 0, we've processed all elements, go print

    # loading arr[i] into t0 for comparison
    # arr[i] is at address: arr_base + i*4 (4 bytes per int)
    slli t0, t4, 2              # t0 = i * 4 (byte offset)
    add t0, t0, s1              # t0 = &arr[i]
    lw t0, 0(t0)                # t0 = arr[i] (current element value)

pop_loop:
    # popping elements from stack that are <= arr[i]
    # these can NEVER be the next greater element for any future (leftward) element
    # because arr[i] is already greater and comes before them
    beqz s4, no_greater         # if stack is empty, no greater element exists

    addi t1, s4, -1             # t1 = index of top element (size-1)
    slli t1, t1, 2              # t1 = (size-1) * 4 (byte offset)
    add t1, t1, s2              # t1 = &stk[top]
    lw t2, 0(t1)                # t2 = stack top VALUE (which is an INDEX into arr)

    # checking if arr[stack.top()] > arr[i]
    slli t3, t2, 2              # t3 = t2 * 4 (byte offset for arr)
    add t3, t3, s1              # t3 = &arr[stack.top()]
    lw t3, 0(t3)                # t3 = arr[stack.top()] (value at that index)

    bgt t3, t0, found           # if arr[top] > arr[i], top is our answer!
    addi s4, s4, -1             # else pop: this element is useless for future comparisons
    j pop_loop

no_greater:
    # stack is empty: no element to the right is greater than arr[i]
    # res[i] stays -1 (already initialised)
    j push_and_next

found:
    # t2 = index of next greater element for position i
    # storing this index in res[i]
    slli t1, t4, 2              # t1 = i * 4 (byte offset)
    add t1, t1, s3              # t1 = &res[i]
    sw t2, 0(t1)                # res[i] = index of next greater element

push_and_next:
    # pushing current index i onto stack
    # future elements (to the left) might find arr[i] as their next greater
    slli t1, s4, 2              # t1 = size * 4 (byte offset for new top)
    add t1, t1, s2              # t1 = &stk[size]
    sw t4, 0(t1)                # stk[top] = i (pushing index, not value)
    addi s4, s4, 1              # incrementing stack size

    addi t4, t4, -1     # i-- (moving left to next element)
    j process

print:
    # printing result array as space-separated integers
    la s1, res                  # s1 = pointer to result array
    mv t0, s0                   # t0 = counter (n elements to print)
    li t5, 0                    # t5 = first element flag (0 = first, 1 = not first)
                                # used to avoid printing leading space

print_loop:
    beqz t0, print_nl           # if counter == 0, print newline and done

    beqz t5, no_space           # if first element, skip printing space

    # printing space separator between elements
    addi sp, sp, -16
    sd t0, 0(sp)                # saving counter
    sd s1, 8(sp)                # saving result pointer
    la a0, fmt_spc              # a0 = " "
    call printf
    ld t0, 0(sp)
    ld s1, 8(sp)
    addi sp, sp, 16

no_space:
    li t5, 1                    # after first element, always print space before next

    # printing current result value
    addi sp, sp, -16
    sd t0, 0(sp)                # saving counter
    sd s1, 8(sp)                # saving result pointer
    lw a1, 0(s1)                # a1 = res[i] (the next greater index, or -1)
    la a0, fmt_int              # a0 = "%d"
    call printf
    ld t0, 0(sp)
    ld s1, 8(sp)
    addi sp, sp, 16

    addi t0, t0, -1             # decrement counter
    addi s1, s1, 4              # move to next result element (4 bytes per int)
    j print_loop

print_nl:
    la a0, fmt_nl               # printing final newline
    call printf

    # restoring callee-saved registers and returning
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    li a0, 0                    # return 0 (success)
    ret