.data
	feedline: .asciiz "\n"
.text
main:
	jal multiplicacao_mul
	jal breakline
	jal multiplicacao_mult
	jal breakline
	jal multiplicacao_sll
li $v0, 10
syscall

multiplicacao_mul: # Multiplicação sem overflow
	li $t0, 9
	li $t1, 9
	mul $a0, $t0, $t1   
	li $v0, 1
	syscall
	jr $ra

multiplicacao_mult: # Armazena o produto no registrador lo, Lower Register.
	li $t0, 1000
	li $t1, 400
	mult $t0, $t1
	mflo $a0 
	li $v0, 1
	syscall
	jr $ra
	
multiplicacao_sll: # Shift Left Logical, move a cadeia de bits de acordo com o imediado especificado
		   # isto simula é equivalente a uma multiplicação
	li $t0, 4
	sll $a0, $t0 ,2
	li $v0, 1
	syscall
	jr $ra

breakline:
	li $v0, 4
	la $a0, feedline
	syscall
	jr $ra
	
	
	
