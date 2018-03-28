#CMPUT 229 Student Submission License (Version 1.1)

#Copyright 2018 Tatenda Chivasa

#Unauthorized redistribution is forbidden in all circumstances. Use of this software without explicit authorization from the author or CMPUT 229 Teaching Staff is prohibited.

#This software was produced as a solution for an assignment in the course CMPUT 229 (Computer Organization and Architecture I) at the University of Alberta, Canada. This solution is #confidential and remains confidential after it is submitted for grading. The course staff has the right to run plagiarism-detection tools on any code developed under this license, #even beyond the duration of the course.

#Copying any part of this solution without including this copyright notice is illegal.

#If any portion of this software is included in a solution submitted for grading at an educational institution, the submitter will be subject to the sanctions for plagiarism at that #institution.

#This software cannot be publicly posted under any circumstances, whether by the original student or by a third party. If this software is found in any public website or public #repository, the person finding it is kindly requested to immediately report, including the URL or other repository locating information, to the following email address: #cmput229@ualberta.ca.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF #MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, #EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER #CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF #ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#---------------------------------------------------------------
# Assignment:           4
# Due Date:             March 28, 2018
# Name:                 Tatenda Chivasa
# Unix ID:              chivasa
# Lecture Section:      B1
# Instructor:           Karim Ali
# Lab Section:          H03 (Wednesday 1400 - 1700)
# Teaching Assistant:   Samuel Suraj Bushi
#---------------------------------------------------------------

#---------------------------------------------------------------
#This program implements a countdown timer in MIPS assembly, that 
#reads in a time in seconds, counts down that time to zero, and then quits Without using any reading or printing syscalls, the timer must do all of the following:
#Upon starting the timer displays Seconds= on screen.
#it allows the user to enter digits, showing them on the screen.
#When the user presses enter it move to a new line and begins 
#displaying the countdown timer with the following format: mm:ss. 
#The timer is updated in-place
#When q is pressed, or when the timer reaches 00:00the program ends
#For all other key presses, do nothing.
#
# Register Usage:
#
#       $v0: is used for pring of values
#
#	$a0: is used to pass values for printing
#
#       $s0: is where the user input is saved
#	$s1: is where the  remainder saved
#	$s2: is where the quotient is saved
#	$s3: conatins the flag for printing after one second has passed
#
#	$t0: contains the status register to enable bits/ contains the remainder of the separating division 
#	$t1: contains the value used to set register 11 and the value 60 for seconds division
#	$t2: is used to set the keyboard control register to enable keyboard interupts
#	$t3: contains the value of the data display register used for polling
#	$t4: contains the value of the immediate used to loop over the backspace function
#	$t5: contains the the keyboard data register / contains the ascii character for backspace
#
#	$t6: the immmediate value for division by sixty
#	$t7: contains the remainder of the seconds has been divided by sixty
#	$t8: contains the immmediate value for further division of time
#	$t9: contains the bytes to be loaded to the data display in order to print
#       
#	$k0: is used to return from the exception handler
#	$k1: contains the cause register into a temporary register to check for exception
#
#--------------------------------------------------------------- 
.data
	prompt: .asciiz "Seconds="
	save0:     .word 0
	sav1:       .word 0
	colon:  .asciiz ":"
	print:  .word 0x0000000


.text
.globl __start
__start:
	
	sw    $s0 save0                #storing the value of s0
       
	li    $v0 4
	la    $a0 prompt               #printing the prompt to the screen 
	syscall

	li    $v0 5                    #getting the user input          
	syscall

	move $s0 $v0                   #putiing the user input in $s0

	mfc0  $t0 $12                  #moving the status register into t0
	ori   $t0 $t0 0x1              #setting bit zero (IE) in status register to 1 to enable interrupts
	
	ori   $t0 $t0 0x8000           #setting bit fifteen in the status register
	ori   $t0 $t0 0x0800           #setting bit 11 to one iin the status register
	mtc0  $t0 $12                  #replacing old status register with new one with the bits set

	lw   $t2 0xffff0000            #loading the keyboard control register  
	ori  $t2 $t2 0x00000002        #setting the keyboard interrupt bit
	sw   $t2 0xffff0000            #returning the value with the set bit
	
	mfc0 $t1 $11                   #moving the timer compare into t1
	li   $t1 100                   #moving the value of the seconds entered by the user into v
        mtc0 $t1 $11                   #returning the register with the new value 
	add  $t7 $zero $zero           #clearing the timer register to zero to restart incrementation 
	mtc0 $t7 $9                    #returning the register to the coprocessor

	li   $t1 60                    #putting the value 60 into t1
	div  $s0 $t1                   #dividing the given value by the use by 60
	mfhi $s1                       #checking if there is a remainder from the division0
	mflo $s2                       #putting the value of the minutes into s2

	addi $s3 $zero 1               #setting a flag to check for seconds
	
check:
	beq  $s3 $zero check	       #checking if the flag is set

	addi  $t4  $zero 5	       #setting the number of places for the backspace character
	jal backspace		       #goes to the function that erases characters

	move $a0, $s2		       # stores minute value in $a0
	sw    $ra,sav1		       # stores $ra in $s3	
	
	
	jal getcharacter	       # calls function to print minute

	la $a0, colon		       # loads colon address in $a0
	jal setcolon     	       # calls function to print colon

	move $a0, $s1		       # stores second value in $a0
	jal getcharacter	       # calls function to print second
	beq $s0 $zero leave            #if the timer ends exit the program

	lw   $ra sav1		       #restoring the value of ra
	add $s3 $zero $zero	       #setting the falg back to zero for next time
	j  check		       #looping back to keep printing the characters


getcharacter:
	addi $t8, $zero, 10            #putting 10 into t8
	div $a0, $t8                   # dividing the in a0 (seconds 0r minute)to get individual digits
	mfhi $t0                       #putting the remainder in the register t0
	mflo $t7		       #putting the quotient in the register t7
	la $a0, print
	
	addi $t7, $t7, 48              #converting the value of quotient, minutes  to ascii value 
	addi $t0, $t0, 48              #converting the value of the remainder (Seconds) to ascii   
	sb $t7, 0($a0)		       #loading the values of the minutes to the byte to be printed
	sb $t0, 1($a0)		       #loading the values of the seconds to be printed

printing:

	lb $t9, 0($a0)                 #checking the value to be printed
	beqz $t9, exit		       #if the value is zero then go to exit

poll:
	lw $t3, 0xffff0008             #loading the value of the data display register  
	andi $t3, $t3, 0x01            #checking bit zero of the data display register
	beqz $t3, poll                 #polling to check if the register is ready
	sw $t9, 0xffff000c             #storing the value to be displayed to the data rdisplay register 
	addi $a0, $a0, 1               #incresing the byte by one to print other characters
	j printing	               #jumping back to print the next values

exit:
	jr $ra			       #exiting the function

setcolon:
	lb $t9, 0($a0)                 #loading the colon into register t9
	lw $t3, 0xffff0008             #loading the value of the data display register  
	andi $t3, $t3, 0x01            #checking bit zero of the data display register
	beqz $t3, poll                 #if display register isnt ready poll until it is
	sw $t9, 0xffff000c             #loading the colon to be printed
	addi $a0, $a0, 1               #incresing the byte by one to print other characters 
	jr $ra                         #jumping back to print the next values

			
backspace:
	lw $t3, 0xffff0008             #loading the value of the data display register
	andi $t3, $t3, 0x01            #checking bit zero of the data display register
	beqz $t3, backspace            #if display register isnt ready loop around until it is
	addi  $t5 $zero 8              #loading the backspace character
	sw  $t5 0xffff000c             #loading the back space character to the display rtegister so it can be printed
	addi $t4 $t4 -1                #decrementing the value in t4 to keep erasing
	bne $t4 $zero backspace        #checking if the backspace is equal zero
	jr $ra                         #jumping back to print the next values
leave:
	li $v0 10                      #exiting the program
	syscall

			

.kdata
	save3: .word 0
	saveat: .word 0
	save2: .word 0
		
.ktext 0x80000180
	  .set noat
	sw  $at saveat                 #storing at into k1
	   .set at
	
	sw    $t5 save3              #storing the value of v0

	mfc0 $k1 $13                   #getting the cause register into a temporary register to check for exception
	andi $k1 $k1 0x8000            #getting the value for bit 15 to check if its keyboard interrupt
	beq  $k1 $zero iskeyboard      #if the bit is zero then a timer interrupt occurred


	addi $s3 $zero 1	
	addi $s0 $s0 -1                #decrementing the number of seconds by the user
	li   $k1 60                    #putting the value 60 into t6
	div  $s0 $t1                   #dividing the given value by the use by 60
	mfhi $s1                       #checking if there is a remainder from the division0
	mflo $s2                       #putting the value of the minutes into s2

	
	add  $k1 $zero $zero           #clearing the timer register to zero to restart incrementation 
	mtc0 $k1 $9                    #returning the register to the coprocessor
	bgez $s0 done                  #if not yet zero continue running

	li $v0 10                      #exiting the program
	syscall

iskeyboard:
	lw   $t5 0xffff0004            #loading the keyboard data register into t5
	li   $k1 113                   #loading the ascii code for q into t6
	bne  $t5 $k1 done              #if it is equal q then raise an exception

	li $v0 10                      #exiting the program
	syscall


				       #returning from the exception 
done:
	mtc0  $zero $13                #moving the cause register into t1
	mfc0  $k0 $12                  #moving the status register into t0
	ori   $k0 $k0 0x1              #setting bit zero (IE) in status register to 1 to enable interrupts
	ori   $k0 $k0 0x8000           #setting bit fifteen in the status register
	ori   $k0 $k0 0x0800           #setting bit 11 to one iin the status register
        andi  $k0 $k0 0xfffd           #clearing the EXL bit to zero but preserving the values of the other bits using 13 as a mask in order to enable future exceptions
	mtc0  $k0 $12                  #move updated Status register to coprocessor
	
	lw    $t5 save3                #Restore $v0

	.set noat
	lw  $at saveat                  #Restore $at
	.set at
	eret                           #Return to EPC



