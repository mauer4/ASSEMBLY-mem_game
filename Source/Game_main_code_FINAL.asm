	;************************************************************************************************;
; This is the main program file which will be usd for our demonstration for Project 1 of ELEC 291;
; There are other files which must be included in the same driectory for this to run properly.   ;
;************************************************************************************************;
;	Project Name: The animal sounds memory game (Working Title)									 ;
;	Project Members:  Nicholas Chan, Adin Mauer, Ore ?										 ;
;	Date: February 18, 2022																		 ;
;************************************************************************************************;

$NOLIST
$MODLP51
$LIST

;---------------------------------------------------------------------------
;--------------------CONSTANTS----------------------------------------------

;Audio constants:

; Commands supported by the SPI flash memory according to the datasheet
WRITE_ENABLE     EQU 0x06  ; Address:0 Dummy:0 Num:0
WRITE_DISABLE    EQU 0x04  ; Address:0 Dummy:0 Num:0
READ_STATUS      EQU 0x05  ; Address:0 Dummy:0 Num:1 to infinite
READ_BYTES       EQU 0x03  ; Address:3 Dummy:0 Num:1 to infinite
READ_SILICON_ID  EQU 0xab  ; Address:0 Dummy:3 Num:1 to infinite
FAST_READ        EQU 0x0b  ; Address:3 Dummy:1 Num:1 to infinite
WRITE_STATUS     EQU 0x01  ; Address:0 Dummy:0 Num:1
WRITE_BYTES      EQU 0x02  ; Address:3 Dummy:0 Num:1 to 256
ERASE_ALL        EQU 0xc7  ; Address:0 Dummy:0 Num:0
ERASE_BLOCK      EQU 0xd8  ; Address:3 Dummy:0 Num:0
READ_DEVICE_ID   EQU 0x9f  ; Address:0 Dummy:2 Num:1 to infinite


;audio addresses and lenghts
; Sound1: COW Sound2: SHEEP Sound3: FROG Sound4: ANOTHE ONE
; values extracted from myindex.c - created by Computer_sender.c
; starting adresses
SOUND1_START_a    equ 0x00
SOUND1_START_b    equ 0x00
SOUND1_START_c    equ 0x2b
SOUND2_START_a    equ 0x01
SOUND2_START_b    equ 0x5b
SOUND2_START_c    equ 0xb0
SOUND3_START_a    equ 0x02
SOUND3_START_b    equ 0x05
SOUND3_START_c    equ 0x1c
SOUND4_START_a    equ 0x02
SOUND4_START_b    equ 0x9e
SOUND4_START_c    equ 0xb9

; difference between start and end address
SOUND1_LENGTH_a    equ 0x00
SOUND1_LENGTH_b    equ 0xb0
SOUND1_LENGTH_c    equ 0x91
SOUND2_LENGTH_a    equ 0x00 
SOUND2_LENGTH_b    equ 0x84
SOUND2_LENGTH_c    equ 0x3c
SOUND3_LENGTH_a    equ 0x00
SOUND3_LENGTH_b    equ 0x99
SOUND3_LENGTH_c    equ 0x9d
SOUND4_LENGTH_a    equ 0x00
SOUND4_LENGTH_b    equ 0xdf
SOUND4_LENGTH_c    equ 0x61







;frequency constants:
CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))

;Audio constants
TIMER1_RATE    EQU 22050     ; 22050Hz is the sampling rate of the wav file we are playing
TIMER1_RELOAD  EQU 0x10000-(CLK/TIMER1_RATE)
BAUDRATE       EQU 115200
BRG_VAL        EQU (0x100-(CLK/(16*BAUDRATE)))

;game constants
Max_seconds equ 5 ; this is the number os seconds until overtime is set

;---------------------------------------------------------------------------

;Reset Vector
ORG 0x0000
ljmp OurProgram

;Timer 0 Overflow interrupt vector
ORG 0x0003 ; Originally changed from 0x000B i don't think it'll make a big difference
    ljmp Timer0_ISR

; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

; External interrupt 1 vector (not used in this code)
org 0x0013
	reti

; Timer/Counter 1 overflow interrupt vector (not used in this code)
org 0x001B
    ljmp Timer1_ISR

; Serial port receive/transmit interrupt vector (not used in this code)
org 0x0023 
	reti
	
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR
;----------------------------------------------------------------------------


;*-*-VARIABLES-*-*;
; Our flags (1 bit values either 0 or 1; use clr and setb)
; BSEG is the absolute segment in the BIT space
BSEG
mf: dbit 1
;hdetect: dbit 1 ; this bit will be set on every touch of the sensor
; 0 - wrong 1- right
; Sensor pressed bits



;DSEG is the absolute segment in the data space
DSEG at 30H
x:			ds 4		;Our x register for math
y:			ds 4		;Our y register for math
z:          ds 4
w:          ds 4        ; 24-bit play counter.  Decremented in Timer 1 ISR.
bcd:			ds 5		; Might use but for LCD displaying


; random variables
seed:       ds 4
rand:       ds 16

; gameplay variables
score:		    ds 1	;Total completed rounds of the player
level:          ds 1    ;The current level (resets every game over)
round:		    ds 1	;The current round of the level (resets @ beginning of every level)
temp_round:     ds 1    ; round + 1
;button_pressed: ds 1    ; 00 - sensor 1 / 01 - sensor 2 / 10 - sensor 3 / 11 - sensor 4     
button_pressed: ds 1    ; 00 - button 1 / 01 - button 2 / 10 - button 3 / 11 - button 4     


average:  ds 1    ;Value which stores values into the reading values
sensor:   ds 1    ;Picks which sensor we are measuring from
reading1:	ds 4		;Stores measure period value from the first measurement
reading2: ds 4		;Stores measured period value from the second measurement


; sound address variables
Sound1_start: ds 3
Sound2_start: ds 3
Sound3_start: ds 3
Sound4_start: ds 4 
; Sound_Length_Variales 
Sound_Length1: ds 3
Sound_Length2: ds 3
Sound_Length3: ds 3
Sound_Length4: ds 3




$NOLIST
$include(math32.inc)
$LIST

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST


; Absolute values in the code space -- code fragments
CSEG
; These 'equ' must match the hardware wiring -- Should be the same as all previous labs
LCD_RS equ P3.2
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

; Audio and Flash drive outputs
SPEAKER  EQU P2.6 ; Used with a MOSFET to turn off speaker when not in use

; The pins used for SPI
FLASH_CE  EQU  P2.5
MY_MOSI   EQU  P2.4 
MY_MISO   EQU  P2.1
MY_SCLK   EQU  P2.0 

;sensor input pins
;Sensor1 equ P1.0
;Sensor2 equ P1.1
;Sensor3 equ P1.2
;Sensor4 equ P1.3

;button input pins
BUTTON1 equ P1.0
BUTTON2 equ P1.1
BUTTON3 equ P1.2
BUTTON4 equ P1.3

;start button 
START_GAME equ P4.5
; for testing
START_LEVEL equ P1.0
START_ROUND equ P1.1


No_Signal_Str:    db 'No signal      ', 0
Welcome:          db 'Press to start ', 0
Level_message:    db 'level:    ',      0
Round_message:    db 'round:    ',      0
Game_Over_Message:db 'Game over      ', 0
You_Win_message:  db 'YOU WIN!       ', 0
Good_try:         db 'Good try       ', 0
Overtime_message: db 'overtime       ', 0
correct:          db 'CORRECT!  ',      0
Listen:           db    'Listen         ',0
Carefully:        db    'carefully      ',0
Go_to:            db    'Go to     ',     0
Start_level_message: db 'Start level!  ',0 
Start_round_message: db 'Start Round!  ',0
Press:            db 'Press!    ',       0
Check_if_message: db 'Check if  ',       0
error_message:    db 'ERROR!',           0    
empty_message:    db '                ', 0
;---------------------------------------------------------------------------------
;-------------------------ISR'S---------------------------------------------------

Timer0_ISR:
    reti

Timer2_ISR:
    reti

InitializeTimer0:
MOV TCON, #0
MOV TH0, #0
MOV TL0, #0
ret

Read1:
CLR		TR0       ; Stop timer 2
MOV		TL0, #0
MOV		TH0, #0
CLR		TF0
SETB	TR0

synch1a:
JB	TF0, oh_no1 ; If the timer overflows, we assume there is no signal
JB	P1.0, synch1a ; If the pulse isn't synced this will loop again
synch1b:    
JB	TF2, oh_no1
JNB	P1.0, synch1b
SJMP	measure1a    

oh_no1:
LJMP	no_signal_detected
	
;Measuring one pulse and how long it took
measure1a: 
JB	TF0, oh_no1
JB	P1.0, measure1a


measure1b:
JB	TF0, oh_no1
JNB	P1.0, measure1b
CLR	TR0		;Stopping timer 0

LJMP calculate

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
Read2:
CLR		TR0       ; Stop timer 2
MOV		TL0, #0
MOV		TH0, #0
CLR		TF0
SETB	TR0

synch2a:
JB	TF0, oh_no2 ; If the timer overflows, we assume there is no signal
JB	P1.1, synch2a ; If the pulse isn't synced this will loop again
synch2b:    
JB	TF2, oh_no2
JNB	P1.1, synch2b
SJMP	measure2a    

oh_no2:
LJMP	no_signal_detected
	
;Measuring one pulse and how long it took
measure2a: 
JB	TF0, oh_no2
JB	P1.1, measure2a

measure2b:
JB	TF0, oh_no2
JNB	P1.1, measure2b
CLR	TR0		;Stopping timer 0

LJMP calculate
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
Read3:
CLR		TR0       ; Stop timer 2
MOV		TL0, #0
MOV		TH0, #0
CLR		TF0
SETB	TR0

synch3a:
JB	TF0, oh_no3 ; If the timer overflows, we assume there is no signal
JB	P1.2, synch3a ; If the pulse isn't synced this will loop again
synch3b:    
JB	TF2, oh_no3
JNB	P1.2, synch3b
SJMP	measure3a    

oh_no3:
LJMP	no_signal_detected
	
;Measuring one pulse and how long it took
measure3a: 
JB	TF0, oh_no3
JB	P1.2, measure3a

measure3b:
JB	TF0, oh_no3
JNB	P1.2, measure3b
CLR	TR0		;Stopping timer 0

LJMP calculate
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
Read4:
CLR		TR0       ; Stop timer 2
MOV		TL0, #0
MOV		TH0, #0
CLR		TF0
SETB	TR0

synch4a:
JB	TF0, oh_no4 ; If the timer overflows, we assume there is no signal
JB	P1.3, synch4a ; If the pulse isn't synced this will loop again
synch4b:    
JB	TF2, oh_no4
JNB	P1.3, synch4b
SJMP	measure4a    

oh_no4:
LJMP	no_signal_detected
	
;Measuring one pulse and how long it took
measure4a: 
JB	TF0, oh_no4
JB	P1.3, measure4a

measure4b:
JB	TF0, oh_no4
JNB	P1.3, measure4b
CLR	TR0		;Stopping timer 0

LJMP calculate
;-----------------------------------------------------------------------------

oh_zero:
LJMP no_signal_detected


;Converting the timer value stored in the TH/TL registers into some time
calculate:
MOV	x+0, TL0
MOV	x+1, TH0
MOV	x+2, #0
MOV	x+3, #0
;Making sure the value isn't zero;
MOV	a, TL0
MOV	a, TH0
JZ	oh_zero

;Doing the actual math
Load_y(45211)       ;represents one clock pulse of 45.21123 nanoseconds
LCALL	mul32		;multiply the value stored in x by this value y

Load_y(1000)
LCALL	div32		;divide the value stored in x by 1000 to restore the scaling we did earlier, this is our period.

MOV	a, average
CJNE	a, #0x03, storesecond
MOV	reading1, x
MOV	average, #0x02
Wait_Milli_Seconds(#20)
LJMP	main_detection_loop

storesecond:
MOV	a, average
CJNE	a, #0x02, storethird
MOV	reading2, x
MOV	average, #0x01
Wait_Milli_Seconds(#20)
LJMP	main_detection_loop

storethird:
MOV	a, average
MOV 	average, #0x03
Load_y(reading1)
LCALL	add32
Load_y(reading2)
LCALL	add32
Load_y(3)
LCALL	div32

;Prints out the averaged value
MOV		a, sensor
CJNE	a, #0x01, thresholdnot1
Load_y(600000)		;This value determines the threshhold where we can detect a change or no change in 
LCALL   div32
LJMP	detected

thresholdnot1:
MOV		a, sensor
CJNE	a, #0x02, thresholdnot2
Load_y(600000)		;This value determines the threshhold where we can detect a change or no change in 
LCALL   div32
LJMP	detected

thresholdnot2:
MOV		a, sensor
CJNE	a, #0x03, thresholdnot3
Load_y(630000)		;This value determines the threshhold where we can detect a change or no change in 
LCALL   div32
LJMP	detected

thresholdnot3:
Load_y(570000)		;This value determines the threshhold where we can detect a change or no change in 
LCALL   div32
LJMP	detected

detected:
MOV     a, x
CJNE	a, #0, Touch_Detected
LJMP	no_signal_detected

Touch_Detected:
MOV   a, sensor
CJNE  a, #0x04, flagnot4
MOV	  button_pressed, #0x03
Set_Cursor(2,14)
WriteData(#'x')
clr TR0
pop psw
pop acc
ret 
LJMP  exitdetection

flagnot4:
CJNE  a, #0x03, flagnot3
MOV		button_pressed, #0x02
Set_Cursor(2,14)
WriteData(#'y')
clr TR0
pop psw
pop acc
ret 
LJMP  exitdetection

flagnot3:
CJNE  a, #0x02, flag1
MOV		button_pressed, #0x01
clr TR0
pop psw
pop acc
ret 
;LJMP  exitdetection

flag1:
MOV 	button_pressed, #0x00
Set_Cursor(2,14)
WriteData(#'d')
clr TR0
pop psw
pop acc
ret 
LJMP exitdetection

no_signal_detected:
MOV	a, sensor
CJNE	a, #0x04, no_sensor_reset
MOV	sensor, #0x01
SJMP	back_to_sensor_loop

no_sensor_reset:
ADD	a, #0x01
MOV	sensor, a

back_to_sensor_loop:
LJMP    main_detection_loop

exitdetection:
	clr TR0
	pop psw
	pop acc
	ret 

main_detection:
push acc
push psw
setb TR0
main_detection_loop:
MOV	a, sensor
CJNE	a, #0x4, readnot4
LJMP	read4

readnot4:
CJNE	a, #0x3, readnot34
LJMP	read3

readnot34:
CJNE	a, #0x2, readnot234
LJMP	read2

readnot234:
LJMP	read1
;-------------------------------------END OF CODE FOR SENSOR DETECTION---------------------------
;------------------------------------------------------------------------------------------------

;------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------
;-------------------------------------CODE FOR BUTTON DETECTION----------------------------------



; ISR for Timer 1.  Used to playback  ;
; the WAV file stored in the SPI      ;
; flash memory.                       ;
;-------------------------------------;
Timer1_ISR:
	; The registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	; Check if the play counter is zero.  If so, stop playing sound.
	mov a, w+0
	orl a, w+1
	orl a, w+2
	jz stop_playing
	
	; Decrement play counter 'w'.  In this implementation 'w' is a 24-bit counter.
	mov a, #0xff
	dec w+0
	cjne a, w+0, keep_playing
	dec w+1
	cjne a, w+1, keep_playing
	dec w+2
	
keep_playing:
	setb SPEAKER
	lcall Send_SPI ; Read the next byte from the SPI Flash...
	add a, #0x80
	mov DADH, a ; Output to DAC. DAC output is pin P2.3
	orl DADC, #0b_0100_0000 ; Start DAC by setting GO/BSY=1
	sjmp Timer1_ISR_Done

stop_playing:
	clr TR1 ; Stop timer 1
	setb FLASH_CE  ; Disable SPI Flash
	clr SPEAKER ; Turn off speaker.  Removes hissing noise when not playing sound.
	mov DADH, #0x80 ; middle of range
	orl DADC, #0b_0100_0000 ; Start DAC by setting GO/BSY=1

Timer1_ISR_Done:	
	pop psw
	pop acc
	reti

;------------------------------------------------------------------------------       
;------------------------------------------------------------------------------
Configure_audio:
    ;initialize LCD_4bit
    ;initialize timers
    ;initialize interrupts
    ; go to initial state of game - DEFAULT

    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    ; Now we can proceed with the configuration
	
	; Enable serial communication and set up baud rate
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
	
	; Configure SPI pins and turn off speaker
	anl P2M0, #0b_1100_1110
	orl P2M1, #0b_0011_0001
	setb MY_MISO  ; Configured as input
	setb FLASH_CE ; CS=1 for SPI flash memory
	clr MY_SCLK   ; Rest state of SCLK=0
	clr SPEAKER   ; Turn off speaker.
	
	; Configure timer 1
	anl	TMOD, #0x0F ; Clear the bits of timer 1 in TMOD
	orl	TMOD, #0x10 ; Set timer 1 in 16-bit timer mode.  Don't change the bits of timer 0
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	; Set autoreload value
	mov RH1, #high(TIMER1_RELOAD)
	mov RL1, #low(TIMER1_RELOAD)

	; Enable the timer and interrupts
    setb ET1  ; Enable timer 1 interrupt
	; setb TR1 ; Timer 1 is only enabled to play stored sound

	; Configure the DAC.  The DAC output we are using is P2.3, but P2.2 is also reserved.
	mov DADI, #0b_1000_0000 ; ACON=1
	mov DADC, #0b_0011_1010 ; Enabled, DAC mode, Left adjusted, CLK/16
	mov DADH, #0x80 ; Middle of scale
	mov DADL, #0
	orl DADC, #0b_0100_0000 ; Start DAC by GO/BSY=1
check_DAC_init:
	mov a, DADC
	jb acc.6, check_DAC_init ; Wait for DAC to finish
	
	setb EA ; Enable interrupts
	ret
;--------------------------------------------------------------------------
;Initializes timer/counter 2 as a 16-bit timer
InitTimer2:
	mov T2CON, #0 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
    ret
;--------------------------------------------------------------------------
initialize_sound_variables:
    push acc
    push psw
    mov Sound_Length1+2, #SOUND1_LENGTH_a
    mov Sound_Length1+1, #SOUND1_LENGTH_b
    mov Sound_Length1+0, #SOUND1_LENGTH_c
    mov Sound_Length2+2, #SOUND2_LENGTH_a
    mov Sound_Length2+1, #SOUND2_LENGTH_b
    mov Sound_Length2+0, #SOUND2_LENGTH_c
    mov Sound_Length3+2, #SOUND3_LENGTH_a
    mov Sound_Length3+1, #SOUND3_LENGTH_b
    mov Sound_Length3+0, #SOUND3_LENGTH_c
    mov Sound_Length4+2, #SOUND4_LENGTH_a
    mov Sound_Length4+1, #SOUND4_LENGTH_b
    mov Sound_Length4+0, #SOUND4_LENGTH_c

    mov Sound1_start+2, #SOUND1_START_a    
    mov Sound1_start+1, #SOUND1_START_b    
    mov Sound1_start+0, #SOUND1_START_c    
    mov Sound2_start+2, #SOUND2_START_a    
    mov Sound2_start+1, #SOUND2_START_b    
    mov Sound2_start+0, #SOUND2_START_c    
    mov Sound3_start+2, #SOUND3_START_a    
    mov Sound3_start+1, #SOUND3_START_b    
    mov Sound3_start+0, #SOUND3_START_c    
    mov Sound4_start+2, #SOUND4_START_a    
    mov Sound4_start+1, #SOUND4_START_b    
    mov Sound4_start+0, #SOUND4_START_c    
    
    pop psw
    pop acc
    ret
;--------------------------------------------------------------------------
Play_Sound:
	push acc
	push psw
    ;based on @(level15_array+round) 
    ; set Start_Addr, Len_of_audio
    ; Play audio file - based on R7!!
    ; R7 = {0, 1, 2, 3} = play {sound1, sound2, sound3, sound4}
    ; Play the bytes in memory from 24-bit address is (R7,R6,R5)
    ; w = amount of bytes
    
	clr TR1 ; Stop Timer 1 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
	
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI

	 
    cjne R7, #0, not_sound_1
; Set the initial position in memory where to start playing
    mov a, Sound1_start+2
    lcall Send_SPI
    mov a, Sound1_start+1
    lcall Send_SPI
    mov a, Sound1_start+0
    lcall Send_SPI
    mov a, #0x00 ; Request first byte to send to DAC
    lcall Send_SPI

    mov w+2, Sound_Length1+2
    mov w+1, Sound_Length1+1
    mov w+0, Sound_Length1+0
not_sound_1:
    cjne R7, #1, not_sound_2
; Set the initial position in memory where to start playing
    mov a, Sound2_start+2
    lcall Send_SPI
    mov a, Sound2_start+1
    lcall Send_SPI
    mov a, Sound2_start+0
    lcall Send_SPI
    mov a, #0x00 ; Request first byte to send to DAC
    lcall Send_SPI

    mov w+2, Sound_Length2+2
    mov w+1, Sound_Length2+1
    mov w+0, Sound_Length2+0
not_sound_2:
    cjne R7, #2, not_sound_3
; Set the initial position in memory where to start playing
    mov a, Sound3_start+2
    lcall Send_SPI
    mov a, Sound3_start+1
    lcall Send_SPI
    mov a, Sound3_start+0
    lcall Send_SPI
    mov a, #0x00 ; Request first byte to send to DAC
    lcall Send_SPI

    mov w+2, Sound_Length3+2
    mov w+1, Sound_Length3+1
    mov w+0, Sound_Length3+0
not_sound_3:
    cjne R7, #3, not_sound_4
; Set the initial position in memory where to start playing
    mov a, Sound4_start+2
    lcall Send_SPI
    mov a, Sound4_start+1
    lcall Send_SPI
    mov a, Sound4_start+0
    lcall Send_SPI
    mov a, #0x00 ; Request first byte to send to DAC
    lcall Send_SPI

    mov w+2, Sound_Length4+2
    mov w+1, Sound_Length4+1
    mov w+0, Sound_Length4+0
not_sound_4:
    
	setb SPEAKER ; Turn on speaker.
	setb TR1 ; Start playback by enabling Timer 1
	pop psw
	pop acc
    ret

Send_SPI:
	SPIBIT MAC
	    ; Send/Receive bit %0
		rlc a
		mov MY_MOSI, c
		setb MY_SCLK
		mov c, MY_MISO
		clr MY_SCLK
		mov acc.0, c
	ENDMAC

	SPIBIT(7)
	SPIBIT(6)
	SPIBIT(5)
	SPIBIT(4)
	SPIBIT(3)
	SPIBIT(2)
	SPIBIT(1)
	SPIBIT(0)

	ret
;--------------------------------------------------------------------------
Audio_Play:
	push acc
	push psw
	clr a
loop_audio:
	mov R7, rand+0
	;play sound 1
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 1
	;skip to end of sound if in level 1
	cjne a, level, sound2
	ljmp end_audio
sound2:
	mov R7, rand+1
	; play sound 2
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 2
	;skip to end of sound if in level 2
	cjne a, level, sound3
	ljmp end_audio
sound3:
	mov R7, rand+2
	; play sound 3
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 3
	;skip to end of sound if in level 3
	cjne a, level, sound4
	ljmp end_audio
sound4:
	mov R7, rand+3
	; play sound 4
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 4
	;skip to end of sound if in level 4
	cjne a, level, sound5
	ljmp end_audio
sound5:
	mov R7, rand+4
	; play sound 5
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 5
	;skip to end of sound if in level 5
	cjne a, level, sound6
	ljmp end_audio
sound6:
	mov R7, rand+5
	; play sound 6
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 6
	;skip to end of sound if in level 6
	cjne a, level, sound7
	sjmp end_audio
sound7:
	mov R7, rand+6
	; play sound 7
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 7
	;skip to end of sound if in level 7
	cjne a, level, sound8
	sjmp end_audio
sound8:
	mov R7, rand+7
	; play sound 8
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 8
	;skip to end of sound if in level 8
	cjne a, level, sound9
	sjmp end_audio
sound9:
	mov R7, rand+8
	; play sound 9
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 9
	;skip to end of sound if in level 9
	cjne a, level, sound10
	sjmp end_audio
sound10:
	mov R7, rand+9
	; play sound 10
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 10
	;skip to end of sound if in level 10
	cjne a, level, sound11
	sjmp end_audio
sound11:
	mov R7, rand+10
	; play sound 11
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 11
	;skip to end of sound if in level 11
	cjne a, level, sound12
	sjmp end_audio
sound12:	
	mov R7, rand+11
	; play sound 12
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 12
	;skip to end of sound if in level 12
	cjne a, level, sound13
	sjmp end_audio
sound13:
	mov R7, rand+12
	; play sound 13
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 13
	;skip to end of sound if in level 13
	cjne a, level, sound14
	sjmp end_audio
sound14:
	mov R7, rand+13
	; play sound 14
	lcall Play_Sound
	jb TR1, $
	inc a
	; a = 14
	;skip to end of sound if in level 14
	cjne a, level, sound15
	sjmp end_audio
sound15:	
	mov R7, rand+14
	; play sound 15
	lcall Play_Sound
	jb TR1, $
	sjmp end_audio
end_audio:
	clr a
	pop psw
	pop acc
	ret
;-------------------------------------------------------------------------
;detect_sensor:
	;ret
;--------MAIN PROGRAM------------------------------------------------------
OurProgram:
    mov sp, #0x7f
    lcall Configure_audio
    lcall initialize_sound_variables
    lcall InitTimer2
	lcall LCD_4BIT
    ;lcall initialize_rand
	;lcall InitializeTimer0

	;SETB Sensor1
	;SETB Sensor2
	;SETB Sensor3
	;SETB Sensor4

	MOV sensor, #0x4
	MOV button_pressed, #0x5	;This is because i dont want any false positives.

	; test rand
	;---------------THIS IS JUST TEMPORARY UNTIL THE RANDOM GENERATOR-------------
	;---------------STARTS WORKING------------------------------------------------
	mov rand+0,  #0x01
	mov rand+1,  #0x00
	mov rand+2,  #0x03
	mov rand+3,  #0x02
	mov rand+4,  #0x02
	mov rand+5,  #0x00
	mov rand+6,  #0x02
	mov rand+7,  #0x01
	mov rand+8,  #0x01
	mov rand+9,  #0x03
	mov rand+10, #0x00
	mov rand+11, #0x01
	mov rand+12, #0x03
	mov rand+13, #0x02
	mov rand+14, #0x01
	;-----------------------------------------------------------------------------
forever_loop:
    Set_Cursor(1,1)
    Send_Constant_String(#Welcome)
    Set_Cursor(2,1)
    Send_Constant_String(#empty_message)
    ; any other configurations - here!
    ; Wait for START_GAME to be PRESSED
    jb START_GAME, forever_loop ; Check if push-button pressed - START_GAME
	Wait_Milli_Seconds(#100)
	jb START_GAME, $
	jnb START_GAME, $ ; Wait for push-button release
    ; set audio stuff
	
    ;lcall initialize_rand - NOT INTEGRATED YET
	; this would happen at the beginning of every game
    mov level, #0x01
	; start at level 1
    mov round, #0x00
	;mov temp_round, #0x01
	; start at round 0
    sjmp Game_play

Game_play:
	Set_Cursor(1,1)
	Send_Constant_String(#Listen)
	Set_Cursor(2,1)
	Send_Constant_String(#Carefully)
    
	lcall Audio_Play
	
	Set_Cursor(1,1)
	Send_Constant_String(#Level_message)
    Set_Cursor(1,15)
    Display_BCD(level)
    Set_Cursor(2,1)
    Send_Constant_String(#empty_message)
	
loop_for_level_button:
	ljmp press_state
after_pressed_state:
	mov round, #0x00
    Set_Cursor(2,15)
    Display_BCD(round)
	mov a, level
	;--------------------------
	; reset round to 0 and
	; check if level - 15,
	; if level - 0 = GAME OVER!
	; if level - 15 = YOU WIN!
	;--------------------------
	cjne a, #0x00, continue_gameplay
	sjmp Game_Over
continue_gameplay:
	cjne a, #(15), Go_to_next_level
	clr a
	sjmp You_win
Go_to_next_level:
	clr a
	; at the beginning of every new leve - we increment level
	inc level
	Set_Cursor(1,15)
	Display_BCD(level)
	ljmp Game_play
Game_Over:
	Set_Cursor(1,1)
	Send_Constant_String(#Game_Over_Message)
    Set_Cursor(2,1)
    Send_Constant_String(#empty_message)
Game_Over_loop:
    jb START_GAME, Game_Over_loop ; Check if push-button pressed - START_GAME
	Wait_Milli_Seconds(#100)
	jb START_GAME, $
	jnb START_GAME, $ ; Wait for push-button release
    ljmp forever_loop
You_win:
	Set_Cursor(1,1)
	Send_Constant_String(#You_Win_message)
    Set_Cursor(2,1)
    Send_Constant_String(#empty_message)
You_win_loop:
    jb START_GAME, You_win_loop ; Check if push-button pressed - START_GAME
	Wait_Milli_Seconds(#100)
	jb START_GAME, $
	jnb START_GAME, $ ; Wait for push-button release
    ljmp forever_loop
	
back_to_start_game:
    ljmp forever_loop
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
Overtime:
	;prints overtime - "GOOD TRY!"
	ljmp forever_loop




press_state:
press_state_loop:
    Wait_Milli_Seconds(#250)
    Wait_Milli_Seconds(#250)
	inc round
    Set_Cursor(2,15)
	Display_BCD(round)
	; print stuff-------------------------
	Set_Cursor(1, 1)
	Send_Constant_String(#Start_round_message)
	; print stuff-------------------------

    ; if round = level+1 - end level
    mov a, round
	mov b, level
	inc b
	cjne a, b, loop_for_round_button
    ljmp after_pressed_state
loop_for_round_button:
    lcall main_detection
    ;ljmp button_detection
return_button_detection:
    Set_Cursor(2,1)
	Send_Constant_String(#correct)
	mov a, round
	; not integrated yet
; This segment compares between the array value at array[round] to button_pressed
; if they are equal - continue until round = level
; if they are not equal - game over!
	mov R1, round
	; R1 = round
	cjne R1, #(1), round2
	mov a, rand+0
	cjne a, button_pressed, fail_level
round2:
	cjne R1, #(2), round3
	mov a, rand+1
	cjne a, button_pressed, fail_level
round3:
	cjne R1, #(3), round4
	mov a, rand+2
	cjne a, button_pressed, fail_level
round4:
	cjne R1, #(4), round5
	mov a, rand+3
	cjne a, button_pressed, fail_level
round5:
	cjne R1, #(5), round6
	mov a, rand+4
	cjne a, button_pressed, fail_level
round6:
	cjne R1, #(6), round7
	mov a, rand+5
	cjne a, button_pressed, fail_level
round7:
	cjne R1, #(7), round8
	mov a, rand+6
	cjne a, button_pressed, fail_level
round8:
	cjne R1, #(8), round9
	mov a, rand+7
	cjne a, button_pressed, fail_level
round9:
	cjne R1, #(9), round10
	mov a, rand+8
	cjne a, button_pressed, fail_level
round10:
	cjne R1, #(10), round11
	mov a, rand+9
	cjne a, button_pressed, fail_level
round11:
	cjne R1, #(11), round12
	mov a, rand+10
	cjne a, button_pressed, fail_level
round12:
	cjne R1, #(12), round13
	mov a, rand+11
	cjne a, button_pressed, fail_level
round13:
	cjne R1, #(13), round14
	mov a, rand+12
	cjne a, button_pressed, fail_level
round14:
	cjne R1, #(14), round15
	mov a, rand+13
	cjne a, button_pressed, fail_level
round15:
	cjne R1, #(15), print_correct
    mov a, rand+14
	cjne a, button_pressed, fail_level
fail_level:
	mov level, #0x00
    mov b, level
    Display_BCD(b)
	ljmp after_pressed_state
print_correct:
	Set_Cursor(2,1)
	Send_Constant_String(#correct)
    jnb  START_GAME, $
	ljmp press_state_loop
;---------------------------------------------------------------------------
button_detection:

button_detect_loop:
    jb BUTTON1, button1_not_detected
    Wait_Milli_Seconds(#100)
    jb BUTTON1, button1_not_detected  
    jnb  BUTTON1, $
    mov button_pressed, #0x00
    ljmp return_button_detection
button1_not_detected:    
    jb BUTTON2, button2_not_detected
    Wait_Milli_Seconds(#100)
    jb BUTTON2, button2_not_detected  
    jnb  BUTTON2, $
    mov button_pressed, #0x01
    ljmp return_button_detection
button2_not_detected:
    jb BUTTON3, button3_not_detected
    Wait_Milli_Seconds(#100)
    jb BUTTON3, button3_not_detected  
    jnb  BUTTON3, $
    mov button_pressed, #0x02
    ljmp return_button_detection
button3_not_detected:
    jb BUTTON4, button_detect_loop
    Wait_Milli_Seconds(#100)
    jb BUTTON4, button_detect_loop  
    jnb  START_GAME, $
    mov button_pressed, #0x03
    ljmp return_button_detection
;-------------------------------------END OF CODE FOR BUTTON DETECTION---------------------------
;------------------------------------------------------------------------------------------------
end

