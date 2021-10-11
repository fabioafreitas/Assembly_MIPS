.data
	display: .word 0x10010000
	cor1:	 .word 0x00C83E3E
	cor2:	 .word 0x00FF7676
.text
	la $s0, display
	lw $s1, cor1
	lw $s2, cor2 
	
	inicio:
	sw $s1, 0($s0)
	
	li $v0, 32
	li $a0, 1000
	syscall
	
	sw $s2, 0($s0)
	
	li $v0, 32
	li $a0, 1000
	syscall
	
	j inicio