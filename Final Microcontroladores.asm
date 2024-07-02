#include "p18f45k50.inc"
    processor 18F45K50 
    ; Aliases definition (EQU and define)
    #define RS LATE, 0, A
    #define RW LATE, 1, A
    #define E  LATE, 2, A
    #define dataLCD LATD, A
; --- delay variables
    
X1   EQU   .245
X2   EQU   .97
X3   EQU   .100
; --- Variables
    cblock 0x40
	flag_pos,flag_loc,flag_end,w1,w2,w3,attempts,score,unita,decine,confronta
	mulH,mulL,temp_val,randomNum,timerVar,EEchange,EETry
	endc
    cblock 0x5F
	l1,l2,l3,l4,l5,l6,l7,l8,l9,l10,l11,l12,l13,l14,l15,l16,low_flag1,low_flag2
	;0x71
	h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,high_flag1,high_flag2
	;0x83
	low_flag3,low_flag4,high_flag3,high_flag4,h_pos,l_pos,up_down,card2show
	;0x8B
	lowp_flag1,lowp_flag2,highp_flag1,highp_flag2,storeNum,flag_pair
	;0x91
	flag_used,flag_again,pos_clear,flag_updown,count_success,MEM1,MEM2,MEM3
	;0x99
	
    endc
    

; --- Origin of the code
    org 0x00
    goto configura
    
    org 0x08 ;	high priority interrupts
    btfsc INTCON, TMR0IF, A	; TMR0 overflow
	goto TMR0overflow
    retfie
	
    org 0x18 ;	low priority interrupts

    retfie
    org 0x30	; origen real del codigo(sin problemas con interrupciones)
configura
    ; --- Basic I/O configuration LCD
    movlb .15
    clrf ANSELE, BANKED
    clrf ANSELD, BANKED
    clrf ANSELA, BANKED
    clrf TRISE, A
    clrf TRISD, A
    clrf TRISA, A
    clrf dataLCD
    
    ; --- Basic I/O configuration Teclado
    clrf ANSELB, BANKED
    bcf INTCON2, 7
    movlw B'00001111'
    movwf TRISB
    movwf WPUB
    
    ; --- Timers configuration
    ;	timer configuration TMR0
    movlw b'00000110'
    movwf T0CON,A
    ;	timer configuration TMR1
    movlw b'00000000'
    movwf T1CON,A
    bcf T1GCON,7,A
    ;	timer configuration TMR2
    movlw b'00111011'
    movwf T2CON,A
    movlw .234
    movwf PR2
    
    ; --- Interrupt configuration 
    movlw b'11100000'	;enable + timer0 interrupt
    movwf INTCON, A
    bcf PIE1,0		; disable TMR1 int
    bcf PIE1,1		; disable TMR2 int
    bsf RCON,7,A	; enable priority int
    bsf INTCON2,2,A	; TMR0 high prior
    
    ; --- LCD configuration
    call retTMR2    ; Start-up time, funcionamento antes que recibir el comando
    movlw b'00111000'
    call sendConfigLCD
    ;	    Entry mode: cursor derecha, no display shift (RS=RW=0, data = b?00000110?)
    movlw b'110'
    call sendConfigLCD
    ;	    Display control: Display on, cursor and blink on (RS=RW=0, data = b?00001111?)
    movlw b'1111'
    call sendConfigLCD
    ;	    Clear display (RS=RW=0, data = b?00000001?)
    movlw b'1'
    call sendConfigLCD
    
; --- LCD Char generator
    movlw b'01000000'
    call sendConfigLCD
    
    ; primero caracter
    movlw b'1110'
    call sendWriteLCD
    movlw b'11111'
    call sendWriteLCD
    movlw b'10101'
    call sendWriteLCD
    movlw b'11111'
    call sendWriteLCD
    movlw b'11011'
    call sendWriteLCD
    movlw b'1010'
    call sendWriteLCD
    movlw b'100'
    call sendWriteLCD
    movlw b'000000'
    call sendWriteLCD
    
	; segundo
    movlw b'11'
    call sendWriteLCD
    movlw b'101'
    call sendWriteLCD
    movlw b'1001'
    call sendWriteLCD
    movlw b'1001'
    call sendWriteLCD
    movlw b'1011'
    call sendWriteLCD
    movlw b'11011'
    call sendWriteLCD
    movlw b'11000'
    call sendWriteLCD
    movlw b'000000'
    call sendWriteLCD
    
	; tercero
    movlw b'1110'
    call sendWriteLCD
    movlw b'1110'
    call sendWriteLCD
    movlw b'10101'
    call sendWriteLCD
    movlw b'1110'
    call sendWriteLCD
    movlw b'100'
    call sendWriteLCD
    movlw b'100'
    call sendWriteLCD
    movlw b'1010'
    call sendWriteLCD
    movlw b'10001'
    call sendWriteLCD
    
	; cuarto
    movlw b'00000000'
    call sendWriteLCD
    movlw b'00000100'
    call sendWriteLCD
    movlw b'00001110'
    call sendWriteLCD
    movlw b'00011111'
    call sendWriteLCD
    movlw b'00001110'
    call sendWriteLCD
    movlw b'00000100'
    call sendWriteLCD
    movlw b'00000000'
    call sendWriteLCD
    movlw b'00000000'
    call sendWriteLCD	
   
main   
    call retTMR1
    call reset_score
    call first_menu
    call teclado_first
    btfss flag_pos,1,A
	goto play
    goto scores
    ; - Infinite loop -    
    goto main 
    
    
    ; * Subroutines *
play
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    ;	set cursor to initial position
    call init_cursor
    call show_cards
    call dibujar_todo
    call init_cursor
    clrf flag_loc
    clrf flag_end
    call light_off
    ;	*    ----    Juego	----	**
    call tecladoON
    bcf T0CON, 7, A
    call calculate_score
    ;	*    ----    Fin del Juego	----	**
    
    call pressCheck ;	Enable cursor
    call retTMR2
   
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_red
    
    call pressCheck
    call retTMR2
    
    ;;;; LLama al la pantalla end_game, guarda el valor de score en EEPROM y espera a que se presione ENTER ;;;
    btfsc flag_end,1
	call gameover_Time
    btfsc flag_end,2
	call gameover_attempts
	
    ;	Enable cursor
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_green
    call end_game
    call save_score
    
Firststep2
    call teclado_second
    btfss flag_pos,0,A
	goto Firststep2
    call high_score
    ;	Enable cursor
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_green
    ;;;; Espera a que se presione ENTER para salir de la pantalla high_score ;;;
Secondstep2
    call teclado_second
    btfss flag_pos,0,A
	goto Secondstep2
    call tecladoON
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    call Cur_on
    goto main    

show_cards
    movlb 0
    movf TMR1L,A
    movwf randomNum
    
    clrf l_pos
    clrf h_pos
    clrf up_down
    
    movlw .16
    movwf temp_val
s_0 call PRNG
    incf h_pos,1,BANKED
    decfsz temp_val,1
    goto s_0
    
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    
    bsf up_down,0
    movlw .16
    movwf temp_val
s_1 call PRNG
    incf l_pos,1,BANKED
    decfsz temp_val,1
    goto s_1
    
    bcf T1CON, 0, A	; shuts timer1 down
    call longdelay
    return   
    
PRNG
    ;	random 0-127
    movf randomNum,W
    rlcf WREG,W
    xorwf randomNum,W
    rlcf WREG,W
    rlcf WREG,W
    
    rlcf randomNum,F
    bcf randomNum,7
    
    movlw .7
    cpfsgt randomNum
	goto placeNum1
    movlw .15
    cpfsgt randomNum
	goto placeNum2
    movlw .23
    cpfsgt randomNum
	goto placeNum3
    movlw .31
    cpfsgt randomNum
	goto placeNum4
    movlw .39
    cpfsgt randomNum
	goto placeNum5
    movlw .47
    cpfsgt randomNum
	goto placeNum6
    movlw .55
    cpfsgt randomNum
	goto placeNum7
    movlw .63
    cpfsgt randomNum
	goto placeNum8
    movlw .71
    cpfsgt randomNum
	goto placeNum9
    movlw .79
    cpfsgt randomNum
	goto placeNum10
    movlw .87
    cpfsgt randomNum
	goto placeNum11
    movlw .95
    cpfsgt randomNum
	goto placeNum12
    movlw .103
    cpfsgt randomNum
	goto placeNum13
    movlw .111
    cpfsgt randomNum
	goto placeNum14	
    movlw .119
    cpfsgt randomNum
	goto placeNum15
    movlw .127
    cpfsgt randomNum
	goto placeNum16
    return    

placeNum1
    btfsc low_flag2,0
	goto PRNG
    btfsc low_flag1,0
	bsf low_flag2,0,BANKED
    movlw .0
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,0,BANKED
    return
placeNum2
    btfsc low_flag2,1
	goto PRNG
    btfsc low_flag1,1
	bsf low_flag2,1,BANKED
    movlw .1
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,1,BANKED
    return
placeNum3
    btfsc low_flag2,2
	goto PRNG
    btfsc low_flag1,2
	bsf low_flag2,2,BANKED
    movlw .2
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,2,BANKED
    return
placeNum4
    btfsc low_flag2,3
	goto PRNG
    btfsc low_flag1,3
	bsf low_flag2,3,BANKED
    movlw 0x32
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,3,BANKED
    return
placeNum5
    btfsc low_flag2,4
	goto PRNG
    btfsc low_flag1,4
	bsf low_flag2,4,BANKED
    movlw 0x33
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,4,BANKED
    return
placeNum6
    btfsc low_flag2,5
	goto PRNG
    btfsc low_flag1,5
	bsf low_flag2,5,BANKED
    movlw 0x34
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,5,BANKED
    return
placeNum7
    btfsc low_flag2,6
	goto PRNG
    btfsc low_flag1,6
	bsf low_flag2,6,BANKED
    movlw 0x35
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,6,BANKED
    return
placeNum8
    btfsc low_flag2,7
	goto PRNG
    btfsc low_flag1,7
	bsf low_flag2,7,BANKED
    movlw 0x36
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf low_flag1,7,BANKED
    return
placeNum9
    btfsc high_flag2,0
	goto PRNG
    btfsc high_flag1,0
	bsf high_flag2,0,BANKED
    movlw 0x37
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,0,BANKED
    return
placeNum10
    btfsc high_flag2,1
	goto PRNG
    btfsc high_flag1,1
	bsf high_flag2,1,BANKED
    movlw 0x38
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,1,BANKED
    return
placeNum11
    btfsc high_flag2,2
	goto PRNG
    btfsc high_flag1,2
	bsf high_flag2,2,BANKED
    movlw 0x39
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,2,BANKED
    return
placeNum12
    btfsc high_flag2,3
	goto PRNG
    btfsc high_flag1,3
	bsf high_flag2,3,BANKED
    movlw 0x41
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,3,BANKED
    return
placeNum13
    btfsc high_flag2,4
	goto PRNG
    btfsc high_flag1,4
	bsf high_flag2,4,BANKED
    movlw 0x51
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,4,BANKED
    return
placeNum14
    btfsc high_flag2,5
	goto PRNG
    btfsc high_flag1,5
	bsf high_flag2,5,BANKED
    movlw 0x54
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,5,BANKED
    return
placeNum15
    btfsc high_flag2,6
	goto PRNG
    btfsc high_flag1,6
	bsf high_flag2,6,BANKED
    movlw 0x4A
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,6,BANKED
    return
placeNum16
    btfsc high_flag2,7
	goto PRNG
    btfsc high_flag1,7
	bsf high_flag2,7,BANKED
    movlw 0x4B
    movwf storeNum,BANKED
    call sendWriteLCD
    call store
    bsf high_flag1,7,BANKED
    return
    
store
    btfss up_down,0,BANKED
	goto store_high
    goto store_low
    
store_low   
    movlw .0
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l1
    movlw .1
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l2
    movlw .2
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l3
    movlw .3
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l4
    movlw .4
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l5
    movlw .5
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l6
    movlw .6
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l7
    movlw .7
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l8
    movlw .8
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l9
    movlw .9
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l10
    movlw .10
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l11
    movlw .11
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l12
    movlw .12
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l13
    movlw .13
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l14
    movlw .14
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l15
    movlw .15
    subwf l_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,l16
    return
	
store_high
    movlw .0
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h1
    movlw .1
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h2
    movlw .2
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h3
    movlw .3
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h4
    movlw .4
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h5
    movlw .5
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h6
    movlw .6
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h7
    movlw .7
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h8
    movlw .8
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h9
    movlw .9
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h10
    movlw .10
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h11
    movlw .11
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h12
    movlw .12
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h13
    movlw .13
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h14
    movlw .14
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h15
    movlw .15
    subwf h_pos,0,BANKED
    btfsc STATUS,2
	movff storeNum,h16
    return

reset_score
    clrf attempts
    return
    
menu_intentos
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    movlw 0x01
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x00
    call sendWriteLCD
    movlw 'A'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw 'm'
    call sendWriteLCD
    movlw 'p'          
    call sendWriteLCD
    movlw 't'          
    call sendWriteLCD
    movlw 's'          
    call sendWriteLCD
    movlw ' '          
    call sendWriteLCD
    movlw 'L'          
    call sendWriteLCD
    movlw 'e'          
    call sendWriteLCD
    movlw 'f'          
    call sendWriteLCD
    movlw 't'          
    call sendWriteLCD
    movlw 0x00          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x48
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw '5'    
    call sendWriteLCD
    return
    
scores 
    call pressCheck
    call retTMR2
    ;	Enable cursor
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_green
    call pressCheck
    call retTMR2
    ;;;; LLama al la pantalla show_score y espera a que se presione ENTER ;;;
    call show_score
Firststep
    call teclado_second
    btfss flag_pos,0,A
	goto Firststep
    call high_score
    ;	Enable cursor
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_green
    ;;;; Espera a que se presione ENTER para salir de high_score ;;;
Secondstep
    call teclado_second
    btfss flag_pos,0,A
	goto Secondstep
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    call Cur_on
    goto main   
    
gameover_Time
    clrf score
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
; ** set position Line 1
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x02
    call sendWriteLCD
    movlw 'G'
    call sendWriteLCD
    movlw 'A'
    call sendWriteLCD
    movlw 'M'
    call sendWriteLCD
    movlw 'E'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'O'          
    call sendWriteLCD
    movlw 'V'          
    call sendWriteLCD
    movlw 'E'          
    call sendWriteLCD
    movlw 'R'          
    call sendWriteLCD
    movlw 0x02          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x41
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x00         
    call sendWriteLCD
    movlw 'T'          
    call sendWriteLCD
    movlw 'i'
    call sendWriteLCD
    movlw 'm'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'i'
    call sendWriteLCD
    movlw 's'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'O'
    call sendWriteLCD
    movlw 'v'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw 'r'
    call sendWriteLCD
    movlw 0x00         
    call sendWriteLCD

    ;	disable cursor
    movlw b'1100'
    call sendConfigLCD
    
Secondstep3
    call teclado_second
    btfss flag_pos,0,A
	goto Secondstep3
    return
    
gameover_attempts
    clrf score
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
; ** set position Line 1
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x02
    call sendWriteLCD
    movlw 'G'
    call sendWriteLCD
    movlw 'A'
    call sendWriteLCD
    movlw 'M'
    call sendWriteLCD
    movlw 'E'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'O'          
    call sendWriteLCD
    movlw 'V'          
    call sendWriteLCD
    movlw 'E'          
    call sendWriteLCD
    movlw 'R'          
    call sendWriteLCD
    movlw 0x02          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 'N'          
    call sendWriteLCD
    movlw 'o'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'M'
    call sendWriteLCD
    movlw 'o'
    call sendWriteLCD
    movlw 'r'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'A'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw 'm'
    call sendWriteLCD
    movlw 'p'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw 's'
    call sendWriteLCD
    call conversione
    ;	disable cursor
    movlw b'1100'
    call sendConfigLCD
    return
    
show_score
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x01
    call sendWriteLCD
    movlw 'L'
    call sendWriteLCD
    movlw 'a'
    call sendWriteLCD
    movlw 's'
    call sendWriteLCD
    movlw 't'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'S'          
    call sendWriteLCD
    movlw 'c'          
    call sendWriteLCD
    movlw 'o'          
    call sendWriteLCD
    movlw 'r'          
    call sendWriteLCD
    movlw 'e'          
    call sendWriteLCD
    movlw 's'          
    call sendWriteLCD
    movlw 0x01          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x00         
    call sendWriteLCD
    ;;;; LLama al valor en la posicion 10 del EEPROM y lo guarda en EETry ;;;
    movlw d'10'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    call conversione2
    movlw 0x46
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x02         
    call sendWriteLCD
    ;;;; LLama al valor en la posicion 11 del EEPROM y lo guarda en EETry ;;;
    movlw d'11'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    call conversione2
    movlw 0x4C
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x03         
    call sendWriteLCD
    ;;;; LLama al valor en la posicion 12 del EEPROM y lo guarda en EETry ;;;
    movlw d'12'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    call conversione2
    ;	set cursor to disabled
    movlw b'1100'
    call sendConfigLCD
    call tecladoON
    return
    
high_score
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x01
    call sendWriteLCD
    movlw 'H'
    call sendWriteLCD
    movlw 'i'
    call sendWriteLCD
    movlw 'g'
    call sendWriteLCD
    movlw 'h'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'S'          
    call sendWriteLCD
    movlw 'c'          
    call sendWriteLCD
    movlw 'o'          
    call sendWriteLCD
    movlw 'r'          
    call sendWriteLCD
    movlw 'e'          
    call sendWriteLCD
    movlw 0x01          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x45
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x03         
    call sendWriteLCD
    ;;;; LLama al valor en la posicion 9 del EEPROM y lo guarda en EETry ;;;
    movlw d'9'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    movf EETry, W
    call conversione2
    ; send text
    movlw 0x03         
    call sendWriteLCD
    ;	disable cursor
    movlw b'1100'
    call sendConfigLCD
    return

;;;; Subrutina para guardar valores en la EEPROM y cambiar el valor mas alto ;;;
save_score
    call last
    call middle
    call new
    call High1
	return
last
    movlw d'11'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EEchange 
    movlw d'12' ;Posiciónen la EEPROM
    movwf EEADR,A
    movf EEchange,W;Valor a escribir
    movwf EEDATA,A;Protocolo de escritura  
    movlw b'00000100';Habilita Write 
    movwf EECON1,A 
    movlw 0x55;Contraseñas
    movwf EECON2,A
    movlw 0x0AA
    movwf EECON2,A
    bsf EECON1, WR, A;Empieza a escribir
waitwrite
    btfsc EECON1,WR,A
    goto waitwrite
    bcf EECON1,2,A
    clrf EEDATA,A
    return

middle
    movlw d'10'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EEchange  
    movlw d'11' ;Posiciónen la EEPROM
    movwf EEADR,A
    movf EEchange,W;Valor a escribir
    movwf EEDATA,A;Protocolodeescrit   
    movlw b'00000100';Habilita Write 
    movwf EECON1,A 
    movlw 0x55;Contraseñas
    movwf EECON2,A
    movlw 0x0AA
    movwf EECON2,A
    bsf EECON1, WR, A;Empieza a escribir
waitwrite1
    btfsc EECON1,WR,A
    goto waitwrite1
    bcf EECON1,2,A
    clrf EEDATA,A
    return

new
    movlw d'10' ;Posiciónen la EEPROM
    movwf EEADR,A
    movf score,W;Valor a escribir
    movwf EEDATA,A;Protocolodeescrit   
    movlw b'00000100';Habilita Write 
    movwf EECON1,A 
    movlw 0x55;Contraseñas
    movwf EECON2,A
    movlw 0x0AA
    movwf EECON2,A
    bsf EECON1, WR, A;Empieza a escribir
waitwrite2
    btfsc EECON1,WR,A
    goto waitwrite2
    bcf EECON1,2,A
    clrf EEDATA,A
    return

High1
    movlw d'9'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    movlw d'0'
    CPFSEQ score, A
	call High3
	return
High3
    movlw h'FF'
    CPFSEQ EETry, A
       call High2
    movlw d'9' ;Posiciónen la EEPROM
    movwf EEADR,A
    movlw d'0';Valor a escribir
    movwf EEDATA,A;Protocolodeescrit   
    movlw b'00000100';Habilita Write 
    movwf EECON1,A 
    movlw 0x55;Contraseñas
    movwf EECON2,A
    movlw 0x0AA
    movwf EECON2,A
    bsf EECON1, WR, A;Empieza a escribir
waitwrite4
    btfsc EECON1,WR,A
    goto waitwrite4
    bcf EECON1,2,A
    clrf EEDATA,A
High2
    movlw score
    CPFSEQ EETry, A
       call checkhigh
    return

checkhigh
    movlw d'9'
    movwf EEADR,A
    bsf EECON1,0,A
    movff EEDATA, EETry
    movlw score
    CPFSGT EETry, A
       call newhigh
    return

newhigh
    movlw d'9' ;Posiciónen la EEPROM
    movwf EEADR,A
    movf score,W;Valor a escribir
    movwf EEDATA,A;Protocolodeescrit   
    movlw b'00000100';Habilita Write 
    movwf EECON1,A 
    movlw 0x55;Contraseñas
    movwf EECON2,A
    movlw 0x0AA
    movwf EECON2,A
    bsf EECON1, WR, A;Empieza a escribir
waitwrite3
    btfsc EECON1,WR,A
    goto waitwrite3
    bcf EECON1,2,A
    clrf EEDATA,A
    return
    

calculate_score
    movlw .16
    subwf attempts,W
    mullw .4
    movf PRODL,W
    sublw .100
    movwf score
    return
    
end_game
    ;	Limpia lcd
    movlw b'1'
    call sendConfigLCD
; ** set position Line 1
    movlw 0x02
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x02
    call sendWriteLCD
    movlw 'G'
    call sendWriteLCD
    movlw 'A'
    call sendWriteLCD
    movlw 'M'
    call sendWriteLCD
    movlw 'E'
    call sendWriteLCD
    movlw ' '
    call sendWriteLCD
    movlw 'O'          
    call sendWriteLCD
    movlw 'V'          
    call sendWriteLCD
    movlw 'E'          
    call sendWriteLCD
    movlw 'R'          
    call sendWriteLCD
    movlw 0x02          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x44
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 'S'          
    call sendWriteLCD
    movlw 'c'
    call sendWriteLCD
    movlw 'o'
    call sendWriteLCD
    movlw 'r'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw ':'
    call sendWriteLCD
    call conversione
    ;	disable cursor
    movlw b'1100'
    call sendConfigLCD
    
Secondstep4
    call teclado_second
    btfss flag_pos,0,A
	goto Secondstep4
    return
    
dibujar_todo
    call init_cursor
    movlw .17
    movwf w2,A
loop_dibuja_1
    dcfsnz w2,F
    goto loop_dibuja
    call dibujar
    goto loop_dibuja_1
loop_dibuja
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw .17
    movwf w2,A
loop_dibuja_2
    dcfsnz w2,F
    return
    call dibujar
    goto loop_dibuja_2
    
    
dibujar
    movlw 0x03
    call sendWriteLCD
    return
    
init_cursor
    movlw 0x00
    bsf WREG,7,A
    call sendConfigLCD
    return
    
;;;; Conversion para valores provenientes de score ;;;
conversione
	movlw .100
	subwf score,W
	btfsc STATUS,2,A
	    goto exit_conv
	clrf unita
	clrf decine
	clrf confronta	
inc_uni	
	movf score,W
	subwf confronta,W
	btfsc STATUS,2,A
	    goto print
	incf confronta,F
	incf unita,F
	
	movlw .10
	subwf unita,W
	btfsc STATUS,2,A
	    call inc_dec
	goto inc_uni
inc_dec
	incf decine,F
	clrf unita
	return

;;;; Conversion para valores provenientes de EEPROM ;;;
conversione2
	movlw .100
	subwf EETry,W
	btfsc STATUS,2,A
	    goto exit_conv
	clrf unita
	clrf decine
	clrf confronta
inc_uni2
	movf EETry,W
	subwf confronta,W
	btfsc STATUS,2,A
	    goto print
	incf confronta,F
	incf unita,F
	
	movlw .10
	subwf unita,W
	btfsc STATUS,2,A
	    call inc_dec2
	goto inc_uni2
inc_dec2
	incf decine,F
	clrf unita
	return
	
exit_conv
    ;   just send 100 in the lcd
    movlw '1'          
    call sendWriteLCD
    movlw '0'          
    call sendWriteLCD
    movlw '0'          
    call sendWriteLCD
	return
print

    movf decine,W
    addlw .48
    call sendWriteLCD
    movf unita,W
    addlw .48
    call sendWriteLCD
    return
	
   
tecladoON
    movlb 0
    clrf up_down,BANKED
    call clear_hlflags
    call retTMR0
tecladoON_0
    movlw b'11011111'	    ;row2
    movwf TRISB
    btfss PORTB, 2
    call T6
    btfss PORTB, 1
    call T5
    btfss PORTB, 0
    call T4

    movlw B'11101111'	    ;row1
    movwf TRISB
    btfss PORTB, 2
    call T3
    btfss PORTB, 1
    call T2
    btfss PORTB, 0
    call T1
    btfsc flag_end,0,A
	return
    goto tecladoON_0
    
    ; Acciones de teclas
T1		    ; abortir
    call pressCheck
    call retTMR2
    bsf flag_end,0,A
    movlw .41		; doberia ser 41
    movwf attempts
    return
T2		    ; up
    call pressCheck
    call retTMR2
    movf flag_loc,W,A
    addlw 0x00
    bsf WREG,7,A
    call sendConfigLCD
    clrf up_down,BANKED
    return
T3		    ; enter
    bcf T0CON, 7, A
    call pressCheck
    call retTMR2
    bcf flag_again,0,BANKED
    
    call check_double	 ;check whether it has been already matched and cleared
    btfsc flag_again,0,BANKED
	return
    incf flag_pair,BANKED
    call show_card
    call restore_cursor
    call check_pair	;check if 1 or 2 boxes are shown
    movlw .2
    subwf flag_pair,0,BANKED
    btfsc STATUS,2
	call few_intents	
    call no_more_attempts
    call retTMR0
    return
T4		    ; left
    call pressCheck
    call retTMR2
    movlw 0x00
    subwf flag_loc,W
    btfsc STATUS,2,A
	return
    decf flag_loc,F
    movlw b'00010000'
    call sendConfigLCD
    return
T5		    ; down
    call pressCheck
    call retTMR2
    movf flag_loc,W,A
    addlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    bsf up_down,0,BANKED
    return
T6		    ; right 
    call pressCheck
    call retTMR2
    movlw 0x0F
    subwf flag_loc,W
    btfsc STATUS,2,A
	return
    incf flag_loc,F
    movlw b'00010100'
    call sendConfigLCD
    return

no_more_attempts
    movf attempts,0,A
    sublw .41
    btfss STATUS,2
    return
    bsf flag_end,0,A
    bsf flag_end,2,A
    return  
    
attempts_left
    movf attempts,W
    sublw .41
    return
    
few_intents
    clrf flag_pair,BANKED	
    call attempts_left
    sublw .5		;should be 5
    btfss STATUS,2
	return
    call menu_intentos
    call DELAY
    call DELAY
    call restore_game
    call init_cursor
    clrf flag_loc
    clrf up_down
    return

limpiar
    movlw ' '
    call sendWriteLCD
    return
    
restore_game
    movlw b'1'	    ; limpia lcd
    call sendConfigLCD
    movlw 0x00
    bsf WREG,7,A
    call sendConfigLCD
    
    btfss highp_flag1,0,BANKED
	call dibujar
    btfsc highp_flag1,0,BANKED
	call limpiar
    btfss highp_flag1,1,BANKED
	call dibujar
    btfsc highp_flag1,1,BANKED
	call limpiar
    btfss highp_flag1,2,BANKED
	call dibujar
    btfsc highp_flag1,2,BANKED
	call limpiar
    btfss highp_flag1,3,BANKED
	call dibujar
    btfsc highp_flag1,3,BANKED
	call limpiar
    btfss highp_flag1,4,BANKED
	call dibujar
    btfsc highp_flag1,4,BANKED
	call limpiar
    btfss highp_flag1,5,BANKED
	call dibujar
    btfsc highp_flag1,5,BANKED
	call limpiar
    btfss highp_flag1,6,BANKED
	call dibujar
    btfsc highp_flag1,6,BANKED
	call limpiar
    btfss highp_flag1,7,BANKED
	call dibujar
    btfsc highp_flag1,7,BANKED
	call limpiar
    btfss highp_flag2,0,BANKED
	call dibujar
    btfsc highp_flag2,0,BANKED
	call limpiar
    btfss highp_flag2,1,BANKED
	call dibujar
    btfsc highp_flag2,1,BANKED
	call limpiar
    btfss highp_flag2,2,BANKED
	call dibujar
    btfsc highp_flag2,2,BANKED
	call limpiar
    btfss highp_flag2,3,BANKED
	call dibujar
    btfsc highp_flag2,3,BANKED
	call limpiar
    btfss highp_flag2,4,BANKED
	call dibujar
    btfsc highp_flag2,4,BANKED
	call limpiar
    btfss highp_flag2,5,BANKED
	call dibujar
    btfsc highp_flag2,5,BANKED
	call limpiar
    btfss highp_flag2,6,BANKED
	call dibujar
    btfsc highp_flag2,6,BANKED
	call limpiar
    btfss highp_flag2,7,BANKED
	call dibujar
    btfsc highp_flag2,7,BANKED
	call limpiar
    
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD

    btfss lowp_flag1,0,BANKED
	call dibujar
    btfsc lowp_flag1,0,BANKED
	call limpiar
    btfss lowp_flag1,1,BANKED
	call dibujar
    btfsc lowp_flag1,1,BANKED
	call limpiar
    btfss lowp_flag1,2,BANKED
	call dibujar
    btfsc lowp_flag1,2,BANKED
	call limpiar
    btfss lowp_flag1,3,BANKED
	call dibujar
    btfsc lowp_flag1,3,BANKED
	call limpiar
    btfss lowp_flag1,4,BANKED
	call dibujar
    btfsc lowp_flag1,4,BANKED
	call limpiar
    btfss lowp_flag1,5,BANKED
	call dibujar
    btfsc lowp_flag1,5,BANKED
	call limpiar
    btfss lowp_flag1,6,BANKED
	call dibujar
    btfsc lowp_flag1,6,BANKED
	call limpiar
    btfss lowp_flag1,7,BANKED
	call dibujar
    btfsc lowp_flag1,7,BANKED
	call limpiar
    btfss lowp_flag2,0,BANKED
	call dibujar
    btfsc lowp_flag2,0,BANKED
	call limpiar
    btfss lowp_flag2,1,BANKED
	call dibujar
    btfsc lowp_flag2,1,BANKED
	call limpiar
    btfss lowp_flag2,2,BANKED
	call dibujar
    btfsc lowp_flag2,2,BANKED
	call limpiar
    btfss lowp_flag2,3,BANKED
	call dibujar
    btfsc lowp_flag2,3,BANKED
	call limpiar
    btfss lowp_flag2,4,BANKED
	call dibujar
    btfsc lowp_flag2,4,BANKED
	call limpiar
    btfss lowp_flag2,5,BANKED
	call dibujar
    btfsc lowp_flag2,5,BANKED
	call limpiar
    btfss lowp_flag2,6,BANKED
	call dibujar
    btfsc lowp_flag2,6,BANKED
	call limpiar
    btfss lowp_flag2,7,BANKED
	call dibujar
    btfsc lowp_flag2,7,BANKED
	call limpiar
    
    call init_cursor
    return
    
check_double
    movlw .1
    subwf up_down,0,BANKED
    btfss STATUS,2
	goto up_check
    goto down_check
    
up_check
    movlw .0
    subwf flag_loc,0
    btfss STATUS,2
	goto uc1
	    btfss highp_flag1,0,BANKED
		goto u0
	    bsf flag_again,0,BANKED
	    return	
u0  bsf highp_flag1,0,BANKED
    return
uc1 movlw .1
    subwf flag_loc,0
    btfss STATUS,2
	goto uc2
	    btfss highp_flag1,1,BANKED
		goto u1
	    bsf flag_again,0,BANKED
	    return
u1  bsf highp_flag1,1,BANKED
    return
uc2 movlw .2
    subwf flag_loc,0
    btfss STATUS,2
	goto uc3
	    btfss highp_flag1,2,BANKED
		goto u2
	    bsf flag_again,0,BANKED
	    return
u2  bsf highp_flag1,2,BANKED
    return
uc3 movlw .3
    subwf flag_loc,0
    btfss STATUS,2
	goto uc4
	    btfss highp_flag1,3,BANKED
		goto u3
	    bsf flag_again,0,BANKED
	    return
u3  bsf highp_flag1,3,BANKED
    return
uc4 movlw .4
    subwf flag_loc,0
    btfss STATUS,2
	goto uc5
	    btfss highp_flag1,4,BANKED
		goto u4
	    bsf flag_again,0,BANKED
	    return
u4  bsf highp_flag1,4,BANKED
    return
uc5 movlw .5
    subwf flag_loc,0
    btfss STATUS,2
	goto uc6
	    btfss highp_flag1,5,BANKED
		goto u5
	    bsf flag_again,0,BANKED
	    return
u5  bsf highp_flag1,5,BANKED
    return
uc6 movlw .6
    subwf flag_loc,0
    btfss STATUS,2
	goto uc7
	    btfss highp_flag1,6,BANKED
		goto u6
	    bsf flag_again,0,BANKED
	    return
u6  bsf highp_flag1,6,BANKED
    return
uc7 movlw .7
    subwf flag_loc,0
    btfss STATUS,2
	goto uc8
	    btfss highp_flag1,7,BANKED
		goto u7
	    bsf flag_again,0,BANKED
	    return
u7  bsf highp_flag1,7,BANKED
    return
uc8 movlw .8
    subwf flag_loc,0
    btfss STATUS,2
	goto uc9
	    btfss highp_flag2,0,BANKED
		goto u8
	    bsf flag_again,0,BANKED
	    return
u8  bsf highp_flag2,0,BANKED
    return
uc9 movlw .9
    subwf flag_loc,0
    btfss STATUS,2
	goto ucA
	    btfss highp_flag2,1,BANKED
		goto u9
	    bsf flag_again,0,BANKED
	    return
u9  bsf highp_flag2,1,BANKED
    return
ucA movlw .10
    subwf flag_loc,0
    btfss STATUS,2
	goto ucB
	    btfss highp_flag2,2,BANKED
		goto uA
	    bsf flag_again,0,BANKED
	    return
uA  bsf highp_flag2,2,BANKED
    return
ucB movlw .11
    subwf flag_loc,0
    btfss STATUS,2
	goto ucC
	    btfss highp_flag2,3,BANKED
		goto uB
	    bsf flag_again,0,BANKED
	    return
uB  bsf highp_flag2,3,BANKED
    return
ucC movlw .12
    subwf flag_loc,0
    btfss STATUS,2
	goto ucD
	    btfss highp_flag2,4,BANKED
		goto uC
	    bsf flag_again,0,BANKED
	    return
uC  bsf highp_flag2,4,BANKED
    return
ucD movlw .13
    subwf flag_loc,0
    btfss STATUS,2
	goto ucE
	    btfss highp_flag2,5,BANKED
		goto uD
	    bsf flag_again,0,BANKED
	    return
uD  bsf highp_flag2,5,BANKED
    return
ucE movlw .14
    subwf flag_loc,0
    btfss STATUS,2
	goto ucF
	    btfss highp_flag2,6,BANKED
		goto uE
	    bsf flag_again,0,BANKED
	    return
uE  bsf highp_flag2,6,BANKED
    return
ucF movlw .15
    subwf flag_loc,0
    btfss STATUS,2
	return
	    btfss highp_flag2,7,BANKED
		goto uF
	    bsf flag_again,0,BANKED
	    return
uF  bsf highp_flag2,7,BANKED
    return
down_check
    movlw .0
    subwf flag_loc,0
    btfss STATUS,2
	goto dc1
	    btfss lowp_flag1,0,BANKED
		goto d0
	    bsf flag_again,0,BANKED
	    return	
d0  bsf lowp_flag1,0,BANKED
    return
dc1 movlw .1
    subwf flag_loc,0
    btfss STATUS,2
	goto dc2
	    btfss lowp_flag1,1,BANKED
		goto d1
	    bsf flag_again,0,BANKED
	    return
d1  bsf lowp_flag1,1,BANKED
    return
dc2 movlw .2
    subwf flag_loc,0
    btfss STATUS,2
	goto dc3
	    btfss lowp_flag1,2,BANKED
		goto d2
	    bsf flag_again,0,BANKED
	    return
d2  bsf lowp_flag1,2,BANKED
    return
dc3 movlw .3
    subwf flag_loc,0
    btfss STATUS,2
	goto dc4
	    btfss lowp_flag1,3,BANKED
		goto d3
	    bsf flag_again,0,BANKED
	    return
d3  bsf lowp_flag1,3,BANKED
    return
dc4 movlw .4
    subwf flag_loc,0
    btfss STATUS,2
	goto dc5
	    btfss lowp_flag1,4,BANKED
		goto d4
	    bsf flag_again,0,BANKED
	    return
d4  bsf lowp_flag1,4,BANKED
    return
dc5 movlw .5
    subwf flag_loc,0
    btfss STATUS,2
	goto dc6
	    btfss lowp_flag1,5,BANKED
		goto d5
	    bsf flag_again,0,BANKED
	    return
d5  bsf lowp_flag1,5,BANKED
    return
dc6 movlw .6
    subwf flag_loc,0
    btfss STATUS,2
	goto dc7
	    btfss lowp_flag1,6,BANKED
		goto d6
	    bsf flag_again,0,BANKED
	    return
d6  bsf lowp_flag1,6,BANKED
    return
dc7 movlw .7
    subwf flag_loc,0
    btfss STATUS,2
	goto dc8
	    btfss lowp_flag1,7,BANKED
		goto d7
	    bsf flag_again,0,BANKED
	    return
d7  bsf lowp_flag1,7,BANKED
    return
dc8 movlw .8
    subwf flag_loc,0
    btfss STATUS,2
	goto dc9
	    btfss lowp_flag2,0,BANKED
		goto d8
	    bsf flag_again,0,BANKED
	    return
d8  bsf lowp_flag2,0,BANKED
    return
dc9 movlw .9
    subwf flag_loc,0
    btfss STATUS,2
	goto dcA
	    btfss lowp_flag2,1,BANKED
		goto d9
	    bsf flag_again,0,BANKED
	    return
d9  bsf lowp_flag2,1,BANKED
    return
dcA movlw .10
    subwf flag_loc,0
    btfss STATUS,2
	goto dcB
	    btfss lowp_flag2,2,BANKED
		goto d10
	    bsf flag_again,0,BANKED
	    return
d10 bsf lowp_flag2,2,BANKED
    return
dcB movlw .11
    subwf flag_loc,0
    btfss STATUS,2
	goto dcC
	    btfss lowp_flag2,3,BANKED
		goto d11
	    bsf flag_again,0,BANKED
	    return
d11 bsf lowp_flag2,3,BANKED
    return
dcC movlw .12
    subwf flag_loc,0
    btfss STATUS,2
	goto dcD
	    btfss lowp_flag2,4,BANKED
		goto d12
	    bsf flag_again,0,BANKED
	    return
d12 bsf lowp_flag2,4,BANKED
    return
dcD movlw .13
    subwf flag_loc,0
    btfss STATUS,2
	goto dcE
	    btfss lowp_flag2,5,BANKED
		goto d13
	    bsf flag_again,0,BANKED
	    return
d13 bsf lowp_flag2,5,BANKED
    return
dcE movlw .14
    subwf flag_loc,0
    btfss STATUS,2
	goto dcF
	    btfss lowp_flag2,6,BANKED
		goto d14
	    bsf flag_again,0,BANKED
	    return
d14  bsf lowp_flag2,6,BANKED
    return
dcF movlw .15
    subwf flag_loc,0
    btfss STATUS,2
	return
	    btfss lowp_flag2,7,BANKED
		goto d15
	    bsf flag_again,0,BANKED
	    return
d15  bsf lowp_flag2,7,BANKED
    return
    
restore_cursor
    movlw b'10000' 
    call sendConfigLCD
    return
    
clear_hlflags
    clrf high_flag1,BANKED  ; pos 1st card if line up
    clrf high_flag2,BANKED  ; value 1st card if line up
    clrf highp_flag1,BANKED  ; position flag high1
    clrf highp_flag2,BANKED  ; position flag high2
    clrf high_flag3,BANKED  ; pos 2nd card if line up
    clrf high_flag4,BANKED  ; value 2nd card if line up
    clrf low_flag1,BANKED   ; pos 1st card if line down
    clrf low_flag2,BANKED   ; value 1st card if line down
    clrf lowp_flag1,BANKED   ; position flag low1
    clrf lowp_flag2,BANKED   ; position flag low2
    clrf low_flag3,BANKED   ; pos 2st card if line down
    clrf low_flag4,BANKED   ; value 2st card if line down
    clrf flag_used,BANKED   ; 0-up1, 1-down1, 2-up2, 3-down2
    clrf flag_pair,BANKED   ; 1 or 10 incremental
    return
    
check_pair
    call light_off
    movlw .2
    subwf flag_pair,0,BANKED
    btfss STATUS,2
	goto save1
    call save2
    call save_back
    clrf flag_used,BANKED
    return
    
save1
    movlw .1
    subwf up_down,0,BANKED
    btfss STATUS,2
	goto up_match1
    goto down_match1
up_match1
    movff flag_loc,high_flag1
    bsf flag_used,0,BANKED
 
    movlw .0
    subwf flag_loc,0
    btfsc STATUS,2
	movff h1,high_flag2
    movlw .1
    subwf flag_loc,0
    btfsc STATUS,2
	movff h2,high_flag2
    movlw .2
    subwf flag_loc,0
    btfsc STATUS,2
	movff h3,high_flag2
    movlw .3
    subwf flag_loc,0
    btfsc STATUS,2
	movff h4,high_flag2
    movlw .4
    subwf flag_loc,0
    btfsc STATUS,2
	movff h5,high_flag2
    movlw .5
    subwf flag_loc,0
    btfsc STATUS,2
	movff h6,high_flag2
    movlw .6
    subwf flag_loc,0
    btfsc STATUS,2
	movff h7,high_flag2
    movlw .7
    subwf flag_loc,0
    btfsc STATUS,2
	movff h8,high_flag2
    movlw .8
    subwf flag_loc,0
    btfsc STATUS,2
	movff h9,high_flag2
    movlw .9
    subwf flag_loc,0
    btfsc STATUS,2
	movff h10,high_flag2
    movlw .10
    subwf flag_loc,0
    btfsc STATUS,2
	movff h11,high_flag2
    movlw .11
    subwf flag_loc,0
    btfsc STATUS,2
	movff h12,high_flag2
    movlw .12
    subwf flag_loc,0
    btfsc STATUS,2
	movff h13,high_flag2
    movlw .13
    subwf flag_loc,0
    btfsc STATUS,2
	movff h14,high_flag2
    movlw .14
    subwf flag_loc,0
    btfsc STATUS,2
	movff h15,high_flag2
    movlw .15
    subwf flag_loc,0
    btfsc STATUS,2
	movff h16,high_flag2
    return
down_match1
    movff flag_loc,low_flag1
    bsf flag_used,1,BANKED
    
    movlw .0
    subwf flag_loc,0
    btfsc STATUS,2
	movff l1,low_flag2
    movlw .1
    subwf flag_loc,0
    btfsc STATUS,2
	movff l2,low_flag2
    movlw .2
    subwf flag_loc,0
    btfsc STATUS,2
	movff l3,low_flag2
    movlw .3
    subwf flag_loc,0
    btfsc STATUS,2
	movff l4,low_flag2
    movlw .4
    subwf flag_loc,0
    btfsc STATUS,2
	movff l5,low_flag2
    movlw .5
    subwf flag_loc,0
    btfsc STATUS,2
	movff l6,low_flag2
    movlw .6
    subwf flag_loc,0
    btfsc STATUS,2
	movff l7,low_flag2
    movlw .7
    subwf flag_loc,0
    btfsc STATUS,2
	movff l8,low_flag2
    movlw .8
    subwf flag_loc,0
    btfsc STATUS,2
	movff l9,low_flag2
    movlw .9
    subwf flag_loc,0
    btfsc STATUS,2
	movff l10,low_flag2
    movlw .10
    subwf flag_loc,0
    btfsc STATUS,2
	movff l11,low_flag2
    movlw .11
    subwf flag_loc,0
    btfsc STATUS,2
	movff l12,low_flag2
    movlw .12
    subwf flag_loc,0
    btfsc STATUS,2
	movff l13,low_flag2
    movlw .13
    subwf flag_loc,0
    btfsc STATUS,2
	movff l14,low_flag2
    movlw .14
    subwf flag_loc,0
    btfsc STATUS,2
	movff l15,low_flag2
    movlw .15
    subwf flag_loc,0
    btfsc STATUS,2
	movff l16,low_flag2
    return
    
save2			    ;check the matches
    incf attempts
    movlw .1
    subwf up_down,0,BANKED
    btfss STATUS,2
	goto up_match2
    goto down_match2

save_back
    btfsc flag_used,0
	call up1
    btfsc flag_used,1
	call down1
    btfsc flag_used,2
	goto up2
    btfsc flag_used,3
	goto down2

success
    call light_green
    incf count_success,1,BANKED
    
    btfsc flag_used,0
	movf high_flag1,0,BANKED
    btfsc flag_used,1
	movf low_flag1,0,BANKED
    btfsc flag_used,1
	addlw 0x40

    bsf WREG,7,A
    call sendConfigLCD
    movlw ' '
    call sendWriteLCD
	
    btfsc flag_used,2
	movf high_flag3,0,BANKED
    btfsc flag_used,3
	movf low_flag3,0,BANKED
    btfsc flag_used,3
	addlw 0x40
	
    bsf WREG,7,A
    call sendConfigLCD
    movlw ' '
    call sendWriteLCD
    call restore_cursor

    movlw .16
    subwf count_success,0,BANKED
    btfsc STATUS,2
	bsf flag_end,0,A
    return
	
failed
    call light_red
    call DELAY
    
    btfsc flag_used,0
	movf high_flag1,0,BANKED
    btfsc flag_used,1
	movf low_flag1,0,BANKED
    btfsc flag_used,1
	addlw 0x40

    bsf WREG,7,A
    call sendConfigLCD
    call dibujar
	
    btfsc flag_used,2
	movf high_flag3,0,BANKED
    btfsc flag_used,3
	movf low_flag3,0,BANKED
    btfsc flag_used,3
	addlw 0x40
	
    bsf WREG,7,A
    call sendConfigLCD
    call dibujar
    call restore_cursor
    call reinit_posvect	; if failed, it is again possible to show the card
    return
 
reinit_posvect
    clrf flag_updown,BANKED
    btfsc flag_used,0,BANKED
	movf high_flag1,0,BANKED
    btfsc flag_used,1,BANKED
	movf low_flag1,0,BANKED
    btfsc flag_used,1,BANKED
	bsf flag_updown,0,BANKED

    movwf pos_clear,BANKED
    call clear_pos
	
    btfsc flag_used,2,BANKED
	movf high_flag3,0,BANKED
    btfsc flag_used,3,BANKED
	movf low_flag3,0,BANKED
    btfsc flag_used,3,BANKED
	bsf flag_updown,0,BANKED
    
    movwf pos_clear,BANKED
    call clear_pos 
    return
    
clear_pos
    movlw .1
    subwf flag_updown,0,BANKED
    btfss STATUS,2
	goto up_pos
    goto down_pos
up_pos
    movlw .0
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,0,BANKED
    movlw .1
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,1,BANKED
    movlw .2
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,2,BANKED
    movlw .3
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,3,BANKED
    movlw .4
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,4,BANKED
    movlw .5
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,5,BANKED
    movlw .6
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,6,BANKED
    movlw .7
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag1,7,BANKED
    movlw .8
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,0,BANKED
    movlw .9
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,1,BANKED
    movlw .10
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,2,BANKED
    movlw .11
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,3,BANKED
    movlw .12
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,4,BANKED
    movlw .13
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,5,BANKED
    movlw .14
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,6,BANKED
    movlw .15
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf highp_flag2,7,BANKED
    return
down_pos
    movlw .0
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,0,BANKED
    movlw .1
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,1,BANKED
    movlw .2
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,2,BANKED
    movlw .3
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,3,BANKED
    movlw .4
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,4,BANKED
    movlw .5
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,5,BANKED
    movlw .6
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,6,BANKED
    movlw .7
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag1,7,BANKED
    movlw .8
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,0,BANKED
    movlw .9
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,1,BANKED
    movlw .10
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,2,BANKED
    movlw .11
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,3,BANKED
    movlw .12
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,4,BANKED
    movlw .13
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,5,BANKED
    movlw .14
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,6,BANKED
    movlw .15
    subwf pos_clear,0,BANKED
    btfsc STATUS,2
	bcf lowp_flag2,7,BANKED
    return

up1
    movf high_flag2,0,BANKED
    return
    
down1
    movf low_flag2,0,BANKED
    return
    
up2
    subwf high_flag4,0,BANKED
    btfsc STATUS,2
	goto success
    goto failed
    
down2
    subwf low_flag4,0,BANKED
    btfsc STATUS,2
	goto success
    goto failed
        
up_match2
    movff flag_loc,high_flag3
    bsf flag_used,2,BANKED
 
    movlw .0
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h1,high_flag4
    movlw .1
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h2,high_flag4
    movlw .2
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h3,high_flag4
    movlw .3
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h4,high_flag4
    movlw .4
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h5,high_flag4
    movlw .5
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h6,high_flag4
    movlw .6
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h7,high_flag4
    movlw .7
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h8,high_flag4
    movlw .8
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h9,high_flag4
    movlw .9
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h10,high_flag4
    movlw .10
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h11,high_flag4
    movlw .11
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h12,high_flag4
    movlw .12
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h13,high_flag4
    movlw .13
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h14,high_flag4
    movlw .14
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h15,high_flag4
    movlw .15
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h16,high_flag4
    return
down_match2
    movff flag_loc,low_flag3
    bsf flag_used,3,BANKED
    
    movlw .0
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l1,low_flag4
    movlw .1
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l2,low_flag4
    movlw .2
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l3,low_flag4
    movlw .3
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l4,low_flag4
    movlw .4
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l5,low_flag4
    movlw .5
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l6,low_flag4
    movlw .6
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l7,low_flag4
    movlw .7
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l8,low_flag4
    movlw .8
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l9,low_flag4
    movlw .9
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l10,low_flag4
    movlw .10
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l11,low_flag4
    movlw .11
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l12,low_flag4
    movlw .12
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l13,low_flag4
    movlw .13
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l14,low_flag4
    movlw .14
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l15,low_flag4
    movlw .15
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l16,low_flag4
    return

show_card
    movlb 0
    clrf card2show,BANKED
    
    btfss up_down,0,BANKED
	goto show_high
    goto show_low
    
show_low   
    movlw .0
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l1,card2show
    movlw .1
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l2,card2show
    movlw .2
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l3,card2show
    movlw .3
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l4,card2show
    movlw .4
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l5,card2show
    movlw .5
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l6,card2show
    movlw .6
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l7,card2show
    movlw .7
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l8,card2show
    movlw .8
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l9,card2show
    movlw .9
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l10,card2show
    movlw .10
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l11,card2show
    movlw .11
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l12,card2show
    movlw .12
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l13,card2show
    movlw .13
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l14,card2show
    movlw .14
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l15,card2show
    movlw .15
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff l16,card2show
	
    movf card2show,0,BANKED
    call sendWriteLCD
    return
show_high
    movlw .0
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h1,card2show
    movlw .1
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h2,card2show
    movlw .2
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h3,card2show
    movlw .3
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h4,card2show
    movlw .4
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h5,card2show
    movlw .5
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h6,card2show
    movlw .6
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h7,card2show
    movlw .7
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h8,card2show
    movlw .8
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h9,card2show
    movlw .9
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h10,card2show
    movlw .10
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h11,card2show
    movlw .11
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h12,card2show
    movlw .12
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h13,card2show
    movlw .13
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h14,card2show
    movlw .14
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h15,card2show
    movlw .15
    subwf flag_loc,0,BANKED
    btfsc STATUS,2
	movff h16,card2show
    
    movf card2show,0,BANKED
    call sendWriteLCD
    return
    
first_menu
    ; ** set position Line 1
    movlw 0x04
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 'W'
    call sendWriteLCD
    movlw 'e'
    call sendWriteLCD
    movlw 'l'
    call sendWriteLCD
    movlw 'c'
    call sendWriteLCD
    movlw 'o'
    call sendWriteLCD
    movlw 'm'          
    call sendWriteLCD
    movlw 'e'          
    call sendWriteLCD
    movlw '!'          
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x01          
    call sendWriteLCD
    movlw 'P'
    call sendWriteLCD
    movlw 'l'
    call sendWriteLCD
    movlw 'a'
    call sendWriteLCD
    movlw 'y'
    call sendWriteLCD
    ; ** set position Line 2
    movlw 0x49
    bsf WREG,7,A
    call sendConfigLCD
    ; send text
    movlw 0x00 
    call sendWriteLCD
    movlw 'S'          
    call sendWriteLCD
    movlw 'c'          
    call sendWriteLCD
    movlw 'o'          
    call sendWriteLCD
    movlw 'r'          
    call sendWriteLCD
    movlw 'e'          
    call sendWriteLCD
    movlw 's'          
    call sendWriteLCD

    ;	Enable cursor
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    movlw b'110'
    call sendConfigLCD
    clrf flag_pos,A    ;limpia bandera de teclas
    bsf flag_pos,0,A
    call light_green
    return
    ;	Routina de movemiento
    
teclado_first
    movlw B'11011111'	    ;row2
    movwf TRISB
    btfss PORTB, 0
    call Ti4
    btfss PORTB, 2
    call Ti6
    
    movlw b'11101111'	    ;row1
    movwf TRISB
    btfss PORTB, 2
    call Ti3
    btfsc flag_pos,2,A
	return
    goto teclado_first
    
teclado_second  
    movlw b'11101111'	    ;row1
    movwf TRISB
    btfss PORTB, 2
    call Ti3
    btfsc flag_pos,2,A
	return
    goto teclado_second
      ; First menu teclas
Cur_on
    call retTMR2    ; Start-up time, funcionamento antes que recibir el comando
    movlw b'00111000'
    call sendConfigLCD
    ;	    Entry mode: cursor derecha, no display shift (RS=RW=0, data = b?00000110?)
    movlw b'110'
    call sendConfigLCD
    ;	    Display control: Display on, cursor and blink on (RS=RW=0, data = b?00001111?)
    movlw b'1111'
    call sendConfigLCD
    ;	    Clear display (RS=RW=0, data = b?00000001?)
    movlw b'1'
    call sendConfigLCD
    return
    
Ti3			;enter
    call retTMR2
    call pressCheck
    call light_off
	btfsc flag_pos, 0
	    bsf flag_pos,2,A
	btfsc flag_pos, 1
	    bsf flag_pos,2,A
	return
Ti4
    call retTMR2
    call pressCheck
    clrf flag_pos,A    ;limpia bandera de teclas   || left
    bsf flag_pos,0,A
    movlw 0x40
    bsf WREG,7,A
    call sendConfigLCD
    call light_off
    call light_green
    return
Ti6
    call retTMR2
    call pressCheck
    clrf flag_pos,A    ;limpia bandera de teclas    || right
    bsf flag_pos,1,A
    movlw 0x49
    bsf WREG,7,A
    call sendConfigLCD
    call light_off
    call light_red
    return

light_green
    movlw b'1'
    movwf LATA,A
    return
    
light_red 
    movlw b'10'
    movwf LATA,A
    return
light_off
    clrf LATA
    return
    
pressCheck
    btfss PORTB,2
	goto pressCheck
    btfss PORTB,1
	goto pressCheck
    btfss PORTB,0
	goto pressCheck
    return
    
killGame
    bsf flag_end,0
    bsf flag_end,1 ; no more time
    bcf INTCON, 2, A
    retfie
    
    ; --- timers delays	
	    ; timer 0 the 7 secs timer
	    ; timer 1 random number input
	    ; timer 2 the general purpose 30 ms timer
	    ; timer 3 general advisories
longdelay
    clrf w1
    bsf w1,1
    call retTMR0
l_0 btfss w1,0
    goto l_0
    bcf T0CON, 7, A	; stop TMR0
    bcf w1,1
    return

retTMR0			; 7000000 cycles, with interrupt
    bcf T0CON, 7, A
    movlw b'00101010'
    movwf TMR0H, A
    movlw b'01100000'	
    movwf TMR0L, A
    bcf INTCON, 2, A
    bsf T0CON, 7, A
    return
restartTMR0
    bcf T0CON, 7, A
    movlw b'00101010'
    movwf TMR0H, A
    movlw b'01100000'	
    movwf TMR0L, A
    bcf INTCON, 2, A
    bsf w1,0
    retfie
TMR0overflow
    btfss w1,1
	goto killGame
	goto restartTMR0
    
retTMR1			  ;count the on time
    bcf PIR1, 0, A
    bsf T1CON, 0, A
    return
    
retTMR2			; 30000 cycles
    bcf PIR1, 1, A
    bsf T2CON, 2, A
loopTMR2
    btfss PIR1,1,A
	goto loopTMR2
	bcf PIR1,1,A
	return	

    ; --- LCD: Send configuration
sendConfigLCD    
    bcf RS
    bcf RW
    bsf E
    movwf dataLCD
    nop
    bcf E
    call retTMR2
    return    
    
    ; --- LCD: Send write
sendWriteLCD    
    bsf RS
    bcf RW
    bsf E
    movwf dataLCD
    nop
    bcf E
    call retTMR2
    return  
    
    ; --- subrutinas de delay
DELAY	movlb 0
	movlw	X1	
	movwf	MEM1,BANKED
DELAY1	incf	MEM1,F,BANKED    ;outern loop 
	btfsc	STATUS,2
	return
	movlw	X2
	movwf	MEM2,BANKED
DELAY2	incf	MEM2,F,BANKED    ;middle loop
	btfsc	STATUS,2
	goto	DELAY1
	movlw	X3
	movwf	MEM3,BANKED
DELAY3	incf	MEM3,F,BANKED    ;inner loop
	btfss	STATUS,2
	goto	DELAY3
	goto	DELAY2

    end



