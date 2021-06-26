.data

.text
	
loop:	sll $t1,$s3,2     # muda para o próximo índice do array
	add $t1,$t1,$s6   # soma a "cabeça" do array com o indice a ser checado
	lw  $t0, 0($t1)   # carrega o valor do endereço atual do arrai, que está armazenado em t1
	bne $t0,$s5, exit # checa se o valor armazenado com t0 é diferente do de checagem do laço
	addi $s3, $s3, 1  # caso o bne der falso essa linha é execurada. Adiciona um no indice, para passar para o próximo
	j loop		  # retorna a execução para o label "loop"
exit: