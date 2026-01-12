This is a 6809 assembly language game for the Dragon 32 that challenges you to repeat random sequences of light by selecting the coloured cells in the correct order.

| File | Description |
| --- | --- |
| build.bat |  A windows batch file to assemble and run the program file.<br> 1.  Set the path to asm6809 and XROAR (change as required) <br>  2.  Assemble the code file using asm6809 <br> 3.  Run the resulting Simon.bin file in XROAR |
| Simon.asm | The assembly code file |
| Simon.cas | The assembled game file. |

Please note, asm6809 and XROAR(and associated ROMS) are not included, but can be downloaded from the following locations: 
https://www.6809.org.uk/xroar/ <br> https://www.6809.org.uk/asm6809/

To run the game without assembling the code file:
+ Download Simon.cas to your device
+ Open a browser and paste the following URL:  https://www.6809.org.uk/xroar/online/
+ Under the emulation screen, click the File tab
+ Click the load button, and select the downloaded Simon.cas
+ In the emulation screen, type the following: CLOADM:EXEC   <press enter>
                
In order for this game to run on the Tandy Color Computer, the following ROM sub-routines will need to be amended....

| Dragon 32 | Co-Co | Description |
| --- | --- | --- |
| $8006 (32774) | $A1C1 (41409) | POLCAT: scans keyboard and puts the character in A Register  |
| $978E (38798) | $BF1F (48927) | Generate an 8 bit random number and put it in location 278 |
| $B3B4 (46004) | $A027 (40999) | RESET:resets whole works, as if reset button has been pressed  |


   <img src='./SimonMenu.jpg' width=60%>     
   <img src='./Simon.jpg' width=60%>     
