.data
   mensagem: .asciiz "5"
   
.text
   li $v0, 4 
   la $a0, mensagem
   syscall
