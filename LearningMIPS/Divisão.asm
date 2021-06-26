.data
	line: .asciiz "\n"
.text

main:	
	jal divisao_regs
	jal newline
	jal divisao_valor
	jal newline
	jal divisao_lower_register
li $v0, 10
syscall

newline:
	li $v0, 4
	la $a0, line
	syscall
	jr $ra

#divisão utilizando três registradores, destino, op1, op2
divisao_regs:
	addi $t0, $zero, 30 
	addi $t1, $zero, 5
	div $a0, $t0, $t1
	li $v0, 1
	syscall
	jr $ra

#divisão utilizando 2 registradores e um numeral, destino, op1, num
divisao_valor:
	addi $t0, $zero, 10
	div $a0, $t0, 2
	li $v0, 1
	syscall
	jr $ra
	
#divisão com dois regs, enviando o valor para lower register
divisao_lower_register:
	addi $t0, $zero, 81
	addi $t1, $zero, 27
	div $t0, $t1
	mflo $s0 #Quociente é armazenado em low register
	mfhi $s1 #Resto é armazenado em high register
	add $a0, $zero, $s0
	li $v0, 1
	syscall
	jr $ra
	
	