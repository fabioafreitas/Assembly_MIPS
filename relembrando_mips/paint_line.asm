# configurar display com width 512, height 256, w pixel 16, h pixel 16, address 0x10010000
.data
	display: .word 0x10010000
	cor1:	 .word 0x00C83E3E
.text
main:
	# $s0 = é sempre o endereco inicial do bitmap
	la $s0, display
	# $s1 = é sempre o valor da cor1
	lw $s1, cor1
	
	# chamada 1 da funcao
	li $a0, 272
	li $a1, 344
	li $a2, 1
	jal paint_line
	
	# chamada 2 da funcao
	li $a0, 900
	li $a1, 1016
	li $a2, 2
	jal paint_line
	
	# chamada 3 da funcao
	li $a0, 1164
	li $a1, 1932
	li $a2, 32
	jal paint_line
li $v0, 10
syscall

	# $a0 = offset inicial
	# $a1 = offset final
	# $a2 = de quantos em quantos pixel pintar
	paint_line:
		sll $a2, $a2, 2 # multiplicar por 4
		paint_line_while:
		bge $a0, $a1, paint_line_end_while
			add $t0, $s0, $a0
			sw $s1, 0($t0)
			add $a0, $a0, $a2
		j paint_line_while
		paint_line_end_while:
	jr $ra
	
	
	
	
	