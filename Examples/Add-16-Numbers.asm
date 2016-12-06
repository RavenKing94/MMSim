//  Program to add 16 numbers (using a loop)
//  ---------------------------------------------------------------
        ORG 100     // Origin of program is HEX 100
        LDA DATA    // Load first address of operand
        STA PTR     // Store in pointer
        LDA NUM_S   // Load negative value of number of operands
        STA COUNT   // Store in counter
        CLA         // Clear AC
LOOP:   ADD PTR I   // Add an operand to AC (Indirect mode)
        ISZ PTR     // Increment pointer
        ISZ COUNT   // Increment counter
        BUN LOOP    // Repeat loop again
        STA SUM     // Store sum
        HLT         // Halt computer
SUM:    HEX 0       // Sum is stored here
                    // (0x10 + 0x20 + ... + 0xF0 + 0x100) = 0x880
DATA:   LBL FIRST   // First address of operands
PTR:    HEX 0       // Reserved for a pointer
NUM_S:  DEC -16     // Initial value for the counter (negative value)
COUNT:  HEX 0       // Reserved for a counter
        // DATA SECTION
        // --------------------------------------------------------
FIRST:  HEX 10      // First operand
        HEX 20
        HEX 30
        HEX 40
        HEX 50
        HEX 60
        HEX 70
        HEX 80
        HEX 90
        HEX A0
        HEX B0
        HEX C0
        HEX D0
        HEX E0
        HEX F0
        HEX 100     // Last operand
        END         // End of symbolic program

