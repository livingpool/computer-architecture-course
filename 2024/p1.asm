.data
	prompt: .asciiz "Please input an  identification number:\n"	# string
	legal: .asciiz "The number is legal.\n"				# string
	illegal: .asciiz "The number is illegal.\n"			# string
	input_buffer: .space 12						# reserve space for the input string
	
.text
main:
	li $v0, 4		# specify print string service
	la $a0, prompt 		# load address of prompt string
	syscall
	
	li $v0, 8		# specify read string service
	la $a0, input_buffer	# load address of input buffer
	li $a1, 12		# specify the maximum buffer size
	syscall
	
	li $v0, 4
	la $a0, input_buffer
	syscall