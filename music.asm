; Bullshit Music and SFX Player
;
; MIT License
; 
; Copyright (c) 2020 Carl-Henrik Skårstedt / Space Moguls Games
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

;
; Kick Assembler Version
; ----------------------
; This version is the same as the x65 version but with Kick Assembler
; syntax. It has not been tested, if anyone has time to try it please
; let me know what mistakes I've made so far.
; 

include music.inc

; SONG VARIABLES
; Initialize: set all to 0 except set bsTrackerTempoWait and bsPatternVoiceWait to 1, bsVolume to 15

bsVoiceTrackIndex:		; current track for each voice
	.fill bsMusicVoices, 0

bsVoicePatternIndex:	; current pattern position for each voice
	.fill bsMusicVoices, 0

bsVoiceInstrument: 		; current instrument for each voice
	.fill bsNumVoices, 0

bsVoiceTriggerNote: 	; 0 or instrument+1 to trigger
	.fill bsNumVoices, 0

.if (bsFreqCache!=0) {
bsVoiceFreqLo:			; frequency for each voice
	.fill bsNumVoices, 0
bsVoiceFreqHi:
	.fill bsNumVoices, 0
}

.if (bsNoteCache!=0) {
bsVoiceNote:
	.fill bsNumVoices, 0
}

.if (bsPulseCache!=0) {
bsVoicePulseLo:
	.fill bsNumVoices, 0
bsVoicePulseHi:
	.fill bsNumVoices, 0
}

.if (bsPulseDeltaSupport!=0) {
bsVoicePulseDelta:
	.fill bsNumVoices, 0
}

.if (bsFilterSupport!=0) {
bsFilterFreq:
	.fill 2, 0				; lower 3 bits, upper 8 bits
bsFilterMode:
	.fill 1, 0
bsFilterResonanceVoiceEnable:
	.fill 1, 0				; lo 3 bits: voice filter enable, upper 4 bits: resonance
.if (bsFilterDeltaSuppor!=0) {
bsFilterDelta:
	.fill 1, 0				; signed byte delta value
}
}

.if (bsArpeggioSupport!=0) {
bsVoiceArpeggioIndex:
	.fill bsNumVoices,0	; last played note on channel
}

bsVoiceInstrumentIndex:	; where in the instrument script we are currently
	.fill bsNumVoices, 0	; 0 means instrument ended

bsVoiceInstrumentWait:	; how many frames until next instrument command
	.fill bsNumVoices, 0	; 0 means instrument paused

bsTrackerTempoWait:		; frames left until next pattern update
	.byte 1				; 0 means tracker is stopped

bsPatternVoiceWait:		; pattern updates until next pattern command
	.fill bsMusicVoices,1	; 0 means pattern is stopped

bsVolume:
	.byte $0f			; this is not updated by the player, but used when updating filter


; CONSTANTS FOR MUSIC/SFX

bsSIDVoiceRegOffs:
	.byte 0, 7, 14
bsBitSet:
	.byte $01, $02, $04
bsBitClr:
	.byte $fe, $fd, $fb

// NOTE: Frequency usage follows the SCmd notes so edit to match
// - These values match the frequency table in Sid Wizard 1.8
FreqTablePalLo:
;      	  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
	.byte $16,$27,$38,$4b,$5e,$73,$89,$a1,$ba,$d4,$f0,$0d  ; 1
	.byte $2c,$4e,$71,$96,$bd,$e7,$13,$42,$74,$a8,$e0,$1b  ; 2
	.byte $59,$9c,$e2,$2c,$7b,$ce,$27,$84,$e8,$51,$c0,$36  ; 3
	.byte $b3,$38,$c4,$59,$f6,$9d,$4e,$09,$d0,$a2,$81,$6d  ; 4
	.byte $67,$70,$88,$b2,$ed,$3a,$9c,$13,$a0,$44,$02,$da  ; 5
	.byte $ce,$e0,$11,$64,$da,$75,$38,$26,$40,$89,$04,$b4  ; 6
	.byte $9c,$c0,$22,$c8,$b4,$eb,$71,$4c,$80,$12,$08,$68  ; 7
	.byte $38,$80,$45,$90,$68,$d6,$e3,$98,$00,$24,$10,$ff  ; 8

FreqTablePalHi:
;      	  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  ; 1
	.byte $02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04  ; 2
	.byte $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08  ; 3
	.byte $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10  ; 4
	.byte $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20  ; 5
	.byte $22,$24,$27,$29,$2b,$2e,$31,$34,$37,$3a,$3e,$41  ; 6
	.byte $45,$49,$4e,$52,$57,$5c,$62,$68,$6e,$75,$7c,$83  ; 7
	.byte $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$ff  ; 8


; MUSIC UPDATE CODE
; call UpdateMusicPlayer to play music

UpdateMusicPlayer:
{
	// Check Trigger Note
	ldx #2
	{
loop:
		lda bsVoiceTriggerNote,x
		beq esc
		bpl play
		and #$7f
		sta bsVoiceTriggerNote,x
		bpl esc
play:	stx restoreX
		jsr bsPlayInstrument
restoreX = *+1
		ldx #0
		lda #0
		sta bsVoiceTriggerNote,x
esc:	dex
		bpl loop
	}

	// Step Patterns and Tracks

	{
		dec bsTrackerTempoWait
		bne esc
.const bsTempo = *+1
		lda #bsPlayerTempo
		sta bsTrackerTempoWait

		; Update all tracks
		ldx #bsMusicVoices-1	; only update tracker voices
loop:	jsr bsUpdateTrackerVoice
		dex
		bpl loop
esc:
	}

	// Update Filter
.if (bsFilterDeltaSupport!=0) {
		lda bsFilterDelta
		beq esc
		clc
		adc bsFilterFreq+1
		sta bsFilterFreq+1
		sta SIDFilterCutoff+1
esc:
}
	// Update instruments
	
	ldx #bsNumVoices-1	; update all managed voices
	{
loop:
.if (bsPulseDeltaSupport!=0) {
			lda bsVoicePulseDelta,x
			beq esc
			bpl pos
			dec bsVoicePulseHi,x
pos:		ldy bsSIDVoiceRegOffs,x
			clc
			adc bsVoicePulseLo,x
			sta bsVoicePulseLo,x
			sta SIDPulse,y
			lda bsVoicePulseHi,x
			adc #0
			sta bsVoicePulseHi,x
			sta SIDPulse+1,y
esc:
}
.if (bsArpeggioSupport!=0) {
restart:	ldy bsVoiceArpeggioIndex,x
			beq esc
			lda ArpeggioTable,y
			cmp #-1
			bne notArpJmp
			iny
			lda ArpeggioTable,y
			sta bsVoiceArpeggioIndex,x
			jmp restart
notArpJmp	inc bsVoiceArpeggioIndex,x
			clc
			adc bsVoiceNote,x
			tay
			lda FreqTablePalHi,y
			pha
			lda FreqTablePalLo,y
			ldy bsSIDVoiceRegOffs,x
			sta SIDFrequency,y
			pla
			sta SIDFrequency+1,y
esc:
}
		{
			; bsVoiceInstrumentWait = 0 => Sound End
			lda bsVoiceInstrumentWait,x
			beq esc	; already 0 -> end command reached
			dec bsVoiceInstrumentWait,x
			bne esc	; reached 0 -> finished waiting
			jsr bsGetCurrentInstrument
			ldy bsVoiceInstrumentIndex,x
			lda bsSIDVoiceRegOffs,x
			tax
			jsr bsUpdateInstrumentCommands
esc:
		}
		dex
		bpl loop
	}
	rts
}

// Block that handles instruments

; x = voice #
bsGetCurrentInstrument:
{
	stx bsTmpSaveVoice		; save voice # since x will be set to SID register offset
	ldy bsVoiceInstrument,x	; index of instrument for current voice
	lda InstrumentsLo,y		; copy the instrument pointer to a zp pointer
	sta bsZPInstrument
	lda InstrumentsHi,y
	sta bsZPInstrument+1
	rts
}

; a = instrument #
; x = voice #
; y = note #
bsSFX:
{
	sta bsVoiceInstrument,x
	tya
} ; fallthrough
; bsTriggerInstrument stops current sound and queues a new instrument
; x = voice #
; a = note #
; x, y unchanged
; can be called to play sound effects to interrupt current sound
bsTriggerInstrument:
{
	ora #$80				; one extra frame before playing to ensure ADSR restart
	sta bsVoiceTriggerNote,x ; store the note for later playback
	tya
	pha
	ldy bsSIDVoiceRegOffs,x
	lda #0					; stop current sound
	sta SIDControl,y		; clear Control
	sta SIDAttackDecay,y	; clear Attack/Decay
	sta SIDSustainRelease,y	; clear Sustain/Release
	pla
	tay
	rts
}

; x = voice #
; a = note #
; can be called to play sound effects (non-interrupting)
bsPlayInstrument:
{
.if (bsNoteCache!=0) {
	sta bsVoiceNote,x
}
	tay ; fetch the note to grab note frequency
	dey
	lda FreqTablePalHi,y
	pha
.if (bsFreqCache!=0) {
	sta bsVoiceFreqHi,x
}
	lda FreqTablePalLo,y
	pha
.if (bsFreqCache!=0) {
	sta bsVoiceFreqLo,x
}
.if (bsPulseDeltaSupport!=0 || bsArpeggioSupport!=0) {
	lda #0
}
.if (bsPulseDeltaSupport!=0) {
	sta bsVoicePulseDelta,x
}
.if (bsArpeggioSupport!=0) {
	sta bsVoiceArpeggioIndex,x
}
	; grab instrument and start setting Frequency, Control, ADSR
	jsr bsGetCurrentInstrument
	lda bsSIDVoiceRegOffs,x
	tax
	pla
	sta SIDFrequency,x
	pla
	sta SIDFrequency+1,x
	ldy #0
	lda (bsZPInstrument),y
	sta SIDControl,x
	iny
	lda (bsZPInstrument),y
	sta SIDAttackDecay,x
	iny
	lda (bsZPInstrument),y
	sta SIDSustainRelease,x
	iny
} ; fallthrough
; x = SID channel address offset (0, 7, 14)
; y = instrument commands index
; bsZPInstrument.w = instrument start
bsUpdateInstrumentCommands:
{	; loop through instrument commands until Wait or End command reached
	{	; fetch next instrument command
loop:	lda (bsZPInstrument),y
		beq end
		iny
		cmp #bsInst.Effects
		bcs effects	; wait command, exit and store wait
end:	jmp esc			; end or wait command
effects:
		bne notControl
		lda (bsZPInstrument),y
		iny
		sta SIDControl,x	; KeyOff etc.
		bne loop
notControl:
		cmp #bsInst.Pulse
		bne notPulse
		lda (bsZPInstrument),y
		sta SIDPulse,x
.if (bsPulseCache!=0) {
		pha
}
		iny
		lda (bsZPInstrument),y
		sta SIDPulse+1,x
		iny
.if (bsPulseCache!=0) {
		ldx bsTmpSaveVoice
		sta bsVoicePulseHi,x
		pla
		sta bsVoicePulseLo,x
		jmp resetSIDOffset
}
.if (bsPulseCache!==0) {
		jmp loop
}
notPulse:
.if (bsPulseDeltaSupport!=0) {
		cmp #bsInst.PulseDelta
		bne notPulseDelta
		ldx bsTmpSaveVoice
		lda (bsZPInstrument),y
		iny
		sta bsVoicePulseDelta,x
		jmp resetSIDOffset
notPulseDelta:
}
.if (bsFilterSupport!=0) {
		cmp #bsInst.FilterCutoff
		bne notFilterCutoff
		lda #0
		sta bsFilterFreq	; clear lower 3 bits
		sta SIDFilterCutoff
		lda (bsZPInstrument),y
		sta SIDFilterCutoff+1
		sta bsFilterFreq+1	; 8 upper bits from effect param
		iny
		bne loop
notFilterCutoff:
		cmp #bsInst.FilterResonance
		bne .notFilterResonance
		lda bsFilterResonanceVoiceEnable
		and #$0f
		ora (bsZPInstrument),y
		sta bsFilterResonanceVoiceEnable
		sta SIDFilterControl
		iny
		bne loop
notFilterResonance:
		cmp #bsInst.FilterEnable
		bne .notFilterEnable
		ldx bsTmpSaveVoice
		lda bsBitSet,x
		ora bsFilterResonanceVoiceEnable
setSIDFilterControl:
		sta bsFilterResonanceVoiceEnable
		sta SIDFilterControl
		jmp resetSIDOffset
notFilterEnable:
		cmp #bsInst.FilterDisable
		bne .notFilterDisable
		ldx bsTmpSaveVoice
		lda bsBitClr,x
		and bsFilterResonanceVoiceEnable
		jmp setSIDFilterControl
notFilterDisable:
		cmp #bsInst.FilterMode
		bne .notFilterMode
		lda (bsZPInstrument),y
		sta bsFilterMode
		ora bsVolume
		sta SIDVolumeFilterMode
		iny
		jmp loop
notFilterMode:
.if (bsFilterDeltaSupport!=0) {
		cmp #bsInst.FilterDelta
		bne .notFilterDelta
		lda (bsZPInstrument),y
		sta bsFilterDelta
		iny
		jmp loop
notFilterDelta:
}
}
.if (bsArpeggioSupport!=0) {
		cmp #bsInst.Arpeggio
		bne notArpeggio
		lda (bsZPInstrument),y
		iny
		ldx bsTmpSaveVoice
		sta bsVoiceArpeggioIndex,x
		jmp resetSIDOffset
notArpeggio:
}
		cmp #bsInst.Goto
		bne notGoto
		ldx bsTmpSaveVoice
		lda (bsZPInstrument),y
		tay
resetSIDOffset:
		lda bsSIDVoiceRegOffs,x
		tax
		jmp loop
notGoto:
		; other effects
esc:
	}
	ldx bsTmpSaveVoice
	sta bsVoiceInstrumentWait,x
	tya
	sta bsVoiceInstrumentIndex,x
	rts
}

// Block that handles patterns

; x = voice #, returns y = pattern offset
bsGetCurrentPattern:
{
	lda VoiceTracksLo,x
	sta bsZPPattern
	lda VoiceTracksHi,x
	sta bsZPPattern+1
	lda bsVoiceTrackIndex,x
	asl
	tay
	lda (bsZPPattern),y
	pha
	iny
	lda (bsZPPattern),y
	sta bsZPPattern+1
	pla
	sta bsZPPattern
	ldy bsVoicePatternIndex,x
	rts
}

; x = voice
bsUpdateTrackerVoice:
{
	lda bsPatternVoiceWait,x
	beq paused
	dec bsPatternVoiceWait,x
	beq update
paused:
	rts
update:
	jsr bsGetCurrentPattern

	; current command in (bsZPPattern),y
	; increment y and store back into bsVoicePatternIndex,x
	{
loop:
		lda (bsZPPattern),y
		bne notPatternEnd
		inc bsVoiceTrackIndex,x
restartSong:
		jsr bsGetCurrentPattern
		ldy #0
		lda bsZPPattern+1	; check if song is over & repeat
		bne loop
		lda bsZPPattern		; check if song is over & repeat
		sta bsVoiceTrackIndex,x
		bpl restartSong
notPatternEnd:
		iny
		cmp #bsCmd.NotesEnd
		bcs notNote
		jsr bsTriggerInstrument
		jmp loop
notNote:
		cmp #bsCmd.ChangeNote
		bcs notInstrument
		sbc #bsCmd.Instrument-1 ; C clear so subtract one less
		sta bsVoiceInstrument,x
		bcs loop
notInstrument:
.if (bsChangeNoteSupport!=0) {
		;cmp #bsCmd.ChangeNote
		bne notChangeNote
		stx restoreVoiceIndex
		lda bsSIDVoiceRegOffs,x
		tax
		lda (bsZPPattern),y
		iny
		sty .restorePatternIndex
		tay
		dey
		lda FreqTablePalLo,y
		sta SIDFrequency,x
.if (bsFreqCache!=0) {
		pha
} ; bsFreqCache
		lda FreqTablePalHi,y
		sta SIDFrequency,x
restoreVoiceIndex = *+1
		ldx #0
.if (bsFreqCache!=0) {
		sta bsVoiceFreqHi,x
		pla
		sta bsVoiceFreqLo,x
} ; bsFreqCache
.if (bsNoteCache!=0) {
		tya
		sta bsVoiceNote,x
} ; bsNoteCache
restorePatternIndex = *+1
		ldy #0
		bne loop
notChangeNote:
}
waitCmd:
		; C set
		sbc #bsCmd.Wait_1-1
		sta bsPatternVoiceWait,x
		tya
		sta bsVoicePatternIndex,x
	}
	rts
}

