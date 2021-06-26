.data
	bufferFile: .space 1024
	filein: .asciiz "entrada.txt"
	fileout: .asciiz "saida.txt"
	texto: .asciiz "este texto deve aparecer no arquivo out"
.text
main:
	
	la $a3, filein
	jal create_file
li $v0, 10
syscall

open_file_leitura: #$a3 indica o arquivo a ser aberto
	#la $a3, filename
	li $v0, 13
	move $a0, $a3
	li $a1, 0
	li $a2, 0
	syscall
	move $s0, $v0 # salvando descriptor do arquivo in
	jr $ra

open_file_escrita: #$a3 indica o arquivo a ser aberto
	#la $a3, filename
	li $v0, 13
	move $a0, $a3
	li $a1, 1
	li $a2, 0
	syscall
	move $s0, $v0 # salvando descriptor do arquivo in
	jr $ra

close_file: # salvando em $a3 o arquivo que fecharemos
	#la $a3, filename
	li $v0, 16
	move $a0, $a3
	syscall
	jr $ra

read_file:
	#la $a3, filename
	li $v0, 14
	la $a0, bufferFile
	li $a1, 1024 # buffer size
	jr $ra

write_file:
	#la $a3, filename
	jr $ra

print_buffer: # recebe em a3 o buffer e o imprime
	li $v0, 4
	move $a0, $a3
	syscall
	jr $ra
	
create_file: # salva em a3 o arquivo a ser criado
	addi $sp, $sp, -4
	sw $ra, 0($sp) # salva o valor do ra do creat file
	jal open_file_escrita
	jal close_file
	lw $ra, 0($sp)
	addi $sp, $sp 4
	jr $ra
	
	
