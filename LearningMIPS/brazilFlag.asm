# configuações default da memoria do mars
# unit width in pixels     32
# unit height in pixels    32
# display width in pixels  512
# display height in pixels 256
# base adress for display  0x10010000
.data
initial_address: .word 0x10010000
.text
main:
	la 	$t0, initial_address
	addi	$t1, $zero,  128       # display_size
	addi 	$a0, $zero,  0x00009933 # green
	addi	$a1, $zero,  0x00003cb3 # blue
	addi	$a2, $zero,  0x00ffff00 # yellow
	addi	$a3, $zero,  0x00ffffff # white
	move	$t4, $zero
	loop: 
	beq 	$t3, $t1, end
	sll 	$t4, $t3, 2
	add 	$t5, $t4, $t0
	sw 	$a0, 0($t5)
	addi 	$t3, $t3, 1 
	j loop
	end:
	sw   $a2,    28($t0)
	sw   $a2,    32($t0)
	sw   $a2,    84($t0)
	sw   $a2,    88($t0)
	sw   $a2,    92($t0)
	sw   $a2,    96($t0)
	sw   $a2,    100($t0)
	sw   $a2,    104($t0)
	sw   $a2,    140($t0)
	sw   $a2,    144($t0)
	sw   $a2,    148($t0)
	sw   $a1,    152($t0)
	sw   $a1,    156($t0)
	sw   $a1,    160($t0)
	sw   $a1,    164($t0)
	sw   $a2,    168($t0)
	sw   $a2,    172($t0)
	sw   $a2,    176($t0)
	sw   $a2,    196($t0)
	sw   $a2,    200($t0)
	sw   $a2,    204($t0)
	sw   $a2,    208($t0)
	sw   $a2,    212($t0)
	sw   $a3,    216($t0)
	sw   $a3,    220($t0)
	sw   $a3,    224($t0)
	sw   $a3,    228($t0)
	sw   $a2,    232($t0)
	sw   $a2,    236($t0)
	sw   $a2,    240($t0)
	sw   $a2,    244($t0)
	sw   $a2,    248($t0)
	sw   $a2,    260($t0)
	sw   $a2,    264($t0)
	sw   $a2,    268($t0)
	sw   $a2,    272($t0)
	sw   $a2,    276($t0)
	sw   $a1,    280($t0)
	sw   $a1,    284($t0)
	sw   $a1,    288($t0)
	sw   $a1,    292($t0)
	sw   $a2,    296($t0)
	sw   $a2,    300($t0)
	sw   $a2,    304($t0)
	sw   $a2,    308($t0)
	sw   $a2,    312($t0)
	sw   $a2,    332($t0)
	sw   $a2,    336($t0)
	sw   $a2,    340($t0)
	sw   $a1,    344($t0)
	sw   $a1,    348($t0)
	sw   $a1,    352($t0)
	sw   $a1,    356($t0)
	sw   $a2,    360($t0)
	sw   $a2,    364($t0)
	sw   $a2,    368($t0)
	sw   $a2,    404($t0)
	sw   $a2,    408($t0)
	sw   $a2,    412($t0)
	sw   $a2,    416($t0)
	sw   $a2,    420($t0)
	sw   $a2,    424($t0)
	sw   $a2,    476($t0)
	sw   $a2,    480($t0)
li $v0, 10
syscall
	