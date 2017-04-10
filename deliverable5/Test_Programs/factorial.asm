###############################################
# This program generates the factorial of an integer, n > 0
# It stores the result in Reg[2] ($2)

# Pseudo-code
# 	function: factorial(n)
# 		i = 1
# 		j = 1
# 		while [j != n] do
# 			temp = i * j
# 			i = temp
# 			j = j + 1
# 		end while
# 		return i
#	  end function

# Example: 6! = 1 * 2 * 3 * 4 * 5
# n = 6
addi $2, $0, 6

# init i = 1
addi $3, $0, 1
# init j = 1
addi $4, $0, 1

loop: 	beq $2, $4, DONE
	     	mult $3, $4
		    mflo $3
		    addi $4, $4, 1
		    j loop

# store result
DONE: addi $2, $3, 0

###############################################
