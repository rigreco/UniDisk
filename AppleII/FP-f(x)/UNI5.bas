 2  PRINT  CHR$ (4);"BLOAD FPMain"
 5  PRINT  CHR$ (4);"BLOAD FPConv"
 15  CALL 24576
 17  PRINT  CHR$ (4);"BLOAD FPData"
 18  HGR2 : HCOLOR= 3
 20  FOR X =  - 10 TO 10 STEP .2
 25  CALL 32768,X
 30  CALL 24576
 35  CALL 32831,Y
 40  HPLOT X * 5 + 140,Y + 10
 50  NEXT