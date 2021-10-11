.macro read_int()
	li $v0, 5
	syscall
.end_macro

.macro print_text(%var)
	la $a0, %var
	li $v0, 4
	syscall
.end_macro

.macro print_int(%var)
	move $a0, %var
	li $v0, 1
	syscall
.end_macro

.data
	msg1: .asciiz "Digite um numero: "
	msg2: .asciiz "Resultado: "
	break_line: .asciiz "\n"

.text
main:
	print_text(msg1)
	read_int()
	move $a0, $v0
	jal fatorial
	print_int($v0)
	print_text(break_line)
li $v0, 10
syscall
	
	# $a0 = input value
	# $v0 = result
	fatorial:
		beqz $a0, fatorial_caso_base
		addi $sp, $sp, -8
		sw $ra, 0($sp)
		sw $a0, 4($sp)
		addi $a0, $a0, -1
		jal fatorial
		lw $a0, 4($sp)
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		mul $v0, $v0, $a0
		j fatorial_end
	fatorial_caso_base:
		li $v0, 1
	fatorial_end:
		jr $ra