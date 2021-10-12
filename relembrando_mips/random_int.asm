
# returna numero aleatorio em $v0
.macro rand(%upperbound)
	li $a1, %upperbound
	li $v0, 42
	syscall
	move $v0, $a0
.end_macro

# print o inteiro armazenado no registrador passado como param
.macro print_int(%register_with_number)
	move $a0, %register_with_number
	li $v0, 1
	syscall
.end_macro

# dá um sleep do valor em milisecs passado como param
.macro sleep(%miliseconds)
	li $a0, %miliseconds
	li $v0, 32
	syscall
.end_macro

.text
	while:
		rand(10)
		print_int($v0)
		sleep(1000)
	j while
	
	
	