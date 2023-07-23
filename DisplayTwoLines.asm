ORG 0000H
RS	EQU	P1.3
E	EQU	P1.2
; ---------------------------------- Main -------------------------------------
	CLR RS		; RS = 0 - Instruction register is selected.
			; Stores instruction codes, e.g., clear display...
; Function set
	CALL FuncSet
; Display on/off control
	CALL DispCon
; Entry mode set (4-bit mode)
	CALL EntryMode
; Send data		
	SETB RS
	MOV DPTR,#LUT1	; RS = 1 - Data register is selected.
			; Send data to data register to be displayed.
Back:		CLR A
		MOVC A,@A+DPTR
		JZ Next
		CALL SendChar
		INC DPTR
		JMP Back	
Next:		CALL CursorPos	;Put cursor onto the next line
		SETB RS
		MOV DPTR,#LUT2	; RS = 1 - Data register is selected.
				; Send data to data register to be displayed.
Again:		CLR A	
		MOVC A,@A+DPTR
		JZ EndHere
		CALL SendChar
		INC DPTR
		JMP Again
EndHere:	JMP $
;--------------------------------- *END* -------------------------------------

;-------------------------------- Subroutines ---------------------------------

; ------------------------- Function set --------------------------------------
FuncSet:	CLR  P1.7	;
		CLR  P1.6	;
		SETB P1.5	; bit 5 = 1
		CLR  P1.4
		CALL Pulse	; (DB4)DL = 0 - puts LCD module into 4-bit mode
		CALL Delay 	; wait for BF to clear
		CALL Pulse	
		SETB P1.7
		CLR  P1.6
		CLR  P1.5
		CLR  P1.4	; P1.7 = 1 (N) - 2 lines
		CALL Pulse
		CALL Delay
		RET
;-----------------------------------------------------------------------------

;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	CLR P1.7	;
		CLR P1.6	;
		CLR P1.5	;
		CLR P1.4
		CALL Pulse	; high nibble set (0H - hex)
		SETB P1.7	;
		SETB P1.6	; Sets entire display ON
		SETB P1.5	; Cursor ON
		SETB P1.4
		CALL Pulse	; Cursor blinking ON
		CALL Delay	; wait for BF to clear
		RET
;--------------------------------------------------------------------------------
CursorPos:	CLR RS
		SETB P1.7	; Sets the DDRAM address
		SETB P1.6	; Set address. Address starts here - '1'
		CLR P1.5	; '0'
		CLR P1.4	; '0'
				; high nibble
		CALL Pulse
		CLR P1.7	; '0'
		CLR P1.6	; '0'
		CLR P1.5	; '0'
		CLR P1.4
		CALL Pulse	; '0'
				; low nibble
				; Therefore address is 100 0000 or 40H
		CALL Delay	; wait for BF to clear
		RET
;----------------------------- Entry mode set (4-bit mode) ----------------------
;    Set to increment the address by one and cursor shifted to the right
EntryMode:	CLR P1.7	; P1.7 = 0
		CLR P1.6	; P1.6 = 0
		CLR P1.5	; P1.5 = 0
		CLR P1.4
		CALL Pulse	; P1.4 = 0
		CLR  P1.7	; P1.7 = '0'
		SETB P1.6	; P1.6 = '1'
		SETB P1.5	; P1.5 = '1'
		CLR  P1.4
		CALL Pulse	; P1.4 = '0'
		CALL Delay	; wait for BF to clear
		RET
;------------------------------------ Pulse --------------------------------------
Pulse:		SETB E		; *P1.2 is connected to 'E' pin of LCD module*
		CLR  E		; negative edge on E
RET
;---------------------------------------------------------------------------------

;------------------------------------- SendChar ----------------------------------
SendChar:	MOV C, ACC.7	;
		MOV P1.7, C	;
		MOV C, ACC.6	;
		MOV P1.6, C	;
		MOV C, ACC.5	;
		MOV P1.5, C	;
		MOV C, ACC.4	;
		MOV P1.4, C	; high nibble
				;JMP $
		CALL Pulse
		MOV C, ACC.3	;
		MOV P1.7, C	;
		MOV C, ACC.2	;
		MOV P1.6, C	;
		MOV C, ACC.1	;
		MOV P1.5, C	;
		MOV C, ACC.0	;
		MOV P1.4, C
		CALL Pulse	; low nibble
		CALL Delay	; wait for BF to clear
		MOV R1,#55h
		RET
;------------------------------------- Delay ------------------------------------
Delay:		MOV R0, #50
		DJNZ R0, $
		RET
;-------------------------------------------------------------------------------

;--------------------------------- End of subroutines ------------------------------

;------------------------------ Look-Up Table (LUT) --------------------------------
ORG 0200h
LUT1:	DB 'Z', 'O', 'N', 'E', ' ', 'A', ':', ' ', '2', '0', 0
LUT2:	DB 'Z', 'O', 'N', 'E', ' ', 'B', ':', ' ', '1', '0', 0

;-----------------------------------------------------------------------------------
Stop:	JMP $
END
