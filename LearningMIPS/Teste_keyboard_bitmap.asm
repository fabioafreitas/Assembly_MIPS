.data
bitmap:   .word 0x10010000
red:   .word 0x00ff0000
blue:  .word 0x000000ff
green: .word 0x0000ff00
black: .word 0x00000000
white: .word 0x00ffffff
keyboard: .word 0xffff0004


.text
.globl main
main:
	#li $t1, 4
	#lw $a3, white
	
	#li $a1, 132
	#li $a2, 184
	#jal paint_line
	#li $a1, 1796
	#li $a2, 1848
	#jal paint_line
	
	#li $t1, 128
	#li $a1, 260
	#li $a2, 1668
	#jal paint_line
	#li $a1, 312
	#li $a2, 1720
	#jal paint_line
	
	jal pintar_labirinto
	
	# pintando o personagem no bitmap
	#la $a0, bitmap
	#lw $a3, red
	#sw $a3, 396($a0)			
	#add $s0, $a0, 396 # endereço inicial do personagem (endereço do excel + endereço inicial do bitmap)
	
	# salvando endereço inicial do personagem
	la $a0, bitmap
	addi $s0, $a0, 920
	
	li $t9, 1
	loop:
	beq $t9, $zero, end
	jal movimentar_syscall
	j loop
	end:
	
li $v0, 10
syscall

#simulando movimento
# $a0 - keyboard
# $
#
movimentar_mmio:
	
jr $ra

# sempre que se mover, atualiar o novo endereço em $s0
# $a0 - bitmap
movimentar_syscall:
	la $a0, bitmap  # se nao pegar, testar com load word
	li $v0, 12
	syscall
	beq $v0, 119, mover_w
	j nao_mover_w
	mover_w:
		# a antiga posicao está em $s0
		# armazeno a nova posiçao em $t0
		sub $t0, $s0, 128  	# calculo a nova posição e armazeno em $t0
		lw $t1, blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, red
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, black #  pinta posição antida de preto
		sw $t1, 0($s0)
		# atualiza posição de memoria do $v0
		sub $s0, $s0, 128
	j fim_movimentar_syscall
	nao_mover_w:
	beq $v0, 97, mover_a
	j nao_mover_a
	mover_a:
		sub $t0, $s0, 4  	# calculo a nova posição e armazeno em $t0
		lw $t1, blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, red
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		sub $s0, $s0, 4
	j fim_movimentar_syscall
	nao_mover_a:
	beq $v0, 115, mover_s
	j nao_mover_s
	mover_s:
		add $t0, $s0, 128  	# calculo a nova posição e armazeno em $t0
		lw $t1, blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, red
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		add $s0, $s0, 128
	j fim_movimentar_syscall
	nao_mover_s:
	beq $v0, 100, mover_d
	j nao_mover_d
	mover_d:
		add $t0, $s0, 4  	# calculo a nova posição e armazeno em $t0
		lw $t1, blue		# carrego a cor branca em $t1
		lw $t2, 0($t0)		# carrego o conteudo da nova posição
		beq $t2, $t1, fim_movimentar_syscall 	# se o conteudo for a cor branca, nao mover
		# pode mover
		lw $t1, red
		sw $t1, 0($t0) # nova posição de vermelho
		lw $t1, black  # pinta posição antida de preto
		sw $t1, 0($s0) # posição antiga do personagem
		# atualiza posição de memoria do $v0
		add $s0, $s0, 4
	j fim_movimentar_syscall
	nao_mover_d:
	
	fim_movimentar_syscall:
jr $ra

# pinta uma linha dentro de um intervalo determinado
# $a0 - display_address
# $a1 - endereço inicial
# $a2 - endereço final
# $a3 - cor a ser pintada
# $t1 - intervalo entre os pixels
paint_line:
	la $a0, bitmap
	paint_line_loop:
	bgt $a1, $a2, end_paint_line_loop
	add $t0, $a1, $a0
	sw $a3, 0($t0)
	add $a1, $a1, $t1
	j paint_line_loop
	end_paint_line_loop:
jr $ra

pintar_labirinto:
	la $a0, bitmap
	lw $a3, blue
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t1, 4
	
	li $a1, 132
	li $a2, 184
	jal paint_line
	
	li $a1, 1796
	li $a2, 1848
	jal paint_line
	
	li $t1, 128
	
	li $a1, 260
	li $a2, 1668
	jal paint_line
	
	li $a1, 312
	li $a2, 1720
	jal paint_line
	
	li $a1, 396
	li $a2, 1548
	jal paint_line
	
	li $a1, 400
	li $a2, 1552
	jal paint_line
	
	li $a1, 404
	li $a2, 1556
	jal paint_line
	
	li $a1, 412
	li $a2, 1564
	jal paint_line
	
	li $a1, 416
	li $a2, 1568
	jal paint_line
	
	li $a1, 424
	li $a2, 1576
	jal paint_line
	
	li $a1, 428
	li $a2, 1580
	jal paint_line
	
	li $a1, 432
	li $a2, 1584
	jal paint_line
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	lw $a3, red
	sw $a3, 920($a0)
jr $ra
