lorom

;Aim Up/Down to any buttons
org $82F5CA
	RTS

org $9181F4
	LDA $8F
	AND #$0F00
	STA $12
	LDA $8B
	AND #$0F00
	STA $14
	LDY $8F
	TYA
	BIT $09B2
	BEQ +
	LDA #$0040
	TSB $12
	TYA
+
	BIT $09B4
	BEQ +
	LDA #$0080
	TSB $12
	TYA
+
	BIT $09B6
	BEQ +
	LDA #$8000
	TSB $12
	TYA
+
	BIT $09B8
	BEQ +
	LDA #$4000
	TSB $12
	TYA
+
	BIT $09BC
	BEQ +
	LDA #$0020
	TSB $12
+
	BIT $09BE
	BEQ +
	LDA #$0010
	TSB $12
+
	LDA $12
	EOR #$FFFF
	STA $12
	LDY $8B
	TYA
	BIT $09B2
	BEQ +
	LDA #$0040
	TSB $14
	TYA
+
	BIT $09B4
	BEQ +
	LDA #$0080
	TSB $14
	TYA
+
	BIT $09B6
	BEQ +
	LDA #$8000
	TSB $14
	TYA
+
	BIT $09B8
	BEQ +
	LDA #$4000
	TSB $14
	TYA
+
	BIT $09BC
	BEQ +
	LDA #$0020
	TSB $14
	TYA
+
	BIT $09BE
	BEQ +
	LDA #$0010
	TSB $14
+
	LDA $14
	EOR #$FFFF
	STA $14
	RTS
print pc