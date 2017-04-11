# This program performs the addition of n successive numbers

# Example: n = 4
# Result = 1 + 2 + 3 + 4

# Pseudo-code
# 	function: addition(n)
# 		i = 1
# 		j = 1
# 		while [j != n] do
# 			i = i + j
# 			j = j + 1
# 		end while
# 		return i
#	  end function

# n = 150
addi $1, $0, 150

# init i = 1
addi $2, $0, 0
# init j = 1
addi $3, $0, 1

loop: 	beq $1, $3, DONE
		add $2, $2, $3
		addi $3, $3, 1
		j loop

# store result
DONE: addi $1, $2, 
