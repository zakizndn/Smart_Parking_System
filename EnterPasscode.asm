ORG 0000H
RS	EQU	P1.3
E	EQU	P1.2
; ---------------------------------- Main -------------------------------------
Main:	CLR RS			; RS = 0 - Instruction register is selected.

;------------------------- Set Instruction Codes ------------------------------
	CALL FuncSet		; Function set (4 bit mode)
	CALL DispCon		; Turn display and cursor on
	CALL EntryMode		; Shift cursor to the right by 1
;-------------------------------------------------------------------------------
	SETB RS			; RS = 1 - Data register is selected.
	MOV DPTR, #LUT1		; Look-up table for "Enter PIN:" message
Again:	CLR A	
	MOVC A, @A+DPTR		; Get the character
	JZ Next			; Exit when A = 0
	CALL SendChar		; Display character
	INC DPTR JMP Again	; Point to the next character
Next:	MOV R4, #00H		; Counter for checking the number of scans
	MOV R5, #00H		; Counter for checking for the number correct key input
	MOV DPTR, #LUT4 	; Copy the start of the look-up table for PIN

;----------------------------------- Get Input ----------------------------------
Iterate:CALL ScanKeyPad		; Scan for the key input SETB RS	
				; RS = 1 - Data register is selected.
	CLR A
	MOV A, #'*'
	CALL SendChar		; Display the asterisk for each key pressed

;------------------- Check for the number of correct code entered ---------------
	CLR A	
	MOVC A, @A+DPTR		; Look-up table of PIN
	CALL CheckInput
	INC DPTR
	INC R4
	CJNE R4, #04H, Iterate	; Check for the number of correct inputs
	CJNE R5, #04H, Wrong	; Check for the number of correct inputs
Right:	CALL CursorPos		; Put cursor onto the next line
	SETB RS
	CALL Granted
	JMP EndHere		; RS = 1 - Data register is selected.
Wrong:	CALL CursorPos		; Put cursor onto the next line
	SETB RS
	CALL Denied		; RS = 1 - Data register is selected.
EndHere:JMP $	
;------------------------------ *End Of Main* ---------------------------------

;------------------------------- Subroutines ------------------------------------

; ------------------------------ Function set ------------------------------------
FuncSet:	CLR  P1.7	; |
		CLR  P1.6	; |
		SETB P1.5	; | bit 5=1
		CLR  P1.4
		CALL Pulse	; | (DB4)DL=0 - puts LCD module into 4-bit mode
		CALL Delay 
		CALL Pulse	; wait for BF to clear
		SETB P1.7
		CLR  P1.6
		CLR  P1.5
		CLR  P1.4	; P1.7=1 (N) - 2 lines
		CALL Pulse
		CALL Delay
		RET
;-----------------------------------------------------------------------------

;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	CLR P1.7	; |
		CLR P1.6	; |
		CLR P1.5	; |
		CLR P1.4
		CALL Pulse	; | high nibble set (0H - hex)
		SETB P1.7	; |
		SETB P1.6	; |Sets entire display ON
		SETB P1.5	; |Cursor ON
		SETB P1.4
		CALL Pulse	; |Cursor blinking ON
		CALL Delay	; wait for BF to clear
		RET
;--------------------------------------------------------------------------------

;----------------------------- Entry mode set (4-bit mode) ----------------------
; Set to increment the address by one and cursor shifted to the right
EntryMode:	CLR P1.7	; |P1.7 = 0
		CLR P1.6	; |P1.6 = 0
		CLR P1.5	; |P1.5 = 0
		CLR P1.4
		CALL Pulse	; |P1.4 = 0
		CLR  P1.7	; |P1.7 = '0'
		SETB P1.6	; |P1.6 = '1'
		SETB P1.5	; |P1.5 = '1'
		CLR  P1.4
		CALL Pulse	; |P1.4 = '0'
		CALL Delay	; wait for BF to clear
		RET
;--------------------------------------------------------------------------------

;------------------------------------ Pulse --------------------------------------
Pulse:	SETB E			; |*P1.2 is connected to 'E' pin of LCD module*
	CLR  E			; | negative edge on E
	RET
;--------------------------------------------------------------------------------

;------------------------------------- SendChar ----------------------------------
SendChar:	MOV C, ACC.7	; |
		MOV P1.7, C	; |
		MOV C, ACC.6	; |
		MOV P1.6, C	; |
		MOV C, ACC.5	; |
		MOV P1.5, C	; |
		MOV C, ACC.4	; |
		MOV P1.4, C	
		; JMP $
		CALL Pulse	; | high nibble set
		MOV C, ACC.3	; |
		MOV P1.7, C	; |
		MOV C, ACC.2	; |
		MOV P1.6, C	; |
		MOV C, ACC.1	; |
		MOV P1.5, C	; |
		MOV C, ACC.0	; |
		MOV P1.4, C
		CALL Pulse	; | low nibble set
		CALL Delay	; wait for BF to clear
		MOV R1,#55H
		RET
;-------------------------------------------------------------------------------

;------------------------------------- Delay ------------------------------------
Delay:	MOV R0, #50
	DJNZ R0, $
	RET
;--------------------------------------------------------------------------------

;---------------------------Scan Keypad Subroutines------------------------------
;------------------------------- Scan Row ---------------------------------------
ScanKeyPad:	CLR P0.3	; Clear Row3
		CALL IDCode0	; Call scan column subroutine
		SETB P0.3	; Set Row 3
		JB F0, Done
		;Scan Row2	; If F0 is set, end scan
		CLR P0.2	; Clear Row2
		CALL IDCode1	; Call scan column subroutine
		SETB P0.2	; Set Row 2
		JB F0, Done	; If F0 is set, end scan
		;Scan Row1	
		CLR P0.1	; Clear Row1
		CALL IDCode2	; Call scan column subroutine
		SETB P0.1	; Set Row 1
		JB F0, Done
		;Scan Row0	; If F0 is set, end scan
		CLR P0.0	; Clear Row0
		CALL IDCode3	; Call scan column subroutine
		SETB P0.0	; Set Row 0
		JB F0, Done	; If F0 is set, end scan
		JMP ScanKeyPad	; Go back to scan Row3
Done:		CLR F0		; Clear F0 flag before exit
		RET
;-------------------------------------------------------------------------------

;---------------------------- Scan column subroutine ----------------------------
IDCode0:	JNB P0.4, KeyCode03	; If Col0 Row3 is cleared - key found
		JNB P0.5, KeyCode13	; If Col1 Row3 is cleared - key found
		JNB P0.6, KeyCode23
		RET			; If Col2 Row3 is cleared - key found
KeyCode03:	SETB F0  	; Key found - set F0
		MOV R7, #'3' 	; Code for '3'
		RET		
KeyCode13:	SETB F0		; Key found - set F0
		MOV R7, #'2' 	; Code for '2'
		RET		
KeyCode23:	SETB F0		; Key found - set F0
		MOV R7, #'1' 	; Code for '1'
		RET		
IDCode1:	JNB P0.4, KeyCode02	; If Col0 Row2 is cleared - key found
		JNB P0.5, KeyCode12	; If Col1 Row2 is cleared - key found
		JNB P0.6, KeyCode22	; If Col2 Row2 is cleared - key found
		RET			
KeyCode02:	SETB F0		; Key found - set F0
		MOV R7, #'6' 	; Code for '6'
		RET		
KeyCode12:	SETB F0		; Key found - set F0
		MOV R7, #'5' 	; Code for '5'	
		;MOV P1, R7	; Display key pressed
		RET		
KeyCode22:	SETB F0		; Key found - set F0
		MOV R7, #'4' 	; Code for '4'
		RET		
IDCode2:	JNB P0.4, KeyCode01	; If Col0 Row1 is cleared - key found
		JNB P0.5, KeyCode11	; If Col1 Row1 is cleared - key found
		JNB P0.6, KeyCode21	; If Col2 Row1 is cleared - key found
		RET		
KeyCode01:	SETB F0		; Key found - set F0
		MOV R7, #'9' 	; Code for '9'
		RET	
KeyCode11:	SETB F0		; Key found - set F0
		MOV R7, #'8' 	; Code for '8'
		RET	
KeyCode21:	SETB F0		; Key found - set F0
		MOV R7, #'7' 	; Code for '7'
		RET	
IDCode3:	JNB P0.4, KeyCode00	; If Col0 Row0 is cleared - key found
		JNB P0.5, KeyCode10	; If Col1 Row0 is cleared - key found
		JNB P0.6, KeyCode20	; If Col2 Row0 is cleared - key found
		RET	
KeyCode00:	SETB F0		; Key found - set F0
		MOV R7, #'#' 	; Code for '#'
		RET	
KeyCode10:	SETB F0		; Key found - set F0
		MOV R7, #'0' 	; Code for '0'
		RET	
KeyCode20:	SETB F0		; Key found - set F0
		MOV R7, #'*'	; Code for '*'
		RET
;--------------------------------------------------------------------------------

;--------------------------------- Check Input -----------------------------------
CheckInput:	CJNE A, 07H, Exit	; 07H is register R7 - it contains the code entered. INC R5
Exit:		RET
;-------------------------------------------------------------------------------

;-----------------------------------CursorPos------------------------------------------
CursorPos:	CLR RS
		SETB P1.7	; Sets the DDRAM address
		SETB P1.6	; Set address. Address starts here - '1'
		CLR P1.5	; '0'
		CLR P1.4
		CALL Pulse	; '0'
				; high nibble
		CLR P1.7	; '0'
		CLR P1.6	; '0'
		CLR P1.5	; '0'
		CLR P1.4
		CALL Pulse	; '0'
				; low nibble
		CALL Delay	; wait for BF to clear
		RET
;-------------------------------------------------------------------------------

;------------------------------ Open ---------------------------------------------
Granted:	MOV DPTR, #LUT2	; Look-up table for "Access Granted"
GoBack:		CLR A
		MOVC A, @A+DPTR
		JZ Home
		CALL SendChar
		INC DPTR
		JMP	GoBack
Home:		RET
;-------------------------------------------------------------------------------

;------------------------------ Deny --------------------------------------------
Denied:		MOV DPTR, #LUT3	; Look-up table for "Access Denied"
OneMore:	CLR A
		MOVC A, @A+DPTR
		JZ BackHome
		CALL SendChar
		INC DPTR
		JMP OneMore
BackHome:	RET
;--------------------------------- End of subroutines --------------------------

;------------------------------ Look-Up Table (LUT) --------------------------

;---------------------------------- Messages -------------------------------------
ORG 0200h
LUT1:	DB 'E', 'n', 't', 'e', 'r', ' ', 'P', 'I', 'N', ':', 0
LUT2:	DB 'A', 'c', 'c', 'e', 's', 's', ' ', 'G', 'r', 'a', 'n', 't', 'e', 'd', 0
LUT3:	DB 'A', 'c', 'c', 'e', 's', 's', ' ', 'D', 'e', 'n', 'i', 'e', 'd', 0
;--------------------------------------------------------------------------------

;------------------------------------- PIN --------------------------------------
ORG 0240h
LUT4:	DB '0', '0', '0', '1', 0
;-------------------------------------------------------------------------------

;--------------------------------- End of Program -----------------------------
Stop:	JMP $
END







