// SUM=(A*B)+C
// First MUL=A*B
     ORG 10
     LDA A
     CMA
     INC
     STA COUNT
JMP1:
     LDA MUL
     ADD B
     STA MUL
     ISZ COUNT
     BUN JMP1
     // Then SUM=MUL+C
     // MUL is already in AC
     ADD C
     STA SUM
     HLT
A: DEC 25
B: DEC 4
C: DEC 10
MUL: DEC 0
SUM: DEC 0
COUNT: DEC 0
ADR: LBL A
END
