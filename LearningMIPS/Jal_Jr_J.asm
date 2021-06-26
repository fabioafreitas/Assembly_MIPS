.data
	texto: .asciiz "Hello"
	texto2: .asciiz " World"
.text
main:
	jal printf
	# o $ra armazena esta linha
	
li $v0, 10
syscall

printf:
	# imprimindo hello
	li $v0, 4
	la $a0, texto
	syscall
	# fim da impressao do hello
	
	#imprimindo world
	# necess�rio armazrnar o ra na pilha, pois � chamada um procedimento dentro de outro
	addi $sp, $sp, -4 # alocando 4 bytes na pilha
	sw $ra, 0($sp) # armazenando o ra do primeiro procedimento
	
	jal printf_2  # chamando outro procedimento
	# o $ra armazena esta linha 
	 
	 
	lw $ra, 0($sp) # recuperando o ra do primeiro procedimento
	addi $sp, $sp, 4 # desalocando 4 bytes da pilha
	#fim da impressao do world
	jr $ra
	
printf_2:
	li $v0, 4
	la $a0, texto2
	syscall
	jr $ra
