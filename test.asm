
.import source "music.inc"

* = $801

// 1 SYS 2064
.byte $0b, $08, $01, $00, $9e, $32, $30, $36, $34, $00, $00, $00, $00, $00, $00

RunTest:
	lda #$f	// set volume
	sta $d418
frame:
	lda #100
wait:
	cmp $d012
	bne wait
	lda #4
	sta $d020
	jsr UpdateMusicPlayer
	lda #14
	sta $d020
	jmp frame

// just include music code to keep it simple
.import source "music.asm"

// and the music included right after
.import source "example.asm"