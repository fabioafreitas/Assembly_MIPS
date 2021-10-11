.macro print_text(%var)
	li $v0, 4
	la $a0, %var
	syscall
.end_macro 

.data
	texto: .asciiz "Hello"
	texto2: .asciiz " World"
	
.text
main:
	jal printf
li $v0, 10
syscall

printf:
	print_text(texto)
	
	# necessário armazrnar o ra na pilha, pois é chamada um procedimento dentro de outro
	addi $sp, $sp, -4 # alocando 4 bytes na pilha
	sw $ra, 0($sp) # armazenando o ra do primeiro procedimento
	
	jal printf_2  # chamando outro procedimento
	# o $ra armazena esta linha 
	
	lw $ra, 0($sp) # recuperando o ra do primeiro procedimento
	addi $sp, $sp, 4 # desalocando 4 bytes da pilha
	#fim da impressao do world
	add $t0, $t0, $zero
	
	jr $ra
	
printf_2:
	print_text(texto2)
	jr $ra
