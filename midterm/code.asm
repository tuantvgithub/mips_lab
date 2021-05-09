	.data
	
bit_string:	.space	256	# khai bao bien luu tru chuoi bit
	
	.text

# chuong trinh chinh
main:
	li	$v0, 8		# set $v0 = 8 tuong uung voi ham read string
	la	$a0, bit_string	# $a0 luu dia chi cua input string
	la	$a1, 256	# $a1 la do dai toi da nguoi dung co the nhap
	syscall			# goi ham

	# vi $a0 dang luu dia chi cua chuoi bit roi nen ko can set tham so $a0 nua, goi luon
	jal	count_char	# goi thu tuc dem do dai chuoi
	add	$s0, $0, $v0	# $s0 = do dai thu tuc tra ve, hay do dai chuoi

	# kiem tra neu do dai chuoi khong phai boi cua 8 thi ket thuc chuong trinh
	addi	$t1, $0, 8	# 
	div	$s0, $t1	# khong phai boi cua 8 thi ket thuc
	mfhi	$t1		# chuong trinh
	bnez	$t1, end	#
	
	# neu do dai hop le thi goi thu tuc print_ascii
	# vi $a0 van chua bi thay doi, van luu dia chi cua chuoi bit nen
	# chi can set tham so thu 2 ($a1)
	li	$a1, 0		# set $a1 = 0 (lan dau goi ham nen vi tri ban dau = 0)
	jal 	print_ascii	#
	
	
# goi lenh ket thuc chuong trinh voi $v0 = 10	
end:
	li	$v0, 10
	syscall
	


# ham dem ky tu cua chuoi bit
# tham so:
#	param1 ($a0): dia chi cua chuoi bit
# return 	$v0	la thanh ghi luu dia chi chua do dai cua chuoi bit
#
count_char:
	addi	$t1, $0, 0	# dai dien cho bien i = 0
	li	$t3, '\n'	# bien nl = '\n'
	while:
		add	$t2, $t1, $a0		# $t2 = dia chi cua bit_string[i]
		lbu	$t2, 0($t2)		# $t2 = bit_string[i]
		beq	$t2, $zero, done	# if bit_string[i] = '\0' -> done
		beq	$t2, $t3, done		# if bit_string[i] = '\n' -> done

		addi	$t1, $t1, 1		# i = i + 1
		j while				# nhay toi while va tiep tuc vong lap
	
	# ket thuc vong lap va tra ve do dai chuoi
	done:
		addi	$v0, $t1, 0	# gan $v0 = $t1 (vi so lan lap i chinh la do dai chuoi)
		jr	$ra		# tro ve noi goi ham

#
# day la ham de quy thuc hien viec
# in ky tu ascii tuong ung voi moi 8 bit
# cua chuoi bit
# 2 tham so: 
#	param1 ($a0) : chuoi bit
#	param2 ($a1) : vi tri bat dau duyet
# khong return gi ca
#
# vi du $a1 = 0 thi se duyet va in ky tu ascii tuong ung cho chuoi bit_string[0->7]
# tuong tu neu = 8 thi la bit_string[8->15]
#
print_ascii:
	# $a0 = bit_string
	# $a1 = i
	
	addi	$sp, $sp, -8	# danh stack cho 2 muc
	sw	$ra, 4($sp)	# cat giu dia chi tra ve 
	sw	$a0, 0($sp)	# cat giu dia chi chuoi bit
	
	addi	$s1, $0, 0	# j = 0
	addi	$s2, $0, 0	# decimal = 0
	li	$t3, '1'	# m = '1'
	li	$t4, '0'	# n = '0'
	loop:
		slti	$t0, $s1, 8		# kiem tra j < 8
		beq	$t0, $0, end_loop	# neu sai -> jump to end_loop
		add	$t0, $s1, $a1		# $t0 = i + j
		add	$t0, $t0, $a0		# $t0 = dia chi bit_string[i+j]
		lb	$t0, 0($t0)		# $t0 = bit_string[i+j]
		
		beq	$t0, $0, exit		# if bit_string[i+j] = '\0' -> exit
		beq	$t0, $t4, continue	# if bit_string[i+j] = '0' -> continue
		bne	$t0, $t3, exit		# else bit_string[i+j] phai = 1 neu khong thi error -> exit
						
		addi	$t1, $0, 7		# 
		sub	$a0, $t1, $s1		# set tham so n cho ham pow: n = 7 - j
		jal	pow			#
		add	$s2, $s2, $v0		# decimal = decimal + pow(7-j)
		lw	$a0, 0($sp)		# khoi phuc lai chuoi bit ban dau va luu vao $a0
	
	# tiep tuc vong lap
	continue:
		addi	$s1, $s1, 1		# j = j + 1
		j	loop			# nhay toi loop
		
	# ket thuc vong lap -> in ky tu ascii tuong ung va goi de qui print_ascii
	end_loop:
		li	$v0, 11		# set $v0 = 11 tuong ung voi ham print char
		la	$a0, 0($s2)	# set tham so $a0 = ky tu de in
		syscall			# goi ham
		
		lw	$a0, 0($sp)	# khoi phuc lai chuoi bit ban dau
		addi	$a1, $a1, 8	# set tham so i = i + 8 (chuyen toi 8 bit tiep theo trong chuoi)
		jal	print_ascii	# goi de qui ham print_ascii
		
	# ket thuc ham print_ascii	
	exit:
		lw	$ra, 4($sp)	# khoi phuc dia chi tro ve
		addi	$sp, $sp, 8	# xoa 2 muc trong stack
		jr	$ra		# va tro ve


# ham de qui tinh luy thua voi co so 2
# tham so:	param1 ($a0):	so mu	n
# return:	$v0	dia chi cua thanh ghi chua gia tri 2^n
#
pow:	# $a0 = n
	addi	$sp, $sp, -4		# danh stack cho 1 muc
	sw	$ra, 0($sp)		# cat giu dia chi tra ve
	bnez	$a0, L1			# kiem tra neu n != 0 thi nhay toi L1
	addi	$v0, $0, 1		# neu n = 0 ket qua = 1
	addi	$sp, $sp, 4		# xoa 1 muc khoi stack
	jr	$ra			# va tro ve
L1:					# neu n != 0 (that ra la > 0)
	addi	$a0, $a0, -1		# giam n = n -1
	jal	pow			# goi de qui
	lw	$ra, 0($sp)		# khoi phuc dia chi tra ve
	addi	$sp, $sp, 4		# xoa 1 muc khoi stack
	addi	$t2, $0, 2		# $t2 = 2
	mul	$v0, $t2, $v0		# nhan ket qua voi 2
	jr	$ra			# va tro ve
	
	
	
	
	
	