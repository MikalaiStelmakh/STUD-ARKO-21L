# Project 24
# Program rotates the given .bmp image 90 degrees X times
# Author: Mikalai Stelmakh

	.data
size:	.space	4		#file size
width:	.space	4		#image width
height:	.space	4		#image height
trash:	.space	14
filename:	.space	50

input:	.asciiz	"Enter the input file name: " 
output:	.asciiz	"rotated.bmp"			
number_of_rotations:	.asciiz	"Number of rotations to make\n"
error:	.asciiz	"Error while opening the file\n"

	.text
main:
	jal	get_filename
	jal	open_bmp
	jal 	read_header
	
	# Close .bmp
	move	$a0, $t0
	li	$v0, 16
	syscall
	

	jal	open_bmp
	jal	allocate_memory
	
	# Store input file descriptor to allocated memory
	move	$a0, $t0	# $t0 - file descriptor
	la	$a1, ($t1)	# $t6 - allocated memory address
	la	$a2, ($t7)	# $t7 - input file size
	li	$v0, 14
	syscall
	
	# Close bmp
	move	$a0, $t0
	li	$v0, 16
	syscall
	
	# Padding
	li	$t2, 4	# number of bytes used for division
	div	$t8, $t2
	mfhi	$k0	# padding (width)
	div	$t9, $t2
	mfhi	$k1	# padding (height)
	
	# Ask user about number of rotations
	la	$a0, number_of_rotations
	li	$v0, 4
	syscall
	# Get input
	li	$v0, 5
	syscall
	move	$s6, $v0	# store number of rotations to $t2
	# Get mod 4 number of rotations
	li	$t2, 4
	div	$s6, $t2
	mfhi	$s6
	move	$s4, $s6	# make copy of $s6 in $s4
	
	la	$t2, 54($t1)
	la	$t5, ($t6)
	subi	$t3, $t7, 54	# input file size without header
	
	beqz	$s6, rotate_zero
	j	rotate

get_filename:
	# Ask for input file name
	la	$a0, input
	li	$v0, 4
	syscall
	la	$a0, filename
	li	$a1, 50
	li	$v0, 8
	syscall
remove:
	# Remove "\n" from the end of the filename
	lb $a3, filename($s0)   # Load character at index
    	addi $s0, $s0, 1      	# Increment index
    	bnez $a3, remove     	# Loop until the end of string is reached
    	beq $a1, $s0, skip    	# Do not remove \n when string = maxlength
    	subiu $s0, $s0, 2     	# If above not true, Backtrack index to '\n'
    	sb $0, filename($s0)    # Add the terminating character in its place
skip:
	jr	$ra

open_bmp:
	la	$a0, filename	# Load input file name
	li	$a1, 0		# Read only flag
	li	$a2, 0
	li	$v0, 13		# Open file syscall
	syscall
	move	$t0, $v0	# Store input file descriptor to $t0
	bltz	$v0, open_error	# Branch if file not opened
	jr $ra
	
read_header:
# Skip first two bytes containing information 
# that this is a file with the bmp extension
	move	$a0, $t0
	la	$a1, trash
	li	$a2, 2  # Read first 2 bytes
	li	$v0, 14
	syscall
# Read next 4 bytes containing file size
  	la  	$a1, size
  	li  	$a2, 4
  	li  	$v0, 14
  	syscall
  	lw	$t7, size	# Store size to $t7
# Skip 12 bytes
  	la  	$a1, trash
  	li  	$a2, 12
  	li  	$v0, 14
  	syscall
# Read 4 bytes with image width
  	la  	$a1, width
  	li  	$a2, 4
  	li  	$v0, 14
  	syscall
  	lw	$t8, width	# Store width to $t8
# Read 4 bytes with image height
  	la  	$a1, height
  	li	$a2, 4
  	li 	$v0, 14
  	syscall
  	lw	$t9, height	# Store height to $t9
	jr $ra

allocate_memory:
	la	$a0, ($t7)	# Number of bytes to allocate memory for the whole file
	li	$v0, 9
	syscall
	move	$t1, $v0	# Store address of allocated memory to $t1
	
	# Allocate memory for pixels
	subiu	$a0, $t7, 54	# Number of bytes to allocate
	li	$v0, 9
	syscall
	move	$t6, $v0	# Store address of allocated memory to $t6
	jr $ra
	
open_error:
	# Error message
	la	$a0, error
	li	$v0, 4
	syscall
	# Exit
	li	$v0, 10
	syscall

rotate_zero:
	lbu	$t4, ($t2)
	sb	$t4, ($t5)
	addiu	$t2, $t2, 1
	addiu	$t5, $t5, 1
	subi	$t3, $t3, 1
	bgtz	$t3, rotate_zero
	la	$t5, ($t6)
	la	$t2, 54($t1)
	j save_start_header

rotate:
	subi	$s0, $t8, 1	# Outside loop index (width - 1)
	mul	$s2, $s0, 3	
	add	$s2, $s2, $k0	# $s2: Number of bytes to move 1 line up
outside_loop:
	subi	$t3, $t9, 1	# Inside loop index (height - 1)
	mul	$s1, $s0, 3	# Number of bytes to move to the end of the row
	la	$t2, 54($t1)	# Move to the beginning of pixel map
	add	$t2, $t2, $s1 	# Move to the end of current row
inside_loop:
	jal	store_pixel
	add	$t2, $t2, $s2	# Move to the next row
	subi	$t3, $t3, 1	# Reduce inside loop index
	bgtz	$t3, inside_loop
	
	jal	store_pixel
	
	add	$t5, $t5, $k1	# Add padding
	
	
	subi	$s0, $s0, 1	# Reduce outside loop index
	bgez	$s0, outside_loop
	
	# Swap padding sizes
	move	$t4, $k0
	move	$k0, $k1
	move	$k1, $t4
	
	# Swap width with height
	move	$t3, $t8
	move	$t8, $t9
	move	$t9, $t3
	
	
	la	$t5, ($t6)
	la	$t2, 54($t1)
	subi	$t3, $t7, 54
	
	jal store_input
	
	subi	$s6, $s6, 1	# Reduce number of rotations left
	beqz	$s6, save_start_header
	j	rotate
store_input:
	lbu	$t4, ($t5)
	sb	$t4, ($t2)
	addi	$t2, $t2, 1
	addi	$t5, $t5, 1
	subi	$t3, $t3, 1
	bgtz	$t3, store_input

	la	$t5, ($t6)
	la	$t2, 54($t1)
	jr	$ra

store_pixel:
# Load 3 bytes from input file and store it in allocated memory
# for output file pixel map.
	# Store first byte
	lbu	$t4, ($t2)
	sb	$t4, ($t5)
	# Move to the next byte
	addi	$t2, $t2, 1
	addi	$t5, $t5, 1
	# Store second byte
	lbu	$t4, ($t2)
	sb	$t4, ($t5)
	# Move to the next byte
	addi	$t2, $t2, 1
	addi	$t5, $t5, 1
	# Store third byte
	lbu	$t4, ($t2)
	sb	$t4, ($t5)
	# Move to the next byte
	addi	$t2, $t2, 1
	addi	$t5, $t5, 1
	jr	$ra

save_start_header:
	la	$a0, output
	li	$a1, 9	# create and append flag
	li	$a2, 0
	li	$v0, 13
	syscall
	move	$t0, $v0	# store outpit file descriptor to $t0
	bltz	$t0, open_error
	
	# Write header
	# First 18 bytes without changes
	la	$a0, ($t0)
	la	$a1, ($t1)
	la	$a2, 18	# write 54 bytes of header
	li	$v0, 15
	syscall
	
	li $s5, 2
	divu $s4, $s5 # w s7 zadana ilosc obrotow
	mfhi $s5
	bnez $s5, swap_size
	
	la	$a0, ($t0)
	la	$a1, 18($t1)
	la	$a2, 4
	li	$v0, 15
	syscall
	# Write file height info
	la	$a0, ($t0)
	la	$a1, 22($t1)
	la	$a2, 4
	li	$v0, 15
	syscall
	b	save_end_header
	
swap_size:
	# Write file width info
	la	$a0, ($t0)
	la	$a1, 22($t1)
	la	$a2, 4
	li	$v0, 15
	syscall
	# Write file height info
	la	$a0, ($t0)
	la	$a1, 18($t1)
	la	$a2, 4
	li	$v0, 15
	syscall

save_end_header:
	# Write remaining 28 bytes of header
	la	$a0, ($t0)
	la	$a1, 26($t1)
	la	$a2, 28
	li	$v0, 15
	syscall
	
	# Write pixel info
	la	$a0, ($t0)
	la	$a1, ($t6)
	subiu	$a2, $t7, 54
	li	$v0, 15
	syscall
	
	# Close file
	move	$a0, $t0
	li	$v0, 16
	syscall
	
exit:
	li	$v0, 10
	syscall
	
	
	
	
	
	
	
	
	
	
	
	
	
	
