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
    # a0 = root pointer, a1 = value to insert
    beqz a0, make_new_root    # if root == NULL, create new root

    # Save root so we can return it at the end
    addi sp, sp, -32
    sd ra, 0(sp)
    sd a0, 8(sp)              # save original root
    sd a1, 16(sp)             # save value (in case clobbered)

    mv t0, a0                 # t0 = current node
    li t1, 0                  # t1 = parent = NULL

loop:
    beqz t0, insert_here      # if current == NULL, insert here

    mv t1, t0                 # parent = current
    lw t2, 0(t0)              # t2 = current node value

    blt a1, t2, go_l          # if val < node val, go left
    blt t2, a1, go_r          # if val > node val, go right
    
    # equal: value already exists, do nothing
    ld ra, 0(sp)
    ld a0, 8(sp)              # return original root
    addi sp, sp, 32
    ret

go_l:
    ld t0, 8(t0)              # t0 = current->left
    j loop

go_r:
    ld t0, 16(t0)             # t0 = current->right
    j loop

insert_here:
    # t1 = parent node (guaranteed non-NULL since root wasn't NULL)
    # a1 = value to insert
    # Need to save t1 across call to make_node (caller-saved, may be clobbered)
    
    sd t1, 24(sp)             # save parent pointer

    mv a0, a1                 # a0 = value for make_node
    call make_node            # allocate new node, returned in a0
    mv t3, a0                 # t3 = new node pointer

    ld t1, 24(sp)             # restore parent pointer
    ld a1, 16(sp)             # restore value

    lw t2, 0(t1)              # t2 = parent->val

    blt a1, t2, attach_left

attach_right:
    sd t3, 16(t1)             # parent->right = new node
    j restore_and_return

attach_left:
    sd t3, 8(t1)              # parent->left = new node

restore_and_return:
    ld ra, 0(sp)
    ld a0, 8(sp)              # return ORIGINAL root
    addi sp, sp, 32
    ret

make_new_root:
    # root was NULL, so new node IS the root
    # no need to save/restore, just call make_node and return
    mv a0, a1
    call make_node            # new root returned in a0
    ret


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