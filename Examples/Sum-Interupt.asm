//Gets input - adds to SUM - outputs SUM on interupt
//ISR Declared
ZRO: 0
BUN ISR

ORG 10  //Code runs from here (first ORG)
LB1: IOF   //Turn interupts off
     SKI   //Manual input (Busy Waiting!)
     BUN LB1
     INP
     ION
     ADD SUM
     STA SUM
     BUN LB1
HLT
//Data Section
SUM: 0 //Sum of input numbers
SAC: 0 //Saved AC
SE: 0  //Saved AC with E inside it

ISR: IOF     //Interupt Service Routine
     STA SAC
     CIL
     STA SE
     LDA SUM //Load SUM
     SKO
     BUN LZ
     OUT     //Output SUM
LZ:  LDA SE  //Restore E
     CIR     //
     LDA SAC //Restore AC
     BUN ZRO I  //Get out of interupt
END
