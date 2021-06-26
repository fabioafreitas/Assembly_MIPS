############################################################################
#   	Fabio Alves - Arquitetura e organizacao de computadores 2018.1     #
#									   #
#	O MARS4_5 BUGA COM O BITMAP E MMIO ABERTOS SIMULTANEAMENTE.	   #
#	UTILIZE O MARSMod 0.0.1 DISPONIBILIZADO NO GITHUB DO PROJETO.	   #
#									   #
#	https://github.com/fabioafreitas/pac_man_assembly		   #
#									   #
#   	Tools -> KeyBoard and Display MMIO Simulator            	   #
#		Keyboard reciever data address: 0xffff0004          	   #
#   	Tools -> Bitmap Display						   #
#		Unit Width in Pixels:  8				   #
#		Unit Height in Pixels: 8				   #
#		Display Width in Pixels:  512				   #
#		Display Height in Pixels: 256				   #
#		Base address for display: 0x10010000 (static data)	   #
############################################################################




##################
#     MACROS     #
##################

# da um sleep de X mili segundos dados na entrada
# (1 pixel a cada X milisegundos)
.macro sleep(%speed_in_miliseconds)
	li $a0, %speed_in_miliseconds
	li $v0, 32
	syscall
.end_macro 



# pausa o movimento dos persoagens até uma tecla ser pressionada
.macro press_any_key()
	beqz $s6, end_loop_wait # checa se a qtd de vidas é zero
	li $t0, -1		# reseta o contador do reciever
	sw $t0, 0xffff0004 	# reseta o conteudo do reciever do keyboard
	loop_wait:
	bgez $t0, end_loop_wait
	lw $t0, 0xffff0004
	j loop_wait
	end_loop_wait:
.end_macro 



# pinta uma linha de uma determinada cor
.macro paint_line(%endereco_inicial,%endereco_final)
	li $a1, %endereco_inicial	 # intervalo inferior de pintura
	li $a2, %endereco_final		 # intervalo superior de pintura
	jal paint_line
.end_macro


# deve ser usado antes de um paint_line()
# configura a cor e o intervalo de pintura
.macro set_cor_intervalo(%intervalo_de_pintura, %cor)
	li $t1, %intervalo_de_pintura 	# intervalo de pixels de pintura
	lw $a3, %cor 					# cor
.end_macro



# efetua a pintura de acordo com o address
.macro paint_by_address(%address)
	addi $t2, $a0, %address
	add $t2, $t2, $t1
	sw $a3, 0($t2)
.end_macro



# efetua a pintura de acordo com o address, usado apenas
# na fun��o "contador_display"
.macro paint_by_address_2(%address)
	addi $t1, $a0, %address
	add $t1, $t1, $t0
	sw $t2, 0($t1)
.end_macro



# seta a pontua��o inicial
.macro pontuacao(%points)
	li $s7, %points
.end_macro


# seta a quantidade de vidas
.macro vidas(%vidas)
	li $s6, %vidas
.end_macro





# seta o stage atual
.macro stage(%stage)
	li $s5, %stage
.end_macro

# (cor de teste) (cor do pixel) (cor do fantasma) (registrador de direcao)
# (registrador do fantasma) (imediato movimento)
.macro move_ghost(%corTeste,%corPaint,%corGhost,%regDir,%regGhost,%immMove,%immWhiteBlack,%WhiteBlack,%immLastDir,%lastDir)
	lw $a3, %corTeste
	lw $a2, 0(%redDir)		
	beq $a3, $a2, move_label
	j dont_move_label	
	move_label:
	lw $a3, %corPaint
	sw $a3, 0(%regGhost)
	lw $a3, %corGhost
	sw $a3, 0(%redDir)
	addi %regGhost , %regGhost, %immMove
	li $t0, %immWhiteBlack
	sw $t0, %WhiteBlack
	li $t0, %immLastDir
	sw $t0, %lastDir
	j end_fantasma_rosa
	dont_move_label:
.end_macro


################
#     DATA     #
################

.data
# bitmap
display_address: 	.word 0x10010000
display_size:		.word 2048

# cores
color_blue:		.word 0x001818FF
color_yellow:		.word 0x00FFFE1D
color_red: 		.word 0x00DF0902
color_pink:		.word 0x00FA9893
color_ciano:		.word 0x0061FAFC
color_orange:		.word 0x00FC9711
color_black:		.word 0x00000000
color_white:		.word 0x00FFFFFF

# indicadores para movimentacao dos fantasmas
indicador_white_red:	.word 0		## (1) indica que o movimento anterior do fantasma foi sobre uma pontuacao	
indicador_white_orange:	.word 0		## (0) indica que o movimento anterior do fantasma não foi sobre uma pontuacao
indicador_white_ciano:	.word 0		## 
indicador_white_pink:	.word 0		## se for 1, então pintamos a proxima posicao da cor do fantasma e a atual de branco

ultima_direcao_red:	.word 2		## Indica a ultima direcao que um fantasma se moveu.
ultima_direcao_orange:	.word 2		##	
ultima_direcao_ciano:	.word 5		##	(1) cima 	(2) esquerda
ultima_direcao_pink:	.word 5		## 	(3) baixo 	(5) direita




################
#     MAIN     #
################

#########################################################
#	(Detalhes importantes)				#
#							#
#	$s0 - posicao do pac man			#
#	$s1 - posicao do fantasma vermelho 		#
#	$s2 - posicao do fantasma laranja 		#
#	$s3 - posicao do fantasma ciano 		#
#	$s4 - posicao do fantasma rosa 			#
#	$s5 - armazena o stage atual (1 ou 2)		#
#	$s6 - armazena a quantidade de vidas (3 a 0)	#
#	$s7 - salva a pontuacao atual do jogo		#
#########################################################
.text
.globl main
main:
	# configura��es do jogo
	pontuacao(0)	# indicando que a pontuacao inicial com zero
	stage(1)       	# indicando que estamos no stage 1
	vidas(3)	# indicando que temos 3 vidas iniciais
	
	# pintando componentes do display
	jal paint_stage_text
	jal paint_pts
	jal contador_da_pontuacao
	jal paint_stage_1
	
	# espera uma tecla ser pressionada para iniciar o movimento do pac man
	wait_1: 
	jal posicionar_personagens
	jal paint_lives
	press_any_key()
	
	# game_loop do stage 1
	game_loop_stage_1:
	beqz $s6, game_over # branch se possui zero vidas
		# movimentacao do pac man
		sleep(35) # velocidade do pac man
		jal contador_da_pontuacao
		jal mover_pac_man
		
		# passagem de estagio
		beq $s7, 101, end_game_loop_stage_1 # 144 pontos no maximo, stage 1
		
		# movimentacao dos fantasmas
		sleep(180) # velocidade do fantasma vermelho
		jal movimentar_fantasma_vermelho
		beq $v0, 1, colisao_stage_1
		#sleep(45) # velocidade do fantasma laranja
		jal movimentar_fantasma_laranja
		beq $v0, 1, colisao_stage_1
		#sleep(45) # velocidade do fantasma ciano
		jal movimentar_fantasma_ciano
		beq $v0, 1, colisao_stage_1
		#sleep(45) # velocidade do fantasma rosa
		jal movimentar_fantasma_rosa
		beq $v0, 1, colisao_stage_1
		
		# configura as colisões
		j sem_colisao_stage_1
		colisao_stage_1:
		jal configurar_colisao
		beq $v0, 1, wait_1
		sem_colisao_stage_1:
	j game_loop_stage_1
	end_game_loop_stage_1:
	
	stage(2)
	jal resetar_labirinto
	jal paint_stage_2
	jal paint_stage_text
	
	# espera uma tecla ser pressionada para iniciar o movimento do pac man
	wait_2: 
	jal posicionar_personagens
	jal paint_lives
	press_any_key()

	game_loop_stage_2:
	beqz $s6, game_over
		# movimentacao do pac man
		sleep(200) # velocidade do pac man (PIXEL / MILISEGUNDO)
		jal contador_da_pontuacao
		jal mover_pac_man
		
		beq $s7, 201, end_game_loop_stage_2 # 130 pontos stage 2, 274 no total.
		
		# movimentacao dos fantasmas
		sleep(45) # velocidade do fantasma vermelho
		jal movimentar_fantasma_vermelho
		beq $v0, 1, colisao_stage_2
		sleep(45) # velocidade do fantasma laranja
		jal movimentar_fantasma_laranja
		beq $v0, 1, colisao_stage_2
		sleep(45) # velocidade do fantasma ciano
		jal movimentar_fantasma_ciano
		beq $v0, 1, colisao_stage_2
		sleep(45) # velocidade do fantasma rosa
		jal movimentar_fantasma_rosa
		beq $v0, 1, colisao_stage_2
		
		# configura as colisões
		j sem_colisao_stage_2
		colisao_stage_2:
		jal configurar_colisao
		beq $v0, 1, wait_2
		sem_colisao_stage_2:
	j game_loop_stage_2
	end_game_loop_stage_2:
	
	you_win:
	jal resetar_labirinto
	jal paint_you_win
	j end_of_program
	
	game_over:
	jal resetar_labirinto
	jal paint_game_over

end_of_program:
li $v0, 10 # fim do programa
syscall





# checa se o pac man tocou em algum fantasma
# se ocorreu uma colisao a funcao pinta a nova quantidade de vidas
# $v0 - retorna 1 se houver colisão, 0 se não houver
configurar_colisao:
	sub $s6, $s6, 1		# atualiza a quantidade total de vidas
	
	# repintando posicao atual do pac man da devida cor
	lw $t0, color_black
	sw $t0, 0($s0)
	
	# repintando posicao atual do fantasma red da devida cor
	lw $t0, indicador_white_red
	beqz $t0, black_reposicionar_red 
	lw $a3, color_white
	sw $a3, 0($s1)
	sw $zero, indicador_white_red
	j exit_reposicionar_red
	black_reposicionar_red:
	lw $a3, color_black
	sw $a3, 0($s1)
	exit_reposicionar_red:
	
	# repintando posicao atual do fantasma orange da devida cor
	lw $t0, indicador_white_orange
	beqz $t0, black_reposicionar_orange 
	lw $a3, color_white
	sw $a3, 0($s2)
	sw $zero, indicador_white_orange
	j exit_reposicionar_orange
	black_reposicionar_orange:
	lw $a3, color_black
	sw $a3, 0($s2)
	exit_reposicionar_orange:
	
	# repintando posicao atual do fantasma ciano da devida cor
	lw $t0, indicador_white_ciano
	beqz $t0, black_reposicionar_ciano
	lw $a3, color_white
	sw $a3, 0($s3)
	sw $zero, indicador_white_ciano
	j exit_reposicionar_ciano
	black_reposicionar_ciano:
	lw $a3, color_black
	sw $a3, 0($s3)
	exit_reposicionar_ciano:
	
	# repintando posicao atual do fantasma pink da devida cor
	lw $t0, indicador_white_pink
	beqz $t0, black_reposicionar_pink
	lw $a3, color_white
	sw $a3, 0($s4)
	sw $zero, indicador_white_pink
	j exit_reposicionar_pink
	black_reposicionar_pink:
	lw $a3, color_black
	sw $a3, 0($s4)
	exit_reposicionar_pink:
jr $ra



# posiciona os personagens de acordo com o stage
# usado no inicio do jogo ou quando uma vida é perdida
# o stage é salvo em $s5
posicionar_personagens:
	la $a0, display_address
	beq $s5, 1, posicionar_stage_1
	j nao_posicionar_stage_1
	posicionar_stage_1:
		##### pintando personagens nas devidas posições #####
		lw $a3, color_yellow
		sw $a3, 1340($a0)
		lw $a3, color_red
		sw $a3, 4916($a0) 
		lw $a3, color_orange
		sw $a3, 4920($a0)
		lw $a3, color_ciano
		sw $a3, 4928($a0)
		lw $a3, color_pink
		sw $a3, 4932($a0)
	
		###### endereço dos personagens no bitmap ######
		addi $s0, $a0, 1340 # pac man
		addi $s1, $a0, 4916  # red ghost
		addi $s2, $a0, 4920  # orange ghost
		addi $s3, $a0, 4928 # ciano ghost
		addi $s4, $a0, 4932 # pink ghost
	j nao_posicionar_stage_2
	nao_posicionar_stage_1:
		
	beq $s5, 2, posicionar_stage_2
	j nao_posicionar_stage_2
	posicionar_stage_2:
		##### pintando personagens nas devidas posições #####
		lw $a3, color_yellow
		sw $a3, 3900($a0)
		lw $a3, color_red
		sw $a3, 5428($a0) 
		lw $a3, color_orange
		sw $a3, 5432($a0)
		lw $a3, color_ciano
		sw $a3, 5440($a0)
		lw $a3, color_pink
		sw $a3, 5444($a0)
	
		###### endereço dos personagens no bitmap ######
		addi $s0, $a0, 3900 # pac man
		addi $s1, $a0, 5428  # red ghost
		addi $s2, $a0, 5432  # orange ghost
		addi $s3, $a0, 5440 # ciano ghost
		addi $s4, $a0, 5444 # pink ghost
	nao_posicionar_stage_2:
jr $ra





# pinta no display a pontuacao atual
# recebe a pontuacao em $s7
contador_da_pontuacao:
	move $t8, $s7 # guarda num registrador auxiliar a pontuacao total

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# armazenando o dígito da centena em $t1
	div $t1, $t8, 100	#
	mul $t4, $t1, 100	#	PINTANDO O DISPLAY DA CENTENA
	sub $t8, $t8, $t4	#
				#
	move $a1, $t1		# valor a ser pintado
	li $a2, 1		# display a ser pintado
	jal contador_display
	
	lw $t0, 4($sp)
	
	# armazenando o dígito da dezena em $t2
	div $t2, $t8, 10	#
	mul $t4, $t2, 10	#	PINTANDO O DISPLAY DA DEZENA
	sub $t8, $t8, $t4	#
				#
	move $a1, $t2		# valor a ser pintado
	li $a2, 2		# display a ser pintado
	jal contador_display
	
	# armazenando o dígito da unidade em $t3
	move $t3, $t8		#
				#
	move $a1, $t3		# valor a ser pintado
	li $a2, 3		# display a ser pintado
	jal contador_display
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra






mover_pac_man:
	la $a0, display_address # se nao pegar, testar com load word
	lw $v0, 0xffff0004	# movimento com keyboard
	#li $v0, 12
	#syscall
	
	beq $v0, 119, mover_w
	j nao_mover_w
	mover_w:
		sub $t0, $s0, 256  			# calculo a nova posicao e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posicao
		beq $t2, $t1, fim_mover_pac_man 	# PAREDE, NÃO MOVER
		lw $t1, color_white			# salva a nova posicao do pac man
		
		beq $t2, $t1, incrementar_pontuacao_w 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_w
		incrementar_pontuacao_w:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_w:
		
		lw $t1, color_yellow
		sw $t1, 0($t0) # nova posicao de vermelho
		lw $t1, color_black #  pinta posicao antiga de preto
		sw $t1, 0($s0)
		sub $s0, $s0, 256
		j fim_mover_pac_man
	nao_mover_w:
	beq $v0, 97, mover_a
	j nao_mover_a
	mover_a:
		sub $t0, $s0, 4  			# calculo a nova posicao e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posicao
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white			# salva a nova posicao do pac man
		
		beq $t2, $t1, incrementar_pontuacao_a 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_a
		incrementar_pontuacao_a:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_a:
		
		addi $t1, $a0, 3844 # endereço do portal da esquerda
		beq $t0, $t1, mover_pelo_portal_w  # se der falso, entao é um movimento comum
		
		# MOVIMENTO COMUM
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posicao de vermelho
		lw $t1, color_black  			# pinta posicao antida de preto
		sw $t1, 0($s0) 				# posicao antiga do personagem
		sub $s0, $s0, 4				# salva a nova posicao do pac man
		j fim_mover_pac_man
		
		# MOVIMENTO PELO PORTAL ESQUERDO - muda a posicao para 3952
		mover_pelo_portal_w:
		addi $t0, $a0, 3952   	# endereço do portal direito
		lw $t1, color_yellow	# carregando a cor amarela
		sw $t1, 0($t0)		# pintando o pac man no outro portal
		lw $t1, color_black	# carregando a cor preto
		sw $t1, 0($s0)		# pintando de preto onde o pac man estava
		addi $s0, $a0, 3952	# salva a nova posicao do pac man
		
		j fim_mover_pac_man
	nao_mover_a:
	beq $v0, 115, mover_s
	j nao_mover_s
	mover_s:
		add $t0, $s0, 256  			# calculo a nova posicao e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posicao
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white
		
		beq $t2, $t1, incrementar_pontuacao_s 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_s
		incrementar_pontuacao_s:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_s:
		
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posicao de vermelho
		lw $t1, color_black  			# pinta posicao antida de preto
		sw $t1, 0($s0) 				# posicao antiga do personagem
		add $s0, $s0, 256
		j fim_mover_pac_man
	nao_mover_s:
	beq $v0, 100, mover_d
	j nao_mover_d
	mover_d:
		add $t0, $s0, 4  			# calculo a nova posicao e armazeno em $t0
		lw $t1, color_blue			# carrego a cor branca em $t1
		lw $t2, 0($t0)				# carrego o conteudo da nova posicao
		beq $t2, $t1, fim_mover_pac_man 	# se o conteudo for a cor azul, nao mover
		lw $t1, color_white
		
		beq $t2, $t1, incrementar_pontuacao_d 	# INCREMENTAR PONTUACAO
		j nao_incrementar_pontuacao_d
		incrementar_pontuacao_d:
			addi $s7, $s7, 1
		nao_incrementar_pontuacao_d:
		
		addi $t1, $a0, 3956 # endereço do portal da direita
		beq $t0, $t1, mover_pelo_portal_d  # se der falso, entao é um movimento comum
		
		# MOVIMENTO COMUM
		lw $t1, color_yellow
		sw $t1, 0($t0) 				# nova posicao de vermelho
		lw $t1, color_black 			# pinta posicao antida de preto
		sw $t1, 0($s0) 				# posicao antiga do personagem
		add $s0, $s0, 4				# salva a nova posicao do pac man
		j fim_mover_pac_man
		
		# MOVIMENTO PELO PORTAL DIREITO - muda a posicao para 3848
		mover_pelo_portal_d:
		addi $t0, $a0, 3848   	# endereço do portal direito
		lw $t1, color_yellow	# carregando a cor amarela
		sw $t1, 0($t0)		# pintando o pac man no outro portal
		lw $t1, color_black	# carregando a cor preto
		sw $t1, 0($s0)		# pintando de preto onde o pac man estava
		addi $s0, $a0, 3848	# salva a nova posicao do pac man
		
		j fim_mover_pac_man
	nao_mover_d:
	
	fim_mover_pac_man:
jr $ra





# pinta no display o labirinto e  a pontuacao
paint_stage_1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	###### labirinto ######
	set_cor_intervalo(4, color_blue)
	paint_line(260,372)
	paint_line(836,856)
	paint_line(780,792)
	paint_line(800,820)
	paint_line(864,876)
	paint_line(7428,7540)
	paint_line(1036,1048)
	paint_line(1548,1560)
	paint_line(1804,1816)
	paint_line(2316,2328)
	paint_line(2572,2584)
	paint_line(1120,1132)
	paint_line(1632,1644)
	paint_line(1888,1900)
	paint_line(2400,2412)
	paint_line(2656,2668)
	paint_line(1056,1076)
	paint_line(1092,1112)
	paint_line(1580,1612)
	paint_line(1836,1868)
	paint_line(2336,2352)
	paint_line(2592,2608)
	paint_line(2376,2392)
	paint_line(1836,1868)
	paint_line(2336,2352)
	paint_line(2592,2608)
	paint_line(2376,2392)
	paint_line(2632,2648)
	paint_line(3076,3096)
	paint_line(3168,3188)
	paint_line(4612,4632)
	paint_line(4704,4724)
	paint_line(3120,3144)
	paint_line(3376,3400)
	paint_line(3632,3656)
	paint_line(3888,3912)
	paint_line(4144,4168)
	paint_line(4400,4424)
	paint_line(4656,4680)
	paint_line(5132,5144)
	paint_line(5388,5400)
	paint_line(5900,5912)
	paint_line(6156,6168)
	paint_line(6668,6680)
	paint_line(6924,6936)
	paint_line(5216,5228)
	paint_line(5472,5484)
	paint_line(5984,5996)
	paint_line(6240,6252)
	paint_line(6752,6764)
	paint_line(7008,7020)
	paint_line(5152,5168)
	paint_line(5408,5424)
	paint_line(5192,5208)
	paint_line(5448,5464)
	paint_line(5932,5964)
	paint_line(6188,6220)
	paint_line(6688,6708)
	paint_line(6944,6964)
	paint_line(6724,6744)
	paint_line(6980,7000)

	set_cor_intervalo(256, color_blue)
	paint_line(516,2820)
	paint_line(628,2932)
	paint_line(572,1084)
	paint_line(1568,2080)
	paint_line(1572,2084)
	paint_line(1620,2132)
	paint_line(1624,2136)
	paint_line(2104,2616)
	paint_line(2112,2624)
	paint_line(2108,2620)
	paint_line(3352,4376)
	paint_line(3424,4448)
	paint_line(3104,4640)
	paint_line(3108,4644)
	paint_line(3112,4668)
	paint_line(3152,4688)
	paint_line(3156,4692)
	paint_line(3160,4696)
	paint_line(4868,7172)
	paint_line(4980,7284)
	paint_line(5664,6176)
	paint_line(5668,6180)
	paint_line(5716,6228)
	paint_line(5720,6232)
	paint_line(6716,7228)
	paint_line(5176,5688)
	paint_line(5184,5696)
	paint_line(5180,5692)
	
	####### pontos ########
	set_cor_intervalo(8, color_white)
	paint_line(520,568)
	paint_line(576,624)
	paint_line(2828,2924)
	paint_line(1292,1332)
	paint_line(1348,1388)
	paint_line(4876,4908)
	paint_line(4940,4972)
	paint_line(6412,6508)
	paint_line(7176,7224)
	paint_line(7232,7280)
	paint_line(2064,2072)
	paint_line(2088,2096)
	paint_line(2120,2128)
	paint_line(2144,2152)
	paint_line(5648,5656)
	paint_line(5672,5680)
	paint_line(5704,5712)
	paint_line(5728,5736)

	set_cor_intervalo(512, color_white)
	paint_line(1032,2568)
	paint_line(1136,2672)
	paint_line(796,6940)
	paint_line(860,7004)
	paint_line(5128,6664)
	paint_line(5232,6768)
	paint_line(3372,4396)
	paint_line(3404,4428)
	
	sw $a3, 1080($a0)
	sw $a3, 1088($a0)
	sw $a3, 1576($a0)
	sw $a3, 1616($a0)
	sw $a3, 2356($a0)
	sw $a3, 2372($a0)
	sw $a3, 5428($a0)
	sw $a3, 5444($a0)
	sw $a3, 6184($a0)
	sw $a3, 6224($a0)
	sw $a3, 6712($a0)
	sw $a3, 6720($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra





# pinta no display o labirinto e a pontuacao
paint_stage_2:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# pintando labirinto
	set_cor_intervalo(4, color_blue)
	paint_line(260,372)
	paint_line(800,824)
	paint_line(832,856)
	paint_line(1056,1080)
	paint_line(1088,1112)
	paint_line(1312,1336)
	paint_line(1344,1368)
	paint_line(1568,1592)
	paint_line(1600,1624)
	paint_line(1824,1848)
	paint_line(1856,1880)
	paint_line(2348,2380)
	paint_line(2604,2636)
	paint_line(2316,2328)
	paint_line(2572,2584)
	paint_line(2828,2840)
	paint_line(3084,3096)
	paint_line(3104,3120)
	paint_line(3360,3376)
	paint_line(3616,3632)
	paint_line(2400,2412)
	paint_line(2656,2668)
	paint_line(2912,2924)
	paint_line(3168,3180)
	paint_line(3144,3160)
	paint_line(3400,3416)
	paint_line(3656,3672)
	paint_line(3588,3608)
	paint_line(4100,4120)
	paint_line(3680,3700)
	paint_line(4192,4212)
	paint_line(4128,4136)
	paint_line(4384,4392)
	paint_line(4620,4648)
	paint_line(4876,4904)
	paint_line(5132,5160)
	paint_line(4144,4168)
	paint_line(4400,4424)
	paint_line(4656,4680)
	paint_line(4912,4936)
	paint_line(5168,5192)
	paint_line(4176,4184)
	paint_line(4432,4440)
	paint_line(4688,4716)
	paint_line(4944,4972)
	paint_line(5200,5228)
	paint_line(7172,7284)
	
	set_cor_intervalo(20, color_blue)
	paint_line(5656,5716)
	paint_line(5660,5720)
	paint_line(5664,5724)
	paint_line(5668,5728)
	paint_line(5912,5972)
	paint_line(5916,5976)
	paint_line(5920,5980)
	paint_line(5924,5984)
	paint_line(6424,6484)
	paint_line(6428,6488)
	paint_line(6432,6492)
	paint_line(6436,6496)
	paint_line(6680,6740)
	paint_line(6684,6744)
	paint_line(6688,6748)
	paint_line(6692,6752)

	set_cor_intervalo(256, color_blue)
	paint_line(516,3332)
	paint_line(864,1888)
	paint_line(868,1892)
	paint_line(872,1896)
	paint_line(876,1900)
	paint_line(780,1804)
	paint_line(784,1808)
	paint_line(788,1812)
	paint_line(792,1816)
	paint_line(628,3444)
	paint_line(4468,7028)
	paint_line(5644,6668)
	paint_line(5648,6672)
	paint_line(5736,6760)
	paint_line(5740,6764)
	paint_line(4356,6916)
	paint_line(2336,2848)
	paint_line(2340,2852)
	paint_line(2388,2900)
	paint_line(2392,2904)
	paint_line(2872,3640)
	paint_line(2876,3644)
	paint_line(2880,3648)

	# pintando pontuacao
	set_cor_intervalo(8, color_white)
	paint_line(520,624)
	paint_line(6920,7024)
	paint_line(4364,4380)
	paint_line(5384,5416)
	paint_line(6164,6244)
	paint_line(5456,5488)
	paint_line(3868,3932)
	paint_line(3340,3356)
	paint_line(3420,3436)
	paint_line(2056,2160)
	paint_line(4444,4460)
	paint_line(2860,2868)
	paint_line(2884,2892)


	set_cor_intervalo(512, color_white)
	paint_line(1032,3080)
	paint_line(796,4380)
	paint_line(2868,3892)
	paint_line(2884,3908)
	paint_line(828,1852)
	paint_line(860,4444)
	paint_line(1136,3184)
	paint_line(4872,6920)
	paint_line(5652,6676)
	paint_line(5928,6440)
	paint_line(5692,6716)
	paint_line(5968,6480)
	paint_line(5732,6756)
	paint_line(4976,7024)
	paint_line(4428,4940)
	paint_line(4396,4908)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra






paint_pts:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	set_cor_intervalo(4, color_white)
	paint_line(3480,3484)
	paint_line(3992,3996)
	paint_line(3492,3500)
	paint_line(3508,3516)
	paint_line(4020,4028)
	paint_line(4532,4540)

	set_cor_intervalo(256, color_white)
	paint_line(3476,4500)
	paint_line(3752,4520)

	sw $a3, 3740($a0)
	sw $a3, 3764($a0)
	sw $a3, 4284($a0)
	sw $a3, 3780($a0)
	sw $a3, 4548($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra








# pinta o TEXTO stage e o valor do stage atual
# $s5 - armazena o valor do stage atual
paint_stage_text:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	set_cor_intervalo(4, color_white)
	paint_line(660,668)
	paint_line(676,684)
	paint_line(692,700)
	paint_line(708,720)
	paint_line(1732,1744)
	paint_line(1172,1180)
	paint_line(1684,1692)

	set_cor_intervalo(256, color_white)
	paint_line(936,1704)
	paint_line(948,1716)
	paint_line(956,1724)
	paint_line(964,1476)
	paint_line(728,1752)
		
	sw $a3, 916($a0)
	sw $a3, 1436($a0)
	sw $a3, 1464($a0)
	sw $a3, 1228($a0)
	sw $a3, 1232($a0)
	sw $a3, 1488($a0)
	sw $a3, 732($a0)
	sw $a3, 736($a0)
	sw $a3, 1244($a0)
	sw $a3, 1248($a0)
	sw $a3, 1756($a0)
	sw $a3, 1760($a0)

	beq $s5, 1, stage_1_texto
	j nao_stage_1_texto
	stage_1_texto:
		set_cor_intervalo(4, color_white)
		paint_line(1772,1780)
		
		set_cor_intervalo(256, color_white)
		paint_line(752,1520)

		sw $a3, 1004($a0)
		
		lw $a3, color_black

		sw $a3, 748($a0)
		sw $a3, 756($a0)
		sw $a3, 1260($a0)
		sw $a3, 1516($a0)
		sw $a3, 1012($a0)
		sw $a3, 1268($a0)
		sw $a3, 1524($a0)
	j nao_stage_2_texto
	nao_stage_1_texto:
	
	beq $s5, 2, stage_2_texto
	j nao_stage_2_texto
	stage_2_texto:
		set_cor_intervalo(4, color_white)
		paint_line(748,756)
		paint_line(1260,1268)
		paint_line(1772,1780)

		sw $a3, 1012($a0)
		sw $a3, 1516($a0)
		
		lw $a3, color_black
		
		sw $a3, 1004($a0)
		sw $a3, 1008($a0)
		sw $a3, 1520($a0)
		sw $a3, 1524($a0)
	nao_stage_2_texto:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra







# pinta os "pac man's" grandes que representam as vidas
# pinta de acordo com a quantidade de vidas armazenados em $s6
# $s6 - quantidade de vidas
paint_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, display_address
	lw $a3, color_yellow
	
	li $t0, 0 # contador do laço
	li $t1, 0 # contador do endereço do pac man (conta de 32 a 32)
	
	# contador auxiliar da pintura de vidas
	li $t4, 0 # conta a partir de qual vida as demais seão pintadas de preto
	
	paint_lives_loop:
	beq $t0, 3, end_paint_lives_loop
		
		beq $t4, $s6, pintar_vidas_de_preto
		j nao_pintar_vidas_de_preto
		pintar_vidas_de_preto:
			lw $a3, color_black
		nao_pintar_vidas_de_preto:
		
		paint_by_address(6048)
		paint_by_address(6052)
		paint_by_address(6056)
		paint_by_address(6300)
		paint_by_address(6304)
		paint_by_address(6308)
		paint_by_address(6312)
		paint_by_address(6316)
		paint_by_address(6552)
		paint_by_address(6556)
		paint_by_address(6560)
		paint_by_address(6564)
		paint_by_address(6808)
		paint_by_address(6812)
		paint_by_address(7064)
		paint_by_address(7068)
		paint_by_address(7072)
		paint_by_address(7076)
		paint_by_address(7324)
		paint_by_address(7328)
		paint_by_address(7332)
		paint_by_address(7336)
		paint_by_address(7340)
		paint_by_address(7584)
		paint_by_address(7588)
		paint_by_address(7592)

	addi $t1, $t1, 32 # contador do enrereço
	addi $t0, $t0, 1 # contador do laço 
	addi $t4, $t4, 1 # contador da pintura
	j paint_lives_loop
	end_paint_lives_loop:
		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra







# pinta uma linha dentro de um intervalo determinado
# $a0 - display_address
# $a1 - endereço inicial
# $a2 - endereço final
# $a3 - cor a ser pintada
# $t1 - intervalo entre os pixels
paint_line:
	la $a0, display_address
	paint_line_loop:
	bgt $a1, $a2, end_paint_line_loop
	add $t0, $a1, $a0
	sw $a3, 0($t0)
	add $a1, $a1, $t1
	j paint_line_loop
	end_paint_line_loop:
jr $ra






# considero o terceiro contador como padrão
# se for o contador 3 nçao incremento o reg contador
# se for o contador 2 incrementar o counter em 16
# se for o contador 2 incrementar o counter em 32
# $a1 - valor a ser pintado
# $a2 - (1 = msb, 3 = lsb)
contador_display:
	la $a0, display_address
	
	# contador 3
	beq $a2, 3, contador_3
	j nao_contador_3
	contador_3:
		li $t0, 32
	j nao_contador_1
	nao_contador_3:
	# contador 2
	beq $a2, 2, contador_2
	j nao_contador_2
	contador_2:
		li $t0, 16
	j nao_contador_1
	nao_contador_2:
	# contador 1
	beq $a2, 1, contador_1
	j nao_contador_1
	contador_1:
		li $t0, 0
	nao_contador_1:
	
	# case 0
	beq $a1, 0, pintar_0
	j nao_pintar_0
	pintar_0:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(3788)
		paint_by_address_2(3796)
		paint_by_address_2(4044)
		paint_by_address_2(4052)
		paint_by_address_2(4300)
		paint_by_address_2(4308)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		
		lw $t2, color_black
		paint_by_address_2(3792)
		paint_by_address_2(4048)
		paint_by_address_2(4304)

	j fim_contador_display
	nao_pintar_0:
	# case 1
	beq $a1, 1, pintar_1
	j nao_pintar_1
	pintar_1:

		lw $t2, color_white
		paint_by_address_2(3536)
		paint_by_address_2(3788)
		paint_by_address_2(3792)
		paint_by_address_2(4048)
		paint_by_address_2(4304)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)

		lw $t2, color_black
		paint_by_address_2(3532)
		paint_by_address_2(3540)
		paint_by_address_2(3796)
		paint_by_address_2(4052)
		paint_by_address_2(4308)
		paint_by_address_2(4044)
		paint_by_address_2(4300)

	j fim_contador_display
	nao_pintar_1:
	# case 2
	beq $a1, 2, pintar_2
	j nao_pintar_2
	pintar_2:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(3796)
		paint_by_address_2(4052)
		paint_by_address_2(4048)
		paint_by_address_2(4044)
		paint_by_address_2(4300)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)

		lw $t2, color_black
		paint_by_address_2(3788)
		paint_by_address_2(3792)
		paint_by_address_2(4304)
		paint_by_address_2(4308)

	j fim_contador_display
	nao_pintar_2:
	# case 3
	beq $a1, 3, pintar_3
	j nao_pintar_3
	pintar_3:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		paint_by_address_2(3796)
		paint_by_address_2(4308)

		lw $t2, color_black
		paint_by_address_2(3788)
		paint_by_address_2(3792)
		paint_by_address_2(4300)
		paint_by_address_2(4304)
		
	j fim_contador_display
	nao_pintar_3:
	# case 4
	beq $a1, 4, pintar_4
	j nao_pintar_4
	pintar_4:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3788)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(3540)
		paint_by_address_2(3796)
		paint_by_address_2(4308)
		paint_by_address_2(4564)

		lw $t2, color_black
		paint_by_address_2(3536)
		paint_by_address_2(3792)
		paint_by_address_2(4300)
		paint_by_address_2(4304)
		paint_by_address_2(4556)
		paint_by_address_2(4560)

	j fim_contador_display
	nao_pintar_4:
	# case 5
	beq $a1, 5, pintar_5
	j nao_pintar_5
	pintar_5:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		paint_by_address_2(3788)
		paint_by_address_2(4308)

		lw $t2, color_black
		paint_by_address_2(3792)
		paint_by_address_2(3796)
		paint_by_address_2(4300)
		paint_by_address_2(4304)

	j fim_contador_display
	nao_pintar_5:
	# case 6
	beq $a1, 6, pintar_6
	j nao_pintar_6
	pintar_6:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		paint_by_address_2(3788)
		paint_by_address_2(4300)
		paint_by_address_2(4308)

		lw $t2, color_black
		paint_by_address_2(3792)
		paint_by_address_2(3796)
		paint_by_address_2(4304)
		
	j fim_contador_display
	nao_pintar_6:
	# case 7
	beq $a1, 7, pintar_7
	j nao_pintar_7
	pintar_7:
		lw $t2, color_white
		
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(3796)
		paint_by_address_2(4052)
		paint_by_address_2(4308)
		paint_by_address_2(4564)

		lw $t2, color_black
		paint_by_address_2(3788)
		paint_by_address_2(3792)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4300)
		paint_by_address_2(4304)
		paint_by_address_2(4556)
		paint_by_address_2(4560)

	j fim_contador_display
	nao_pintar_7:
	# case 8
	beq $a1, 8, pintar_8
	j nao_pintar_8
	pintar_8:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		paint_by_address_2(3788)
		paint_by_address_2(3796)
		paint_by_address_2(4300)
		paint_by_address_2(4308)

		lw $t2, color_black
		paint_by_address_2(3792)
		paint_by_address_2(4304)

	j fim_contador_display
	nao_pintar_8:
	# case 9
	beq $a1, 9, pintar_9
	j nao_pintar_9
	pintar_9:

		lw $t2, color_white
		paint_by_address_2(3532)
		paint_by_address_2(3536)
		paint_by_address_2(3540)
		paint_by_address_2(4044)
		paint_by_address_2(4048)
		paint_by_address_2(4052)
		paint_by_address_2(4556)
		paint_by_address_2(4560)
		paint_by_address_2(4564)
		paint_by_address_2(3788)
		paint_by_address_2(3796)
		paint_by_address_2(4308)

		lw $t2, color_black
		paint_by_address_2(3792)
		paint_by_address_2(4300)
		paint_by_address_2(4304)

	j fim_contador_display
	nao_pintar_9:
	
	fim_contador_display:
jr $ra











paint_game_over:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	## G ##
	set_cor_intervalo(256, color_red)
	paint_line(2068,3860)
	paint_line(2320,3600)
	paint_line(2852,3876)
	paint_line(2856,3624)

	set_cor_intervalo(4, color_red)
	paint_line(2072,2084)
	paint_line(2328,2340)
	paint_line(3608,3616)
	paint_line(3864,3872)

	sw $a3, 2848($a0)
	sw $a3, 3104($a0)
	
	## A ##
	
	set_cor_intervalo(256, color_red)
	paint_line(2352,3888)
	paint_line(2100,3892)
	paint_line(2108,3900)
	paint_line(2368,3904)
	
	sw $a3, 2104($a0)
	sw $a3, 2360($a0)
	sw $a3, 3128($a0)
	sw $a3, 3384($a0)
	
	## M ##
	
	set_cor_intervalo(256, color_red)
	paint_line(2120,3912)
	paint_line(2124,3916)
	paint_line(2384,2896)
	paint_line(2644,3156)
	paint_line(2904,3416)
	paint_line(2652,3164)
	paint_line(2400,2912)
	paint_line(2148,3940)
	paint_line(2152,3944)
	
	## E ##

	set_cor_intervalo(256, color_red)
	paint_line(2160,3952)
	paint_line(2164,3956)

	set_cor_intervalo(4, color_red)
	paint_line(2168,2176)
	paint_line(2424,2432)
	paint_line(2936,2944)
	paint_line(3192,3200)
	paint_line(3704,3712)
	paint_line(3960,3968)
		
	## O ##
	set_cor_intervalo(256, color_red)
	paint_line(4628,5908)
	paint_line(4376,6168)
	paint_line(4388,6180)
	paint_line(4648,5928)
	
	sw $a3, 4380($a0)
	sw $a3, 4384($a0)
	sw $a3, 4636($a0)
	sw $a3, 4640($a0)
	sw $a3, 5916($a0)
	sw $a3, 5920($a0)
	sw $a3, 6172($a0)
	sw $a3, 6176($a0)
	
	## V ##

	paint_line(4400,5680)
	paint_line(4404,5940)
	paint_line(4420,5956)
	paint_line(4424,5704)
	paint_line(5688,6200)
	paint_line(5696,6208)

	sw $a3, 5948($a0)
	sw $a3, 6204($a0)
	
	## E ##
	
	paint_line(4432,6224)
	paint_line(4436,6228)

	set_cor_intervalo(4, color_red)
	paint_line(4440,4448)
	paint_line(5208,5216)
	paint_line(4696,4704)
	paint_line(5464,5472)
	paint_line(5976,5984)
	paint_line(6232,6240)
	
	## R ##
	
	set_cor_intervalo(256, color_red)
	paint_line(4456,6248)
	paint_line(4460,6252)
	paint_line(4472,6264)
	paint_line(4732,5244)
	paint_line(5756,6268)

	sw $a3, 4464($a0)
	sw $a3, 4468($a0)
	sw $a3, 4720($a0)
	sw $a3, 4724($a0)
	sw $a3, 5488($a0)
	sw $a3, 5492($a0)
	sw $a3, 5744($a0)
	sw $a3, 5748($a0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra

















paint_you_win:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	### Y #####

	set_cor_intervalo(256, color_red)
	paint_line(2076,2332)
	paint_line(2080,2592)
	paint_line(2340,2852)
	paint_line(2600,3880)
	paint_line(2604,3884)
	paint_line(2352,2864)
	paint_line(2100,2612)
	paint_line(2104,2360)
	
	#### O ###
	
	paint_line(2368,3648)
	paint_line(2116,3908)
	paint_line(2128,3920)
	paint_line(2388,3668)

	sw $a3, 2120($a0)
	sw $a3, 2124($a0)
	sw $a3, 2376($a0)
	sw $a3, 2380($a0)
	sw $a3, 3656($a0)
	sw $a3, 3660($a0)
	sw $a3, 3912($a0)
	sw $a3, 3916($a0)
	
	## U ##

	paint_line(2140,3676)
	paint_line(2144,3936)
	paint_line(2160,3952)
	paint_line(2164,3700)
	paint_line(3684,3940)
	paint_line(3688,3944)
	paint_line(3692,3948)

	## W ##

	paint_line(4376,5656)
	paint_line(4380,5916)
	paint_line(5664,6176)
	paint_line(5672,6184)
	paint_line(4396,5932)
	paint_line(4400,5936)
	paint_line(4416,5952)
	paint_line(4420,5700)
	paint_line(5684,6196)
	paint_line(5692,6204)

	sw $a3, 5924($a0)
	sw $a3, 6180($a0)
	sw $a3, 5944($a0)
	sw $a3, 6200($a0)	
	
	## I ##

	paint_line(5200,6224)
	paint_line(5196,6220)
	
	sw $a3, 4428($a0)
	sw $a3, 4432($a0)
	sw $a3, 4684($a0)
	sw $a3, 4688($a0)
	
	## N ##
	
	paint_line(4440,6232)
	paint_line(4444,6236)
	paint_line(4468,6260)
	paint_line(4472,6264)
	paint_line(4704,4960)
	paint_line(4964,5220)
	paint_line(5224,5480)
	paint_line(5484,5740)
	paint_line(5744,6000)

	lw $ra, 0($sp)
	addi $sp, $sp, 4
jr $ra

# pinta o labirinto de preto
resetar_labirinto:
	la $a0, display_address
	li $t4, 260
	lw $a3, color_black
	li $t1, 4
	
	addi $sp, $sp, -4
	sw $ra 0($sp)

	loop_reset:
	bgt $t4, 7428, end_loop_reset
		move $a1, $t4
		addi $a2, $t4, 112
		jal paint_line
	addi $t4, $t4, 256
	j loop_reset
	end_loop_reset:
	
	lw $ra 0($sp)
	addi $sp, $sp, 4
jr $ra
		
movimentar_fantasma_vermelho:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos validos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s1, 256	# endereço fantasma vermelho acima
	sub $t2, $s1, 4		# endereço fantasma vermelho esquerda
	addi $t3, $s1, 256	# endereço fantasma vermelho abaixo
	addi $t4, $s1, 4	# endereço fantasma vermelho direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_red # parede acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_red # fantasma laranja acima
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_cima_red # fantasma azul acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_red # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_red:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_red # parede a esquerda
	lw $a3, color_orange
	beq $a3, $a2, invalido_esquerda_red # fantasma laranja a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_red # fantasma azul a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_red # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_red:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_red # parede abaixo
	lw $a3, color_orange
	beq $a3, $a2, invalido_baixo_red # fantasma laranja abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_red # fantasma azul abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_red # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_red:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_red # parede a direita
	lw $a3, color_orange
	beq $a3, $a2, invalido_direita_red # fantasma laranja a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_red # fantasma azul a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_red # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_red:
	
	### 2º parte, segue para os calculos de movimentacao ###
	beq $t0, 0, nenhum_movimento_possivel_red
	beq $t0, 1, um_movimento_possivel_red
	beq $t0, 2, dois_movimentos_possiveis_red
	beq $t0, 3, tres_movimentos_possiveis_red
	beq $t0, 4, quatro_movimentos_possiveis_red
	
	# permanece na mesma posicao
	nenhum_movimento_possivel_red: 
	j end_fantasma_red
	
	# calcula qual a direcao e se movimento nela
	um_movimento_possivel_red:
		beq $t9, 1, mover_cima_red
		beq $t9, 2, mover_esquerda_red
		beq $t9, 3, mover_baixo_red
		beq $t9, 5, mover_direita_red
	
	dois_movimentos_possiveis_red:
	
		lw $t0, ultima_direcao_red
		beq $t9, 7, dois_direita_esquerda_red
		beq $t9, 4, dois_cima_baixo_red
		beq $t9, 3, dois_cima_esquerda_red
		beq $t9, 6, dois_cima_direita_red
		beq $t9, 5, dois_baixo_esquerda_red
		beq $t9, 8, dois_baixo_direita_red
		
		dois_direita_esquerda_red: # 7
			beq $t0, 2, mover_esquerda_red
			beq $t0, 5, mover_direita_red
			
		dois_cima_baixo_red: # 4
			beq $t0, 1, mover_cima_red
			beq $t0, 3, mover_baixo_red
			
		dois_cima_esquerda_red: # 3
			beq $t0, 5, mover_cima_red
			beq $t0, 3, mover_esquerda_red
			
		dois_cima_direita_red: # 6
			beq $t0, 2, mover_cima_red
			beq $t0, 3, mover_direita_red
			
		dois_baixo_esquerda_red: # 5
			beq $t0, 5, mover_baixo_red
			beq $t0, 1, mover_esquerda_red
			
		dois_baixo_direita_red: # 8
			beq $t0, 2, mover_baixo_red
			beq $t0, 1, mover_direita_red
			
	tres_movimentos_possiveis_red:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do red ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do red ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do red ghost
		move $t4, $v1 # coluna do red ghost
		
		beq $t1, $t3, tres_mesma_linha_red
		beq $t2, $t4, tres_mesma_coluna_red
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		j tres_sem_perseguicao_red
		
		tres_mesma_linha_red:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_red
			lw $t0, 0xffff0004
			beq $t0, 97, mover_esquerda_red # a
			beq $t0, 100, mover_direita_red # d
		
		tres_mesma_coluna_red:
			move $a0, $t1
			move $a1, $t2
			move $a2, $t3
			move $a3, $t4
			jal distancia_euclidiana
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			bgt $v0, 5, tres_sem_perseguicao_red
			lw $t0, 0xffff0004
			beq $t0, 119, mover_cima_red # w
			beq $t0, 115, mover_baixo_red # s
		
		tres_sem_perseguicao_red:
		
		# gerando o numero aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
	 	
	 	lw $t0, ultima_direcao_red
	 	beq $t9, 8,  direita_cima_esquerda_red
	 	beq $t9, 6,  cima_esquerda_baixo_red
	 	beq $t9, 10, esquerda_baixo_direita_red
	 	beq $t9, 9,  baixo_direita_cima_red
	 	
	 	direita_cima_esquerda_red:# 8
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, cima_esquerda_red
	 		beq $t9, 5, esquerda_direita_red
	 		beq $t9, 2, cima_direita_red
	 		
	 	cima_esquerda_baixo_red: # 6
	 		sub $t9, $t9, $t0
	 		beq $t9, 3, baixo_esquerda_red
	 		beq $t9, 1, cima_baixo_red
	 		beq $t9, 5, cima_esquerda_red
	 		
	 	esquerda_baixo_direita_red: # 10
	 		sub $t9, $t9, $t0
	 		beq $t9, 8, baixo_esquerda_red
	 		beq $t9, 9, esquerda_direita_red
	 		beq $t9, 5, baixo_direita_red
	 		
	 	baixo_direita_cima_red: # 9
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, baixo_direita_red
	 		beq $t9, 7, cima_baixo_red
	 		beq $t9, 8, cima_direita_red
	 		
	 	esquerda_direita_red:
	 		beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_direita_red
	 	
	 	cima_baixo_red:
			beq $a0, 0, mover_cima_red
	 		beq $a0, 1, mover_baixo_red
	 		
		cima_esquerda_red:
			beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_cima_red
	 		
		cima_direita_red:
			beq $a0, 0, mover_cima_red
	 		beq $a0, 1, mover_direita_red
	 		
	 	baixo_esquerda_red:
	 		beq $a0, 0, mover_esquerda_red
	 		beq $a0, 1, mover_baixo_red
	 	
	 	baixo_direita_red:
			beq $a0, 0, mover_direita_red
	 		beq $a0, 1, mover_baixo_red
		
	quatro_movimentos_possiveis_red:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do red ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do red ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do red ghost
		move $t4, $v1 # coluna do red ghost
		
		# pac man - ($t1,$t2), red ghost - ($t3,$t4)
		move $a0, $t3	# x do fantasma
		move $a1, $t4	# y do fantasma
		
		# se eles estiverem na mesma linha ou coluna
		beq $t1, $t3, mesma_linha_red
		beq $t2, $t4, mesma_coluna_red

		#determinar o quadrante que o pac man esta em relacao ao red ghost
		bgt $t3, $t1, quadrante_esquerda_red 
		j quadrante_direita_red
		
		quadrante_esquerda_red:
			blt $t4, $t1, quadrante_cima_esquerda_red
			j quadrante_baixo_esquerda_red
			
		quadrante_direita_red:
			blt $t4, $t1, quadrante_cima_direita_red
			j quadrante_baixo_direita_red
		
		# efetua a lógica dos movimentos
		quadrante_cima_esquerda_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_esquerda_red
			# ir para cima
			bgt $v1, $v0, mover_cima_red 
			# ir para esquerda
			j mover_esquerda_red
			
		quadrante_baixo_esquerda_red:
			move $a2, $t1
			move $a3, $t4 
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_esquerda_red
			# ir para cima
			bgt $v1, $v0, mover_baixo_red 
			# ir para esquerda
			j mover_esquerda_red
			
		quadrante_cima_direita_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_direita_red
			# ir para cima
			bgt $v1, $v0, mover_cima_red 
			# ir para esquerda
			j mover_direita_red
			
		quadrante_baixo_direita_red:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_direita_red
			# ir para cima
			bgt $v1, $v0, mover_baixo_red 
			# ir para esquerda
			j mover_direita_red
			
		randomico_cima_esquerda_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_red
			j  mover_esquerda_red
			
		randomico_baixo_esquerda_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_red
			j  mover_esquerda_red
			
		randomico_cima_direita_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_red
			j  mover_direita_red
			
		randomico_baixo_direita_red:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_red
			j  mover_direita_red
			
		mesma_linha_red:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			blt $t3, $t1, mover_direita_red # pac man a direita - va para direita
			j mover_esquerda_red # senão va para esquerda
			
		mesma_coluna_red:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			blt $t4, $t2, mover_cima_red
			j mover_baixo_red 
		
	mover_cima_red:
		sub $t1, $s1, 256	# endereço fantasma vermelho acima
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_cima_red_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_black_black
		j red_nao_valido_mover_cima_black_black	
		red_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_black_white
		j red_nao_valido_mover_cima_black_white	
		red_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, red_valido_mover_cima_white_black
		j red_nao_valido_mover_cima_white_black	
		red_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t1)
		sub $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 1
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_cima_white_black:
		
	mover_esquerda_red:
		sub $t2, $s1, 4		# endereço fantasma vermelho esquerda
		
		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_red
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_red
		lw $a3, color_black
		sw $a3, 0($s1)
		addi $s1, $a0, 3952
		lw $a3, color_red
		sw $a3, 0($s1)
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		nao_portal_esquerdo_red:
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_esquerda_red_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_black_black
		j red_nao_valido_mover_esquerda_black_black	
		red_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_black_white
		j red_nao_valido_mover_esquerda_black_white	
		red_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, red_valido_mover_esquerda_white_black
		j red_nao_valido_mover_esquerda_white_black	
		red_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t2)
		sub $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 2
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_red:
		addi $t3, $s1, 256	# endereço fantasma vermelho abaixo

		lw $t0, indicador_white_red
		beq $t0, 1, mover_baixo_red_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_black_black
		j red_nao_valido_mover_baixo_black_black	
		red_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_black_white
		j red_nao_valido_mover_baixo_black_white	
		red_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, red_valido_mover_baixo_white_black
		j red_nao_valido_mover_baixo_white_black	
		red_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t3)
		addi $s1, $s1, 256
		sw $zero, indicador_white_red
		li $t0, 3
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_baixo_white_black:
		
	mover_direita_red:
		addi $t4, $s1, 4	# endereço fantasma vermelho direita
		
		# portal direito
		bne $s5, 2, nao_portal_direito_red
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_red
		lw $a3, color_black
		sw $a3, 0($s1)
		addi $s1, $a0, 3848
		lw $a3, color_red
		sw $a3, 0($s1)
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		nao_portal_direito_red:
	
		lw $t0, indicador_white_red
		beq $t0, 1, mover_direita_red_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_black_black
		j red_nao_valido_mover_direita_black_black	
		red_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_black_white
		j red_nao_valido_mover_direita_black_white	
		red_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		li $t0, 1
		sw $t0, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_red_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, red_valido_mover_direita_white_black
		j red_nao_valido_mover_direita_white_black	
		red_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s1)
		lw $a3, color_red
		sw $a3, 0($t4)
		addi $s1, $s1, 4
		sw $zero, indicador_white_red
		li $t0, 5
		sw $t0, ultima_direcao_red
		j end_fantasma_red
		red_nao_valido_mover_direita_white_black:

	end_fantasma_red:
	
	sub $t1, $s1, 256
	sub $t2, $s1, 4
	addi $t3, $s1, 256
	addi $t4, $s1, 4
	
	beq $t1, $s0, colisao_red
	beq $t2, $s0, colisao_red
	beq $t3, $s0, colisao_red
	beq $t4, $s0, colisao_red
	li $v0, 0
	j end_colisao_red
	colisao_red:
	li $v0, 1
	end_colisao_red:
jr $ra
	
movimentar_fantasma_laranja:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos validos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s2, 256	# endereço fantasma orange acima
	sub $t2, $s2, 4		# endereço fantasma orange esquerda
	addi $t3, $s2, 256	# endereço fantasma orange abaixo
	addi $t4, $s2, 4	# endereço fantasma orange direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_orange # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_orange # fantasma vermelho acima
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_cima_orange # fantasma azul acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_orange # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_orange:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_orange # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_orange # fantasma vermelho a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_orange # fantasma azul a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_orange # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_orange:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_orange # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_orange # fantasma vermelho abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_orange # fantasma azul abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_orange # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_orange:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_orange # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_orange # fantasma vermelho a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_orange # fantasma azul a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_orange # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_orange:
	
	### 2º parte, segue para os calculos de movimentacao ###
	beq $t0, 0, nenhum_movimento_possivel_orange
	beq $t0, 1, um_movimento_possivel_orange
	beq $t0, 2, dois_movimentos_possiveis_orange
	beq $t0, 3, tres_movimentos_possiveis_orange
	beq $t0, 4, quatro_movimentos_possiveis_orange
	
	# permanece na mesma posicao
	nenhum_movimento_possivel_orange: 
	j end_fantasma_orange
	
	# calcula qual a direcao e se movimento nela
	um_movimento_possivel_orange:
		beq $t9, 1, mover_cima_orange
		beq $t9, 2, mover_esquerda_orange
		beq $t9, 3, mover_baixo_orange
		beq $t9, 5, mover_direita_orange
	
	dois_movimentos_possiveis_orange:
		lw $t0, ultima_direcao_orange
		beq $t9, 7, dois_direita_esquerda_orange
		beq $t9, 4, dois_cima_baixo_orange
		beq $t9, 3, dois_cima_esquerda_orange
		beq $t9, 6, dois_cima_direita_orange
		beq $t9, 5, dois_baixo_esquerda_orange
		beq $t9, 8, dois_baixo_direita_orange
		
		dois_direita_esquerda_orange: # 7
			beq $t0, 2, mover_esquerda_orange
			beq $t0, 5, mover_direita_orange
			
		dois_cima_baixo_orange: # 4
			beq $t0, 1, mover_cima_orange
			beq $t0, 3, mover_baixo_orange
			
		dois_cima_esquerda_orange: # 3
			beq $t0, 5, mover_cima_orange
			beq $t0, 3, mover_esquerda_orange
			
		dois_cima_direita_orange: # 6
			beq $t0, 2, mover_cima_orange
			beq $t0, 3, mover_direita_orange
			
		dois_baixo_esquerda_orange: # 5
			beq $t0, 5, mover_baixo_orange
			beq $t0, 1, mover_esquerda_orange
			
		dois_baixo_direita_orange: # 8
			beq $t0, 2, mover_baixo_orange
			beq $t0, 1, mover_direita_orange
			
	tres_movimentos_possiveis_orange:
		lw $t0, 0xffff0004 	# ultimo movimento do pac man 
		li $v0, 42
		li $a1, 2
		syscall			# valor randomico
		lw $t5, ultima_direcao_orange
		beq $t9, 8,  direita_cima_esquerda_orange
	 	beq $t9, 6,  cima_esquerda_baixo_orange
	 	beq $t9, 10, esquerda_baixo_direita_orange
	 	beq $t9, 9,  baixo_direita_cima_orange
	 	
	 	direita_cima_esquerda_orange: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 116, decisao_direita_cima_esquerda_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 6, cima_esquerda_orange
	 		beq $t9, 5, direita_esquerda_orange
	 		beq $t9, 3, cima_direita_orange
	 		decisao_direita_cima_esquerda_orange:
	 		beq $t0, 119, mover_cima_orange
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 100, mover_direita_orange
	 		
	 	cima_esquerda_baixo_orange: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 100, decisao_cima_esquerda_baixo_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 5, cima_esquerda_orange
	 		beq $t9, 1, cima_baixo_orange
	 		beq $t9, 3, baixo_esquerda_orange
	 		decisao_cima_esquerda_baixo_orange:
	 		beq $t0, 119, mover_cima_orange
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 116, mover_baixo_orange
	 		
	 	esquerda_baixo_direita_orange:
	 		bne $t0, 119, decisao_esquerda_baixo_direita_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, baixo_esquerda_orange
	 		beq $t9, 9, direita_esquerda_orange
	 		beq $t9, 5, baixo_direita_orange
	 		decisao_esquerda_baixo_direita_orange:
	 		beq $t0, 97, mover_esquerda_orange
	 		beq $t0, 116, mover_baixo_orange
	 		beq $t0, 100, mover_direita_orange
	 		
	 	baixo_direita_cima_orange:
	 		bne $t0, 97, decisao_baixo_direita_cima_orange  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, cima_direita_orange
	 		beq $t9, 7, cima_baixo_orange
	 		beq $t9, 6, baixo_direita_orange
	 		decisao_baixo_direita_cima_orange:
	 		beq $t0, 116, mover_baixo_orange
	 		beq $t0, 100, mover_direita_orange
	 		beq $t0, 119, mover_cima_orange
	 	
	 	cima_baixo_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_baixo_orange
	 	
	 	direita_esquerda_orange:
	 		beq $a0, 0, mover_direita_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	cima_esquerda_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	cima_direita_orange:
	 		beq $a0, 0, mover_cima_orange
	 		beq $a0, 1, mover_direita_orange
	 	
	 	baixo_esquerda_orange:
	 		beq $a0, 0, mover_baixo_orange
	 		beq $a0, 1, mover_esquerda_orange
	 	
	 	baixo_direita_orange:
	 		beq $a0, 0, mover_baixo_orange
	 		beq $a0, 1, mover_direita_orange

	quatro_movimentos_possiveis_orange:
		lw $t0, 0xffff0004
		beq $t0, 119, mover_cima_orange # w
		beq $t0, 97, mover_esquerda_orange # a
		beq $t0, 116 mover_baixo_orange # s
		beq $t0, 100 mover_direita_orange # d
		
	mover_cima_orange:
		sub $t1, $s2, 256	# endereço fantasma orange acima
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_cima_orange_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_black_black
		j orange_nao_valido_mover_cima_black_black	
		orange_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_black_white
		j orange_nao_valido_mover_cima_black_white	
		orange_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, orange_valido_mover_cima_white_black
		j orange_nao_valido_mover_cima_white_black	
		orange_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t1)
		sub $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 1
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_cima_white_black:
		
	mover_esquerda_orange:
		sub $t2, $s2, 4		# endereço fantasma orange esquerd
	
		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_orange
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_orange
		lw $a3, color_black
		sw $a3, 0($s2)
		addi $s2, $a0, 3952
		lw $a3, color_orange
		sw $a3, 0($s2)
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		nao_portal_esquerdo_orange:
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_esquerda_orange_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_black_black
		j orange_nao_valido_mover_esquerda_black_black	
		orange_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_black_white
		j orange_nao_valido_mover_esquerda_black_white	
		orange_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, orange_valido_mover_esquerda_white_black
		j orange_nao_valido_mover_esquerda_white_black	
		orange_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t2)
		sub $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 2
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_orange:
		addi $t3, $s2, 256	# endereço fantasma orange abaixo
		
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_baixo_orange_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_black_black
		j orange_nao_valido_mover_baixo_black_black	
		orange_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_black_white
		j orange_nao_valido_mover_baixo_black_white	
		orange_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, orange_valido_mover_baixo_white_black
		j orange_nao_valido_mover_baixo_white_black	
		orange_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t3)
		addi $s2, $s2, 256
		sw $zero, indicador_white_orange
		li $t0, 3
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_baixo_white_black:
		
	mover_direita_orange:
		addi $t4, $s2, 4	# endereço fantasma orange direita
	
		# portal direito
		bne $s5, 2, nao_portal_direito_orange
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_orange
		lw $a3, color_black
		sw $a3, 0($s2)
		addi $s2, $a0, 3848
		lw $a3, color_orange
		sw $a3, 0($s2)
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		nao_portal_direito_orange:
	
		lw $t0, indicador_white_orange
		beq $t0, 1, mover_direita_orange_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_black_black
		j orange_nao_valido_mover_direita_black_black	
		orange_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_black_white
		j orange_nao_valido_mover_direita_black_white	
		orange_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		li $t0, 1
		sw $t0, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_orange_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, orange_valido_mover_direita_white_black
		j orange_nao_valido_mover_direita_white_black	
		orange_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s2)
		lw $a3, color_orange
		sw $a3, 0($t4)
		addi $s2, $s2, 4
		sw $zero, indicador_white_orange
		li $t0, 5
		sw $t0, ultima_direcao_orange
		j end_fantasma_orange
		orange_nao_valido_mover_direita_white_black:

	end_fantasma_orange:
	
	sub $t1, $s2, 256
	sub $t2, $s2, 4
	addi $t3, $s2, 256
	addi $t4, $s2, 4
	
	beq $t1, $s0, colisao_orange
	beq $t2, $s0, colisao_orange
	beq $t3, $s0, colisao_orange
	beq $t4, $s0, colisao_orange
	li $v0, 0
	j end_colisao_orange
	colisao_orange:
	li $v0, 1
	end_colisao_orange:
jr $ra
	
	
movimentar_fantasma_ciano:
	li $t9, 0
	li $t0, 0 # conta a quantidade de movimentos validos
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s3, 256	# endereço fantasma ciano acima
	sub $t2, $s3, 4		# endereço fantasma ciano esquerda
	addi $t3, $s3, 256	# endereço fantasma ciano abaixo
	addi $t4, $s3, 4	# endereço fantasma ciano direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_blue # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_blue # fantasma vermelho acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_blue # fantasma laranja acima
	lw $a3, color_pink	
	beq $a3, $a2, invalido_cima_blue # fantasma rosa acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1
	invalido_cima_blue:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_blue # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_blue # fantasma vermelho a esquerda
	lw $a3, color_orange	
	beq $a3, $a2, invalido_esquerda_blue # fantasma laranja a esquerda
	lw $a3, color_pink	
	beq $a3, $a2, invalido_esquerda_blue # fantasma rosa a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_blue:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_blue # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_blue # fantasma vermelho abaixo
	lw $a3, color_orange	
	beq $a3, $a2, invalido_baixo_blue # fantasma laranja abaixo
	lw $a3, color_pink	
	beq $a3, $a2, invalido_baixo_blue # fantasma rosa abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_blue:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_blue # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_blue # fantasma vermelho a direita
	lw $a3, color_orange	
	beq $a3, $a2, invalido_direita_blue # fantasma laranja a direita
	lw $a3, color_pink	
	beq $a3, $a2, invalido_direita_blue # fantasma rosa a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_blue:
	
	### 2º parte, segue para os calculos de movimentacao ###
	beq $t0, 0, nenhum_movimento_possivel_ciano
	beq $t0, 1, um_movimento_possivel_ciano
	beq $t0, 2, dois_movimentos_possiveis_ciano
	beq $t0, 3, tres_movimentos_possiveis_ciano
	beq $t0, 4, quatro_movimentos_possiveis_ciano
	
	# permanece na mesma posicao
	nenhum_movimento_possivel_ciano: 
	j end_fantasma_ciano
	
	# calcula qual a direcao e se movimento nela
	um_movimento_possivel_ciano:
		beq $t9, 1, mover_cima_ciano
		beq $t9, 2, mover_esquerda_ciano
		beq $t9, 3, mover_baixo_ciano
		beq $t9, 5, mover_direita_ciano
	
	dois_movimentos_possiveis_ciano:
		lw $t0, ultima_direcao_ciano
		beq $t9, 7, dois_direita_esquerda_ciano
		beq $t9, 4, dois_cima_baixo_ciano
		beq $t9, 3, dois_cima_esquerda_ciano
		beq $t9, 6, dois_cima_direita_ciano
		beq $t9, 5, dois_baixo_esquerda_ciano
		beq $t9, 8, dois_baixo_direita_ciano
		
		dois_direita_esquerda_ciano: # 7
			beq $t0, 2, mover_esquerda_ciano
			beq $t0, 5, mover_direita_ciano
			
		dois_cima_baixo_ciano: # 4
			beq $t0, 1, mover_cima_ciano
			beq $t0, 3, mover_baixo_ciano
			
		dois_cima_esquerda_ciano: # 3
			beq $t0, 5, mover_cima_ciano
			beq $t0, 3, mover_esquerda_ciano
			
		dois_cima_direita_ciano: # 6
			beq $t0, 2, mover_cima_ciano
			beq $t0, 3, mover_direita_ciano
			
		dois_baixo_esquerda_ciano: # 5
			beq $t0, 5, mover_baixo_ciano
			beq $t0, 1, mover_esquerda_ciano
			
		dois_baixo_direita_ciano: # 8
			beq $t0, 2, mover_baixo_ciano
			beq $t0, 1, mover_direita_ciano
			
	tres_movimentos_possiveis_ciano:
		li $v0, 42 # 1 - fica corajoso e persegue o pac man
		li $a1, 2  # 0 - fica assustado e foge do pac man
		syscall
		move $t9, $a0
	
		lw $t0, 0xffff0004 	# ultimo movimento do pac man 
		li $v0, 42
		li $a1, 2
		syscall			# valor randomico
		lw $t5, ultima_direcao_ciano
		beq $t9, 8,  direita_cima_esquerda_ciano
	 	beq $t9, 6,  cima_esquerda_baixo_ciano
	 	beq $t9, 10, esquerda_baixo_direita_ciano
	 	beq $t9, 9,  baixo_direita_cima_ciano
	 	
	 	direita_cima_esquerda_ciano: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 116, decisao_direita_cima_esquerda_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 6, cima_esquerda_ciano
	 		beq $t9, 5, direita_esquerda_ciano
	 		beq $t9, 3, cima_direita_ciano
	 		decisao_direita_cima_esquerda_ciano:
	 		beq $t0, 119, mover_cima_ciano
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		
	 	cima_esquerda_baixo_ciano: # se o pac man se moveu para baixo, movimento aleatorio
	 		bne $t0, 100, decisao_cima_esquerda_baixo_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 5, cima_esquerda_ciano
	 		beq $t9, 1, cima_baixo_ciano
	 		beq $t9, 3, baixo_esquerda_ciano
	 		decisao_cima_esquerda_baixo_ciano:
	 		beq $t0, 119, mover_cima_ciano
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 116, mover_baixo_ciano
	 		
	 	esquerda_baixo_direita_ciano:
	 		bne $t0, 119, decisao_esquerda_baixo_direita_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, baixo_esquerda_ciano
	 		beq $t9, 9, direita_esquerda_ciano
	 		beq $t9, 5, baixo_direita_ciano
	 		decisao_esquerda_baixo_direita_ciano:
	 		beq $t0, 97, mover_esquerda_ciano
	 		beq $t0, 116, mover_baixo_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		
	 	baixo_direita_cima_ciano:
	 		bne $t0, 97, decisao_baixo_direita_cima_ciano  
	 		sub $t9, $t9, $t5
	 		beq $t9, 8, cima_direita_ciano
	 		beq $t9, 7, cima_baixo_ciano
	 		beq $t9, 6, baixo_direita_ciano
	 		decisao_baixo_direita_cima_ciano:
	 		beq $t0, 116, mover_baixo_ciano
	 		beq $t0, 100, mover_direita_ciano
	 		beq $t0, 119, mover_cima_ciano
	 	
	 	cima_baixo_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_baixo_ciano
	 	
	 	direita_esquerda_ciano:
	 		beq $a0, 0, mover_direita_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	cima_esquerda_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	cima_direita_ciano:
	 		beq $a0, 0, mover_cima_ciano
	 		beq $a0, 1, mover_direita_ciano
	 	
	 	baixo_esquerda_ciano:
	 		beq $a0, 0, mover_baixo_ciano
	 		beq $a0, 1, mover_esquerda_ciano
	 	
	 	baixo_direita_ciano:
	 		beq $a0, 0, mover_baixo_ciano
	 		beq $a0, 1, mover_direita_ciano
	 		
	quatro_movimentos_possiveis_ciano:
	li $v0, 42 # 1 - fica corajoso e persegue o pac man
	li $a1, 2  # 0 - fica assustado e foge do pac man
	syscall
	move $t9, $a0
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
		# pegando as coordenadas do pac man e do ciano ghost
		move $a0, $s0 # coordenada do pac man
		jal calcular_coordenadas
		move $t1, $v0 # linha do pac man
		move $t2, $v1 # coluna do pac man
		
		move $a0, $s1 # coordenada do ciano ghost
		jal calcular_coordenadas
		move $t3, $v0 # linha do ciano ghost
		move $t4, $v1 # coluna do ciano ghost
		
		# pac man - ($t1,$t2), ciano ghost - ($t3,$t4)
		move $a0, $t3	# x do fantasma
		move $a1, $t4	# y do fantasma
		
		# se eles estiverem na mesma linha ou coluna
		beq $t1, $t3, mesma_linha_ciano
		beq $t2, $t4, mesma_coluna_ciano

		#determinar o quadrante que o pac man esta em relacao ao ciano ghost
		bgt $t3, $t1, quadrante_esquerda_ciano 
		j quadrante_direita_ciano
		
		quadrante_esquerda_ciano:
			blt $t4, $t1, quadrante_cima_esquerda_ciano
			j quadrante_baixo_esquerda_ciano
			
		quadrante_direita_ciano:
			blt $t4, $t1, quadrante_cima_direita_ciano
			j quadrante_baixo_direita_ciano
		
		# efetua a lógica dos movimentos
		quadrante_cima_esquerda_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_esquerda_ciano # ir para cima
			
			# indica se o fantasma esta corajoso ou assustado
			beq $t9, 1, corajoso_cima_esquerda_ciano
			j assustado_cima_esquerda_ciano
			
			corajoso_cima_esquerda_ciano:
			bgt $v1, $v0, mover_cima_ciano
			j mover_esquerda_ciano
			
			assustado_cima_esquerda_ciano:
			bgt $v1, $v0, mover_esquerda_ciano
			j mover_cima_ciano
			
		quadrante_baixo_esquerda_ciano:
			move $a2, $t1
			move $a3, $t4 
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_esquerda_ciano
			
			# indica se o fantasma esta corajoso ou assustado
			beq $t9, 1, corajoso_baixo_esquerda_ciano
			j assustado_baixo_esquerda_ciano
			
			corajoso_baixo_esquerda_ciano:
			bgt $v1, $v0, mover_baixo_ciano
			j mover_esquerda_ciano
			
			assustado_baixo_esquerda_ciano:
			bgt $v1, $v0, mover_esquerda_ciano
			j mover_baixo_ciano
			
		quadrante_cima_direita_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_cima_direita_ciano
			
			# indica se o fantasma esta corajoso ou assustado
			beq $t9, 1, corajoso_cima_direita_ciano
			j assustado_cima_direita_ciano
			
			corajoso_cima_direita_ciano:
			bgt $v1, $v0, mover_cima_ciano
			j mover_direita_ciano
			
			assustado_cima_direita_ciano:
			bgt $v1, $v0, mover_direita_ciano
			j mover_cima_ciano
			
		quadrante_baixo_direita_ciano:
			move $a2, $t1
			move $a3, $t4
			jal distancia_euclidiana
			move $v1, $v0 # distancia hotizontal

			move $a2, $t3
			move $a3, $t2
			jal distancia_euclidiana # distancia vertical
			
			lw $ra, 0($sp)
			addi $sp, $sp 4
			# mesma distancia - movimento aleatorio
			beq $v1, $v0, randomico_baixo_direita_ciano
			
			# indica se o fantasma esta corajoso ou assustado
			beq $t9, 1, corajoso_baixo_direita_ciano
			j assustado_baixo_direita_ciano
			
			corajoso_baixo_direita_ciano:
			bgt $v1, $v0, mover_baixo_ciano
			j mover_direita_ciano
			
			assustado_baixo_direita_ciano:
			bgt $v1, $v0, mover_direita_ciano
			j mover_baixo_ciano
			
		randomico_cima_esquerda_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_ciano
			j  mover_esquerda_ciano
			
		randomico_baixo_esquerda_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_ciano
			j  mover_esquerda_ciano
			
		randomico_cima_direita_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_cima_ciano
			j  mover_direita_ciano
			
		randomico_baixo_direita_ciano:
			li $v0, 42
			li $a1, 2
			syscall
			beqz $a0, mover_baixo_ciano
			j  mover_direita_ciano
			
		mesma_linha_ciano:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			
			beq $t9, 1, corajoso_mesma_linha_ciano
			j assustado_mesma_linha_ciano
			
			corajoso_mesma_linha_ciano:
			blt $t3, $t1, mover_direita_ciano # pac man a direita - va para direita
			j mover_esquerda_ciano # senão va para esquerda
			
			assustado_mesma_linha_ciano:
			blt $t3, $t1, mover_esquerda_ciano # pac man a direita - va para direita
			j mover_direita_ciano # senão va para esquerda
			
		mesma_coluna_ciano:
			lw $ra, 0($sp)
			addi $sp, $sp 4
			
			beq $t9, 1, corajoso_mesma_coluna_ciano
			j assustado_mesma_coluna_ciano
			
			corajoso_mesma_coluna_ciano:
			blt $t4, $t2, mover_cima_ciano
			j mover_baixo_ciano
			
			assustado_mesma_coluna_ciano:
			blt $t4, $t2, mover_baixo_ciano
			j mover_cima_ciano
			
	mover_cima_ciano:
		sub $t1, $s3, 256	# endereço fantasma ciano acima
		
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_cima_ciano_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_black_black
		j ciano_nao_valido_mover_cima_black_black	
		ciano_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_black_white
		j ciano_nao_valido_mover_cima_black_white	
		ciano_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, ciano_valido_mover_cima_white_black
		j ciano_nao_valido_mover_cima_white_black	
		ciano_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t1)
		sub $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 1
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_cima_white_black:
		
	mover_esquerda_ciano:
		sub $t2, $s3, 4		# endereço fantasma ciano esquerda

		# portal esquerdo
		bne $s5, 2, nao_portal_esquerdo_ciano
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_ciano
		lw $a3, color_black
		sw $a3, 0($s3)
		addi $s3, $a0, 3952
		lw $a3, color_ciano
		sw $a3, 0($s3)
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		nao_portal_esquerdo_ciano:
	
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_esquerda_ciano_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_black_black
		j ciano_nao_valido_mover_esquerda_black_black	
		ciano_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_black_white
		j ciano_nao_valido_mover_esquerda_black_white	
		ciano_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, ciano_valido_mover_esquerda_white_black
		j ciano_nao_valido_mover_esquerda_white_black	
		ciano_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t2)
		sub $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 2
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_ciano:
		addi $t3, $s3, 256	# endereço fantasma ciano abaixo

		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_baixo_ciano_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_black_black
		j ciano_nao_valido_mover_baixo_black_black	
		ciano_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_black_white
		j ciano_nao_valido_mover_baixo_black_white	
		ciano_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, ciano_valido_mover_baixo_white_black
		j ciano_nao_valido_mover_baixo_white_black	
		ciano_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t3)
		addi $s3, $s3, 256
		sw $zero, indicador_white_ciano
		li $t0, 3
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_baixo_white_black:
		
	mover_direita_ciano:
		addi $t4, $s3, 4	# endereço fantasma ciano direita
		
		# portal direito
		bne $s5, 2, nao_portal_direito_ciano
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_ciano
		lw $a3, color_black
		sw $a3, 0($s3)
		addi $s3, $a0, 3848
		lw $a3, color_ciano
		sw $a3, 0($s3)
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		nao_portal_direito_ciano:
	
		lw $t0, indicador_white_ciano
		beq $t0, 1, mover_direita_ciano_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_black_black
		j ciano_nao_valido_mover_direita_black_black	
		ciano_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_black_white
		j ciano_nao_valido_mover_direita_black_white	
		ciano_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		li $t0, 1
		sw $t0, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_ciano_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, ciano_valido_mover_direita_white_black
		j ciano_nao_valido_mover_direita_white_black	
		ciano_valido_mover_direita_white_black:
		lw $a3, color_white
		sw $a3, 0($s3)
		lw $a3, color_ciano
		sw $a3, 0($t4)
		addi $s3, $s3, 4
		sw $zero, indicador_white_ciano
		li $t0, 5
		sw $t0, ultima_direcao_ciano
		j end_fantasma_ciano
		ciano_nao_valido_mover_direita_white_black:

	end_fantasma_ciano:
	sub $t1, $s3, 256
	sub $t2, $s3, 4
	addi $t3, $s3, 256
	addi $t4, $s3, 4
	
	beq $t1, $s0, colisao_ciano
	beq $t2, $s0, colisao_ciano
	beq $t3, $s0, colisao_ciano
	beq $t4, $s0, colisao_ciano
	li $v0, 0
	j end_colisao_ciano
	colisao_ciano:
	li $v0, 1
	end_colisao_ciano:
jr $ra	
	
movimentar_fantasma_rosa:
	li $t0, 0 # conta a quantidade de movimentos validos
	li $t9, 0 # lógica para determinar o sentido do movimento de varias direções
	
	###### 1º parte, contando movimentos possíveis ######
	sub $t1, $s4, 256	# endereço fantasma rosa acima
	sub $t2, $s4, 4		# endereço fantasma rosa esquerda
	addi $t3, $s4, 256	# endereço fantasma rosa abaixo
	addi $t4, $s4, 4	# endereço fantasma rosa direita
	
	lw $a2, 0($t1)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_cima_pink # parede acima
	lw $a3, color_red
	beq $a3, $a2, invalido_cima_pink # fantasma vermelho acima
	lw $a3, color_orange
	beq $a3, $a2, invalido_cima_pink # fantasma laranja acima
	lw $a3, color_ciano
	beq $a3, $a2, invalido_cima_pink # fantasma ciano acima
	addi $t0, $t0, 1
	addi $t9, $t9, 1 
	invalido_cima_pink:
	
	lw $a2, 0($t2)		
	lw $a3, color_blue
	beq $a3, $a2, invalido_esquerda_pink # parede a esquerda
	lw $a3, color_red
	beq $a3, $a2, invalido_esquerda_pink # fantasma vermelho a esquerda
	lw $a3, color_orange	
	beq $a3, $a2, invalido_esquerda_pink # fantasma laranja a esquerda
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_esquerda_pink # fantasma ciano a esquerda
	addi $t0, $t0, 1
	addi $t9, $t9, 2
	invalido_esquerda_pink:
	
	lw $a2, 0($t3)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_baixo_pink # parede abaixo
	lw $a3, color_red
	beq $a3, $a2, invalido_baixo_pink # fantasma vermelho abaixo
	lw $a3, color_orange	
	beq $a3, $a2, invalido_baixo_pink # fantasma laranja abaixo
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_baixo_pink # fantasma ciano abaixo
	addi $t0, $t0, 1
	addi $t9, $t9, 3
	invalido_baixo_pink:
	
	lw $a2, 0($t4)	
	lw $a3, color_blue
	beq $a3, $a2, invalido_direita_pink # parede a direita
	lw $a3, color_red
	beq $a3, $a2, invalido_direita_pink # fantasma vermelho a direita
	lw $a3, color_orange	
	beq $a3, $a2, invalido_direita_pink # fantasma laranja a direita
	lw $a3, color_ciano	
	beq $a3, $a2, invalido_direita_pink # fantasma ciano a direita
	addi $t0, $t0, 1
	addi $t9, $t9, 5
	invalido_direita_pink:
	
	### 2º parte, segue para os calculos de movimentacao ###
	beq $t0, 0, nenhum_movimento_possivel_rosa
	beq $t0, 1, um_movimento_possivel_rosa
	beq $t0, 2, dois_movimentos_possiveis_rosa
	beq $t0, 3, tres_movimentos_possiveis_rosa
	beq $t0, 4, quatro_movimentos_possiveis_rosa
	
	# permanece na mesma posicao
	nenhum_movimento_possivel_rosa: 
	j end_fantasma_rosa
	
	# calcula qual a direcao e se movimento nela
	um_movimento_possivel_rosa:
		beq $t9, 1, mover_cima_rosa
		beq $t9, 2, mover_esquerda_rosa
		beq $t9, 3, mover_baixo_rosa
		beq $t9, 5, mover_direita_rosa
	
	dois_movimentos_possiveis_rosa:
		lw $t0, ultima_direcao_pink
		beq $t9, 7, dois_direita_esquerda_rosa
		beq $t9, 4, dois_cima_baixo_rosa
		beq $t9, 3, dois_cima_esquerda_rosa
		beq $t9, 6, dois_cima_direita_rosa
		beq $t9, 5, dois_baixo_esquerda_rosa
		beq $t9, 8, dois_baixo_direita_rosa
		
		dois_direita_esquerda_rosa: # 7
			beq $t0, 2, mover_esquerda_rosa
			beq $t0, 5, mover_direita_rosa
			
		dois_cima_baixo_rosa: # 4
			beq $t0, 1, mover_cima_rosa
			beq $t0, 3, mover_baixo_rosa
			
		dois_cima_esquerda_rosa: # 3
			beq $t0, 5, mover_cima_rosa
			beq $t0, 3, mover_esquerda_rosa
			
		dois_cima_direita_rosa: # 6
			beq $t0, 2, mover_cima_rosa
			beq $t0, 3, mover_direita_rosa
			
		dois_baixo_esquerda_rosa: # 5
			beq $t0, 5, mover_baixo_rosa
			beq $t0, 1, mover_esquerda_rosa
			
		dois_baixo_direita_rosa: # 8
			beq $t0, 2, mover_baixo_rosa
			beq $t0, 1, mover_direita_rosa
			
	tres_movimentos_possiveis_rosa:
		# gerando o numero aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
	 	
	 	lw $t0, ultima_direcao_pink
	 	beq $t9, 8,  direita_cima_esquerda_rosa
	 	beq $t9, 6,  cima_esquerda_baixo_rosa
	 	beq $t9, 10, esquerda_baixo_direita_rosa
	 	beq $t9, 9,  baixo_direita_cima_rosa
	 	
	 	direita_cima_esquerda_rosa:# 8
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, cima_esquerda_rosa
	 		beq $t9, 5, esquerda_direita_rosa
	 		beq $t9, 2, cima_direita_rosa
	 		
	 	cima_esquerda_baixo_rosa: # 6
	 		sub $t9, $t9, $t0
	 		beq $t9, 3, baixo_esquerda_rosa
	 		beq $t9, 1, cima_baixo_rosa
	 		beq $t9, 5, cima_esquerda_rosa
	 		
	 	esquerda_baixo_direita_rosa: # 10
	 		sub $t9, $t9, $t0
	 		beq $t9, 8, baixo_esquerda_rosa
	 		beq $t9, 9, esquerda_direita_rosa
	 		beq $t9, 5, baixo_direita_rosa
	 		
	 	baixo_direita_cima_rosa: # 9
	 		sub $t9, $t9, $t0
	 		beq $t9, 6, baixo_direita_rosa
	 		beq $t9, 7, cima_baixo_rosa
	 		beq $t9, 8, cima_direita_rosa
	 		
	 	esquerda_direita_rosa:
	 		beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_direita_rosa
	 	
	 	cima_baixo_rosa:
			beq $a0, 0, mover_cima_rosa
	 		beq $a0, 1, mover_baixo_rosa
	 		
		cima_esquerda_rosa:
			beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_cima_rosa
	 		
		cima_direita_rosa:
			beq $a0, 0, mover_cima_rosa
	 		beq $a0, 1, mover_direita_rosa
	 		
	 	baixo_esquerda_rosa:
	 		beq $a0, 0, mover_esquerda_rosa
	 		beq $a0, 1, mover_baixo_rosa
	 	
	 	baixo_direita_rosa:
			beq $a0, 0, mover_direita_rosa
	 		beq $a0, 1, mover_baixo_rosa

	quatro_movimentos_possiveis_rosa:
		# gerando o número aleatorio em $a0
		li $v0, 42
		li $a1, 3
		syscall
		
		lw $t0, ultima_direcao_pink
		sub $t9, $t9, $t0
		beq $t9, 10, quatro_direita_cima_esquerda_rosa
		beq $t9, 9,  quatro_cima_esquerda_baixo_rosa
		beq $t9, 8,  quatro_esquerda_baixo_direita_rosa
		beq $t9, 6,  quatro_baixo_direita_cima_rosa
		
		quatro_direita_cima_esquerda_rosa: # 10
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_cima_esquerda_baixo_rosa: # 9
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_esquerda_baixo_direita_rosa: # 8
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
		quatro_baixo_direita_cima_rosa: # 6
			beq $a0, 0, mover_direita_rosa
			beq $a0, 1, mover_cima_rosa
			beq $a0, 2, mover_esquerda_rosa
		
	mover_cima_rosa:
		sub $t1, $s4, 256	# endereço fantasma rosa acima
		
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_cima_rosa_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_black_black
		j rosa_nao_valido_mover_cima_black_black	
		rosa_valido_mover_cima_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_black_white
		j rosa_nao_valido_mover_cima_black_white	
		rosa_valido_mover_cima_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_black_white:
		
		# branco preto
		mover_cima_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t1)		
		beq $a3, $a2, rosa_valido_mover_cima_white_black
		j rosa_nao_valido_mover_cima_white_black	
		rosa_valido_mover_cima_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t1)
		sub $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 1
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_cima_white_black:
		
	mover_esquerda_rosa:
		sub $t2, $s4, 4		# endereço fantasma rosa esquerda
		
		# portal esquerdo
		beq $s5, 1, nao_portal_esquerdo_rosa
		la $a0, display_address
		addi $t0, $a0, 3844
		bne $t2, $t0, nao_portal_esquerdo_rosa
		lw $a3, color_black
		sw $a3, 0($s4)
		addi $s4, $a0, 3952
		lw $a3, color_pink
		sw $a3, 0($s4)
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		
		nao_portal_esquerdo_rosa:
		
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_esquerda_rosa_WHITE_BLACK
	
		# preto preto
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_black_black
		j rosa_nao_valido_mover_esquerda_black_black	
		rosa_valido_mover_esquerda_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_black_white
		j rosa_nao_valido_mover_esquerda_black_white	
		rosa_valido_mover_esquerda_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_black_white:
		
		# branco preto
		mover_esquerda_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t2)		
		beq $a3, $a2, rosa_valido_mover_esquerda_white_black
		j rosa_nao_valido_mover_esquerda_white_black	
		rosa_valido_mover_esquerda_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t2)
		sub $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 2
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_esquerda_white_black:
		
	mover_baixo_rosa:
		addi $t3, $s4, 256	# endereço fantasma rosa abaixo
	
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_baixo_rosa_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_black_black
		j rosa_nao_valido_mover_baixo_black_black	
		rosa_valido_mover_baixo_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_black_white
		j rosa_nao_valido_mover_baixo_black_white	
		rosa_valido_mover_baixo_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_black_white:
		
		# branco preto
		mover_baixo_rosa_WHITE_BLACK:
		
		lw $a3, color_black
		lw $a2, 0($t3)		
		beq $a3, $a2, rosa_valido_mover_baixo_white_black
		j rosa_nao_valido_mover_baixo_white_black	
		rosa_valido_mover_baixo_white_black:
		lw $a3, color_white
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t3)
		addi $s4, $s4, 256
		sw $zero, indicador_white_pink
		li $t0, 3
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_baixo_white_black:
		
	mover_direita_rosa:
		addi $t4, $s4, 4	# endereço fantasma rosa direita
	
		# portal direito
		beq $s5, 1, nao_portal_direito_rosa
		la $a0, display_address
		addi $t0, $a0, 3956
		bne $t4, $t0, nao_portal_direito_rosa
		lw $a3, color_black
		sw $a3, 0($s4)
		addi $s4, $a0, 3848
		lw $a3, color_pink
		sw $a3, 0($s4)
		sw $zero, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		nao_portal_direito_rosa:
	
		lw $t0, indicador_white_pink
		beq $t0, 1, mover_direita_rosa_WHITE_BLACK
	
		# preto preto			
		lw $a3, color_black
		lw $a2, 0($t4)		
		beq $a3, $a2, rosa_valido_mover_direita_black_black
		j rosa_nao_valido_mover_direita_black_black	
		rosa_valido_mover_direita_black_black:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t4)
		addi $s4, $s4, 4
		sw $zero, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_direita_black_black:
		
		# preto branco
		lw $a3, color_white
		lw $a2, 0($t4)		
		beq $a3, $a2, rosa_valido_mover_direita_black_white
		j rosa_nao_valido_mover_direita_black_white	
		rosa_valido_mover_direita_black_white:
		lw $a3, color_black
		sw $a3, 0($s4)
		lw $a3, color_pink
		sw $a3, 0($t4)
		addi $s4, $s4, 4
		li $t0, 1
		sw $t0, indicador_white_pink
		li $t0, 5
		sw $t0, ultima_direcao_pink
		j end_fantasma_rosa
		rosa_nao_valido_mover_direita_black_white:
		
		# branco preto
		mover_direita_rosa_WHITE_BLACK:
		
		
	
	move_ghost(color_black, color_white, color_pink, $t4, $s4, 4, 0, indicador_white_pink, 5, ultima_direcao_pink)

	end_fantasma_rosa:
	
	sub $t1, $s4, 256
	sub $t2, $s4, 4
	addi $t3, $s4, 256
	addi $t4, $s4, 4
	
	beq $t1, $s0, colisao_pink
	beq $t2, $s0, colisao_pink
	beq $t3, $s0, colisao_pink
	beq $t4, $s0, colisao_pink
	li $v0, 0
	j end_colisao_pink
	colisao_pink:
	li $v0, 1
	end_colisao_pink:
jr $ra

# $a0 - x1
# $a1 - y1
# $a2 - x2
# $a3 - y2
# $v0 - distancia
# distance = sqrt((x1-x2)^2+(y1-y2)^2)
# devido a limitacao da raiz quadrada em assembly alguns resultados não serão bem definidos
distancia_euclidiana:
	# parte de dentro da raiz
	sub $a0, $a0, $a2 # a =(x1-x2)
	sub $a1, $a1, $a3 # b = (y1-y2)
	mul $a0, $a0, $a0 # a^2
	mul $a1, $a1, $a1 # b^2
	add $a0, $a0, $a1 # c = a^2 + b^2
	# raiz
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal integerSqrt # sqrt(c)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# o retorno de integerSqrt ja esta em $v0
jr $ra

# $a0 - endereço no bit map
# $v0 - valor da linha
# $v1 - valor da coluna
calcular_coordenadas:
	la $a3, display_address
	sub $a0, $a0, $a3
	div $a1, $a0, 256 	# t1 é o valor da linha
	mul $a2, $a1, 256	
	sub $a2, $a0, $a2 
	div $a2, $a2, 4		# t2 é o valor da coluna
	move $v0, $a1
	move $v1, $a2
jr $ra

# $a0 valor de entrada
# $v0 resultado
integerSqrt:
  	move $v0, $zero        # initalize return
  	move $t1, $a0          # move a0 to t1
  	addi $t0, $zero, 1
	sll $t0, $t0, 30      # shift to second-to-top bit

	integerSqrt_bit:
 	slt $t2, $t1, $t0     # num < bit
 	beq $t2, $zero, integerSqrt_loop
	srl $t0, $t0, 2       # bit >> 2
 	j integerSqrt_bit

	integerSqrt_loop:
	beq $t0, $zero, integerSqrt_return
  	add $t3, $v0, $t0     # t3 = return + bit
 	slt $t2, $t1, $t3
 	beq $t2, $zero, integerSqrt_else
 	srl $v0, $v0, 1       # return >> 1
 	j integerSqrt_loop_end
	
	integerSqrt_else:
 	sub $t1, $t1, $t3     # num -= return + bit
 	srl $v0, $v0, 1       # return >> 1
 	add $v0, $v0, $t0     # return + bit

	integerSqrt_loop_end:
 	srl $t0, $t0, 2       # bit >> 2
 	j integerSqrt_loop

	integerSqrt_return:
jr $ra
