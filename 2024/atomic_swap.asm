try:
	add $t0, $zero, $s4	# copy exchange value
	ll $t1, 0($s1)		# load linked
	sc $t0, 0($s1)		# store conditional
	beq $t0, $zero, try	# branch store fails
	add $s4, $zero, $t1	# put load value in $s4
