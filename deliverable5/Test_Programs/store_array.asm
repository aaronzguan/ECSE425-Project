# This program stores an array into memory
# The values being stored are 1, 2, 3, ..., 20

addi $10, $0, 2000  	# initializing the beginning of Data Section address in memory
add $1, $10, $0         # array pointer
addi $2, $0, 1		# value to store in array
addi $3, $0, 2020 	# loop until this address

loop1: sw $2, 0($1) 
addi $1, $1, 1
addi $2, $2, 1
bne $1, $3, loop1 

addi $1, $10, 0

loop2: lw $5, 0($1)
addi $1, $1, 1
bne $1, $3, loop2 
