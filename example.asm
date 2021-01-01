//
// Important:
//	The intention of this sample is not to sound good. It is just to illustrate how to
//	use the player to edit instruments and patterns.
//
// SONG DATA
// Must contain:
//	* InstrumentsLo, InstrumentsHi
//	  - Array of pointers to instruments
//	  - Instruments start with Control (waveform + bsControl.VoiceOn), then AttackDecay, SustainRelease
//	  - After the first three bytes a list of instrument commands (bInst.*)
//	  - Use bsInst.Wait_1 + <extra frames> to wait for a certain number of frames
//	  - Use bsInst.Goto to jump to a byte for looping effects
//	  - To trigger envelope release issue a Control command without bsInst.VoiceOn, just waveform.
//	* VoiceTracksLo, VoiceTracksHi
//	  - Needs one array of Patterns for each Music Voice
//	  - Multi song support by having sequential lists in each track,
//		then overwrite bsVoiceTrackIndex and set bsTrackerTempoWait and bsPatternVoiceWait to 1
//	* Patterns
//	  - Patterns are lists of bsCmd commands which includes setting instruments,
//		playing notes, changing note on a plaing instrument, waiting and ending a pattern
//	  - Patterns can be up to 255 bytes, number of tracker steps doesn't matter
//	  - Patterns in different voices doesn't need to be the same length

InstrumentsLo:
	.byte <Instrument0, <Instrument1, <Instrument2

InstrumentsHi:
	.byte >Instrument0, >Instrument1, >Instrument2

Instrument0:
	bsInstSetup(bsCtrl_Triangle, $6, $6, $6, $8)
	bsInstEnd()

Instrument1:
	bsInstSetup(bsCtrl_SawTooth, $4, $2, $4, $6)
	bsInstWait(8)
	bsInstControl(bsCtrl_SawTooth)
	bsInstEnd()

Instrument2:
	bsInstSetup(bsCtrl_SawTooth, $2, $4, $7, $8)
	bsInstWait(16)
	bsInstControl(bsCtrl_SawTooth)
	bsInstEnd()

// This example doesn't support Arpeggios but an arpeggio table would look something like this:
// (each byte is added to the note index played, next frame next value is added to original note
// and so on, -1 means jump which can jump back to the start of the arpeggio or somewhere else in
// the table)
//const ArpeggioTable = *-1	// make sure first arpeggio is not using index 0
//Arpeggio0 = * - ArpeggioTable
//	.byte 0, 0, 0, 0, 12, 12, 12, 12
//	.byte -1, Arpeggio0
//Arpeggio1 = * - ArpeggioTable
//	.byte 0, 0, 7, 7, 12, 12
//	.byte -1, Arpeggio1
//
// When referencing arpeggio in an instrument just use the offsets in the ArpeggioTable:
//
// bsInstArpeggio Arpeggio1
//

ArpeggioTable:

VoiceTracksLo:
	.byte <VoiceTrack0, <VoiceTrack1, <VoiceTrack2

VoiceTracksHi:
	.byte >VoiceTrack0, >VoiceTrack1, >VoiceTrack2

VoiceTrack0:
	.word Pattern00
	.word Pattern10
	.word 0 ; restart on first pattern

VoiceTrack1:
	.word Pattern01
	.word 0 ; restart on first pattern

VoiceTrack2:
	.word Pattern02
	.word Pattern12
	.word 0 ; restart on first pattern


Pattern00:
	bsSetInstrument(0)
	bsNote(bsCmd_E_6)
	bsPatternWait(10)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_C_6)
	bsPatternWait(2)
	bsNote(bsCmd_D_6)
	bsPatternWait(13)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_C_6)
	bsPatternWait(2)
	bsNote(bsCmd_D_6)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(16)
	bsNote(bsCmd_A_5)
	bsPatternWait(16)
	bsPatternEnd()

Pattern10:
	bsPatternWait(10)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_E_6)
	bsPatternWait(2)
	bsNote(bsCmd_D_6)
	bsPatternWait(12)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_C_6)
	bsPatternWait(2)
	bsNote(bsCmd_D_6)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(16)
	bsNote(bsCmd_G_5)
	bsPatternWait(8)
	bsNote(bsCmd_A_5)
	bsPatternWait(8)
	bsPatternEnd()

Pattern01:
	bsSetInstrument(1)
	bsNote(bsCmd_A_5)
	bsPatternWait(1)
	bsNote(bsCmd_A_5)
	bsPatternWait(1)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(1)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(1)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5) // 16
	bsPatternWait(1)
	bsNote(bsCmd_G_5)
	bsPatternWait(1)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(1)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(1)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5) // 32
	bsPatternWait(1)
	bsNote(bsCmd_D_5)
	bsPatternWait(1)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(1)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(1)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5) // 48
	bsPatternWait(1)
	bsNote(bsCmd_F_5)
	bsPatternWait(1)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(1)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(1)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsPatternEnd()

Pattern02:
	bsSetInstrument(0)
	bsNote(bsCmd_A_5)
	bsPatternWait(50)
	bsSetInstrument(2)
	bsNote(bsCmd_A_4)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(2)
	bsNote(bsCmd_A_5)
	bsPatternWait(2)
	bsNote(bsCmd_G_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsNote(bsCmd_E_5)
	bsPatternWait(2)
	bsNote(bsCmd_F_5)
	bsPatternWait(2)
	bsPatternEnd()

Pattern12:
	bsNote(bsCmd_E_5)
	bsPatternWait(1)
	bsNote(bsCmd_E_5)
	bsPatternWait(2)
	bsNote(bsCmd_D_5)
	bsPatternWait(1)
	bsNote(bsCmd_E_5)
	bsPatternWait(1)
	bsNote(bsCmd_D_5)
	bsPatternWait(1)
	bsNote(bsCmd_C_5)
	bsPatternWait(1)
	bsNote(bsCmd_A_4)
	bsPatternWait(4)
	bsSetInstrument(0)
	bsNote(bsCmd_A_5)
	bsPatternWait(52)
	bsPatternEnd()
