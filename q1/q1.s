# node layout: [0-3]: int value, [8-15]: left child pointer, [16-23]: right child pointer

.text

    .globl make_node

make_node:
    addi sp, sp, -16
    sd ra, 8(sp)           #saving ra
    sw a0, 4(sp)           #saving a0 onto stack

    li a0, 24              #4 bytes for value+ 8 bytes for left pointer+ 8 bytes for right pointer
    call malloc            #result(pointer) returned in a0

    lw t4, 4(sp)           #relaoding saved value from stack into t4.
    sw t4, 0(a0)           #store value of new node(at offset 0)
    sd zero, 8(a0)         # store NULL for left child(offest 8 from a0)
    sd zero, 16(a0)        #store NULL for right child(offest 16 from a0)

    ld ra, 8(sp)           #laoding ra to sp
    addi sp, sp, 16 
    ret                    # return (a0 has pointer to new node NOW)


    .globl insert

insert:
    addi sp, sp, -24       # growing stack by 24 bytes
    sd ra, 16(sp)          # save ra
    sd a0, 8(sp)           #save a0(pointer to node)
    sw a1, 4(sp)           #save value(a1)

    beqz a0, new_node      #if node==NULL, jump to fucntion new_node

    lw t4, 0(a0)           #laod node->value to t4
    lw t5, 4(sp)           #relaod value we want to add (newnode->val)

    blt t4, t5, go_right   #if val > node->val we go right
    blt t5, t4, go_left    #if val < node->val we go left [t4: current_node->val, t5: new_node->val]
    j finish_insert        #if equal, we do nothing

go_left:
    ld t3, 8(a0)           # t3=node->left
    mv a0, t3              #a0=node->left
    mv a1, t5              #a1=value of new node
    call insert            #recrusivelt adding into left subtree
    ld t6, 8(sp)           #relaod orignal node pointer
    sd a0, 8(t6)           # node->left= result of recursive call
    mv a0, t6              #retuning original node
    j finish_insert

go_right:
    ld t3, 16(a0)          #same as go_left but everything happens in terms of the right subtree
    mv a0, t3
    mv a1, t5
    call insert
    ld t6, 8(sp)
    sd a0, 16(t6)
    mv a0, t6
    j finish_insert

new_node:
    lw a0, 4(sp)           #load value from stack
    call make_node         #creating a new node with that value [a0 now has a pointer to new node]

finish_insert:
    ld ra, 16(sp)          #reloading ra
    addi sp, sp, 24
    ret                    #return node pointer in a0


    .globl get

get:
search_loop:               #a0= node, a1= search_val
    li t5, 0
    beq a0, t5, val_missing # if node ==NULL, not found

    lw t4, 0(a0)           #t4=a0(node->val)
    beq t4, a1, val_found  #if t4==a1 [node value=search value], go to val_found
    blt a1, t4, check_left #if a1<t4[search val<node val] go to the left subtree

    ld a0, 16(a0)          #go right :a0= node->right
    j search_loop

check_left:
    ld a0, 8(a0)           # go to left subtree [a0=node->left]
    j search_loop

val_found:
    ret                    #return a0 which has the node pointer

val_missing:
    li a0, 0               # return NULL(0)
    ret


    .globl getAtMost

getAtMost:                 #a0: search val, a1: node pointer, t4=node->val
    li t3, -1              #t3 stores the result and is initialsed to -1(not found)

scan_loop:
    beqz a1, scan_done     #if node==NULL we are done

    lw t4, 0(a1)           # t4= node->val 
    bgt t4, a0, scan_left  #if node->val > search_val go left

    mv t3, t4              #t3=t4(result = node->value) [best candidate so far]
    ld a1, 16(a1)          #a1= node->right
    j scan_loop

scan_left:
    ld a1, 8(a1)           # go left: a1= node->left
    j scan_loop

scan_done:
    mv a0, t3              #moce result into a0
    ret