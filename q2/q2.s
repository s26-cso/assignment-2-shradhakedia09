.data

fmt_int: .string "%d"        # format for printf
fmt_spc: .string " "         # space between outputs
fmt_nl:  .string "\n"        # newline at end
answers: .space 400          # stores answers(will get overwritten with results)
originals: .space 400        # stores original values(we never touch this one)
mystack: .space 400          # our stack

# since it is command line arg, argv in a1, argc in a0
# n. of integers = argc-1, cuz we ignore the name of the cmd
.text
.global main 
main:

    addi sp, sp, -8
    sd ra, 0(sp)
    #saving ra so return address is not lost

    #also store no. of ints in s1
    addi s1, a0, -1    #s1 = argc-1 = number of integers

    addi t3, a0, -1    #t3 = counter for input loop
    la t4, answers     #t4 = pointer into answers
    addi a1, a1, 8     #skipping program name in argv

    read_args:
        beq zero, t3, args_done  #all numbers parsed, exit loop

        #t3, t4, a1 need to be saved to sp, since atoi will overwrite them
        addi sp, sp, -24
        sd a1, 0(sp)
        sd t3, 8(sp)
        sd t4, 16(sp)

        ld a0, 0(a1)   #loading current argv string

        call atoi      #converting string to int, result comes back in a0

        #restoring regs after atoi
        ld a1, 0(sp)
        ld t3, 8(sp)
        ld t4, 16(sp)        
        addi sp, sp, 24

        sw a0, 0(t4)   #storing the integer we got from atoi into answers

        addi t4, t4, 4  #moving to next answers slot (4 bytes cuz int)

        addi t3, t3, -1 #one int parsed, decrement counter

        addi a1, a1, 8  #moving to next argv string

        j read_args

    args_done:

        # copying answers into originals so we always have the original values
        # answers will get overwritten with results but originals will not change
        la t3, answers
        la t4, originals
        mv t5, s1
    make_copy:
        beqz t5, copy_finished
        lw t6, 0(t3)        #loading from answers
        sw t6, 0(t4)        #storing into originals
        addi t3, t3, 4      #moving to next answers slot
        addi t4, t4, 4      #moving to next originals slot
        addi t5, t5, -1     #decrementing counter
        j make_copy
    copy_finished:
    
    #input is done, now we use the stack

    init_stack:
        #s1 has no. of elements
        la s2, answers
        addi t3, s1, 0      #t3 = no. of elements left to be processed

        la s3, mystack
        li s4, 0            #s4 tracks no. of elements in stack

        #s6 = base of originals, we do not touch this one
        la s6, originals

        #setting s2 to point to last element of answers
        li t5, 4
        mul t4, s1, t5
        
        add s2, t4, s2
        addi s2, s2, -4     #s2 = answers + (n-1)*4, pointing to last element

        #pushing index (n-1) onto stack
        addi t4, s1, -1
        sw t4, 0(s3)
        addi s4, s4, 1

        #overwriting answers[n-1] with -1 since it has no next greater element
        li t4, -1
        sw t4, 0(s2)

        addi s2, s2, -4     #moving left to second last element
        addi t3, t3, -1     #one element processed

    find_next_greater:
        #processing n-1 elements from right to left
        #if t3=0, we are done
        beq t3, zero, print_answers

        la s5, answers

        #loading original value of answers[i] from originals, not answers
        #bcz answers is being overwritten with results
        sub t6, s2, s5
        srai t6, t6, 2
        slli t6, t6, 2
        add t6, t6, s6
        lw t4, 0(t6)        #t4 = original value at current position

        pop_stk:
            #if stack is empty, no next greater exists
            beq s4, zero, no_greater

            #peeking at stack top (its an index not a value)
            #s4 tracks no. of elements, s3 keeps base address always
            addi t5, s4, -1
            slli t5, t5, 2
            add t5, t5, s3
            lw t5, 0(t5)    #t5 = index at top of stack

            #loading originals[mystack[top]] to get actual value at that index
            #loading from originals not answers, bcz answers[mystack[top]] might already be overwritten
            slli t6, t5, 2
            add t6, t6, s6
            lw t6, 0(t6)    #t6 = value at that index

            bgt t6, t4, found_greater   
            #if mystack[top] value > answers[i], answer is t5(the index)

            #popping since mystack[top] <= answers[i]
            addi s4, s4, -1
            j pop_stk

            no_greater:
            #by default we put -1 to answers[i] if there is no next greater
                li t5, -1
            
            found_greater:
                sw t5, 0(s2)    #storing answer(index or -1) into answers[i]

                #getting current index i
                sub t5, s2, s5
                srai t5, t5, 2  #t5 = current index i

                #pushing current index i onto the stack
                slli t6, s4, 2
                add t6, t6, s3
                sw t5, 0(t6)
                addi s4, s4, 1

                addi s2, s2, -4 #moving left to next element
                addi t3, t3, -1 #one more element processed

                j find_next_greater

    print_answers:
        la s2, answers      #resetting s2 to start of answers
        mv t3, s1           #t3 = n, will count down

    output_loop:
        beqz t3, output_done #printed all elements, done

        #saving regs since printf will overwrite them
        addi sp, sp, -32
        sd s1, 0(sp)
        sd s2, 8(sp)
        sd s4, 16(sp)
        sd t3, 24(sp)

        lw a1, 0(s2)    #a1 = answers[i], the answer for this position
        la a0, fmt_int  #format string "%d"
        call printf

        ld s1, 0(sp)
        ld s2, 8(sp)
        ld s4, 16(sp)
        ld t3, 24(sp)
        addi sp, sp, 32

        addi t3, t3, -1 #one less to print
        addi s2, s2, 4  #moving to next element

        beqz t3, output_done #if that was the last one, skip the space

        #printing space between elements
        addi sp, sp, -32
        sd s1, 0(sp)
        sd s2, 8(sp)
        sd s4, 16(sp)
        sd t3, 24(sp)

        la a0, fmt_spc
        call printf

        ld s1, 0(sp)
        ld s2, 8(sp)
        ld s4, 16(sp)
        ld t3, 24(sp)
        addi sp, sp, 32

        j output_loop

    output_done:
        la a0, fmt_nl   #newline at the end
        call printf

        ld ra, 0(sp)    #restoring ra before returning
        addi sp, sp, 8
        li a0, 0
        ret