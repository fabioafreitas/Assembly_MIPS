# programa que recebe um inteiro e retorna se ele é par ou impar

.data
	impar: .asciiz "impar"
	par: .asciiz "par"
	var1: .word 10 # parametro da função
	var2: .word 11
.text
main:
	# fazer com entrada do usuário depois
	lw $a0, var1
	jal par_impar
	
li $v0, 10
syscall

par_impar:
	add $a1, $zero, $a0
	addi $t0, $zero, 2
	div $a1, $t0
	mfhi $t1
	
	# if (t1 != 0)
	bnez $t1, else # se diferente de zero, impar
	li $v0, 4
	la $a0, par
	syscall	
	j exit
	
	else: 
	li $v0, 4
	la $a0, impar
	syscall
	exit:
	jr $ra