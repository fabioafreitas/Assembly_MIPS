li $v0, 30
syscall
move $t0, $a0

#sleep
li $v0, 32
li $a0, 10000
syscall

li $v0, 30
syscall
move $t1, $a0

sub $t2, $t1, $t0
div $t2, $t2, 1000

move $a0, $t2
li $v0, 1
syscall