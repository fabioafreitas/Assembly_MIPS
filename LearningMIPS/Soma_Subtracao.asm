.data
	x: .word 5
	y: .word 4
	feedline: .asciiz "\n"
.text
main:
	jal soma_registradores
	jal breakline
	jal soma_imediato
	jal breakline
	jal subtracao_registradores
	jal breakline
	jal subtracao_imediato
li $v0, 10
syscall

soma_registradores:
	lw $a1, y
	lw $a2, x
	add $a0, $a2, $a1 # z = x + y
	li $v0, 1
	syscall
	jr $ra
	
soma_imediato:
	lw $a1, y
	lw $a2, x
	addi $a0, $a2, 1 # z = x + 1
	li $v0, 1
	syscall
	jr $ra
	
subtracao_registradores:
	lw $a1, y
	lw $a2, x
	sub $a0, $a2, $a1 # z = x - y
	li $v0, 1
	syscall
	jr $ra
	
subtracao_imediato:
	lw $a1, y
	lw $a2, x
	subi $a0, $a2, 1 # z = x - 1
	li $v0, 1
	syscall
	jr $ra

breakline:
	li $v0, 4
	la $a0, feedline
	syscall
	jr $ra