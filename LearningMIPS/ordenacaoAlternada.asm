.data
	list: 	 .space 20
	msg1:  .asciiz "Insira um inteiro: "
	msg2:  .asciiz "valor: "
	linha: .asciiz "\n"
	espaco:.asciiz "  "
	pointer: .word 0

#$s0 - guarda o valor do vetor
#$s1 - guarda o tamanho real do vetor (n*5)
#$s2 - guarda o tamanho em bytes do vetor (n*5*4)
.text
main:
	jal printMenssagem1
	jal lerInt
	move $s0, $v0
	mul $s1, $s0, 5
	sll $s2, $s1, 2
	
	move $a0, $s2
	jal alocarVetor
	la $t0, pointer
	sw $v0, 0($t0)
	
	
	li $s3, 0
	loop_main:
	beq $s3, $s0, end_loop_main
		jal preencherVetorAuxiliar
		
		li $t0, 2
		div $s3, $t0
		mfhi $t0
		bne $t0, $zero, impar
			jal bubbleSortCrescente
			j end_condicao
		impar:
			jal bubbleSortDecrescente
		end_condicao:
		
		li $t0, 0
		li $t1, 5
		loop_interno:
		beq $t0, $t1, end_loop_interno
			
			la $t2, list
			lw $t3, pointer
			
			#posicao da list
			sll $s4, $t0, 2
			add $s4, $s4, $t2
			lw $s5, 0($s4)
			
			#posicao de pointer
			mul $s6, $s3, 5
			add $s6, $s6, $t0
			sll $s6, $s6, 2
			add $s6, $s6, $t3
			sw $s5, 0($s6) 
			
		addi $t0, $t0, 1
		j loop_interno
		end_loop_interno:
	addi $s3, $s3, 1
	j loop_main
	end_loop_main:
	
	
	li $t0, 0
	move $t1, $s1
	li $t2, 5
	loop_print:
	beq $t0, $t1, end_loop_print
		
		div $t0, $t2
		mfhi $t4
		bne $t4, $zero, condicao
			jal printNovaLinha
		condicao:
		
		lw $t3, pointer
		sll $t5, $t0, 2
		add $t5, $t5, $t3
		lw $a0, 0($t5)
		jal printInteiro
		jal printEspaco
		
	addi $t0, $t0, 1
	j loop_print
	end_loop_print:
	
li $v0, 10
syscall

# preenche o vetor auxiliar, de 5 posições (list)
preencherVetorAuxiliar:
	li $t0, 0
	li $t1, 5
	loop_vetor_aux:
	beq $t0, $t1, end_loop_vetor_aux
	
		li $v0, 4
		la $a0, msg2
		syscall
	
		li $v0 5
		syscall
		move $t2, $v0
		
		la $a0, list
		sll $t3, $t0, 2
		add $t3, $t3, $a0
		sw $t2, 0($t3)
	addi $t0, $t0, 1
	j loop_vetor_aux
	end_loop_vetor_aux:
jr $ra

# ordena o vetor da variável list
bubbleSortCrescente:
	la $a0, list
	li $t0, 0
	li $t1, 5
	loopSort:
	beq $t0, $t1, endSort
		addi $t2, $t0, 1
		loopSortInterno:
		beq $t2, $t1, endSortInterno
			sll $t3, $t0, 2
			add $t3, $t3, $a0
			sll $t4, $t2, 2
			add $t4, $t4, $a0
			lw $t5, 0($t3)
			lw $t6, 0($t4)
			bgt $t6, $t5, condicaoSort
				sw $t5, 0($t4)
				sw $t6, 0($t3)
			condicaoSort:
		addi $t2, $t2, 1
		j loopSortInterno
		endSortInterno:
	addi $t0, $t0, 1
	j loopSort
	endSort:
jr $ra

# ordena o vetor da variável list
bubbleSortDecrescente:
	la $a0, list
	li $t0, 0
	li $t1, 5
	loopSortDec:
	beq $t0, $t1, endSortDec
		addi $t2, $t0, 1
		loopSortInternoDec:
		beq $t2, $t1, endSortInternoDec
			sll $t3, $t0, 2
			add $t3, $t3, $a0
			sll $t4, $t2, 2
			add $t4, $t4, $a0
			lw $t5, 0($t3)
			lw $t6, 0($t4)
			blt $t6, $t5, condicaoSortDec
				sw $t5, 0($t4)
				sw $t6, 0($t3)
			condicaoSortDec:
		addi $t2, $t2, 1
		j loopSortInternoDec
		endSortInternoDec:
	addi $t0, $t0, 1
	j loopSortDec
	endSortDec:
jr $ra

#Armazena a leitura em $v0
lerInt:
	li $v0, 5
	syscall
jr $ra

printMenssagem1:
	li $v0, 4
	la $a0, msg1
	syscall
jr $ra


printNovaLinha:
	li $v0, 4
	la $a0, linha
	syscall
jr $ra

printEspaco:
	li $v0, 4
	la $a0, espaco
	syscall
jr $ra

#recebe o valor a ser impresso em $a0
printInteiro:
	li $v0 1
	syscall
jr $ra

# recebe o tamanho do vetor em $a0
# retorna o ponteiro do array em $v0
alocarVetor:
	li $v0, 9
	syscall
jr $ra
