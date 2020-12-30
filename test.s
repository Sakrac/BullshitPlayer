
ifndef MUSIC_INC
include music.i
endif

org $801

; 1 SYS 2064
dc.b $0b, $08, $01, $00, $9e, $32, $30, $36, $34, $00, $00, $00, $00, $00, $00

RunTest:
{
	lda #$f	; set volume
	sta $d418
}
{
	lda #100
	{
		cmp $d012
		bne !
	}
	lda #4
	sta $d020
if 0
	ldx #0
	{
		dex
		bne !
	}
endif
	jsr UpdateMusicPlayer
	lda #14
	sta $d020
	jmp !
}

// just include music code to keep it simple
include "music.s"

// and the music included right after
include "example.s"