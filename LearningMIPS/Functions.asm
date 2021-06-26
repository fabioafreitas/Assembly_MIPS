# fun��es em assembly s�o chamados procedimentos (procedures)
#
# como boa pr�tica � importante ter uma fun��o main

.data
	msg: .asciiz "Hi everybody.\nMy name is F�bio\n\n"
.text
	main:
		jal displayMsg # jump and link para o procedimento escolhido		
		jal printaInt
		#addi $a0, $zero, 10
		#li $v0, 1
		#syscall
	
	li $v0, 10 #indica o "fim" do procedimento main
	syscall    #� semelhante ao fecha chaves "}"
	

	displayMsg:
		li $v0, 4
		la $a0, msg
		syscall
		
		jr $ra # endere�o de retorno de uma fun��o ou procedimento
		
	
	printaInt:
		li $v0, 1
		addi $a0, $zero, 1
		syscall
		
		jr $ra
