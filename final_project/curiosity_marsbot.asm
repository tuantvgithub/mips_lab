.eqv	KEY_CODE			0xFFFF0004	# ASCII code from keyboard, 1 byte
.eqv	KEY_READY			0xFFFF0000	# = 1 if has a new keyboard ?
							# Auto clear after lw

.eqv	IN_ADDRESS_HEXA_KEYBOARD	0xFFFF0012
.eqv	OUT_ADDRESS_HEXA_KEYBOARD	0xFFFF0014

# key value tuong ung tu 0 -> f trong digital lab sim
.eqv	KEY_0	0x00000011
.eqv	KEY_1	0x00000021
.eqv	KEY_2	0x00000041
.eqv	KEY_3	0xffffff81
.eqv	KEY_4	0x00000012
.eqv	KEY_5	0x00000022
.eqv	KEY_6	0x00000042
.eqv	KEY_7	0xffffff82
.eqv	KEY_8	0x00000014
.eqv	KEY_9	0x00000024
.eqv	KEY_a	0x00000044
.eqv	KEY_b	0xffffff84
.eqv	KEY_c	0x00000018
.eqv	KEY_d	0x00000028
.eqv	KEY_e	0x00000048
.eqv	KEY_f	0xffffff88

.eqv 	HEADING 	0xffff8010 	# Integer: An angle between 0 and 359
.eqv 	MOVING 		0xffff8050 	# Boolean: whether or not to move
.eqv 	LEAVETRACK 	0xffff8020 	# Boolean (0 or non-0):
 					# whether or not to leave a track
.eqv 	WHEREX 		0xffff8030 	# Integer: Current x-location of MarsBot
.eqv 	WHEREY 		0xffff8040 	# Integer: Current y-location of MarsBot


.data
	# ------------------------------------------------------------------------------------
	# control code
		MOVE_CODE:		.asciiz	"1b4"
		STOP_CODE:		.asciiz	"c68"
		ROTATE_LEFT_CODE:	.asciiz	"444"	# re trai 90 do
		ROTATE_RIGHT_CODE:	.asciiz	"666"	# re phai 90 do		
		TRACK_CODE:		.asciiz	"dad"	
		UNTRACK_CODE:		.asciiz	"cbc"	
		GO_BACK_CODE:		.asciiz	"999"	# tu dong quay tro ve theo lo trinh nguoc lai
							# khong de lai vet, khong nhan lenh
							# cho toi khi ket thuc lo trinh	

		INVALID_CODE:		.asciiz	"invalid control code\n"				
	# ------------------------------------------------------------------------------------
	# ------------------------------------------------------------------------------------
	
		current_code:		.space	100	# luu chuoi control code
		length_of_current_code:	.word	0	# do dai cua chuoi cotrol code
		now_heading:		.word	0	# huong di chuyen hien tai
		
	# ------------------------------------------------------------------------------------	
	# ------------------------------------------------------------------------------------
	# duong di cua marsbot duoc luu tru vao mang path de phuc vu cho viec
	# quay tro ve vi tri ban dau theo lo trinh nguoc lai
	# can luu 3 thong tin sau:
	# 	- toa do diem x, y
	#	- heading tai thoi diem do (z) --> de khi di nguoc lai chi can quay goc 180 do
	#
	# mac dinh tai thoi diem khoi dau : x = y = z = 0
	#---------------------------------------------------------------------------------
	
		path: 		.space 	120	
		length_path:	.word	0	# chieu dai cua path
						# boi so cua 12
						# vi luu 3 word (x, y, z) trong path
						# cho moi diem nen can 12 bytes
						
	#---------------------------------------------------------------------------------	

.text
	main:
		li	$k0, KEY_CODE
		li	$k1, KEY_READY
		#----------------------------------------------------------------
		# Enable the interrupt of Keyboard matrix 4x4 of Digital Lab Sim
		#----------------------------------------------------------------
		
		li 	$t1, IN_ADDRESS_HEXA_KEYBOARD
		li 	$t3, 0x80 			# bit 7 = 1 to enable
		sb 	$t3, 0($t1)
		
		#----------------------------------------------------------------
		
	loop:	nop
	
	wait_for_key:
		lw	$t7, 0($k1)			# $t7 = [$k1] = KEY_READY
		beq	$t7, $zero, wait_for_key	# if $t7 == 0 then polling

	read_key:
		lw	$t7, 0($k1)			# note!
		beq	$t7, $zero, wait_for_key	# mac du $t7 = 0 nhung van vao day dc ???
							
		lw	$t8, 0($k0)			# $t8 = [$k0] = KEY_CODE

		beq	$t8, 127, delete_current_code	# 127 is DELETE key in ascii
		nop
		
		beq	$t8, '\n', handling_current_code	# if $t8 == '\n' then handling current code
		nop						# '\n' is ENTER key
								# else continue to polling
		nop
		j	loop

	handling_current_code:
		# print current code to the console
		la	$a0, current_code
		li	$v0, 4
		syscall
		li	$a0, '\n'
		li	$v0, 11
		syscall
		
		# kiem tra current code trung control code nao de xu ly
		# neu khong trung -> in thong bao loi (INVALID_CODE)
		case_move:
			la	$a0, MOVE_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_stop
			
			jal	store_path	
			
			jal	GO
			j	done	
		case_stop:
			la	$a0, STOP_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_rotate_left
			
			jal	STOP
#			jal	UNTRACK		# dung test cho nhanh thoi
#			jal	TRACK			# khong can phai nhap cbc, dad moi lan chuyen huong
			j	done
		case_rotate_left:
			la	$a0, ROTATE_LEFT_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_rotate_right
			
			la	$t0, now_heading		
			lw	$a0, 0($t0)		# $a0 = now heading

			li	$t1, 360
			addi	$a0, $a0, 270		# quay trai 90 <-> quay phai (360 - 90)
			div	$a0, $t1
			mfhi	$a0			# $a0 = (now_heading + 270) % 360 = heading sau khi quay trai 90
			sw	$a0, 0($t0)		# update now_heading
			
			jal	ROTATE	 
			j	done		
		case_rotate_right:
			la	$a0, ROTATE_RIGHT_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_track
			
			la	$t0, now_heading
			lw	$a0, 0($t0)		# $a0 = now heading

			li	$t1, 360
			addi	$a0, $a0, 90
			div	$a0, $t1
			mfhi	$a0			# $a0 = (now_heading + 90) % 360 = heading sau khi quay phai 90
			sw	$a0, 0($t0)		# update now_heading
			
			jal	ROTATE	
			j	done		
		case_track:
			la	$a0, TRACK_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_untrack
			
			jal	TRACK
			j	done		
		case_untrack:
			la	$a0, UNTRACK_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, case_go_back
			
			jal	UNTRACK
			j	done		
		case_go_back:
			la	$a0, GO_BACK_CODE
			li	$a1, 3
			jal	current_code_is_equal
			beqz	$v0, default
			
			jal	GO_BACK
			j	done		
		default:
			la	$a0, INVALID_CODE		
			li	$v0, 4
			syscall				
		done:

	# thuc hien xoa current_code
	# bang cach sua cac byte thanh '\0'
	# va update length_of_current_code = 0
	delete_current_code:
		la	$s1, current_code
		
		li	$t6, 0
		la	$t7, length_of_current_code
		lw	$t8, 0($t7)
		
		loop_to_del:
			slt	$t0, $t6, $t8
			beqz	$t0, end_loop_to_del
			
			li	$t5, '\0'
			add	$s5, $s1, $t6
			sb	$t5, 0($s5)
			
			addi	$t6, $t6, 1
			j	loop_to_del			
			
		end_loop_to_del:
			li	$t8, 0
			sw	$t8, 0($t7)	# update length_of_current_code = 0		
			nop
			j	loop

	end_main:
	
# ----------------------------------------------------------------------------------------------
# Procedures current_code_is_equal: kiem tra chuoi current_code co bang voi chuoi tham so khong
# param[in]	$a0	string		string
# param[in]	$a1	integer		length_of_string
# return	$v0	boolean		true: 1, false: 0
# ----------------------------------------------------------------------------------------------
current_code_is_equal:
	backup_in_current_code_is_equal:
		addi	$sp, $sp, 4
		sw	$ra, 0($sp)	
		addi	$sp, $sp, 4
		sw	$t0, 0($sp)
		addi	$sp, $sp, 4
		sw	$t1, 0($sp)
		addi	$sp, $sp, 4
		sw	$t2, 0($sp)
		addi	$sp, $sp, 4
		sw	$t3, 0($sp)
		addi	$sp, $sp, 4
		sw	$t4, 0($sp)
			
	la	$t3, current_code
	
	la	$t2, length_of_current_code	# 
	lw	$t2, 0($t2)			# $t2 = length of current code
	bne	$t2, $a1, is_not_equal		# neu 2 do dai khac nhau -> ko bang nhau
			
	li	$t1, 0				# $t1 = i = 0
	while:
		slt	$t0, $t1, $t2
		beqz	$t0, is_equal		# cu chay het vong while la ok bang nhau
		
		add	$t0, $a0, $t1
		lb	$t0, 0($t0)		# $t0 = [$a0 + $t1] = string[i]
		
		add	$t4, $t3, $t1
		lb	$t4, 0($t4)		# $t4 = current_code[i]
		
		bne	$t0, $t4, is_not_equal	# if string[i] != current_code[i] -> not equal
		
		addi	$t1, $t1, 1		# i = i + 1
		j	while	
	
	is_equal:
		li	$v0, 1
		j	restore_in_current_code_is_equal
	
	is_not_equal:
		li	$v0, 0		
	
	restore_in_current_code_is_equal:
		lw	$t4, 0($sp)
		addi	$sp, $sp, -4		
		lw	$t3, 0($sp)
		addi	$sp, $sp, -4
		lw	$t2, 0($sp)
		addi	$sp, $sp, -4
		lw	$t1, 0($sp)
		addi	$sp, $sp, -4
		lw	$t0, 0($sp)
		addi	$sp, $sp, -4		
		lw	$ra, 0($sp)
		addi	$sp, $sp, -4
		
	jr	$ra				
		
#------------------------------------------------------------------------------
# store_path procedure: luu lai vi tri TRUOC KHI DI CHUYEN
#			vi tri can luu gom : toa do x, y va huong di chuyen z
# param[in]     none
# remark	thay doi path, length_path
#------------------------------------------------------------------------------		
store_path:
	# backup
	addi	$sp, $sp, 4
	sw	$t1, 0($sp)
	addi	$sp, $sp, 4
	sw	$t2, 0($sp)
	addi	$sp, $sp, 4
	sw	$t3, 0($sp)
	addi	$sp, $sp, 4
	sw	$t4, 0($sp)
	addi	$sp, $sp, 4
	sw	$t5, 0($sp)
	addi	$sp, $sp, 4
	sw	$s4, 0($sp)					
	
	li	$t1, WHEREX
	lw	$t1, 0($t1)		# $t1 = x
	li	$t2, WHEREY
	lw	$t2, 0($t2)		# $t2 = y
	la	$t3, now_heading
	lw	$t3, 0($t3)		# $t3 = now heading
	
	la	$s4, length_path
	lw	$t4, 0($s4)		# $t4 = length path (bytes)
	
	la	$t5, path
	add	$t5, $t5, $t4		# position to store new point
	
	sw	$t1, 0($t5)		# store x
	sw	$t2, 4($t5)		# store y
	sw	$t3, 8($t5)		# store z = now heading
	
	addi	$t4, $t4, 12		# 3 word (x, y, z) = 3 * 4 = 12 bytes
	sw	$t4, 0($s4)		# update length path
	
	# restore
	lw	$s4, 0($sp)
	addi	$sp, $sp, -4
	lw	$t5, 0($sp)
	addi	$sp, $sp, -4
	lw	$t4, 0($sp)
	addi	$sp, $sp, -4		
	lw	$t3, 0($sp)
	addi	$sp, $sp, -4
	lw	$t2, 0($sp)
	addi	$sp, $sp, -4
	lw	$t1, 0($sp)
	addi	$sp, $sp, -4
		
	jr	$ra

		
#-----------------------------------------------------------
# GO procedure, to start running
# param[in]    none
#-----------------------------------------------------------
GO:     
	# backup
	addi	$sp, $sp, 4
	sw	$at, 0($sp)
	addi	$sp, $sp, 4
	sw	$k0, 0($sp)
		
	li	$at, MOVING     # change MOVING port
	addi  	$k0, $zero,1    # to  logic 1,
	sb    	$k0, 0($at)     # to start running

	# restore
	lw	$k0, 0($sp)
	addi	$sp, $sp, -4
	lw	$at, 0($sp)
	addi	$sp, $sp, -4
	
	jr    	$ra


#-----------------------------------------------------------
# GO_BACK procedure: quay ve voi lo trinh nguoc lai
# param[in]     none
# remark	se thay doi lenght_path (vi quay lai len 
#		se xoa nhung vi tri da luu trong path
#		-> length path = 0)
#-----------------------------------------------------------
GO_BACK:
	# backup
	addi	$sp, $sp, 4
	sw	$t0, 0($sp)
	addi	$sp, $sp, 4
	sw	$t1, 0($sp)	
	addi	$sp, $sp, 4
	sw	$t2, 0($sp)
	addi	$sp, $sp, 4
	sw	$t3, 0($sp)
	addi	$sp, $sp, 4
	sw	$t4, 0($sp)
	addi	$sp, $sp, 4
	sw	$t5, 0($sp)
	addi	$sp, $sp, 4
	sw	$a0, 0($sp)
	addi	$sp, $sp, 4
	sw	$s1, 0($sp)
	addi	$sp, $sp, 4
	sw	$s2, 0($sp)
	addi	$sp, $sp, 4
	sw	$ra, 0($sp)
	
	la	$s1, path
	la	$s2, length_path
	lw	$t2, 0($s2)		# $t2 = length path
	
	jal	UNTRACK			# di nguoc lai thi khong de lai dau vet
	
	addi	$t2, $t2, -12		# day giong nhu index de xac dinh 1 struct trong
					# mang path luu tru list struct dang {x, y, z}
	loop_to_go_back:
		slt	$t0, $t2, $zero
		bnez	$t0, end_loop_to_go_back
		
		add	$t0, $s1, $t2		# position to load last point
		lw	$t3, 0($t0)		# $t3 = x
		lw	$t4, 4($t0)		# $t4 = y
		lw	$t5, 8($t0)		# $t5 = z
				
		addi	$t0, $zero, 360
		addi	$a0, $t5, 180		# $a0 = z + 180
		div	$a0, $t0		#
		mfhi	$a0			# $a0 = $a0 % 360 = (z + 180) % 360
						# suy ra $a0 la huong nghich dao	
		
		la	$t1, now_heading
		sw	$a0, 0($t1)		# update now_heading
				
		jal	ROTATE				 		
		jal	GO			# xac dinh xong huong -> di chuyen marsbot
		
		# dung vong lap de tim diem dung
		# dua vao x, y cua marsbot roi so sanh voi diem luu trong path
		loop_to_find_stop_point:
			li	$t0, WHEREX
			lw	$t0, 0($t0)	# $t0 = x
			li	$t1, WHEREY	
			lw	$t1, 0($t1)	# $t1 = y
						
			bne	$t0, $t3, loop_to_find_stop_point
			nop
			bne	$t1, $t4, loop_to_find_stop_point
			nop
		
	continue_loop_to_go_back:				
		jal	STOP			# toi day la da tim thay diem dung -> stop marsbot
		addi	$t2, $t2, -12		# vi duyet tu diem cuoi trong path toi diem dau
						# nen can -12 bytes cho 3 words (x, y, z)
		j	loop_to_go_back
		
	end_loop_to_go_back:
		addi	$t2, $zero, 0
		sw	$t2, 0($s2)		# update length path to 0
			
	# restore
	lw	$ra, 0($sp)
	addi	$sp, $sp, -4		
	lw	$s2, 0($sp)
	addi	$sp, $sp, -4
	lw	$s1, 0($sp)
	addi	$sp, $sp, -4		
	lw	$a0, 0($sp)
	addi	$sp, $sp, -4
	lw	$t5, 0($sp)
	addi	$sp, $sp, -4		
	lw	$t4, 0($sp)
	addi	$sp, $sp, -4
	lw	$t3, 0($sp)
	addi	$sp, $sp, -4
	lw	$t2, 0($sp)
	addi	$sp, $sp, -4		
	lw	$t1, 0($sp)
	addi	$sp, $sp, -4
	lw	$t0, 0($sp)
	addi	$sp, $sp, -4
	
	jr	$ra
						
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in]    none
#-----------------------------------------------------------
STOP:   
	# backup
	addi	$sp, $sp, 4
	sw	$at, 0($sp)
	
	li	$at, MOVING     # change MOVING port to 0
	sb  	$zero, 0($at)   # to stop

	# restore
	lw	$at, 0($sp)
	addi	$sp, $sp, -4
			
	jr    $ra						

#-----------------------------------------------------------
# TRACK procedure, to start drawing line 
# param[in]    none
#-----------------------------------------------------------
TRACK:  
	# backup
	addi	$sp, $sp, 4
	sw	$at, 0($sp)
	addi	$sp, $sp, 4
	sw	$k0, 0($sp)
	
	li    	$at, LEAVETRACK # change LEAVETRACK port
	addi  	$k0, $zero,1    # to  logic 1,
	sb    	$k0, 0($at)     # to start tracking

	# restore
	lw	$k0, 0($sp)
	addi	$sp, $sp, -4
	lw	$at, 0($sp)
	addi	$sp, $sp, -4
			
	jr    $ra
	
#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in]    none
#-----------------------------------------------------------
UNTRACK:
	# backup
	addi	$sp, $sp, 4
	sw	$at, 0($sp)
	
	li   	$at, LEAVETRACK # change LEAVETRACK port to 0
	sb    	$zero, 0($at)   # to stop drawing tail
	
	# restore
	lw	$at, 0($sp)
	addi	$sp, $sp, -4
		
	jr    $ra
	
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in]    $a0, An angle between 0 and 359
#                   0 : North (up)			
#                   90: East  (right)
#                  180: South (down)
#                  270: West  (left)
#-----------------------------------------------------------
ROTATE: 
	# backup
	addi	$sp, $sp, 4
	sw	$at, 0($sp)
	
	li    	$at, HEADING    # change HEADING port
	sw    	$a0, 0($at)     # to rotate robot
	
	# restore
	lw	$at, 0($sp)
	addi	$sp, $sp, -4
		
	jr    $ra																																												


# --------------------------------------------------------------------------------------
# GENERAL INTERRUPT SERVED ROUTINE for all interrupts 
# --------------------------------------------------------------------------------------
.ktext	0x80000180

	backup:
		addi	$sp, $sp, 4
		sw	$at, 0($sp)		
		addi	$sp, $sp, 4
		sw	$t1, 0($sp)
		addi	$sp, $sp, 4
		sw	$t2, 0($sp)				
		addi	$sp, $sp, 4
		sw	$t3, 0($sp)		
		addi	$sp, $sp, 4
		sw	$a0, 0($sp)
		addi	$sp, $sp, 4
		sw	$s1, 0($sp)
		addi	$sp, $sp, 4
		sw	$s2, 0($sp)					
									
	get_code:
		li	$t1, IN_ADDRESS_HEXA_KEYBOARD
		li	$t2, OUT_ADDRESS_HEXA_KEYBOARD

	scan:
		li	$t3, 0x81			# check row 1 with key 0, 1, 2, 3
		sb	$t3, 0($t1)
		lb	$a0, 0($t2)			# read scan code of key button and store to $a0
		bnez	$a0, store_code			# if $a0 != 0 -> jump current_code
		nop

		li	$t3, 0x82			# check row 2 with key 4, 5, 6, 7
		sb	$t3, 0($t1)
		lb	$a0, 0($t2)
		bnez	$a0, store_code
		nop
		
		li	$t3, 0x84			# check row 3 with key 8, 9, A, B
		sb	$t3, 0($t1)
		lb	$a0, 0($t2)
		bnez	$a0, store_code
		nop
		
		li	$t3, 0x88			# check row 4 with key C, D, E, F
		sb	$t3, 0($t1)
		lb	$a0, 0($t2)
		bnez	$a0, store_code
		nop
	
	# ham store_code:
	#	- chuyen code of key button sang ky tu ascii tuong ung
	#	- sau do luu ky tu do vao mang ky tu (chuoi) current_code
	#																										
	store_code:
		# convert code to char
		case_key_0:
			bne	$a0, KEY_0, case_key_1
			li	$a0, '0'
			j	done_convert
		case_key_1:
			bne	$a0, KEY_1, case_key_2
			li	$a0, '1'
			j	done_convert
		case_key_2:
			bne	$a0, KEY_2, case_key_3
			li	$a0, '2'
			j	done_convert
		case_key_3:
			bne	$a0, KEY_3, case_key_4
			li	$a0, '3'
			j	done_convert									
		case_key_4:
			bne	$a0, KEY_4, case_key_5
			li	$a0, '4'
			j	done_convert
		case_key_5:
			bne	$a0, KEY_5, case_key_6
			li	$a0, '5'
			j	done_convert
		case_key_6:
			bne	$a0, KEY_6, case_key_7
			li	$a0, '6'
			j	done_convert
		case_key_7:
			bne	$a0, KEY_7, case_key_8
			li	$a0, '7'
			j	done_convert
		case_key_8:
			bne	$a0, KEY_8, case_key_9
			li	$a0, '8'
			j	done_convert
		case_key_9:
			bne	$a0, KEY_9, case_key_a
			li	$a0, '9'
			j	done_convert
		case_key_a:
			bne	$a0, KEY_a, case_key_b
			li	$a0, 'a'
			j	done_convert
		case_key_b:
			bne	$a0, KEY_b, case_key_c
			li	$a0, 'b'
			j	done_convert									
		case_key_c:
			bne	$a0, KEY_c, case_key_d
			li	$a0, 'c'
			j	done_convert
		case_key_d:
			bne	$a0, KEY_d, case_key_e
			li	$a0, 'd'
			j	done_convert
		case_key_e:
			bne	$a0, KEY_e, case_key_f
			li	$a0, 'e'
			j	done_convert
		case_key_f:
			bne	$a0, KEY_f, case_default
			li	$a0, 'f'
			j	done_convert		
		case_default:					# truong hop nay gan nhu ko xay ra
		done_convert:
			la	$s1, current_code
			la	$s2, length_of_current_code
			lw	$t2, 0($s2)			# $t2 = length of current code
		
			add	$s1, $s1, $t2			# $s1 = current_code + length_of_current_code
			sb	$a0, 0($s1)			# current_code[length_of..] = $a0
		
			addi	$s1, $s1, 1
			addi	$t1, $zero, '\0'
			sb	$t1, 0($s1)			# current_code[length_of.. + 1] = '\0'		
		
			addi	$t2, $t2, 1			# length_of_current_code += 1
			sw	$t2, 0($s2)			# update length_of_current_code 
																															
	next_pc:
		mfc0    $at, $14        # $at <=  Coproc0.$14 = Coproc0.epc 
		addi    $at, $at, 4     # $at = $at + 4   (next instruction) 
		mtc0    $at, $14        # Coproc0.$14 = Coproc0.epc <= $a
			
	restore:
		lw	$s2, 0($sp)
		addi	$sp, $sp, -4
		lw	$s1, 0($sp)
		addi	$sp, $sp, -4
		lw	$a0, 0($sp)
		addi	$sp, $sp, -4					
		lw	$t3, 0($sp)
		addi	$sp, $sp, -4
		lw	$t2, 0($sp)
		addi	$sp, $sp, -4
		lw	$t1, 0($sp)
		addi	$sp, $sp, -4
		lw	$at, 0($sp)
		addi	$sp, $sp, -4

	return:	eret
		
		
		
		
		
		
		
		
		
		
