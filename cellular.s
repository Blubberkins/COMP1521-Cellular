########################################################################
# COMP1521 20T2 --- assignment 1: a cellular automaton renderer
#
# Written by <<Aaron Wang>> (z5308498), July 2020.


# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	=    0
MAX_RULE	=  255

# Characters used to print alive/dead cells.

ALIVE_CHAR	= '#'
DEAD_CHAR	= '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

	.data

# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

cells:	.space MAX_CELLS_BYTES


# Some strings you'll need to use:

prompt_world_size:	.asciiz "Enter world size: "
error_world_size:	.asciiz "Invalid world size\n"
prompt_rule:		.asciiz "Enter rule: "
error_rule:		.asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"

	.text

	# Register purposes:
	#
	# t0: address of cells[0][world_size / 2] (*)
	# t1: world_size / 2 (*)
	#
	# s0: world_size
	# s1: which_generation
	# s2: rule
	# s3: reverse
	# s4: g
	# s5: n_generations
	#
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	# - denoted with a (*)

main:

	sw	$fp, -4($sp)				# setup stack frame
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	sw	$s0, -8($fp)
	sw 	$s1, -12($fp)
	sw 	$s2, -16($fp)
	sw 	$s3, -20($fp)
	sw 	$s4, -24($fp)
	sw 	$s5, -28($fp)
	addi $sp, $sp, -32	
	
	la $a0, prompt_world_size  		# printf("Enter world size: ");
    li $v0, 4 						# calls printf (4 is for strings)
    syscall

    li $v0, 5                  		# scanf("%d", number);
    syscall

    move $s0, $v0					# stores world_size in s0

	blt $s0, MIN_WORLD_SIZE, invalid_world_size	# if (world_size < 
												# MIN_WORLD_SIZE) jump to
												# invalid_world_size
	ble $s0, MAX_WORLD_SIZE, valid_world_size	# if (world_size <=
												# MAX_WORLD_SIZE) jump to
												# valid_world_size

invalid_world_size:

	la $a0, error_world_size  		# printf("Invalid world size\n");
    li $v0, 4
    syscall

	li $v0, 1						# return 1;
	jr $ra

valid_world_size:

	la $a0, prompt_rule  			# printf("Enter rule: ");
    li $v0, 4 						# calls printf (4 is for strings)
    syscall

    li $v0, 5                  		# scanf("%d", number);
    syscall

    move $s2, $v0					# stores rule in s2

	blt $s2, MIN_RULE, invalid_rule # if (rule < MIN_RULE) jump to invalid_rule
	ble $s2, MAX_RULE, valid_rule 	# if (rule <= MAX_RULE) jump to valid_rule

invalid_rule:

	la $a0, error_rule  			# printf("Invalid rule\n");
    li $v0, 4
    syscall

	li $v0, 1						# return 1;
	jr $ra

valid_rule:

	la $a0, prompt_n_generations  	# printf("Enter how many generations: ");
    li $v0, 4 						# calls printf (4 is for strings)
    syscall

    li $v0, 5                  		# scanf("%d", number);
    syscall

    move $s5, $v0					# stores n_generations in s5

	blt $s5, MIN_GENERATIONS, invalid_generations	# if (n_generations < 
													# MIN_GENERATIONS) jump to
													# invalid_generations
	ble $s5, MAX_GENERATIONS, valid_generations 	# if (n_generations <=
													# MAX_GENERATIONS) jump to
													# valid_generations

invalid_generations:

	la $a0, error_n_generations 	# printf("Invalid number of generations\n");
    li $v0, 4
    syscall

	li $v0, 1						# return 1;
	jr $ra

valid_generations:

	li $a0, '\n'      				# printf("%c", '\n');
    li $v0, 11
    syscall

	li $s3, 0						# int reverse = 0;

	bge $s5, 0, no_reverse			# if (n_generations >= 0) jump to no_reverse

	li $s3, 1						# reverse = 1;
	mul $s5, $s5, -1				# n_generations = -n_generations;
	
no_reverse:

	la $t0, cells					# load address of cells[0][0] into t0

	div $t1, $s0, 2					# t1 = world_size / 2
	add $t0, $t0, $t1				# load address of cells[0][world_size / 2]
									# into t0

	li $s4, 1						# int g = 1
	sb $s4, ($t0)					# store g into cells[0][world_size / 2]

for_loop0:

	bgt $s4, $s5, if_reverse		# if (g > n_generations) jump to if_reverse

	move $s1, $s4					# load g into which_generation

	jal run_generation				# call run_generation()

	add $s4, $s4, 1					# g++;
	b for_loop0						# jump to for_loop0

if_reverse:

	li $s4, 0						# g = 0;

	beqz $s3, for_loop2				# if (reverse == 0) jump to for_loop2

	move $s4, $s5					# g = n_generations;

for_loop1:

	blt	$s4, 0, main_end			# if (g < 0) jump to main_end

	move $s1, $s4					# load g into which_generation

	jal print_generation			# call print_generation

	sub $s4, $s4, 1					# g--;
	b for_loop1						# jump to for_loop1

for_loop2:

	bgt $s4, $s5, main_end			# if (g > n_generations) jump to main_end

	move $s1, $s4					# load g into which_generation

	jal print_generation			# call print_generation

	add $s4, $s4, 1					# g++;
	b for_loop2						# jump to for_loop2

main_end:

	lw  $ra, -4($fp)				# tear down stack frame
   	lw	$s0, -8($fp)
   	lw	$s1, -12($fp)
	lw 	$s2, -16($fp)
	lw	$s3, -20($fp)
	lw	$s4, -24($fp)
	lw	$s5, -28($fp)

	la	$sp, 4($fp)
   	lw	$fp, ($fp)

	li	$v0, 0						# return 0
	jr 	$ra

	#
	# Given `world_size', `which_generation', and `rule', calculate
	# a new generation according to `rule' and store it in `cells'.
	#

	# Register purposes:
	# 
	# t0: x
	# t1: address of cells[which_generation - 1][0]
	# t2: (which_generation - 1) / (world_size - 1) / 
	# 	  (world_size * which_generation)
	# t3: cells[which_generation - 1][x]
	# t4: centre / a
	# t5: left
	# t6: right
	# t7: state
	# t8: i / bit / set
	# t9: address of cells[which_generation][x]
	#
	# s0: world_size
	# s1: which_generation
	# s2: rule
	#
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	# - denoted with a (*)

run_generation:

	sw	$fp, -4($sp)				# setup stack frame
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	addi $sp, $sp, -8

	li $t0, 0						# int x = 0;

run_gen_loop:

	bge $t0, $s0, run_generation_end	# if (x >= world_size) jump
										# to run_generation_end

	la $t1, cells					# load address of cells[0][0] into t1
	sub $t2, $s1, 1					# load (which_generation - 1) into t2

	mul $t2, $t2, $s0				# multiply by world_size
	add $t1, $t1, $t2				# load address of
									# cells[which_generation - 1][0] into t1
	
centre:

	add $t3, $t1, $t0				# load address of
									# cells[which_generation - 1][x] into t3
	lbu $t4, ($t3)					# centre = cells[which_generation - 1][x]

left:

	li $t5, 0						# int left = 0;

	ble $t0, 0, right				# if (x <= 0) jump to right

	lbu $t5, -1($t3)				# left = cells[which_generation - 1][x - 1]

right:

	li $t6, 0						# int right = 0;

	sub $t2, $s0, 1					# store (world_size - 1) in t2
	bge $t0, $t2, state				# if (x >= (world_size - 1)) jump to state

	lbu $t6, 1($t3)					# right = cells[which_generation - 1][x + 1]

state:

	sll $t5, $t5, 2					# shift 'left' left by 2
	sll $t4, $t4, 1					# shift 'centre' left by 1
	
	or $t7, $t5, $t4				# int state = left | centre;
	or $t7, $t7, $t6				# state = state | right;

bit:

	li $t8, 1						# int i = 1;

	sllv $t8, $t8, $t7  			# int bit = i << state;
	and $t8, $s2, $t8				# int set = rule & bit;

	la $t9, cells					# load address of cells[0][0] into t9

	mul $t2, $s0, $s1				# t2 = world_size * which_generation
	add $t9, $t9, $t2				# load address of
									# cells[which_generation][0] into t9
	add $t9, $t9, $t0				# load address of
									# cells[which_generation][x] into t9
								
if_set:

	beqz $t8, not_set				# if (set == 0), jump to not_set

	li $t4, 1						# int a = 1
	sb $t4, ($t9)					# store a into cells[which_generation][x]

	b end_run_gen_loop				# jump to end_run_gen_loop

not_set:

	li $t4, 0						# int a = 0
	sb $t4, ($t9)					# store a into cells[which_generation][x]

end_run_gen_loop:

	add $t0, $t0, 1					# x++;
	b run_gen_loop					# jump to run_gen_loop

run_generation_end:

	lw	$ra, -4($fp)				# tear down stack frame
	la	$sp, 4($fp)
   	lw	$fp, ($fp)

	li	$v0, 0						# return 0
	jr	$ra

	#
	# Given `world_size', and `which_generation', print out the
	# specified generation.
	#

	# Register purposes:
	# 
	# t0: x 
	# t1: address of cells[which_generation][x]
	# t2: (world_size * which_generation)
	# t3: cells[which_generation][x]
	#
	# s0: world_size
	# s1: which_generation
	#
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `print_generation' FINISHES
	# - denoted with a (*)

print_generation:

	sw	$fp, -4($sp)				# setup stack frame
	la	$fp, -4($sp)
	sw	$ra, -4($fp)
	addi $sp, $sp, -8

	move $a0, $s1 					# printf("%d", which_generation);
    li $v0, 1 						# calls printf (1 is for ints)
    syscall

	li $a0, '\t'      				# printf("%c", '\t');
    li $v0, 11
    syscall

	li $t0, 0						# int x = 0;

print_gen_loop:

	bge $t0, $s0, print_newline		# if (x >= world_size) jump to print_newline

	la $t1, cells					# load address of cells[0][0] into t1
	mul $t2, $s0, $s1				# t2 = world_size * which_generation
	add $t1, $t1, $t2				# load address of
									# cells[which_generation][0] into t1
	add $t1, $t1, $t0				# load address of
									# cells[which_generation][x] into t1	
	lbu $t3, ($t1)					# t3 = cells[which_generation][x]

	beqz $t3, char_dead				# if (t3 == 0) jump to char_dead

	li $a0, ALIVE_CHAR      		# printf("%c", ALIVE_CHAR);
    li $v0, 11
    syscall

	b end_print_gen_loop			# jump to end_print_gen_loop

char_dead:

	li $a0, DEAD_CHAR      			# printf("%c", DEAD_CHAR);
    li $v0, 11
    syscall

end_print_gen_loop:

	add $t0, $t0, 1					# x++;
	b print_gen_loop				# jump to print_gen_loop

print_newline:

	li $a0, '\n'      				# printf("%c", '\n');
    li $v0, 11
    syscall

print_generation_end:

	lw	$ra, -4($fp)				# tear down stack frame
	la	$sp, 4($fp)
   	lw	$fp, ($fp)

	li	$v0, 0						# return 0
	jr	$ra