.data

.text
	
loop:	sll $t1,$s3,2     # muda para o pr�ximo �ndice do array
	add $t1,$t1,$s6   # soma a "cabe�a" do array com o indice a ser checado
	lw  $t0, 0($t1)   # carrega o valor do endere�o atual do arrai, que est� armazenado em t1
	bne $t0,$s5, exit # checa se o valor armazenado com t0 � diferente do de checagem do la�o
	addi $s3, $s3, 1  # caso o bne der falso essa linha � execurada. Adiciona um no indice, para passar para o pr�ximo
	j loop		  # retorna a execu��o para o label "loop"
exit: