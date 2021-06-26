.data
	feedline: .asciiz "\n"
	string: .asciiz "ESTE TEXTO SERÁ IMPRESSO"
	float: .float 3.14
	double: .double 2018.1
	double2: .double 0.0
.text
main:
	jal print_int
	jal breakline
	jal print_char_string
	jal breakline
	jal print_float
	jal breakline
	jal print_double
	
li $v0, 10
syscall

print_int: 
	li $v0, 1
	li $a0, 10
	syscall
	jr $ra

print_char_string:
	li $v0, 4
	la $a0, string
	syscall
	jr $ra
	
print_float:
	li $v0, 2 	 # valores flutuantes devem ser mandados para o CoProcessador1
	lwc1 $f12, float # reg $f12 está no CoPrecessador 1 
	syscall
	jr $ra
	
print_double:
	ldc1 $f2, double
	ldc1 $f0, double2
	li $v0, 3  # 3 printa double
	add.d $f12,$f2,$f0
	syscall
	jr $ra
	
breakline:
	li $v0, 4
	la $a0, feedline
	syscall
	jr $ra