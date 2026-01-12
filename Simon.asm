
                    ORG $4000

;Key press Constants
PIAKeys             EQU $FF00  
Y_KeyPress1         EQU $FD
Y_KeyPress2         EQU $20
B_KeyPress1         EQU $FB
B_KeyPress2         EQU $04
R_KeyPress1         EQU $FB
R_KeyPress2         EQU $10
G_KeyPress1         EQU $7F
G_KeyPress2         EQU $04
Q_KeyPress1         EQU $FD
Q_KeyPress2         EQU $10
Z_KeyPress1         EQU $FB
Z_KeyPress2         EQU $20
O_KeyPress1         EQU $7F
O_KeyPress2         EQU $08
M_KeyPress1         EQU $DF
M_KeyPress2         EQU $08
BreakKeyPress1      EQU $FB
BreakKeyPress2      EQU $40

PressCorrect        EQU $01
PressIncorrect      EQU $00

;Flash delay for SIMON Text
SimonFlashDelay     EQU $0FFF           

;Sound tone constants
YellowTone          EQU $1F
YellowToneDuration  EQU $68
BlueTone            EQU $3F
BlueToneDuration    EQU $78
RedTone             EQU $5F
RedToneDuration     EQU $90
GreenTone           EQU $7F
GreenToneDuration   EQU $B0
ErrorTone           EQU $01

YellowColour        EQU $00                 
BlueColour          EQU $01
RedColour           EQU $02
GreenColour         EQU $03

                ;Initialise Screen
START           JSR    InitialiseScreen
 
                ;Draw Introduction Message Border
                LEAY   IntroMsgBorder,PCR
                JSR    DrawBox
                
                ;Write Intro message
                LEAY   IntroText,PCR
                JSR    ShowText

                ;Wait for key press
IntroMsgWait    JSR    $8006                      
                BEQ    IntroMsgWait

                ;Initialise screen - again
Initialise      JSR    InitialiseScreen
        
                ;Draw simon text
                JSR    DrawSimonText
        
                ;Show main menu
ShowMenu        LEAY   MenuText,PCR
                JSR    ShowText
         
                LDA    #$00
                STA    QuitCheck
         
                ;***********
                ;Act on menu
                ;***********
Menu            JSR    SimonColScroll       ;Scroll SIMON Colours
                JSR    $8006
                BEQ    Menu
                CMPA   #03                  ;Break - QUIT
                LBEQ   QuitGame
                CMPA   #78                  ;'N' - New Game
                BEQ    NewGame
                CMPA   #82                  ;'R' - Replay game
                BEQ    PlayGame
                CMPA   #83                  ;'S' - Show last game
                BNE    Menu
                JSR    ClearMenu
                JSR    ShowLastGame
                JMP    ShowMenu
 
                ;***********************************
                ;New Game - clear previous game data
                ;***********************************
NewGame         LDX    #GameData            ;Location of game data
                LDA    #$00
                LDB    #$00                 ;ReSet GoesCount to 0
                STB    GoesCount
                STB    PressCount
                STD    ScoreToDisp

                ;Get Next Number
GetNextColour   JSR    $978E                ;Generate Random Number
                LDA    $0116                ;Get the random number 
                LDB    #4                   ;Make sure it is between 1 and 4
                MUL                         ;Random number in 'A' register
                LDX    #GameData                
                LDB    GoesCount            ;Get current number of goes;
                LEAX   B,X                  ;Get next "go" position
                STA    ,X                   ;Store the next go
                INCB                        ;Add 1 to GoesCount
                STB    GoesCount            ;And Store
                JSR    AddShowGoesCount
                
PlayGame        JSR    ShowGoesCount
                JSR    ShowLastGame
                JSR    PlayerRepeat
                
                ;If player press Q during game, then JMP MENU
                LDA    QuitCheck
                BNE    Initialise
                
                ;Was player incorrect?
                LDA    GoCheck
                BEQ    Initialise           ;Yes - reset game
                
                ;Player correct - continue
                JMP    GetNextColour

                ;**********************************
                ;Show last Game Sequence of colours
                ;**********************************
ShowLastGame    LDX   #GameData                 ;Point to first colour in sequence     
                LDB   GoesCount                 ;Get number of goes to repeat
SLastGame1      DECB
                BMI   SLastGameExit             ;Minus - we've finished -exit
                LDA   ,X+                       ;Get the colour to display
                STA   CellOffset                ;Store in temp workspace
                
                PSHS  B
                JSR   SetCellData
                PULS  B

ShowCell        PSHS   X,Y,A,B                  ;TODO no need to push Y ? Or A
                LDY    CellToDisplay   
                JSR    DrawBox 
                JSR    PlayContSound
                LDY    BorderToDisplay
                JSR    DrawBox 
                LDY    #$9FFF
                JSR    Delay
                PULS   X,Y,A,B          
                JMP    SLastGame1
SLastGameExit   RTS             
        
                ;***********************
                ;Player Repeats sequence
                ;***********************
PlayerRepeat    LDA    #0                       ;Reset press count 
                STA    PressCount

PRepeat2        LDB    KeyMapCount              ;Number of different keys to check                     
                LDU    #KeyMap                  ;map keys to colours

                ;Loop through key map and check if key pressed
PRepeat1        LDX    #PIAKeys

                LDA    ,U+                      ;Point to current key press to check
                STA    CellOffset               ;Colour of current keypress            
                LDA    ,U+                      ;Get PIA Keyboard data
                STA    2,X                      ;Mask PIA
                STA    KeyPressTemp2            ;Store for later use (Press release)
                LDA    ,U+                      ;Get PIA keyboad Data
                STA    KeyPressTemp1            ;Store for later use (Press release)
                LDA    ,X                       ;Get current column value for PIA
                ANDA   KeyPressTemp1
                BEQ    KeyPressed               ;Key has been pressed
                DECB                            ;No key pressed, next keymap entry
                BNE    PRepeat1         
                JMP    PRepeat2                 ;Keymap scnanned - reset and restart

KeyPressed      LDA    CellOffset               ;Should be the colour pressed (0,1,2,3 4-Quit)
                CMPA   #$03                     ;0-3 
                BLS    PRepeat3                 ;No - show colour that was pressed
                LDA    #$01                     ;Tell Main control that Break was pressed
                STA    QuitCheck                
                JMP    KEYEND

PRepeat3        JSR    SetCellData              ;Set cell data for cell drawing routine

                LDY    CellToDisplay            ;Set Y to block data start location
                JSR    DrawBox                  ;Draw box
                LDA    ToneToPlay               ;Set sound tone

                PSHS   A,B,X,Y                  ;Check if key press was correct - load error tone instead
                LDB    CellOffset
                JSR    CheckPlayerPress         ;
                PULS   A,B,X,Y
                
                JSR    PressRelease             ;check that key is released
                LDY    BorderToDisplay          ;Point to border
                JSR    DrawBox                  ;Undraw the block - replace with border
                JMP    CheckPlayerFinished
    
                ;******************************************
                ;Have we finished the current GO sequence ?
                ;******************************************
CheckPlayerFinished
                LDA    GoCheck                  ;0=Incorrect, 1=Correct
                BEQ    KEYEND                   ;Player made a mistake - exit 
                LDA    PressCount               ;Get number of presses player has made
                INCA                            ;Increase it
                STA    PressCount
                CMPA   GoesCount                ;Compare to number of colours repeated
                LBNE   PRepeat2                 ;Player still has presses to make
        
KEYEND          LDY    #$EFFF                   ;YES - key sequence finished - no mistakes
                JSR    Delay                    ;Pause before next sequence played
                RTS                             ;Goes back to PlayGame loop

                ;Check if key released
PressRelease    LDB    KeyPressTemp2
                STB    2,X                      ;TODO get B from KeyPressTemp2 and change to A
PressRelease1   JSR    PlaySound                ;Play sound while key is pressed
                LDA    ,X
                ANDA   KeyPressTemp1
                BEQ    PressRelease1            ;Key is still pressed
                RTS

                ;**************************************
                ;Check if players key press was correct
                ;**************************************
CheckPlayerPress
                LDX    #GameData                ;Point to current game sequence
                LDA    PressCount               ;Get the press count in sequence
                LEAX   A,X                      ;point to colour
                LDA    ,X                       ;get it
                STA    CurrentColour
                CMPB   CurrentColour            ;Reg 'B' = colour pressed
                BEQ    SetCorrect               ;Press is correct
                LDA    PressIncorrect           ;Press was incorrect
                STA    GoCheck                  ;Let main routine know incorrect press
                LDA    #ErrorTone               ;Override tone of colour pressed
                STA    ToneToPlay
                JMP    CPPressExit
SetCorrect      LDA    PressCorrect
                STA    GoCheck
CPPressExit     RTS

SetCellData     LEAU  CellTable,PCR             ;First cell data
                LDA   CellOffset,PCR            ;Get offset

                LDB   #$07                      ;There are seven data items
                MUL
                LEAU  B,U   
                                
                LDD   ,U++                      ;Get location for cell data and store
                STD   CellToDisplay
                LDD   ,U++                      ;Get location for cell data and store
                STD   BorderToDisplay
                LDA   ,U+                       ;Get location for Sound data and store
                STA   ToneToPlay                
                LDD   ,U                        ;Get location for Sound durection data and store
                STD   ToneDuration

                RTS

                ;************************
                ; Play sound for 1 second
                ;************************
PlayContSound   LDY   ToneDuration
PCSound1        JSR   PlaySound
                LEAY  -1,Y
                BNE   PCSound1
                RTS

                ;**************
                ; SOUND ROUTINE
                ;**************
PlaySound       LDA   $FF03
                ORA   #$01
                STA   $FF03

                BSR   SoundOn

                BSR   PlaySound1

                BSR   PlaySound21
                LDA   #$FC
                BSR   PlaySound23
                BSR   PlaySound21
                LDA   #$00
                BSR   PlaySound23

                BSR   SoundOff
                RTS
           
PlaySound21     LDA   #$7E
PlaySound23     STA   $FF20
                LDA   ToneToPlay
PlaySound22     INCA
                BNE   PlaySound22
                RTS
            
PlaySound1      LDU   #$FF01
                BSR   PlaySound2
PlaySound2      LDA   ,U
                ANDA  #$F7
PlaySound3      STA   ,U++
                RTS
            
SoundOn         PSHS  D,U
                LDB   $FF23
                ORB   #$08
                STB   $FF23
                PULS  D,U,PC
            
SoundOff        PSHS  A
                LDA   $FF23
                ANDA  #$F7
                STA   $FF23
                PULS  A,PC          

                ;*****************
                ;Initialise Screen
                ;*****************
InitialiseScreen  
                LDX   #$0400                    ;Clear Screen      
                LDA   #128
IScreen1        STA   ,X+
                CMPX  #$0600
                BLE   IScreen1

                ;Draw empty boxes 
                LDY   #YellowBorder             
                JSR   DrawBox
                LDY   #BlueBorder
                JSR   DrawBox
                LDY   #RedBorder
                JSR   DrawBox
                LDY   #GreenBorder
                JSR   DrawBox
                RTS

ClearMenu       LDY   #ClearMenuData            ;Set Y to Clear block data start location
                JSR   DrawBox                   ;Draw empty box 
                RTS

                ;*******************************
                ;Show text pointed at by Reg 'Y'
                ;*******************************
ShowText        LDX    ,Y++                     ;Get Write location
                LDB    ,Y+                      ;Get Num Columns
                LDA    ,Y+                      ;Get Num Rows
                PSHS   X,B,A                    ;Store values
ShowText2       LDA    ,Y+                      ;Get Character to write
                ANDA   #$BF                     ;Tidy it up
                STA    ,X+                      ;write screen
                DECB                            ;Decrease column written count
                BNE    ShowText2                ;Not finished
                PULS   X,B,A                    ;Get Original Values
                DECA                            ;Decrease number of rows written count
                BEQ    ShowTextExit             ;Finished
                LEAX   32,X                     ;Go down next row
                PSHS   X,B,A                    ;Save updated values
                BRA    ShowText2                ;Next row
ShowTextExit    RTS
                
                ;**********************************************
                ;Delay after displaying colours during playback
                ;**********************************************
Delay           LEAY -1,Y
                BNE Delay
                RTS

                ;*****************************************************************
                ;Draw the selected pattern on screen - data location in Y register 
                ;*****************************************************************
DrawBox         PSHS   X,A,B
                LDX    ,Y++                     ;Get location on screen where data to be written
                CLRA
                STA    DBColDrawnTot            ;Reset number of columns drawn
 
DBNewBlock      LDA    ,Y+                      ;Get Number of times the next data block is to be written to screen
                CMPA   #99                      ;is it 99?
                BEQ    DrawBoxExit              ;Yes - reached end of data stream - exit
                STA    DBBlockRepCnt  
                LDA    ,Y+                      ;Get number of input lines for block
                STA    DBInputLineCnt             ;Store it in line counter
                STA    DBInputLineTot           ;Store it in Line Total
                LDA    ,Y+                      ;Get offset from starting position
                LEAX   A,X                      ;repoint
 
NewInputLine    LDA    ,Y+                      ;Get character to write to screen
                LDB    ,Y+                      ;Get number of times character to be written (for this input line)
                STB    DBColDrawnCnt            ;Store it
                
                LDB    DBColDrawnTot            ;Get the column count for current input block
                ADDB   DBColDrawnCnt            ;Add number of columns drawn for current input line
                STB    DBColDrawnTot            ;And store

                LDB    DBColDrawnCnt            ;Get the number of times it is to be written
DrawChar        STA    ,X+                      ;write character to screen
                DECB                
                BNE    DrawChar
 
                LDA    DBInputLineCnt             ;Get the number of input lines (in this block)
                DECA                
                STA    DBInputLineCnt
                BNE    NewInputLine             ;More lines to read - go and get it and draw
 
                ;No more input lines for block - reset screen draw point
                LDA    #32                      
                SUBA   DBColDrawnTot            ;Offset from number of columns already drawn
                LEAX   A,X
 
                CLRA                            ;Reset number of columns drawn
                STA    DBColDrawnTot   
 
                ;Do we need to repeat drawing the data block?
                LDA    DBBlockRepCnt      
                DECA
                STA    DBBlockRepCnt
                BEQ    DBNewBlock               ;New data block to be drawn
 
                ;Repeat the data block
                LDA    DBInputLineTot           ;Get the total number of input lines for the block
                STA    DBInputLineCnt           ;Reset the number of input lines that are to be read
                LDB    #$02                     ;There are two parameters per input line
                MUL                 
                DECB
                COMB
                LEAY   B,Y                      ;Reset input line point back to start of block
                BRA    NewInputLine             ;redraw the 1st input line and block
 
DrawBoxExit     PULS   X,A,B
                RTS

                ;*****************************
                ;Scroll the SIMON text colours
                ;*****************************
SimonColScroll  LDY    SimonFlashCounter        ;Get current flash counter
                LEAY   -1,Y                     ;Sub 1
                STY    SimonFlashCounter        ;and re-store
                BNE    SCSExit                  ;If not ZERO then exit
                JSR    DrawSimonText            ;It is zero, so redraw simon text
                LDY    #SimonFlashDelay         ;Get flash delay counter
                STY    SimonFlashCounter        ;And reset 
                JSR    $978E                    ;Randomise colour selection a bit
SCSExit         RTS     

                ;*************************
                ;Draw Simon text on screen
                ;*************************
DrawSimonText   LDX    SimonData                ;Get screen location 
                LDY    #SimonData+2             ;Point Y register to data
DrawSimon1      LDA    ,Y+                      ;Get character to draw on screen
                CMPA   #0                       ;If ZERO - End of data stream, reset colour offset data
                BEQ    DSResetColour
                CMPA   #99                      ;If 99 - End of line on screen
                BEQ    DSNewLine                ;Reset screen drawing position
                LDB    ,Y+                      ;get colour offset for current character
                PSHS   A,Y        
                LDY    #COLOUR                  ;point to current colour data
                LEAY   B,Y                      ;reposition Y to colour offset to use
                LDB    ,Y                       ;get colour offset
                LDA    #16                      ;Increase character to write by colour offset
                MUL
                STB    DSTempOffSet             ;Store temporarily 
                PULS   A,Y                
                ADDA   DSTempOffSet             ;Add offset value to character
                STA    ,X+                      ;Write character to screen  
                JMP    DrawSimon1               ;Repeat
DSNewLine       LEAX   20,X
                JMP    DrawSimon1

DSResetColour   LDB    #5                       ;There are 5 colour data items to update
                LDY    #COLOUR                  ;Point to colour data
DrawSimon3      LDA    ,Y                       ;Get coour data
                DECA                            ;Reduce it by 1
                CMPA   #$FF                     ;Was it zero?
                BNE    DrawSimon2               ;No
                LDA    #$07                     ;Yes - set it to 7 (0-7 - 8 colours available)
DrawSimon2      STA    ,Y+                      ;Store it
                DECB                    
                BNE    DrawSimon3               ;Still more colour data items to check
DrawSimonExit   RTS

                ;****************************
                ;Display Score\Goes on Screen
                ;****************************
AddShowGoesCount
                LDX   #ScoreToDisp     
                LEAX  1,X
DSCR3           LDA   ,X                ;Get the Number
                INCA                    ;Increase the score
                STA   ,X                ;And store it
                CMPA  #$0A              ;Has it got to 10? 
                BCS   DSCR1             ;No
                CLRA                    ;Yes - clear it to ZERO
                CLR   ,X                ;Reset current number to ZERO 
                LEAX  -1,X              ;Get next significant number
                BRA   DSCR3             ;Repeat
DSCR1           RTS

ShowGoesCount   JSR   ClearMenu
                LDY   #$0510
                LDX   #ScoreToDisp
                LEAX  1,X
DSCR4           LDA   ,X                ;Get the score number
                BSR   DrawGoes          ;Draw it on screen
                CMPX  #ScoreToDisp      ;Have we finished draw num
                BEQ   ShowGoesExit      ;Yes - Exit
                LEAX  -1,X              ;No - move next sig score number
                LEAY  -99,Y             ;Reposition drawing point
                BRA   DSCR4
ShowGoesExit    RTS

DrawGoes        PSHS  A,B,X,U
                LDB   #Length           ;Get number of data items for each number to draw       
                MUL                 
                LEAU  Numbers,PCR       ;Point to number data
                LEAU  D,U
                LDB   #$03              ;Three rows high
DrawGoes1       LDA   ,U+               ;Get number data
                STA   ,Y+               ;Write to screen
                LDA   ,U+               
                STA   ,Y
                LEAY  31,Y              ;Reset writing location
                DECB                    ;Decrease row count
                BNE   DrawGoes1         ;Not finished
                PULS  A,B,X,U,PC

;Score to display data
Length          EQU   6                 ;Number of chars per digit to display
ScoreToDisp     FCB   $00,$05           ;Score to display
 
                ;Quit Game
QuitGame        JSR  $B3B4              ;Reset system  
                RTS                     ;Exit

;Map colour to PIA Key values used during game play
KeyMapCount     FCB   $09
KeyMap          FCB   YellowColour, Y_KeyPress1, Y_KeyPress2
                FCB   BlueColour, B_KeyPress1, B_KeyPress2
                FCB   RedColour, R_KeyPress1, R_KeyPress2
                FCB   GreenColour, G_KeyPress1, G_KeyPress2
                FCB   YellowColour, Z_KeyPress1, Z_KeyPress2
                FCB   BlueColour, M_KeyPress1, M_KeyPress2
                FCB   RedColour, O_KeyPress1, O_KeyPress2
                FCB   GreenColour, Q_KeyPress1, Q_KeyPress2
                FCB   $99, BreakKeyPress1, BreakKeyPress2

;Sound temporary Data
ToneToPlay      FCB   $00                 ;Sound tone to play
ToneDuration    FDB   $00

;Temporary key press data
KeyPressTemp1   FCB   $00                 ;Register which key is pressed during game
KeyPressTemp2   FCB   $00

;"Simon" Text temporary data
SimonFlashCounter   FDB SimonFlashDelay

;Draw Box temporary data
DBColDrawnCnt   FCB   0                 ;Running total of columns drawn
DBColDrawnTot   FCB   0                 ;So we can reset draw position
DBInputLineCnt  FCB   0                 ;Running total of inp[ut lines read
DBInputLineTot  FCB   0                 ;Total number of input lines per block, so we can reset data pointer
DBBlockRepCnt   FCB   0                 ;Number of times current block has been used

;Cell drawing temporary data
CellOffset      FCB   $0
CellToDisplay   FDB   $0000
BorderToDisplay FDB   $0000

;Will assemble with memory location of cell data items
CellTable       FDB   YellowCell        ;0
                FDB   YellowBorder
                FCB   YellowTone
                FDB   YellowToneDuration
                FDB   BlueCell          ;1
                FDB   BlueBorder
                FCB   BlueTone   
                FDB   BlueToneDuration
                FDB   RedCell           ;2
                FDB   RedBorder
                FCB   RedTone
                FDB   RedToneDuration
                FDB   GreenCell         ;3
                FDB   GreenBorder
                FCB   GreenTone
                FDB   GreenToneDuration

;Cell data 
GreenCell       FDB 1024            ;Position on screen where data to be written
                FCB 4,1,0           ;repeat next data block 4 times, 1 input line in block, offset from start location
                FCB 143,16          ;CHR(143), 16 columns across
                FCB 4,1,0           ;repeat next data block 4 times, 1 input line in block, offset from start location
                FCB 143,9           ;CHR(143), 9 columns across
                FCB 99              ;End of cell
GreenBorder     FDB 1024            ;Position on screen where data to be written
                FCB 1,3,0           ;repeat next data block 1 time, 3 input lines in block, offset from start location
                FCB 142,1
                FCB 140,14
                FCB 141,1
                FCB 2,3,0           ;repeat next data block 3 times, 3 input lines, no offset
                FCB 138,1       
                FCB 128,14
                FCB 133,1
                FCB 1,5,0
                FCB 138,1
                FCB 128,7
                FCB 129,1
                FCB 131,6
                FCB 135,1
                FCB 3,3,0
                FCB 138,1
                FCB 128,7
                FCB 133,1
                FCB 1,3,0
                FCB 139,1
                FCB 131,7
                FCB 135,1
                FCB 99

RedCell         FDB 1040
                FCB 4,1,0
                FCB 191,16
                FCB 4,1,7
                FCB 191,9
                FCB 99
RedBorder       FDB 1040
                FCB 1,3,0
                FCB 190,1
                FCB 188,14
                FCB 189,1
                FCB 2,3,0
                FCB 186,1
                FCB 128,14
                FCB 181,1
                FCB 1,5,0
                FCB 187,1
                FCB 179,6
                FCB 178,1
                FCB 128,7
                FCB 181,1
                FCB 3,3,7
                FCB 186,1
                FCB 128,7
                FCB 181,1
                FCB 1,3,0
                FCB 187,1
                FCB 179,7
                FCB 183,1
                FCB 99

BlueCell        FDB 1296
                FCB 4,1,7
                FCB 175,9
                FCB 4,1,-7
                FCB 175,16
                FCB 99
BlueBorder      FDB 1296
                FCB 1,3,7
                FCB 174,1
                FCB 172,7
                FCB 173,1
                FCB 3,3,0
                FCB 170,1
                FCB 128,7
                FCB 165,1
                FCB 1,5,-7
                FCB 174,1
                FCB 172,6
                FCB 168,1
                FCB 128,7
                FCB 165,1
                FCB 2,3,0
                FCB 170,1
                FCB 128,14
                FCB 165,1
                FCB 1,3,0
                FCB 171,1
                FCB 163,14
                FCB 167,1
                FCB 99

YellowCell      FDB 1280
                FCB 4,1,0
                FCB 159,9
                FCB 4,1,0
                FCB 159,16
                FCB 99
YellowBorder    FDB 1280
                FCB 1,3,0
                FCB 158,1
                FCB 156,7
                FCB 157,1
                FCB 3,3,0
                FCB 154,1
                FCB 128,7
                FCB 149,1
                FCB 1,5,0
                FCB 154,1
                FCB 128,7
                FCB 148,1
                FCB 156,6
                FCB 157,1
                FCB 2,3,0
                FCB 154,1
                FCB 128,14
                FCB 149,1
                FCB 1,3,0
                FCB 155,1
                FCB 147,14
                FCB 151,1
                FCB 99
 
IntroMsgBorder  FDB 1058
                FCB 1,3,0
                FCB 206,1
                FCB 204,26
                FCB 205,1
                FCB 12,3,0
                FCB 202,1
                FCB 128,26
                FCB 197,1
                FCB 1,3,0
                FCB 203,1
                FCB 195,26
                FCB 199,1
                FCB 99
 
ClearMenuData   FDB 1289        ;Start Position
                FCB 3,1,1       ;Repeat 3 rows, 1 set of data, offset
                FCB 128,12      ;Character To Draw for 12 columns
                FCB 99

;Data for SIMON text 
DSTempOffSet    FCB 0           ;Used to change colours of simon text
SimonData       FDB 1162        ;Position on screen where data to be written
                FCB 131,0       ;First line - character and colour code (offset)
                FCB 131,0
                FCB 130,0
                FCB 130,1
                FCB 131,2
                FCB 131,2
                FCB 130,2
                FCB 131,3
                FCB 131,3
                FCB 129,4
                FCB 131,4
                FCB 130,4,99    ;Character, colour code, end of line
                FCB 139,0       ;Second line
                FCB 131,0
                FCB 130,0
                FCB 138,1
                FCB 138,2
                FCB 138,2
                FCB 138,2
                FCB 138,3
                FCB 133,3
                FCB 133,4
                FCB 128,4
                FCB 138,4,99
                FCB 131,0       ;Third line
                FCB 131,0
                FCB 138,0
                FCB 138,1
                FCB 138,2
                FCB 128,2
                FCB 138,2
                FCB 139,3
                FCB 135,3
                FCB 133,4
                FCB 128,4
                FCB 138,4,99
                FCB 0           ;End of input

;Colour code for simon text
COLOUR          FCB 1
                FCB 2
                FCB 3
                FCB 4
                FCB 5

IntroText       FDB $0443                           ;Position on screen
                FCB $1A, $0C                        ;Number of columns, Number of rows
                FCB "REPEAT THE RANDOM SEQUENCE"
                FCB "  OF COLOURS BY PRESSING  "
                FCB "                          "
                FCB "     (G)REEN   (R)ED      "
                FCB "     (Y)ELLOW  (B)LUE     "
                FCB "            OR            "
                FCB "    (Q)GREEN   (O)RED     "
                FCB "    (Z)YELLOW  (M)BLUE    "
                FCB "                          "
                FCB "      BREAK TO QUIT       "
                FCB "                          "
                FCB "  PRESS ANY KEY TO START  "

MenuText        FDB $050A
                FCB $0C, $03
                FCB "N: NEW GAME "
                FCB "S: SHOW LAST"
                FCB "R: REPLAY   "

;On screen score text data - 2 wide, 3 high
Numbers         FCB 206,205         ;Zero
                FCB 202,197
                FCB 204,204
                FCB 192,202         ;1
                FCB 192,202
                FCB 192,200
                FCB 204,205         ;2
                FCB 206,204
                FCB 204,204
                FCB 204,205         ;3
                FCB 196,205
                FCB 204,204
                FCB 202,192         ;4
                FCB 203,203
                FCB 192,200
                FCB 206,204         ;5
                FCB 204,205
                FCB 204,204
                FCB 202,192         ;6
                FCB 206,205
                FCB 204,204
                FCB 204,205         ;7
                FCB 193,200
                FCB 200,192
                FCB 206,205         ;8
                FCB 206,205
                FCB 204,204
                FCB 206,205         ;9
                FCB 204,205
                FCB 192,196
        
                ;Data of game play
QuitCheck       FCB 0               ;0 = No, 1=Yes
GoCheck         FCB 0               ;0 = incorrect, 1 = Correct             
CurrentColour   FCB 0           	;Used to compare players press with colour
PressCount      FCB 0               ;Number of presses player has made
GoesCount       FCB 5               ;Number of goes in play 
GameData        FCB YellowColour    ;Current game plays - preset game
                FCB BlueColour           
                FCB RedColour           
                FCB GreenColour           
                FCB YellowColour
 
