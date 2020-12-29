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

ifndef MUSIC_INC
include music.i
endif

; SONG VARIABLES
; Initialize: set all to 0 except set bsTrackerTempoWait and bsPatternVoiceWait to 1, bsVolume to 15

bsVoiceTrackIndex:		; current track for each voice
	ds bsMusicVoices, 0

bsVoicePatternIndex:	; current pattern position for each voice
	ds bsMusicVoices, 0

bsVoiceInstrument: 		; current instrument for each voice
	ds bsNumVoices, 0

bsVoiceTriggerNote: 	; 0 or instrument+1 to trigger
	ds bsNumVoices, 0

if bsFreqCache
bsVoiceFreqLo:			; frequency for each voice
	ds bsNumVoices, 0
bsVoiceFreqHi:
	ds bsNumVoices, 0
endif

if bsNoteCache
bsVoiceNote:
	ds bsNumVoices, 0
endif

if bsPulseCache
bsVoicePulseLo:
	ds bsNumVoices, 0
bsVoicePulseHi:
	ds bsNumVoices, 0
endif

if bsPulseDeltaSupport
bsVoicePulseDelta:
	ds bsNumVoices, 0
endif

if bsFilterSupport
bsFilterFreq:
	ds 2, 0				; lower 3 bits, upper 8 bits
bsFilterMode:
	ds 1, 0
bsFilterResonanceVoiceEnable:
	ds 1, 0				; lo 3 bits: voice filter enable, upper 4 bits: resonance
if bsFilterDeltaSupport
bsFilterDelta:
	ds 1, 0				; signed byte delta value
endif
endif

if bsArpeggioSupport
bsVoiceArpeggioIndex:
	ds bsNumVoices,0	; last played note on channel
endif

bsVoiceInstrumentIndex:	; where in the instrument script we are currently
	ds bsNumVoices, 0	; 0 means instrument ended

bsVoiceInstrumentWait:	; how many frames until next instrument command
	ds bsNumVoices, 0	; 0 means instrument paused

bsTrackerTempoWait:		; frames left until next pattern update
	dc.b 1				; 0 means tracker is stopped

bsPatternVoiceWait:		; pattern updates until next pattern command
	ds bsMusicVoices,1	; 0 means pattern is stopped

bsVolume:
	dc.b $0f			; this is not updated by the player, but used when updating filter


; CONSTANTS FOR MUSIC/SFX

bsSIDVoiceRegOffs:
	dc.b 0, 7, 14
bsBitSet:
	dc.b $01, $02, $04
bsBitClr:
	dc.b $fe, $fd, $fb

// NOTE: Frequency usage follows the SCmd notes so edit to match
// - These values match the frequency table in Sid Wizard 1.8
FreqTablePalLo:
;      	  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
	dc.b $16,$27,$38,$4b,$5e,$73,$89,$a1,$ba,$d4,$f0,$0d  ; 1
	dc.b $2c,$4e,$71,$96,$bd,$e7,$13,$42,$74,$a8,$e0,$1b  ; 2
	dc.b $59,$9c,$e2,$2c,$7b,$ce,$27,$84,$e8,$51,$c0,$36  ; 3
	dc.b $b3,$38,$c4,$59,$f6,$9d,$4e,$09,$d0,$a2,$81,$6d  ; 4
	dc.b $67,$70,$88,$b2,$ed,$3a,$9c,$13,$a0,$44,$02,$da  ; 5
	dc.b $ce,$e0,$11,$64,$da,$75,$38,$26,$40,$89,$04,$b4  ; 6
	dc.b $9c,$c0,$22,$c8,$b4,$eb,$71,$4c,$80,$12,$08,$68  ; 7
	dc.b $38,$80,$45,$90,$68,$d6,$e3,$98,$00,$24,$10,$ff  ; 8

FreqTablePalHi:
;      C   C#  D   D#  E   F   F#  G   G#  A   A#  B
	dc.b $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  ; 1
	dc.b $02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04  ; 2
	dc.b $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08  ; 3
	dc.b $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10  ; 4
	dc.b $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20  ; 5
	dc.b $22,$24,$27,$29,$2b,$2e,$31,$34,$37,$3a,$3e,$41  ; 6
	dc.b $45,$49,$4e,$52,$57,$5c,$62,$68,$6e,$75,$7c,$83  ; 7
	dc.b $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$ff  ; 8


; MUSIC UPDATE CODE
; call UpdateMusicPlayer to play music

UpdateMusicPlayer:
{
	// Check Trigger Note
	ldx #2
	{
		{
			lda bsVoiceTriggerNote,x
			beq %
			bpl .play
			and #$7f
			sta bsVoiceTriggerNote,x
			bpl %
.play		stx .restoreX
			jsr bsPlayInstrument
.restoreX = *+1
			ldx #0
			lda #0
			sta bsVoiceTriggerNote,x
		}
		dex
		bpl !
	}

	// Step Patterns and Tracks

	{
		dec bsTrackerTempoWait
		bne %
const bsTempo = *+1
		lda #bsPlayerTempo
		sta bsTrackerTempoWait

		; Update all tracks
		ldx #bsMusicVoices-1	; only update tracker voices
		{
			jsr bsUpdateTrackerVoice
			dex
			bpl !
		}
	}

	// Update Filter
if bsFilterDeltaSupport
	{
		lda bsFilterDelta
		beq %
		clc
		adc bsFilterFreq+1
		sta bsFilterFreq+1
		sta SIDFilterCutoff+1
	}
endif

	// Update instruments
	
	ldx #bsNumVoices-1	; update all managed voices
	{
if bsPulseDeltaSupport
		{
			lda bsVoicePulseDelta,x
			beq %
			{
				bpl %
				dec bsVoicePulseHi,x
			}
			ldy bsSIDVoiceRegOffs,x
			clc
			adc bsVoicePulseLo,x
			sta bsVoicePulseLo,x
			sta SIDPulse,y
			lda bsVoicePulseHi,x
			adc #0
			sta bsVoicePulseHi,x
			sta SIDPulse+1,y
		}
endif
if bsArpeggioSupport
		{
			ldy bsVoiceArpeggioIndex,x
			beq %
			lda ArpeggioTable,y
			cmp #-1
			bne .notArpJmp
			iny
			lda ArpeggioTable,y
			sta bsVoiceArpeggioIndex,x
			jmp !
.notArpJmp	inc bsVoiceArpeggioIndex,x
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
		}
endif
		{
			; bsVoiceInstrumentWait = 0 => Sound End
			lda bsVoiceInstrumentWait,x
			beq %	; already 0 -> end command reached
			dec bsVoiceInstrumentWait,x
			bne %	; reached 0 -> finished waiting
			jsr bsGetCurrentInstrument
			ldy bsVoiceInstrumentIndex,x
			lda bsSIDVoiceRegOffs,x
			tax
			jsr bsUpdateInstrumentCommands
		}
		dex
		bpl !
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
if bsNoteCache
	sta bsVoiceNote,x
endif
	tay ; fetch the note to grab note frequency
	dey
	lda FreqTablePalHi,y
	pha
if bsFreqCache
	sta bsVoiceFreqHi,x
endif
	lda FreqTablePalLo,y
	pha
if bsFreqCache
	sta bsVoiceFreqLo,x
endif
if bsPulseDeltaSupport || bsArpeggioSupport
	lda #0
endif
if bsPulseDeltaSupport
	sta bsVoicePulseDelta,x
endif
if bsArpeggioSupport
	sta bsVoiceArpeggioIndex,x
endif
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
		lda (bsZPInstrument),y
		beq .end
		iny
		cmp #bsInst.Effects
		bcs .effects	; wait command, exit and store wait
.end	jmp %			; end or wait command
.effects
		bne .notControl
		lda (bsZPInstrument),y
		iny
		sta SIDControl,x	; KeyOff etc.
		bne !
.notControl
		cmp #bsInst.Pulse
		bne .notPulse
		lda (bsZPInstrument),y
		sta SIDPulse,x
if bsPulseCache
		pha
endif
		iny
		lda (bsZPInstrument),y
		sta SIDPulse+1,x
		iny
if bsPulseCache
		ldx bsTmpSaveVoice
		sta bsVoicePulseHi,x
		pla
		sta bsVoicePulseLo,x
		jmp .resetSIDOffset
else
		jmp !
endif
.notPulse
if bsPulseDeltaSupport
		cmp #bsInst.PulseDelta
		bne .notPulseDelta
		ldx bsTmpSaveVoice
		lda (bsZPInstrument),y
		iny
		sta bsVoicePulseDelta,x
		jmp .resetSIDOffset
.notPulseDelta
endif
if bsFilterSupport
		cmp #bsInst.FilterCutoff
		bne .notFilterCutoff
		lda #0
		sta bsFilterFreq	; clear lower 3 bits
		sta SIDFilterCutoff
		lda (bsZPInstrument),y
		sta SIDFilterCutoff+1
		sta bsFilterFreq+1	; 8 upper bits from effect param
		iny
		bne !
.notFilterCutoff
		cmp #bsInst.FilterResonance
		bne .notFilterResonance
		lda bsFilterResonanceVoiceEnable
		and #$0f
		ora (bsZPInstrument),y
		sta bsFilterResonanceVoiceEnable
		sta SIDFilterControl
		iny
		bne !
.notFilterResonance
		cmp #bsInst.FilterEnable
		bne .notFilterEnable
		ldx bsTmpSaveVoice
		lda bsBitSet,x
		ora bsFilterResonanceVoiceEnable
.setSIDFilterControl
		sta bsFilterResonanceVoiceEnable
		sta SIDFilterControl
		jmp .resetSIDOffset
.notFilterEnable
		cmp #bsInst.FilterDisable
		bne .notFilterDisable
		ldx bsTmpSaveVoice
		lda bsBitClr,x
		and bsFilterResonanceVoiceEnable
		jmp .setSIDFilterControl
.notFilterDisable
		cmp #bsInst.FilterMode
		bne .notFilterMode
		lda (bsZPInstrument),y
		sta bsFilterMode
		ora bsVolume
		sta SIDVolumeFilterMode
		iny
		jmp !
.notFilterMode
if bsFilterDeltaSupport
		cmp #bsInst.FilterDelta
		bne .notFilterDelta
		lda (bsZPInstrument),y
		sta bsFilterDelta
		iny
		jmp !
.notFilterDelta
endif
endif
if bsArpeggioSupport
		cmp #bsInst.Arpeggio
		bne .notArpeggio
		lda (bsZPInstrument),y
		iny
		ldx bsTmpSaveVoice
		sta bsVoiceArpeggioIndex,x
		jmp .resetSIDOffset
.notArpeggio
endif
		cmp #bsInst.Goto
		bne .notGoto
		ldx bsTmpSaveVoice
		lda (bsZPInstrument),y
		tay
.resetSIDOffset
		lda bsSIDVoiceRegOffs,x
		tax
		jmp !
.notGoto
		; other effects
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
	{
		lda bsPatternVoiceWait,x
		beq .paused
		dec bsPatternVoiceWait,x
		beq %
.paused
		rts
	}
	jsr bsGetCurrentPattern

	; current command in (bsZPPattern),y
	; increment y and store back into bsVoicePatternIndex,x
	{
		lda (bsZPPattern),y
		bne .notPatternEnd
		inc bsVoiceTrackIndex,x
.restartSong
		jsr bsGetCurrentPattern
		ldy #0
		lda bsZPPattern+1	; check if song is over & repeat
		bne !
		lda bsZPPattern		; check if song is over & repeat
		sta bsVoiceTrackIndex,x
		bpl .restartSong
.notPatternEnd
		iny
		cmp #bsCmd.NotesEnd
		bcs .notNote
		jsr bsTriggerInstrument
		jmp !
.notNote
		cmp #bsCmd.ChangeNote
		bcs .notInstrument
		sbc #bsCmd.Instrument-1 ; C clear so subtract one less
		sta bsVoiceInstrument,x
		bcs !
.notInstrument
if bsChangeNoteSupport
//		cmp #bsCmd.ChangeNote
		bne .notChangeNote
		stx .restoreVoiceIndex
		lda bsSIDVoiceRegOffs,x
		tax
		lda (bsZPPattern),y
		iny
		sty .restorePatternIndex
		tay
		dey
		lda FreqTablePalLo,y
		sta SIDFrequency,x
if bsFreqCache
		pha
endif // bsFreqCache
		lda FreqTablePalHi,y
		sta SIDFrequency,x
.restoreVoiceIndex = *+1
		ldx #0
if bsFreqCache
		sta bsVoiceFreqHi,x
		pla
		sta bsVoiceFreqLo,x
endif // bsFreqCache
if bsNoteCache
		tya
		sta bsVoiceNote,x
endif // bsNoteCache
.restorePatternIndex = *+1
		ldy #0
		bne !
.notChangeNote
endif
.waitCmd
		; C set
		sbc #bsCmd.Wait_1-1
		sta bsPatternVoiceWait,x
		tya
		sta bsVoicePatternIndex,x
	}
	rts
}

; SONG DATA
; Must contain:
;	* InstrumentsLo, InstrumentsHi
;	  - Array of pointers to instruments
;	  - Instruments start with Control (waveform + bsControl.VoiceOn), then AttackDecay, SustainRelease
;	  - After the first three bytes a list of instrument commands (bInst.*)
;	  - Use bsInst.Wait_1 + <extra frames> to wait for a certain number of frames
;	  - Use bsInst.Goto to jump to a byte for looping effects
;	  - To trigger envelope release issue a Control command without bsInst.VoiceOn, just waveform.
;	* VoiceTracksLo, VoiceTracksHi
;	  - Needs one array of Patterns for each Music Voice
;	  - Multi song support by having sequential lists in each track,
;		then overwrite bsVoiceTrackIndex and set bsTrackerTempoWait and bsPatternVoiceWait to 1
;	* Patterns
;	  - Patterns are lists of bsCmd commands which includes setting instruments,
;		playing notes, changing note on a plaing instrument, waiting and ending a pattern
;	  - Patterns can be up to 255 bytes, number of tracker steps doesn't matter
;	  - Patterns in different voices doesn't need to be the same length

InstrumentsLo:

InstrumentsHi:

VoiceTracksLo:

VoiceTracksHi:

