.data
	fileIn: .asciiz "string.in"
	fileOut: .asciiz "string.out"
	
	bufferPointer: .word 0	    # ponteiro para o bufferFile
	bufferFile: .space 1024     # buffer que salva o conteudo do arquivo
	bufferFileOut: .space 1024  # s6 armazena o ponteiro deste buffer
	
	barraN: .byte '\n'
	barraR: .byte '\r'
	EOF: .byte '\0'
	
	maior: .word 0           # armazena o tamanho da maior palavra
	menor: .word 100         # armazena o tamanho da menor palavra
.text
main:

	# Abrindo para leitura, Lendo e Fechando o string.in
	la $a3, fileIn
	jal open_file_read
	jal read_file
	jal close_file
	
	# Salvando o bufferPointer do bufferFile
	la $t0, bufferFile    # pego o endereço do buffer
	sw $t0, bufferPointer # armazeno o endereço do buffer no ponteiro
	
	# Selecionando a maior e menor palavra
	jal menor_e_maior_palavra
	sw $a2, menor # salvando o tamanho da menor palavra
	sw $a3, maior # salvando o tamanho da maior palavra
	
	# Concatenando as menores (caso haja mais de uma) palavras num array
	la $a0, bufferFile    
	sw $a0, bufferPointer # ponteiro padrao para o buffer
	jal concatenar_palavras_menores
	
	# Concatenando as maiores (caso haja mais de uma) palavras num array
	la $a0, bufferFile    
	sw $a0, bufferPointer # ponteiro padrao para o buffer
	jal concatenar_palavras_maiores
	
	# Definindo tamanho do Buffer de saída
	jal tamanho_buffer_saida
	
	# Abrindo para escrita, Escrevendo e Fechando o string.out
	la $a3, fileOut
	jal open_file_write
	jal write_file
	jal close_file
	
	# Imprimindo o BufferFileOut
	la $a3, bufferFileOut
	jal print_buffer

li $v0, 10
syscall

tamanho_buffer_saida: # recebe o buffer a se calcular em $a0 retorno em $v1
	li $t0, 0 # contador
	lb $t1, EOF
	la $a0, bufferFileOut
	loop:
		lb $t3, 0($a0)
		beq $t1 $t3, exit_loop
		addi $t0, $t0, 1
		addi $a0, $a0, 1
		j loop
	exit_loop:
	move $v1, $t0
	jr $ra


concatenar_palavras_menores: # a0 está com o ponteiro do bufferfile
	move $t5, $a0         # Ponteiro bufferFile
	la $s6, bufferFileOut # Ponteiro bufferMenores
	li $t6, 0  	      # Contador do loop que
	li $t7, 10            # Repete 10 vezes.
	lw $s4, menor         # tamanho da menor palavra
	loop_menor_palavra:   # não mexo no t1 inicialmente, só após checar se a palavra em questão é igual a menor
		beq $t6, $t7, exit_loop_menor_palavra # comparou todas as palavras com a menor
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal tamanho_palavra # retorna o tamanho da palavra lida atualmente
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		bne $v1, $s4, nao_concatenar_palavras_menores # comparo se o tamanho da palavra lida é igual a da menor
							      # se der falso a palavra não é a menor, não concatenar
		li $s5, 0	      # Contador para o loop da palavra menor
		loop_concatena_menor: # deve repetir (.word menor) vezes
			beq $s5, $s4, exit_loop_concatena_menor 
			
			# passar o byte atual do buffer para o buffermenor
			lb $s3, 0($t5) # Copia em $s3 o caracter que BufferPointer aponta
			sb $s3, 0($s6) # Cola de $s3 o caracter armazenado no ponteiro de BufferMenores ($s6)
			addi $t5, $t5, 1 # passo para o próximo caracter do BufferPointer
			addi $s6, $s6, 1 # passo para o proximo endereço de memoria de BufferMenores
			
			addi $s5, $s5, 1 #contador do laço
			j loop_concatena_menor
		exit_loop_concatena_menor:
		
		lb $s3, barraR
		sb $s3, 0($s6)
		addi $t5, $t5, 1
		addi $s6, $s6, 1
		lb $s3, barraN
		sb $s3, 0($s6)
		addi $t5, $t5, 1
		addi $s6, $s6, 1 # copiando um \n
		
		nao_concatenar_palavras_menores: # pulo para a proxima palavra
		
		move $t5, $a1   # Pulo para a proxima palavra #talvez tenha bug
		addi $t6, $t6, 1 # contador do loop          
		j loop_menor_palavra
	exit_loop_menor_palavra:
	jr $ra

concatenar_palavras_maiores:  # a posição atual, no fim do bufferFileOut já está salva 
			      # em $s6 após a execução do procedimento concatenar_palavras_menores
			      
	move $t5, $a0         # Ponteiro bufferFile
	li $t6, 0  	      # Contador do loop que
	li $t7, 10            # Repete 10 vezes.
	lw $s4, maior         # tamanho da maior palavra
	lw $s2, menor
	
	beq $s4, $s2, exit_menor_igual_a_maior
	
	loop_maior_palavra:   # não mexo no t1 inicialmente, só após checar se a palavra em questão é igual a menor
		beq $t6, $t7, exit_loop_maior_palavra # comparou todas as palavras com a menor
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal tamanho_palavra # retorna o tamanho da palavra lida atualmente
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		bne $v1, $s4, nao_concatenar_palavras_maiores # comparo se o tamanho da palavra lida é igual a da menor
							      # se der falso a palavra não é a menor, não concatenar
		li $s5, 0	      # Contador para o loop da palavra menor
		loop_concatena_maior: # deve repetir (.word menor) vezes
			beq $s5, $s4, exit_loop_concatena_maior
			
			# passar o byte atual do buffer para o buffermenor
			lb $s3, 0($t5) # Copia em $s3 o caracter que BufferPointer aponta
			sb $s3, 0($s6) # Cola de $s3 o caracter armazenado no ponteiro de BufferMenores ($s6)
			addi $t5, $t5, 1 # passo para o próximo caracter do BufferPointer
			addi $s6, $s6, 1 # passo para o proximo endereço de memoria de BufferMenores
			
			addi $s5, $s5, 1#contador do laço
			j loop_concatena_menor
		exit_loop_concatena_maior:
		
		lb $t9, EOF # checando se é o fim do arquivo
		bne $t9, $s3, else_EOF
		sb $t9, 0($s6) # colocando um eof no fim do buffer
		
		j exit_loop_maior_palavra
		else_EOF:
		lb $s3, barraR
		sb $s3, 0($s6)
		addi $t5, $t5, 1
		addi $s6, $s6, 1
		lb $s3, barraN
		sb $s3, 0($s6)
		addi $t5, $t5, 1
		addi $s6, $s6, 1 # copiando um \n
		exit_EOF:
		
		nao_concatenar_palavras_maiores: # pulo para a proxima palavra
		
		move $t5, $a1   # Pulo para a proxima palavra #talvez tenha bug
		addi $t6, $t6, 1 # contador do loop          
		j loop_menor_palavra
	exit_loop_maior_palavra:
	exit_menor_igual_a_maior:
	
	jr $ra

tamanho_palavra: # retorna o tamanho da palavra em #####($v1)######
	li $v1, 0 # setando o contador do retorno como zero
	li $t1, 0 # contador da palavra
	lw $a1, bufferPointer # recebe o ponteiro do buffer
	lb $t2, EOF
	lb $t3, barraR # a leitura ocorre com o \r primeiro, basta incrementar em 2 o ponteiro
	loop_strlen:
		lb $t4, 0($a1)   # carrega o caracter atual do buffer
		beq $t2, $t4, end_of_file # end of file
		beq $t3, $t4, end_of_line # end of line leu um \r
		addi $t1, $t1, 1
		addi $a1, $a1, 1
		j loop_strlen
	end_of_line:	
	addi $a1, $a1, 2 # somo 2 pois após ler o \r tem um \n, então pulo para o próximo caracter válido
			 # que não será o fim do arquivo, pois esta checagem é feita anterioemente
	end_of_file:  
	sw $a1, bufferPointer # armazena a posição atual do bufferpointer
	move $v1, $t1  #retorno da função
	jr $ra

menor_e_maior_palavra:
	lw $a2, menor
	lw $a3, maior
	li $t7, 10   # gambiarra, executa mais 9 vezes o procedimento, pois restam 9 palavras a serem checadas
	li $t6, 0
	loop_sizes:
		beq $t6, $t7, exit_loop_sizes
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal tamanho_palavra # retorno em $v1 
		lw $ra, 0($sp)
		addi $sp, $sp, 4 
		  
		bgt $v1, $a2, nao_eh_menor
		add $a2, $zero, $zero 
		add $a2, $zero, $v1
		nao_eh_menor:
		     
		blt $v1, $a3, nao_eh_maior
		add $a3, $zero, $zero 
		add $a3, $zero, $v1
		nao_eh_maior:
		
		addi $t6, $t6, 1
		j loop_sizes
	exit_loop_sizes:
	sw $a2, menor
	sw $a3, maior
	jr $ra

open_file_read: #$a3 indica o arquivo a ser aberto
	#la $a3, filename
	li $v0, 13
	move $a0, $a3 # salvando em a0 o adress do arquivo q está em a3
	li $a1, 0
	li $a2, 0
	syscall
	move $s7, $v0 # salvando descriptor do arquivo in
	jr $ra

open_file_write: #$a3 indica o arquivo a ser aberto
	#la $a3, filename
	li $v0, 13
	move $a0, $a3  # salvando em a0 o adress do arquivo q está em a3
	li $a1, 1
	li $a2, 0
	syscall
	move $s6, $v0 # salvando descriptor do arquivo in
	jr $ra

close_file: # salvando em $a3 o arquivo que fecharemos
	#la $a3, filename
	li $v0, 16
	move $a0, $a3
	syscall
	jr $ra

read_file: 
	li $v0, 14
	move $a0, $s7
	la $a1, bufferFile
	li $a2, 1024
	syscall
	jr $ra

write_file: # recebe o endereço do arquivo em $a3 # precisa receber o tamanho do buffer da função Tamanho_buffer
	li $v0, 15
	move $a0, $s6
	la $a1, bufferFileOut
	add $a2, $zero, $v1 # recebe o valor do buffer recebido em v1 pelo procedimento
	syscall
	jr $ra
	
create_file: # salva em a3 o arquivo a ser criado
	addi $sp, $sp, -4
	sw $ra, 0($sp) # salva o valor do ra do creat file
	jal open_file_write
	jal close_file
	lw $ra, 0($sp)
	addi $sp, $sp 4
	jr $ra
	
print_buffer: # recebe o buffer a ser impresso em $a3
	li $v0, 4
	move $a0, $a3
	syscall
	jr $ra