 10  HOME 
 20  PRINT  CHR$ (4);"BLOAD UNIDRIVE2"
 25  INPUT "N1,N2? ";N1,N2
 30  POKE 25,(N1 -  INT (N1 / 256) * 256)
 32  POKE 26, INT (N1 / 256)
 35  POKE 27,(N2 -  INT (N2 / 256) * 256)
 37  POKE 28, INT (N2 / 256)
 40  CALL 32768
 50  PRINT : PRINT "RESULT IS "; PEEK (29) + 256 *  PEEK (30)