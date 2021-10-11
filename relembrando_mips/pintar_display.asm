# configurar display com width 512, height 256, w pixel 32, h pixel 32, address 0x10010000
.data
	display: .word 0x10010000
	cor1:	 .word 0x00C83E3E
.text
	la $s0, display
	lw $s1, cor1
	
	li $t0, 0
	li $t1, 128
	while:
	bgt $t0, $t1, end_while
		sll $t2, $t0, 2
		add $t2, $t2, $s0
		sw $s1, 0($t2)
		addi $t0, $t0, 1
	j while
	end_while: