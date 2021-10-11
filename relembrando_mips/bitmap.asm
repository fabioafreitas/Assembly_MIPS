.data 
	initial_address: .word 0x10010000
	cor: .word 0x003EC8C1
.text
	la $t0, initial_address
	lw $t1, cor
	sw $t1, 588($t0)
	sw $t1, 592($t0)
	sw $t1, 716($t0)
	sw $t1, 720($t0)
	
	
	