.data # RandoM Access Memory (RAM)

	## INSIRA A PALAVRA DESEJADA NESSE LABEL A SEGUIR
	##
	msg1: .asciiz "universidade 1"
	#
	##
	msg2: .asciiz "O tamanho da palavra ("
	msg3: .asciiz ") é: "
	test: .byte '\0'
.text
main:
	la $s1, msg1
	li $v0, 4
	la $a0, msg2
	syscall
	
	li $v0, 4
	la $a0, msg1
	syscall
	
	li $v0, 4
	la $a0, msg3
	syscall
	
	jal srtlen # chamada do procedimento
	
	move $a0, $v1
	li $v0, 1
	syscall
	
li $v0, 10
syscall

srtlen:
	lb $t4, test
	addi $t3, $zero, 0 # contador de letras da palavra
	la $a1, msg1
	while:
		lb $t0, 0($a1)
		beq $t0, $t4, exit_while
		addi $a1, $a1, 1 # contador do String(array)
		#addi $t1, $t1, 1 # contador do loop (NÃO PRECISA)
		addi $t3, $t3, 1 # contador de palavras
	j while
	exit_while:
	move $v1, $t3
	jr $ra
