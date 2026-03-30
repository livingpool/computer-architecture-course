.data 
prompt1 : .asciiz "Please input array A:\n"				# the first prompt string
prompt2 : .asciiz "Please input a key value:\n"				# the second prompt string
error: .asciiz "Error! The array is not sorted."
step: .asciiz "Step "
colon: .asciiz ": "
arr_prefix: .asciiz "A["
arr_suffix: .asciiz "] "
less_than: .asciiz "< "
greater_than: .asciiz "> "
equal: .asciiz "= "
endl: .asciiz "\n"
not_found: .asciiz "Not found!"

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
   	
   	# check arr status(a0=arr, a1=size) -> v0=status
   	la $a0, arr
   	move $a1, $s0
   	jal check_arr
   	move $s1, $v0					# s1: arr status
   	
   	# if status == 0, input array is invalid
   	beqz $s1, invalid_arr
	
	# print prompt2 (syscall 4)
	la $a0, prompt2					
	li $v0, 4					
	syscall
	
	# read key value as integer (syscall 5)
	li $v0, 5					
	syscall
	move $s2, $v0					# s2: key
	
	# call binary search procedure
	la $a0, arr					# arg 0: arr
	li $a1, 0					# arg 1: l
	addi $a2, $s0, -1				# arg 2: r = count - 1
	move $a3, $s2					# arg 3: key
	addi $sp, $sp, 4
	li $t0, 1					# step = 1
	sw $t0, 0($sp)					# store arg 4: step on stack
	beq $s1, 1, m1					# branch for status 1 (ascending)
	beq $s1, 3, m2					# branch for status 3 (monotonic)
	jal binary_search_descending			# branch for status 2 (descending)
	j exit
m1:
	jal binary_search_ascending
	j exit
m2:
	jal binary_search_ascending
	j exit
exit:
	la $a0, endl					# print '\n'
	li $v0, 4
	syscall
	addi $sp, $sp, 4
	li $v0, 10					# syscall for exit
	syscall
	
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
	beq $t5, $t6, p_store		# go to p_store if we encounter comma
	
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
	li $t2, 1			# t2: status = 1
	beq $t1, 1, c_done		# if size == 1, return 1
	li $t2, 3			# t2: status = 3
	
	lw $t3, 0($t0)			# t3 = arr[0]
	lw $t4, 4($t0)			# t4 = arr[1]
	slt $t5, $t3, $t4		# t3 < t4 ? t5 = 1 : t5 = 0
	beq $t5, 1, c_if_1		# branch for t3 < t4
	beq $t5, 0, c_else_if_1		# branch for t3 >= t4
	j c_else_1
c_if_1:
	li $t2, 1			# if t3 < t4, status = 1
	j c_else_1
c_else_if_1:
	seq $t5, $t3, $t4		# t3 == t4 ? t5 = 1 : t5 = 0
	beq $t5, 1, c_else_1
	li $t2, 2			# if t3 > t4, status = 2
	j c_else_1
c_else_1:				# if t3 == t4, status = 3 
	
	li $t6, 1			# set loop variable i = 1
c_loop:
	beq $t6, $t1, c_done		# if i == size, break loop
	lw $t3, 0($t0)			# t3 = arr[i]
	lw $t4, 4($t0)			# t4 = arr[i+1]
	slt $t5, $t3, $t4		# t3 < t4 ? t5 = 1 : t5 = 0
	beq $t5, 1, c_if_2		# branch for arr[i] < arr[i+1]
	beq $t5, 0, c_else_if_2		# branch for arr[i] >= arr[i+1]
	j c_end_loop
c_if_2:
	beq $t2, 2, c_if_if_2		# if t3 < t4 but status == 2, return 0
	li $t2, 1			# it t3 < t4, status = 1
	j c_end_loop
c_if_if_2:
	li $t2, 0
	j c_done
c_else_if_2:
	seq $t5, $t3, $t4		# t3 == t4 ? t5 = 1 : t5 = 0
	beq $t5, 1, c_end_loop		# if t3 == t4, continue loop (do nothing)
	beq $t2, 1, c_else_if_if_2	# if t3 > t4 but status == 1, return 0
	li $t2, 2			# if t3 > t4, statu2 = 2
	j c_end_loop
c_else_if_if_2:
	li $t2, 0
	j c_done
c_end_loop:
	addi $t0, $t0, 4		# advance loop
	addi $t6, $t6, 1		# increment loop variable i
	j c_loop
	
c_done:
	move $v0, $t2			# return status
	jr $ra

# ------------------------------------------------------------
# invalid_arr (input array is not valid)
# ------------------------------------------------------------
invalid_arr:
	la $a0, error
	li $v0, 4
	syscall
	j exit
	
# ------------------------------------------------------------
# binary_search_ascending(a0=int* arr, a1=int l, a2=int r, a3=int key, 0($sp)= int step)
# ------------------------------------------------------------
binary_search_ascending:
	addi $sp, $sp, -12		# adjust stack for 3 items (preserving step)
	sw $s0, 8($sp)
	sw $ra, 4($sp)			# save return address
	
	move $t4, $a0			# t4: arr (pointer)
				
	la $a0, step
	li $v0, 4
	syscall
	move $a0, $a3
	li $v0, 1
	syscall
	la $a0, colon
	li $v0, 4
	syscall
	
	# base case: if (l > r) return;
	slt $t0, $a2, $a1		# r < l ? t0 = 1 : t0 = 0
	beq $t0, 0, ba_1
	la $a0, not_found
	li $v0, 4
	syscall
	j ba_return
ba_1:
	add $t0, $a1, $a2		
	div $s0, $t0, 2			# s0: int m = (l + r) / 2
	la $a0, arr_prefix		# print A[m]
	li $v0, 4
	syscall
	move $a0, $s0
	li $v0, 1
	syscall
	la $a0, arr_suffix
	li $v0, 4
	syscall
	
	sll $t0, $s0, 2			# t0: m * 4 (offset)
	add $t0, $t4, $t0		# t0: base address + offset
	lw $t0, 0($t0)			# t0 = A[m]
	
	slt $t1, $t0, $a3		# t0 < a3 ? t1 = 1 : t1 = 0
	beq $t1, 1, ba_if		# branch for arr[m] < key
	seq $t1, $t0, $a3 		# t0 == a3 ? t1 = 1 : t1 = 0
	beq $t1, 0, ba_else_if		# branch for arr[m] > key
	# else case (arr[m] == key)	
	la $a0, equal			# print "= "
	li $v0, 4
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	j ba_return
ba_if:
	la $a0, less_than		# print "< "
	li $v0, 4			
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	la $a0, endl			# print '\n'
	li $v0, 4
	syscall
	move $a0, $t4			# restore arg 0: arr
	addi $a1, $s0, 1		# arg 1: m + 1
	lw $t0, 12($sp)			# get arg 5 (step)
	addi $sp, $sp, -4		# adjust stack for arg 5
	addi $t0, $t0, 1		# arg 5: step + 1
	sw $t0, 0($sp)			# store arg 5 on stack
	jal binary_search_ascending
	addi $sp, $sp, 4
	j ba_return
ba_else_if:
	la $a0, greater_than		# print "> "
	li $v0, 4			
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	la $a0, endl			# print '\n'
	li $v0, 4
	syscall
	move $a0, $t4			# restore arg 0: arr
	addi $a2, $s0, -1		# arg 2: m - 1
	lw $t0, 12($sp)			# get arg 5 (step)
	addi $sp, $sp, -4		# adjust stack for arg 5
	addi $t0, $t0, 1		# arg 5: step + 1
	sw $t0, 0($sp)			# store arg 5 on stack
	jal binary_search_ascending
	addi $sp, $sp, 4
ba_return:
	lw $ra, 4($sp)			# restore return address
	addi $sp, $sp, 12		# pop 3 items from stack
	jr $ra
	
# ------------------------------------------------------------
# binary_search_descending(a0=int* arr, a1=int l, a2=int r, a3=int key, 0($sp)= int step)
# ------------------------------------------------------------
binary_search_descending:
	addi $sp, $sp, -12		# adjust stack for 3 items (preserving step)
	sw $s0, 8($sp)
	sw $ra, 4($sp)			# save return address
	
	move $t4, $a0			# t4: arr (pointer)
				
	la $a0, step
	li $v0, 4
	syscall
	move $a0, $a3
	li $v0, 1
	syscall
	la $a0, colon
	li $v0, 4
	syscall
	
	# base case: if (l > r) return;
	slt $t0, $a2, $a1		# r < l ? t0 = 1 : t0 = 0
	beq $t0, 0, bd_1
	la $a0, not_found
	li $v0, 4
	syscall
	j bd_return
bd_1:
	add $t0, $a1, $a2		
	div $s0, $t0, 2			# s0: int m = (l + r) / 2
	la $a0, arr_prefix		# print A[m]
	li $v0, 4
	syscall
	move $a0, $s0
	li $v0, 1
	syscall
	la $a0, arr_suffix
	li $v0, 4
	syscall
	
	sll $t0, $s0, 2			# t0: m * 4 (offset)
	add $t0, $t4, $t0		# t0: base address + offset
	lw $t0, 0($t0)			# t0 = A[m]
	
	slt $t1, $t0, $a3		# t0 < a3 ? t1 = 1 : t1 = 0
	beq $t1, 1, bd_if		# branch for arr[m] < key
	seq $t1, $t0, $a3 		# t0 == a3 ? t1 = 1 : t1 = 0
	beq $t1, 0, bd_else_if		# branch for arr[m] > key
	# else case (arr[m] == key)	
	la $a0, equal			# print "= "
	li $v0, 4
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	j bd_return
bd_if:
	la $a0, less_than		# print "< "
	li $v0, 4			
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	la $a0, endl			# print '\n'
	li $v0, 4
	syscall
	move $a0, $t4			# restore arg 0: arr
	addi $a2, $s0, -1		# arg 2: m - 1
	lw $t0, 12($sp)			# get arg 5 (step)
	addi $sp, $sp, -4		# adjust stack for arg 5
	addi $t0, $t0, 1		# arg 5: step + 1
	sw $t0, 0($sp)			# store arg 5 on stack
	jal binary_search_descending
	addi $sp, $sp, 4
	j bd_return
bd_else_if:
	la $a0, greater_than		# print "> "
	li $v0, 4			
	syscall
	move $a0, $a3			# print key
	li $v0, 1
	syscall
	la $a0, endl			# print '\n'
	li $v0, 4
	syscall
	move $a0, $t4			# restore arg 0: arr
	addi $a1, $s0, 1		# arg 1: m + 1
	lw $t0, 12($sp)			# get arg 5 (step)
	addi $sp, $sp, -4		# adjust stack for arg 5
	addi $t0, $t0, 1		# arg 5: step + 1
	sw $t0, 0($sp)			# store arg 5 on stack
	jal binary_search_descending
	addi $sp, $sp, 4
bd_return:
	lw $ra, 4($sp)			# restore return address
	addi $sp, $sp, 12		# pop 3 items from stack
	jr $ra

