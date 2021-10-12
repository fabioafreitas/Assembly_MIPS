# returna numero aleatorio em $v0
.macro rand(%upperbound)
	li $a1, %upperbound
	li $v0, 42
	syscall
	move $v0, $a0
.end_macro

# print o inteiro armazenado no registrador passado como param
.macro print_int(%register_with_number)
	move $a0, %register_with_number
	li $v0, 1
	syscall
.end_macro

# print o inteiro armazenado no registrador passado como param
.macro print_virgula()
	la $a0, comma
	li $v0, 4
	syscall
.end_macro


.data
	# espaço de memoria contendo 40 bytes
	# cada bloco de memoria possui 4 bytes
	# logo, este label representa um vetor
	# de 10 elementos
	vetor: .space 40
	vetor_len: .word 10
	comma: .asciiz ", "
	
.text
	la $s0, vetor
	lw $s1, vetor_len
	
	# armazenando numeros aleatorios no vetor
	li $t0, 0
	while:
	bgt $t0, $s1, end
		sll $t1, $t0, 2
		add $t1, $t1, $s0
		rand(100)
		sw $v0, 0($t1)
		addi $t0, $t0, 1
	j while
	end:
	
	
	# printando o vetor
	li $t0, 0
	while2:
	bgt $t0, $s1, end2
		sll $t1, $t0, 2
		add $t1, $t1, $s0
		lw $t2, 0($t1)
		print_int($t2)
		print_virgula()
		addi $t0, $t0, 1
	j while2
	end2:
	