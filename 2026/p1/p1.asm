.data 
prompt : .asciiz "Please input the decimal integer (1~3999):\n"		# prompt string
illegal_input : .asciiz "Illegal input.\n"				# illegal output string
output_prefix : .asciiz "The Roman numeral is " 			# output prefix string
output_suffix : .asciiz ".\n"						# output suffix string
lower_limit : .word 1							# input lower limit integer
upper_limit : .word 3999						# input upper limit integer
first : .space 16							# ones digit of output
second : .space 16							# tens digit of output
third : .space 16							# hundreds digit of output
fourth : .space 16							# thousands digit of output
symbols_1 : .asciiz "IVX"						# potential roman numerals for ones digit
symbols_2 : .asciiz "XLC"						# potential roman numerals for tens digit
symbols_3 : .asciiz "CDM"						# potential roman numerals for hundreds digit
symbols_4 : .asciiz "M"							# potential roman numerals for thousands digit

# strategy: handle each digit of the input separately and concatenate the results in the end

# 1, 2, 3: I; 4: IV; 5, 6, 7, 8: V, I; 9: IX
# 10, 20, 30: X; 40: XL; 50, 60, 70, 80: L, X; 90: XC
# 100, 200, 300: C; 400: CD; 500, 600, 700, 800: D, C; 900: CM
# 1000, 2000, 3000: M

.text
main:
	la $a0, prompt					# load the address of the "prompt" string
	li $v0, 4					# specify print string service
	syscall
	li $v0, 5					# specify read integer service
	syscall
	
	# detect illegal input
	la $t1, lower_limit				# load the address of the "lower_limit" value
	lw $t1, 0($t1)					# load the "lower_limit" value
	blt $v0, $t1, IL				# jump to "IL" if input is less than "lower_limit"
	la $t1, upper_limit				# load the address of the "upper_limit" value
	lw $t1, 0($t1)					# load the "upper_limit" value
	bgt $v0, $t1, IL				# jump to "IL" if input if greater than "upper_limit"
	
	li $t0, 4					# set number of loops to run
	
START_LOOP:
	# start of loop
	beqz $t0, EXIT					# if done, go to EXIT
	li $t1, 10					# set divisor
	divu $v0, $t1					# divide input by 10
	mfhi $t1					# get remainder (current digit of input we're examining)
	mflo $v0					# place quotient in $v0	(remaining input we haven't examined)
	
	# branch based on current digit to load output buffers and symbol strings
	beq $t0, 4, LOAD_FIRST
	beq $t0, 3, LOAD_SECOND
	beq $t0, 2, LOAD_THIRD
	beq $t0, 1, LOAD_FOURTH
	
LOADED:
	# branch to get the roman numeral string of the current digit
	beqz $t1, END_LOOP				# if current digit = 0, continue loop
	blt $t1, 4, BELOW_4				# if current digit < 4, go to BELOW_4 (1~3)
	beq $t1, 4, EQUAL_4				# if current digit = 4, go to EQUAL_4
	beq $t1, 9, EQUAL_9				# if current digit = 9, go to EQUAL_9
	j ABOVE_4					# if current digit > 4, go to ABOVE_4 (5~8)

END_LOOP:
	sb $zero, 0($t3)				# string[n] = '\0'
	subiu $t0, $t0, 1				# decrement number of loops to run
	j START_LOOP

EXIT:
	# print our result
	la $a0, output_prefix				# print output_prefix
	li $v0, 4
	syscall
	la $a0, fourth					# print thousands digit
	li $v0, 4
	syscall
	la $a0, third					# print hundreds digit
	li $v0, 4
	syscall
	la $a0, second					# print tens digit
	li $v0, 4
	syscall
	la $a0, first					# print ones digit
	li $v0, 4
	syscall
	la $a0, output_suffix				# print output_suffix
	li $v0, 4
	syscall
	li $v0, 10					# syscall for exit
	syscall

IL: 	
	la $a0, illegal_input				# load the address of the "illegal_input" string
	li $v0, 4					# specify print string service
	syscall
	li $v0, 10					# syscall for exit
	syscall

LOAD_FIRST:
	la $t2, symbols_1				# load the address of the "symbols_1" string 
	la $t3, first					# load the address of the allocated space for ones digit
	j LOADED					# go to LOADED

LOAD_SECOND:
	la $t2, symbols_2				# load the address of the "symbols_2" string
	la $t3, second					# load the address of the allocated space for tens digit
	j LOADED					# go to LOADED

LOAD_THIRD:
	la $t2, symbols_3				# load the address of the "symbols_3" string
	la $t3, third					# load the address of the allocated space for hundreds digit
	j LOADED					# go to LOADED

LOAD_FOURTH:
	la $t2, symbols_4				# load the address of the "symbols_4" string
	la $t3, fourth					# load the address of the allocated space for thousands digit
	j LOADED					# go to LOADED
	
BELOW_4:
	beqz $t1, END_LOOP				# if $t1 = 0, go to END_LOOP
	lb $t4, 0($t2)					# load the first byte of $t2, i.e., I, X, or C
	sb $t4, 0($t3)					# store the first byte of $t2
	addiu $t3, $t3, 1				# move $t3 one byte forward for storing
	subiu $t1, $t1, 1				# decrement $t1 (loop counter)
	j BELOW_4					# go to the beginning of the loop
	
EQUAL_4:
	lb $t4, 0($t2)					# load the first byte of $t2, i.e., I, X, or C
	sb $t4, 0($t3)					# store the first byte of $t2
	lb $t4, 1($t2)					# load the second byte of $t2, i.e., V, L, or D
	sb $t4, 1($t3)					# store the second byte of $t2
	addiu $t3, $t3, 2				# add 2 to $t3 for the null-terminator
	j END_LOOP					# go to END_LOOP

EQUAL_9:
	lb $t4, 0($t2)					# load the first byte of $t2, i.e., I, X, or C
	sb $t4, 0($t3)					# store the first byte of $t2
	lb $t4, 2($t2)					# load the third byte of $t2, i.e., X, C, or M
	sb $t4, 1($t3)					# store the third byte of $t2, i.e., X, C, or M
	addiu $t3, $t3, 2 				# add 2 to $t3 for the null-terminator
	j END_LOOP					# go to END_LOOP

ABOVE_4:
	subiu $t1, $t1, 5				# set number of loops to run for
	lb $t4, 1($t2)					# load the second byte of $t2, i.e., V, L, or D
	sb $t4, 0($t3)					# store the second byte of $t2
	addiu $t3, $t3, 1				# move $t3 one byte forward for storing
	
ABOVE_4_LOOP:
	beqz $t1, END_LOOP				# if $t1 = 0, go to END_LOOP
	lb $t4, 0($t2)					# load the first byte of $t2, i.e., I, X, or C
	sb $t4, 0($t3)					# store the first byte of $t2
	addiu $t3, $t3, 1				# move $t3 one byte forward for storing
	subiu $t1, $t1, 1				# decrement $t1 (loop counter)
	j ABOVE_4_LOOP					# go to the beginning of the loop
