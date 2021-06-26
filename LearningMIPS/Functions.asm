# funções em assembly são chamados procedimentos (procedures)
#
# como boa prática é importante ter uma função main

.data
	msg: .asciiz "Hi everybody.\nMy name is Fábio\n\n"
.text
	main:
		jal displayMsg # jump and link para o procedimento escolhido		
		jal printaInt
		#addi $a0, $zero, 10
		#li $v0, 1
		#syscall
	
	li $v0, 10 #indica o "fim" do procedimento main
	syscall    #é semelhante ao fecha chaves "}"
	

	displayMsg:
		li $v0, 4
		la $a0, msg
		syscall
		
		jr $ra # endereço de retorno de uma função ou procedimento
		
	
	printaInt:
		li $v0, 1
		addi $a0, $zero, 1
		syscall
		
		jr $ra
