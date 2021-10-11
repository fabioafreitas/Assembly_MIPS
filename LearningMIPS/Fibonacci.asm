.data
msg1: .asciiz "Give a number: "

.text
.globl main
main:
    li $a0, 4 # function args
    jal fib             # call fib

    move $a0, $v0
    li  $v0, 1
    syscall
li $v0, 10
syscall

fib:
    # $a0 = y
    # if (y == 0) return 0;
    # if (y == 1) return 1;
    # return fib(y - 1) + fib(y - 2);

    #save in stack
    addi $sp, $sp, -12 
    sw   $ra, 0($sp)
    sw   $s0, 4($sp) # $s0 armazena os args
    sw   $s1, 8($sp) # $s1 armazena o resultado

    move $s0, $a0

    beq  $s0, 0, return0
    beq  $s0, 1, return1

    addi $a0, $s0, -1

    jal fib

    add $s1, $zero, $v0         # $s1 = fib(y - 1)

    addi $a0, $s0, -2

    jal fib                     # $v0 = fib(n - 2)

    add $v0, $v0, $s1           # $v0 = fib(n - 2) + $s1

    exitfib:

        lw   $ra, 0($sp)        # read registers from stack
        lw   $s0, 4($sp)
        lw   $s1, 8($sp)
        addi $sp, $sp, 12       # bring back stack pointer
        jr $ra

    return1:
        li $v0,1
        j exitfib

    return0:     
        li $v0,0
        j exitfib
