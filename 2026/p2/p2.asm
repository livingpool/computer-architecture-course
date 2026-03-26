.data 
prompt1 : .asciiz "Please input array A:\n"				# the first prompt string
prompt2 : .asciiz "Please input a key value:\n"				# the second prompt string
error: .asciiz "Error! The array is not sorted.\n"
step: .asciiz "Step "
colon: .asciiz ": "
arr_prefix: .asciiz "A["
arr_suffix: .asciiz "] "
less_than: .asciiz "< "
greater_than: .asciiz "> "
equal: .asciiz "= "
endl: .asciiz "\n"
not_found: .asciiz "Not found!\n"

buf: .space 512			# max 100 integers, 99 commas, values between -100 and 100
.align 2			# 4-byte alignment for the integer array
arr: .word 0:100		# max 100 integers

.text
main:
	# print prompt1 (syscall 4)
	la $a0, prompt1					
	li $v0, 4					
	syscall
	
	# read array A as commma-separated string (syscall 8): a0=buf, a1=maxlen
	la $a0, buf					
	li $a1, 512					
	li $v0, 8					
	syscall
	
	# parse_csv_ints(a0=buf, a1=arr) -> v0=count
    	la   $a0, buf
    	la   $a1, arr
    	jal  parse_csv_ints
   	move $s0, $v0         				 # s0: count (# of ints in arr)
	
	# print prompt2 (syscall 4)
	la $a0, prompt2					
	li $v0, 4					
	syscall
	
	# read key value as integer (syscall 5)
	li $v0, 5					
	syscall
	move $s1, $v0					# s1: key
	
	# 
	li $s2, 1					# s2: step
	
# ------------------------------------------------------------
# parse_csv_ints(a0=char* in, a1=int* out)
# returns v0 = number of ints written
# accepts: optional '-', digits; delimiter: comma
# stops at NUL; commits last number even without trailing comma
# ------------------------------------------------------------
parse_csv_ints:
	move $t0, $a0		# t0: input pointer (comma-separated string)
	move $t1, $a1		# t1: output pointer (integer array)
	li $t2, 0		# t2: current number
	li $t3, 1		# t3: sign
	li $t4, 0		# t4: count

p_loop:
	lb $t5, 0($t0)			# t5: next byte of the input string
	
	beq $t5, $zero, p_end		# go to parse_end if we encounter '\0'
	li $t6, 10			# '\n'
	beq $t5, $t6, p_end		# go to parse_end if we encounter newline
	
	li $t6, 44			# ','
	beq, $t5, $t6, p_store		# go to p_store if we encounter comma
	
	li $t6, 45			# '-'
	beq $t5, $t6, p_set_negative	# go to set_negative if we encounter the negative sign
	
	addi $t5, $t5, -48		# convert a char to an integer
	mul $t2, $t2, 10
	add $t2, $t2, $t5
	
	addi $t0, $t0, 1		# input string index += 1
	j p_loop

p_set_negative:
	li $t3, -1			# set sign = -1
	addi $t0, $t0, 1		# input string index += 1
	j p_loop

p_store:
	mul $t2, $t2, $t3		# current number *= sign
	sw $t2, 0($t1)			# store the current number
	addi $t0, $t0, 1		# input string index += 1
	addi $t1, $t1, 4		# output array index += 1 (1*4 for integer)
	addi $t4, $t4, 1		# count += 1
	li $t2, 0			# reset current number
	li $t3, 1			# reset sign
	j p_loop
	
p_end:
	# appends the last number to the array
	mul $t2, $t2, $t3		# current number *= sign
	sw $t2, 0($t1)
	addi $t4, $t4, 1		# count += 1

p_done:
	move $v0, $t4			# return count
	jr $ra

# ------------------------------------------------------------
# check_arr(a0=int* arr, a1=int size)
# returns v0 = arr status (0: not sorted; 1: ascending; 2: descending; 3: monotonic)
# ------------------------------------------------------------
check_arr:
	move $t0, $a0			# t0: input pointer (integer array)
	move $t1, $a1			# t1: arr size
	li $t2, 0			# t2: status = 0
	beq $t1, 0, c_done		# if size == 0, return 0
	li $t2, 1
	beq $t1, 1, c_1			# if size == 1, return 1
	li $t2, 0
	
	lw $t2, 0($t0)			# t2 = arr[0]
	lw $t3, 4($t0)			# t3 = arr[1]
	slt $t4, $t2, $t3		# t2 < t3 ? t4 = 1 : t4 = 0
	
c_done:
	move $v0, $t2			# return status
	jr $ra
