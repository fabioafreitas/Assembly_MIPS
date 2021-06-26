# Display Weidth 512
# Display Height 256
# Pixel Weidth 16
# Pixel Height 16
# BitMap Address 0x10010000

# [Bit superior esquerdo] = 0
# [Bit superior direito]  = (Display Weidth)/(Pixel Weidth) - 4
# [Bit inferior esquerdo] = ((Display Weidth)/(Pixel Weidth)) * (Display Height-1) * 4
# [Bit inferior direito]  = (display_size)*4 - 4
.data
base_address: 	.word 0x10010000
display_size: 	.word 512          # 512 pixel's  Largura = 32, Altura = 16
c_black:	.word 0x00000000 
c_white:	.word 0x00ffffff
c_red:		.word 0x00ff0000
c_yellow:	.word 0x00f1c40f
string_x:	.asciiz "\nVez do X, digite onde irá jogar: \n"
string_o:	.asciiz "\nVez do O, digite onde irá jogar: \n"
jogada_invalida:.asciiz "\nJogada inválida, tente novamente!\n"

.text
main:
	jal pintar_jogo_da_velha 
	
	move $s0, $zero # 0 - vez do X, 1 - vez da O
	addi $s1, $zero, 1 # se for igual a 0 o jogo acaba
	addi $s2, $zero, 0 # conta a quantidade de jogadas efetuadas
	
	game_loop:
	beq $zero, $s1, end_game_loop
	
	# inicio da vez do x #
	beq $zero, $s0, if # vez do X, $s0 = 0
	j else
	if:
		# lendo do teclado
		la $a0, string_x
		li $v0, 4
		syscall
		li $v0, 5
		syscall
		move $a1, $v0
		
		# checa se a jogada é válida
		addi $t0, $zero, 9
		bgt $a1, $t0, print_erro_if
		blt $a1, $zero, print_erro_if
		j nao_print_erro_if
		print_erro_if:
		la $a0, jogada_invalida
		li $v0, 4
		syscall
		j else
		nao_print_erro_if:
		
		# checa se a posição já está pintada
		# a posicao a ser jogada deve estar armazenada em $a1
		# se o $v0 for 0 a jogada foi inválida, jogador tenta denovo
		jal checar_jogada
		beq $v0, $zero, if
		
		# se chegou aqui a jogada é válida e deve ser pintada no display
		jal pintar_x
	addi $s0, $zero, 1
	addi $s2, $s2, 1
	j end_if_else
	# fim da vez do x #
		
	# inicio da vez do o #
	else:              # vez do O, $s0 = 1
		# lendo do teclado
		la $a0, string_o
		li $v0, 4
		syscall
		li $v0, 5
		syscall
		move $a1, $v0
		
		# checa se a jogada é válida
		addi $t0, $zero, 9
		bgt $a1, $t0, print_erro_else
		blt $a1, $zero, print_erro_else
		j nao_print_erro_else
		print_erro_else:
		la $a0, jogada_invalida
		li $v0, 4
		syscall
		j else
		nao_print_erro_else:
		
		# checa se a posição já está pintada
		# a posicao a ser jogada deve estar armazenada em $a1
		# se o $v0 for 0 a jogada foi inválida, jogador tenta denovo
		jal checar_jogada
		beq $v0, $zero, else
		
		# se chegou aqui a jogada é válida e deve ser pintada no display
		jal pintar_o
	addi $s0, $zero, 0
	addi $s2, $s2, 1
	end_if_else:
	# fim da vez do o #
	
	# inicio checa se deu velha
	addi $t0, $zero, 9
	beq $t0, $s2, deu_velha
	j nao_deu_velha
	deu_velha:
	addi $s1, $zero, 0 # para o loop do jogo
	jal pintar_deu_velha
	j game_loop
	nao_deu_velha:
	# fim checa se deu velha
	
	# inicio das checagens jogo (se houve vencedor ou não)
	jal checar_fim_de_jogo
	beq $v0, $zero, houve_vencedor
	j nao_houve_vencedor
	houve_vencedor:
	addi $s1, $zero, 0 # para o loop do jogo
	j game_loop
	nao_houve_vencedor:
	# final das checagens jogo

	j game_loop
	end_game_loop:
li $v0, 10
syscall

# $a0 (Address bitmap)
# $v0 (0 - houve vencedor, 1 - nao houve vencedor)
# $v1 (linha que indica a vitoria) [1,2,3,4,5,6,7,8]
# regras do $v1 indicadas na função (pintar_traco_vitoria)
# checa se alguem venceu o jogo ou se deu velha
checar_fim_de_jogo:
	la $a0, base_address
	lw $t0, c_red
	
######## inicio checando linhas
	
	# inicio linha 1 X
	lw $t1, 296($a0)
	lw $t2, 316($a0)
	lw $t3, 340($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_linha_1
	j x_nao_venceu_linha_1
	x_venceu_linha_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_linha_1:
	# fim linha 1 X
	
	# inicio linha 1 O
	lw $t1, 292($a0)
	lw $t2, 312($a0)
	lw $t3, 336($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_linha_1
	j o_nao_venceu_linha_1
	o_venceu_linha_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_linha_1:
	# fim linha 1 O
	
	# inicio linha 2 X
	lw $t1, 936($a0)
	lw $t2, 956($a0)
	lw $t3, 980($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_linha_2
	j x_nao_venceu_linha_2
	x_venceu_linha_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 2
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_linha_2:
	# fim linha 2 X
	
	# inicio linha 2 O
	lw $t1, 932($a0)
	lw $t2, 952($a0)
	lw $t3, 976($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_linha_2
	j o_nao_venceu_linha_2
	o_venceu_linha_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 2
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_linha_2:
	# fim linha 2 O
	
	# inicio linha 3 X
	lw $t1, 1704($a0)
	lw $t2, 1724($a0)
	lw $t3, 1748($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_linha_3
	j x_nao_venceu_linha_3
	x_venceu_linha_3:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 3
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_linha_3:
	# fim linha 3 X
	
	# inicio linha 3 O
	lw $t1, 1700($a0)
	lw $t2, 1720($a0)
	lw $t3, 1744($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_linha_3
	j o_nao_venceu_linha_3
	o_venceu_linha_3:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 3
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_linha_3:
	# fim linha 3 O
	
######## fim checando linhas
	
	
######## inicio checando colunas
	
	# inicio coluna 1 X
	lw $t1, 296($a0)
	lw $t2, 936($a0)
	lw $t3, 1704($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_coluna_1
	j x_nao_venceu_coluna_1
	x_venceu_coluna_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 4
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_coluna_1:
	# fim coluna 1 X
	
	# inicio coluna 1 O
	lw $t1, 292($a0)
	lw $t2, 932($a0)
	lw $t3, 1700($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_coluna_1
	j o_nao_venceu_coluna_1
	o_venceu_coluna_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 4
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_coluna_1:
	# fim coluna 1 O
	
	# inicio coluna 2 X
	lw $t1, 316($a0)
	lw $t2, 956($a0)
	lw $t3, 1724($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_coluna_2
	j x_nao_venceu_coluna_2
	x_venceu_coluna_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 5
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_coluna_2:
	# fim coluna 2 X
	
	# inicio coluna 2 O
	lw $t1, 312($a0)
	lw $t2, 952($a0)
	lw $t3, 1720($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_coluna_2
	j o_nao_venceu_coluna_2
	o_venceu_coluna_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 5
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_coluna_2:
	# fim coluna 2 O
	
	# inicio coluna 3 X
	lw $t1, 340($a0)
	lw $t2, 980($a0)
	lw $t3, 1748($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_coluna_3
	j x_nao_venceu_coluna_3
	x_venceu_coluna_3:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 6
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_coluna_3:
	# fim coluna 3 X
	
	# inicio coluna 3 O
	lw $t1, 336($a0)
	lw $t2, 976($a0)
	lw $t3, 1744($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_coluna_3
	j o_nao_venceu_coluna_3
	o_venceu_coluna_3:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 6
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_coluna_3:
	# fim coluna 3 O
	
######## fim checando colunas
	
	
######## inicio checando diagonais
	
	# inicio diagonal principal do X
	lw $t1, 164($a0)
	lw $t2, 824($a0)
	lw $t3, 1616($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_diagonal_1
	j x_nao_venceu_diagonal_1
	x_venceu_diagonal_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 7
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_diagonal_1:
	# fim diagonal principal do X
	
	# inicio diagonal principal do O
	lw $t1, 296($a0)
	lw $t2, 956($a0)
	lw $t3, 1748($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_diagonal_1
	j o_nao_venceu_diagonal_1
	o_venceu_diagonal_1:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 7
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_diagonal_1:
	# fim diagonal principal do O
	
	# inicio diagonal secundaria do X
	lw $t1, 216($a0)
	lw $t2, 832($a0)
	lw $t3, 1580($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, x_venceu_diagonal_2
	j x_nao_venceu_diagonal_2
	x_venceu_diagonal_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 8
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	x_nao_venceu_diagonal_2:
	# fim diagonal secundaria do X
	
	# inicio diagonal secundaria do O
	lw $t1, 340($a0)
	lw $t2, 956($a0)
	lw $t3, 1704($a0)
	and $t4, $t0, $t1
	and $t4, $t4, $t2
	and $t4, $t4, $t3
	beq $t0, $t4, o_venceu_diagonal_2
	j o_nao_venceu_diagonal_2
	o_venceu_diagonal_2:
	addi $v0, $zero, 0 # houve vencedor
	
	addi $a1, $zero, 8
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal pintar_traco_vitoria
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j venceu
	o_nao_venceu_diagonal_2:
	# fim diagonal secundaria do O
	
######## fim checando diagonais
	venceu:
jr $ra

# $a0 (Address bitmap)
# $a1 (numero quadrado a ser pintado) [1,2,3,4,5,6,7,8,9]
# $v0 (0 - não pode jogar nesse local, 1 - pode jogar nesse local)
# checa se a posição escolhida é válida para ser preenchida
checar_jogada:
	la $a0, base_address
	lw $t0, c_red
	addi $t1, $zero, 1
	
	# case 1
	beq $a1, $t1, checar_quadrado_1
	addi $t1, $t1, 1
	j nao_checar_quadrado_1
	checar_quadrado_1:
		lw $t2, 164($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 168($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_1:
	# case 2
	beq $a1, $t1, checar_quadrado_2
	addi $t1, $t1, 1
	j nao_checar_quadrado_2
	checar_quadrado_2:
		lw $t2, 184($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 188($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 	
	j checagem_encerrada
	nao_checar_quadrado_2:
	# case 3
	beq $a1, $t1, checar_quadrado_3
	addi $t1, $t1, 1
	j nao_checar_quadrado_3
	checar_quadrado_3:
		lw $t2, 208($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 212($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_3:
	# case 4
	beq $a1, $t1, checar_quadrado_4
	addi $t1, $t1, 1
	j nao_checar_quadrado_4
	checar_quadrado_4:
		lw $t2, 804($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 808($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_4:
	# case 5
	beq $a1, $t1, checar_quadrado_5
	addi $t1, $t1, 1
	j nao_checar_quadrado_5
	checar_quadrado_5:
		lw $t2, 824($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 828($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_5:
	# case 6
	beq $a1, $t1, checar_quadrado_6
	addi $t1, $t1, 1
	j nao_checar_quadrado_6
	checar_quadrado_6:
		lw $t2, 848($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 852($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_6:
	# case 7
	beq $a1, $t1, checar_quadrado_7
	addi $t1, $t1, 1
	j nao_checar_quadrado_7
	checar_quadrado_7:
		lw $t2, 1572($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 1576($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_7:
	# case 8
	beq $a1, $t1, checar_quadrado_8
	addi $t1, $t1, 1
	j nao_checar_quadrado_8
	checar_quadrado_8:
		lw $t2, 1592($a0)
		beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 1596($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_8:
	# case 9
	beq $a1, $t1, checar_quadrado_9
	addi $t1, $t1, 1
	j nao_checar_quadrado_9
	checar_quadrado_9:
		lw $t2, 1616($a0)
	 	beq $t0, $t2, posicao_ja_ocupada
		lw $t2, 1620($a0)
		beq $t0, $t2, posicao_ja_ocupada
		# indica que a posição está livre para ser pintada
		addi $v0, $zero, 1 
	j checagem_encerrada
	nao_checar_quadrado_9:
	# end case
	j checagem_encerrada
	
	# retorna que não é possível jogar nessa posição
	posicao_ja_ocupada:
	addi $v0, $zero, 0
	
	checagem_encerrada:
jr $ra

# $a0 (Address bitmap)
# $a1 (Display size)
# imprime no display o jogo da velha
pintar_jogo_da_velha: 
	la $a0, base_address
	lw $a1, display_size
	lw $t0, c_white
	sw $t0, 52($a0)
	sw $t0, 180($a0)
	sw $t0, 308($a0)
	sw $t0, 436($a0)
	sw $t0, 564($a0)
	sw $t0, 692($a0)
	sw $t0, 820($a0)
	sw $t0, 948($a0)
	sw $t0, 1076($a0)
	sw $t0, 1204($a0)
	sw $t0, 1332($a0)
	sw $t0, 1460($a0)
	sw $t0, 1588($a0)
	sw $t0, 1716($a0)
	sw $t0, 1844($a0)
	sw $t0, 1972($a0)
	sw $t0, 72($a0)
	sw $t0, 200($a0)
	sw $t0, 328($a0)
	sw $t0, 456($a0)
	sw $t0, 584($a0)
	sw $t0, 712($a0)
	sw $t0, 840($a0)
	sw $t0, 968($a0)
	sw $t0, 1096($a0)
	sw $t0, 1224($a0)
	sw $t0, 1352($a0)
	sw $t0, 1480($a0)
	sw $t0, 1608($a0)
	sw $t0, 1736($a0)
	sw $t0, 1864($a0)
	sw $t0, 1992($a0)
	sw $t0, 672($a0)
	sw $t0, 676($a0)
	sw $t0, 680($a0)
	sw $t0, 684($a0)
	sw $t0, 688($a0)
	sw $t0, 696($a0)
	sw $t0, 700($a0)
	sw $t0, 704($a0)
	sw $t0, 708($a0)
	sw $t0, 716($a0)
	sw $t0, 720($a0)
	sw $t0, 724($a0)
	sw $t0, 728($a0)
	sw $t0, 732($a0)
	sw $t0, 1312($a0)
	sw $t0, 1316($a0)
	sw $t0, 1320($a0)
	sw $t0, 1324($a0)
	sw $t0, 1328($a0)
	sw $t0, 1336($a0)
	sw $t0, 1340($a0)
	sw $t0, 1344($a0)
	sw $t0, 1348($a0)
	sw $t0, 1356($a0)
	sw $t0, 1360($a0)
	sw $t0, 1364($a0)
	sw $t0, 1368($a0)
	sw $t0, 1372($a0)
jr $ra

# $a0 (Address bitmap)
# $a1 (indica qual dos 9 quadrados será pintado) [1,2,3,4,5,6,7,8,9]
# imprime no display um X na posição indicada em $a1
pintar_x:
	la $a0, base_address
	lw $t1, c_red
	addi $t0, $zero, 1 
	# case 1
	beq $t0, $a1, pintar_x_1
	addi $t0, $t0, 1
	j nao_pintar_x_1
	pintar_x_1:
	sw $t1, 164($a0)
	sw $t1, 172($a0)
	sw $t1, 296($a0)
	sw $t1, 420($a0)
	sw $t1, 428($a0)
	j pintou_x
	nao_pintar_x_1:
	# case 2
	beq $t0, $a1, pintar_x_2
	addi $t0, $t0, 1
	j nao_pintar_x_2
	pintar_x_2:
	sw $t1, 184($a0)
	sw $t1, 192($a0)
	sw $t1, 316($a0)
	sw $t1, 440($a0)
	sw $t1, 448($a0)
	j pintou_x
	nao_pintar_x_2:
	# case 3
	beq $t0, $a1, pintar_x_3
	addi $t0, $t0, 1
	j nao_pintar_x_3
	pintar_x_3:
	sw $t1, 208($a0)
	sw $t1, 216($a0)
	sw $t1, 340($a0)
	sw $t1, 464($a0)
	sw $t1, 472($a0)
	j pintou_x
	nao_pintar_x_3:
	# case 4
	beq $t0, $a1, pintar_x_4
	addi $t0, $t0, 1
	j nao_pintar_x_4
	pintar_x_4:
	sw $t1, 804($a0)
	sw $t1, 812($a0)
	sw $t1, 936($a0)
	sw $t1, 1060($a0)
	sw $t1, 1068($a0)
	j pintou_x
	nao_pintar_x_4:
	# case 5
	beq $t0, $a1, pintar_x_5
	addi $t0, $t0, 1
	j nao_pintar_x_5
	pintar_x_5:
	sw $t1, 824($a0)
	sw $t1, 832($a0)
	sw $t1, 956($a0)
	sw $t1, 1080($a0)
	sw $t1, 1088($a0)
	j pintou_x
	nao_pintar_x_5:
	# case 6
	beq $t0, $a1, pintar_x_6
	addi $t0, $t0, 1
	j nao_pintar_x_6
	pintar_x_6:
	sw $t1, 848($a0)
	sw $t1, 856($a0)
	sw $t1, 980($a0)
	sw $t1, 1104($a0)
	sw $t1, 1112($a0)
	j pintou_x
	nao_pintar_x_6:
	# case 7
	beq $t0, $a1, pintar_x_7
	addi $t0, $t0, 1
	j nao_pintar_x_7
	pintar_x_7:
	sw $t1, 1572($a0)
	sw $t1, 1580($a0)
	sw $t1, 1704($a0)
	sw $t1, 1828($a0)
	sw $t1, 1836($a0)
	j pintou_x
	nao_pintar_x_7:
	# case 8
	beq $t0, $a1, pintar_x_8
	addi $t0, $t0, 1
	j nao_pintar_x_8
	pintar_x_8:
	sw $t1, 1592($a0)
	sw $t1, 1600($a0)
	sw $t1, 1724($a0)
	sw $t1, 1848($a0)
	sw $t1, 1856($a0)
	j pintou_x
	nao_pintar_x_8:
	# case 9
	beq $t0, $a1, pintar_x_9
	addi $t0, $t0, 1
	j nao_pintar_x_9
	pintar_x_9:
	sw $t1, 1616($a0)
	sw $t1, 1624($a0)
	sw $t1, 1748($a0)
	sw $t1, 1872($a0)
	sw $t1, 1880($a0)
	j pintou_x
	nao_pintar_x_9:
	# end case
	pintou_x:
	jr $ra

# $a0 (indica qual dos 9 quadrados será pintado)
# $a1 (indica qual dos 9 quadrados será pintado) [1,2,3,4,5,6,7,8,9]
# imprime no display um X na posição indicada em $a1
pintar_o:
	la $a0, base_address
	lw $t1, c_red
	addi $t0, $zero, 1 
	# case 1
	beq $t0, $a1, pintar_o_1
	addi $t0, $t0, 1
	j nao_pintar_o_1
	pintar_o_1:
	sw $t1, 168($a0)
	sw $t1, 292($a0)
	sw $t1, 300($a0)
	sw $t1, 424($a0)
	j pintou_o
	nao_pintar_o_1:
	# case 2
	beq $t0, $a1, pintar_o_2
	addi $t0, $t0, 1
	j nao_pintar_o_2
	pintar_o_2:
	sw $t1, 188($a0)
	sw $t1, 312($a0)
	sw $t1, 320($a0)
	sw $t1, 444($a0)
	j pintou_o
	nao_pintar_o_2:
	# case 3
	beq $t0, $a1, pintar_o_3
	addi $t0, $t0, 1
	j nao_pintar_o_3
	pintar_o_3:
	sw $t1, 212($a0)
	sw $t1, 336($a0)
	sw $t1, 344($a0)
	sw $t1, 468($a0)
	j pintou_o
	nao_pintar_o_3:
	# case 4
	beq $t0, $a1, pintar_o_4
	addi $t0, $t0, 1
	j nao_pintar_o_4
	pintar_o_4:
	sw $t1, 808($a0)
	sw $t1, 932($a0)
	sw $t1, 940($a0)
	sw $t1, 1064($a0)
	j pintou_o
	nao_pintar_o_4:
	# case 5
	beq $t0, $a1, pintar_o_5
	addi $t0, $t0, 1
	j nao_pintar_o_5
	pintar_o_5:
	sw $t1, 828($a0)
	sw $t1, 952($a0)
	sw $t1, 960($a0)
	sw $t1, 1084($a0)
	j pintou_o
	nao_pintar_o_5:
	# case 6
	beq $t0, $a1, pintar_o_6
	addi $t0, $t0, 1
	j nao_pintar_o_6
	pintar_o_6:
	sw $t1, 852($a0)
	sw $t1, 976($a0)
	sw $t1, 984($a0)
	sw $t1, 1108($a0)
	j pintou_o
	nao_pintar_o_6:
	# case 7
	beq $t0, $a1, pintar_o_7
	addi $t0, $t0, 1
	j nao_pintar_o_7
	pintar_o_7:
	sw $t1, 1576($a0)
	sw $t1, 1700($a0)
	sw $t1, 1708($a0)
	sw $t1, 1832($a0)
	j pintou_o
	nao_pintar_o_7:
	# case 8
	beq $t0, $a1, pintar_o_8
	addi $t0, $t0, 1
	j nao_pintar_o_8
	pintar_o_8:
	sw $t1, 1596($a0)
	sw $t1, 1720($a0)
	sw $t1, 1728($a0)
	sw $t1, 1852($a0)
	j pintou_o
	nao_pintar_o_8:
	# case 9
	beq $t0, $a1, pintar_o_9
	addi $t0, $t0, 1
	j nao_pintar_o_9
	pintar_o_9:
	sw $t1, 1620($a0)
	sw $t1, 1744($a0)
	sw $t1, 1752($a0)
	sw $t1, 1876($a0)
	j pintou_o
	nao_pintar_o_9:
	# end case
	pintou_o:	
jr $ra

# $a0 (Address bitmap)
# $a1 (indica a linha a ser pintada)
# [1,2,3] - linha 1, 2, 3
# [4,5,6] - coluna 1, 2, 3
# [7,8]   - diagonal principal (7), diagonal secundaria (8) 
# pinta um traço da vitoria
pintar_traco_vitoria:
	la $a0, base_address
	lw $t0, c_yellow
	addi $t1, $zero, 1
	# case 1
	beq $t1, $a1, pintar_linha_1
	addi $t1, $t1, 1
	j nao_pintar_linha_1
	pintar_linha_1:
	sw $t0, 288($a0)
	sw $t0, 292($a0)
	sw $t0, 296($a0)
	sw $t0, 300($a0)
	sw $t0, 304($a0)
	sw $t0, 308($a0)
	sw $t0, 312($a0)
	sw $t0, 316($a0)
	sw $t0, 320($a0)
	sw $t0, 324($a0)
	sw $t0, 328($a0)
	sw $t0, 332($a0)
	sw $t0, 336($a0)
	sw $t0, 340($a0)
	sw $t0, 344($a0)
	sw $t0, 348($a0)
	j pintou_a_linha
	nao_pintar_linha_1:
	# case 2
	beq $t1, $a1, pintar_linha_2
	addi $t1, $t1, 1
	j nao_pintar_linha_2
	pintar_linha_2:
	sw $t0, 928($a0)
	sw $t0, 932($a0)
	sw $t0, 936($a0)
	sw $t0, 940($a0)
	sw $t0, 944($a0)
	sw $t0, 948($a0)
	sw $t0, 952($a0)
	sw $t0, 956($a0)
	sw $t0, 960($a0)
	sw $t0, 964($a0)
	sw $t0, 968($a0)
	sw $t0, 972($a0)
	sw $t0, 976($a0)
	sw $t0, 980($a0)
	sw $t0, 984($a0)
	sw $t0, 988($a0)
	j pintou_a_linha
	nao_pintar_linha_2:
	# case 3
	beq $t1, $a1, pintar_linha_3
	addi $t1, $t1, 1
	j nao_pintar_linha_3
	pintar_linha_3:
	sw $t0, 1696($a0)
	sw $t0, 1700($a0)
	sw $t0, 1704($a0)
	sw $t0, 1708($a0)
	sw $t0, 1712($a0)
	sw $t0, 1716($a0)
	sw $t0, 1720($a0)
	sw $t0, 1724($a0)
	sw $t0, 1728($a0)
	sw $t0, 1732($a0)
	sw $t0, 1736($a0)
	sw $t0, 1740($a0)
	sw $t0, 1744($a0)
	sw $t0, 1748($a0)
	sw $t0, 1752($a0)
	sw $t0, 1756($a0)
	j pintou_a_linha
	nao_pintar_linha_3:
	# case 4
	beq $t1, $a1, pintar_coluna_1
	addi $t1, $t1, 1
	j nao_pintar_coluna_1
	pintar_coluna_1:
	sw $t0, 40($a0)
	sw $t0, 168($a0)
	sw $t0, 296($a0)
	sw $t0, 424($a0)
	sw $t0, 552($a0)
	sw $t0, 680($a0)
	sw $t0, 808($a0)
	sw $t0, 936($a0)
	sw $t0, 1064($a0)
	sw $t0, 1192($a0)
	sw $t0, 1320($a0)
	sw $t0, 1448($a0)
	sw $t0, 1576($a0)
	sw $t0, 1704($a0)
	sw $t0, 1832($a0)
	sw $t0, 1960($a0)
	j pintou_a_linha
	nao_pintar_coluna_1:
	# case 5
	beq $t1, $a1, pintar_coluna_2
	addi $t1, $t1, 1
	j nao_pintar_coluna_2
	pintar_coluna_2:
	sw $t0, 60($a0)
	sw $t0, 188($a0)
	sw $t0, 316($a0)
	sw $t0, 444($a0)
	sw $t0, 572($a0)
	sw $t0, 700($a0)
	sw $t0, 828($a0)
	sw $t0, 956($a0)
	sw $t0, 1084($a0)
	sw $t0, 1212($a0)
	sw $t0, 1340($a0)
	sw $t0, 1468($a0)
	sw $t0, 1596($a0)
	sw $t0, 1724($a0)
	sw $t0, 1852($a0)
	sw $t0, 1980($a0)
	j pintou_a_linha
	nao_pintar_coluna_2:
	# case 6
	beq $t1, $a1, pintar_coluna_3
	addi $t1, $t1, 1
	j nao_pintar_coluna_3
	pintar_coluna_3:
	sw $t0, 84($a0)
	sw $t0, 212($a0)
	sw $t0, 340($a0)
	sw $t0, 468($a0)
	sw $t0, 596($a0)
	sw $t0, 724($a0)
	sw $t0, 852($a0)
	sw $t0, 980($a0)
	sw $t0, 1108($a0)
	sw $t0, 1236($a0)
	sw $t0, 1364($a0)
	sw $t0, 1492($a0)
	sw $t0, 1620($a0)
	sw $t0, 1748($a0)
	sw $t0, 1876($a0)
	sw $t0, 2004($a0)
	j pintou_a_linha
	nao_pintar_coluna_3:
	# case 7
	beq $t1, $a1, pintar_diagonal_1
	addi $t1, $t1, 1
	j nao_pintar_diagonal_1
	pintar_diagonal_1:
	sw $t0, 32($a0)
	sw $t0, 164($a0)
	sw $t0, 296($a0)
	sw $t0, 428($a0)
	sw $t0, 560($a0)
	sw $t0, 692($a0)
	sw $t0, 824($a0)
	sw $t0, 956($a0)
	sw $t0, 1088($a0)
	sw $t0, 1220($a0)
	sw $t0, 1352($a0)
	sw $t0, 1484($a0)
	sw $t0, 1616($a0)
	sw $t0, 1748($a0)
	sw $t0, 1880($a0)
	sw $t0, 2012($a0)
	j pintou_a_linha
	nao_pintar_diagonal_1:
	# case 8
	beq $t1, $a1, pintar_diagonal_2
	addi $t1, $t1, 1
	j nao_pintar_diagonal_2
	pintar_diagonal_2:
	sw $t0, 92($a0)
	sw $t0, 216($a0)
	sw $t0, 340($a0)
	sw $t0, 464($a0)
	sw $t0, 588($a0)
	sw $t0, 712($a0)
	sw $t0, 836($a0)
	sw $t0, 960($a0)
	sw $t0, 1084($a0)
	sw $t0, 1208($a0)
	sw $t0, 1332($a0)
	sw $t0, 1456($a0)
	sw $t0, 1580($a0)
	sw $t0, 1704($a0)
	sw $t0, 1828($a0)
	sw $t0, 1952($a0)
	j pintou_a_linha
	nao_pintar_diagonal_2:
	
	pintou_a_linha:
jr $ra

# $a0 (Address bitmap)
# pinta na tela "deu velha"
pintar_deu_velha:
	la $a0, base_address
	lw $a1, display_size
	lw $t0, c_black
	lw $t4, c_yellow
	addi $t1, $zero, 0
	
	# pintando o display de preto
	loop_reset_display:
	beq $t1, $a1, end_loop_reset_display 
	sll $t2, $t1, 2
	add $t2, $t2, $a0
	sw $t0, 0($t2)
	addi $t1, $t1, 1
	j loop_reset_display
	end_loop_reset_display:

	sw $t4, 292($a0)
	sw $t4, 296($a0)
	sw $t4, 300($a0)
	sw $t4, 420($a0)
	sw $t4, 432($a0)
	sw $t4, 548($a0)
	sw $t4, 560($a0)
	sw $t4, 676($a0)
	sw $t4, 688($a0)
	sw $t4, 804($a0)
	sw $t4, 808($a0)
	sw $t4, 812($a0)
	sw $t4, 312($a0)
	sw $t4, 316($a0)
	sw $t4, 320($a0)
	sw $t4, 440($a0)
	sw $t4, 568($a0)
	sw $t4, 572($a0)
	sw $t4, 576($a0)
	sw $t4, 696($a0)
	sw $t4, 824($a0)
	sw $t4, 828($a0)
	sw $t4, 832($a0)
	sw $t4, 328($a0)
	sw $t4, 456($a0)
	sw $t4, 340($a0)
	sw $t4, 468($a0)
	sw $t4, 584($a0)
	sw $t4, 596($a0)
	sw $t4, 712($a0)
	sw $t4, 724($a0)
	sw $t4, 844($a0)
	sw $t4, 848($a0)
	sw $t4, 1036($a0)
	sw $t4, 1164($a0)
	sw $t4, 1296($a0)
	sw $t4, 1424($a0)
	sw $t4, 1556($a0)
	sw $t4, 1052($a0)
	sw $t4, 1180($a0)
	sw $t4, 1304($a0)
	sw $t4, 1432($a0)
	sw $t4, 1556($a0)
	sw $t4, 1060($a0)
	sw $t4, 1064($a0)
	sw $t4, 1068($a0)
	sw $t4, 1188($a0)
	sw $t4, 1316($a0)
	sw $t4, 1320($a0)
	sw $t4, 1324($a0)
	sw $t4, 1444($a0)
	sw $t4, 1572($a0)
	sw $t4, 1576($a0)
	sw $t4, 1580($a0)
	sw $t4, 1076($a0)
	sw $t4, 1204($a0)
	sw $t4, 1332($a0)
	sw $t4, 1460($a0)
	sw $t4, 1588($a0)
	sw $t4, 1592($a0)
	sw $t4, 1596($a0)
	sw $t4, 1092($a0)
	sw $t4, 1220($a0)
	sw $t4, 1348($a0)
	sw $t4, 1476($a0)
	sw $t4, 1604($a0)
	sw $t4, 1352($a0)
	sw $t4, 1356($a0)
	sw $t4, 1104($a0)
	sw $t4, 1232($a0)
	sw $t4, 1360($a0)
	sw $t4, 1488($a0)
	sw $t4, 1616($a0)
	sw $t4, 1116($a0)
	sw $t4, 1120($a0)
	sw $t4, 1240($a0)
	sw $t4, 1252($a0)
	sw $t4, 1368($a0)
	sw $t4, 1380($a0)
	sw $t4, 1496($a0)
	sw $t4, 1500($a0)
	sw $t4, 1504($a0)
	sw $t4, 1508($a0)
	sw $t4, 1624($a0)
	sw $t4, 1636($a0)
	sw $t4, 1132($a0)
	sw $t4, 1260($a0)
	sw $t4, 1388($a0)
	sw $t4, 1644($a0)	
jr $ra