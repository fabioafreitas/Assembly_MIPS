.data
array: 		.space  20000 # tamanho do array em bytes
tam_array:	.word	5000 # tamanho do array
bucket:		.space	40 # O VALOR DO BUCKET É DE 40 BYTES, NÃO ALTERE
space:		.ascii " "
time_begin:	.word 0
time_end:	.word 0

.text
.globl main
main:
	jal preencher_array
	
	#li $v0, 30
	#syscall
	#sw $a0, time_begin
	
	jal radixsort
	
	#li $v0, 30
	#syscall
	#sw $a0, time_end
	
	#lw $t0, time_begin
	#lw $t1, time_end
	#sub $a0, $t0, $t1
	#div $a0, $a0, 1000
	#li $v0, 1
	#syscall
li $v0, 10
syscall

# retorna o array em ordem crescente
# $a2 - array
# $a3 - tam_array
# $s0 - armazena o ponteiro do array auxiliar
# $s1 - armazena o ponteiro do array bucket
# $s2 - armazena o maior valor do array principal
# $s3 - armazena o primeiro valor do array principal
# $s4 - armazena o valor do expoente atual
radixsort:
addi $sp, $sp, -4
sw $ra, 0($sp)
	
	
	# preparações iniciais
	jal alocar_array_auxiliar	# $s0
	la $s1, bucket			# $s1
	jal get_max			# $s2
	la $a2, array
	li $s4, 1	# valor do expoente em $s4

	# incício do algoritmo
	while:
	div $t0, $s2, $s4	# enquanto (maior/expoente) > 0
	beqz $t0, end_while
		jal zerar_array_bucket
		jal contar_quantidade_de_digitos
		jal incrementar_indices_anteriores
		jal posicionar_valores_array_auxiliar
		jal copiar_array_auxiliar
		mul $s4, $s4, 10
	j while
	end_while:
	
	
lw $ra, 0($sp)
addi $sp, $sp, 4		
jr $ra

# preenche o array bucket com zeros
zerar_array_bucket:
	li $t0, 0
	loop_array_bucket:
	beq $t0, 10, end_loop_array_bucket
	sll $t1, $t0, 2
	add $t1, $t1, $s1
	sw $zero, 0($t1)
	addi $t0, $t0, 1
	j loop_array_bucket
	end_loop_array_bucket:
jr $ra

# conta a quantidade de numeros do array principal que tem digito X em relação
# a uma casa decimal. A contagem é armazenada no array bucket
contar_quantidade_de_digitos:
	li $t0, 0
	lw $t1, tam_array
	la $a2, array
	loop_count_bucket:	
	beq $t0, $t1, end_loop_count_bucket
		# vetor[i]
		sll $t2, $t0, 2
		add $t2, $t2, $a2
		lw $t2, 0($t2)
	
		# X = (vetor[i] / exp)
		div $t2, $t2, $s4 
	
		# X mod 10
		li $t3, 10
		div $t2, $t3
		mfhi $t2 # recebe o resto da divisão
	
		# bucket[X]
		sll $t2, $t2, 2
		add $t2, $t2, $s1 
	
		# bucket[X]++
		lw $t3, 0($t2)
		addi $t3, $t3, 1
	
		# bucket[X] = bucket[X]++
		sw $t3, 0($t2)
	addi $t0, $t0, 1
	j loop_count_bucket
	end_loop_count_bucket:
jr $ra

# incrementa o valor de indice (N+1) com o de indice N no array bucket
incrementar_indices_anteriores:
	li $t0, 1
	lw $t1, tam_array
	loop_sum_bucket:
	beq $t0, $t1, end_loop_sum_bucket
		# indice i (bucket[i])
		sll $t2, $t0, 2
		add $t2, $t2, $s1 # endereço
		lw $t4, 0($t2) # obtendo bucket[i]
		
		# indice i (bucket[i-1])
		sll $t3, $t0, 2
		add $t3, $t3, $s1
		sub $t3, $t3, 4
		lw $t5, 0($t3) # obtendo bucket[i-1]
		
		# bucket[i] += bucket[i - 1]
		addu $t5, $t5, $t4
		sw $t5, 0($t2) # salvando a soma em bucket[i]
	addi $t0, $t0, 1
	j loop_sum_bucket
	end_loop_sum_bucket:
jr $ra

#for (i = tamanho - 1; i >= 0; i--)
#    	    b[--bucket[(vetor[i] / exp) % 10]] = vetor[i];

# posiciona os valores do array principal no array auxiliar de acordo com o digito atual
# a seleçao dos valores é efetuada de acordo com os valores guardados no bucket
posicionar_valores_array_auxiliar:
	la $a2, array
	lw $t0, tam_array
	sub $t0, $t0, 1		# i = tamanho - 1
	loop_posicionar:
	bltz $t0, end_loop_posicionar
		# vetor[i]
		sll $t2, $t0, 2
		add $t2, $t2, $a2
		lw $t2, 0($t2)
		move $t4, $t2
		
		# X = (vetor[i] / exp)
		div $t2, $t2, $s4
		
		# X mod 10
		li $t3, 10
		div $t2, $t3
		mfhi $t2
		
		# Y = bucket[X mod 10]
		sll $t2, $t2, 2
		add $t2, $t2, $s1
		lw $t3, 0($t2) # valor de Y
		
		# --Y
		sub $t3, $t3, 1
		sw $t3, 0($t2) # armazeno valor de Y - 1
		
		# auxArray[--Y]
		sll $t3, $t3, 2
		add $t3, $t3, $s0 # endereço
		sw $t4, 0($t3)
		
	sub $t0, $t0, 1
	j loop_posicionar
	end_loop_posicionar:
jr $ra

# copia o array auxiliar no array principal
copiar_array_auxiliar:
	la $a2, array
	li $t0, 0
	lw $t1, tam_array
	loop_x:
	beq $t0, $t1, end_loop_x
		sll $t2, $t0, 2
		add $t3, $t2, $a2 # incide atual array principal $t3
		add $t4, $t2, $s0 # incide atual array auxiliar  $t4
		lw $t4, 0($t4)	  # valor atual array auxiliar
		sw $t4, 0($t3)    # copiando dados
	addi $t0, $t0, 1
	j loop_x
	end_loop_x:
jr $ra

# salva em $s0 o ponteiro do array auxiliar
alocar_array_auxiliar:
	lw $a0, tam_array
	li $v0, 9
	syscall 	# alocando o array auxiliar
	move $s0, $v0 	# move o ponteiro do novo array para $s0
jr $ra

# recebe o maior elemento de um array de inteiros
# $a2 - array
# $a3 - tam_array
# $s2 - maior valor
get_max:
	la $a2, array
	lw $t1, tam_array
	li $t0, 1
	lw $t3, 0($a2) # primeiro elemento do array
	max_loop:
	beq $t0, $t1, end_max_loop
	sll $t2, $t0, 2
	add $t2, $t2, $a2
	lw $t2, 0($t2)
	
	blt $t2, $t3, nao_trocar
	move $t3, $t2
	nao_trocar: 
	
	addi $t0, $t0, 1
	j max_loop
	end_max_loop:
	move $s2, $t3
jr $ra

# preenche o array com valores aleatorios
# $a2 - array
# $a3 - tam_array
preencher_array:
	la $a2, array	# ponteiro para o array
	lw $a3, tam_array	# tamanho do array
	li $t0, 0	# contador do loop
	#move $a1, $a3
	li $a1, 1000
	loop:
	beq $t0, $a3, end_loop
	li $v0, 42
	syscall
	sll $t2, $t0, 2
	add $t2, $t2, $a2
	sw $a0, 0($t2)
	addi $t0, $t0, 1
	sub $a0, $a0, 1
	j loop
	end_loop:
jr $ra
