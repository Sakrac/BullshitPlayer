// Bullshit Music and SFX Player
//
// MIT License
// 
// Copyright (c) 2020 Carl-Henrik Skårstedt / Space Moguls Games
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//
// Kick Assembler Version
// ----------------------
// This version is the same as the x65 version but with Kick Assembler
// syntax. It has not been tested, if anyone has time to try it please
// let me know via https://github.com/sakrak/bullshitplayer
// 

.const MUSIC_INC = 1

// SID registers
.const SIDBase = $d400
.const SIDFrequency = SIDBase
.const SIDPulse = SIDBase+2
.const SIDControl = SIDBase+4
.const SIDAttackDecay = SIDBase+5
.const SIDSustainRelease = SIDBase+6

.const SIDFilterCutoff = SIDBase+$15 // 3 + 8 bits
.const SIDFilterControl = SIDBase+$17 // voice mask, resonance
.const SIDVolumeFilterMode = SIDBase+$18 // volume, filter mode

// Player Customization
.const bsPlayerTempo = 6	// default tempo, in frames per tracker step

.const bsZeroPagePtr = $fe	// 2 byte pointer must be zero page
.const bsByteTmp = $fd		// 1 byte temp storage, doesn't have to be zero page

.const bsZPPattern = bsZeroPagePtr		// pointer current pattern for current voice
.const bsZPInstrument = bsZeroPagePtr	// pointer current instrument for current voice
.const bsTmpSaveVoice = bsByteTmp		// save voice # when updating SID regs

// Flags to enable/disable features
.const bsPulseDeltaSupport = 0			// enables bsInst_PulseDelta instrument command
.const bsArpeggioSupport = 0				// enables bsInst_Arpeggio instrument command and requires an ArpeggioTable to be defined
.const bsFilterDeltaSupport = 0			// enables bsInst_FilterDelta instrument command
.const bsChangeNoteSupport = 0			// enables bsCmd_ChangeNote track command (changes note without restarting instrument)

// remember last set frequency for slide/vibrato etc
.const bsFreqCache = 0
// remember last set note for arpeggio
.const bsNoteCache = bsArpeggioSupport
// 1: Remember lsat pulse width for pulse slide etc.
.const bsPulseCache = bsPulseDeltaSupport
// using filters
.const bsFilterSupport = 1 || bsFilterDeltaSupport

// Hard coded constants
.const bsMusicVoices = 3 	// # voices controlled by tracks & patterns
.const bsSFXVoices = 0 		// # voices reserved for SFX (no tracks & pattern control)
.const bsNumVoices = bsMusicVoices + bsSFXVoices // # voices that can play instruments

.const bsMaxInstruments = 32	// # instrument slots in track command (can be changed)
.const bsMaxWaitSteps = 64	// # of pattern steps a pattern can wait (can be changed)
.const bsMaxInstrumentWait = 192 // Max frames wait time for instruments

.enum {						// SID Control register bits
	bsCtrl_VoiceOn = 1,			// AKA Gate
	bsCtrl_SyncOn = 2,
	bsCtrl_RingOn = 4,
	bsCtrl_Disable = 8,
	bsCtrl_Triangle = 16,			// Set Triangle Waveform
	bsCtrl_SawTooth = 32,			// Set SawTooth Waveform
	bsCtrl_Rectangle = 64,			// Set Rectangle Waveform, uses the Pulse register
	bsCtrl_Noise = 128				// Set Noise Waveform
}

// Filter types, used with bsInst
.enum {				// use with bsInstSetFilterMode .macro
	bsFilter_LowPass = $10,
	bsFilter_BandPass = $20,
	bsFilter_HighPass = $40
}

// pattern commands (unused notes can be removed as long as FreqTablePalLo & FreqTablePalHi matches with order)
.enum {
	bsCmd_End,	// end pattern / 
	bsCmd_Notes, // start of notes
	bsCmd_C_1 = bsCmd_Notes,
	bsCmd_Cs1,
	bsCmd_D_1,
	bsCmd_Ds1,
	bsCmd_E_1,
	bsCmd_F_1,
	bsCmd_Fs1,
	bsCmd_G_1,
	bsCmd_Gs1,
	bsCmd_A_1,
	bsCmd_As1,
	bsCmd_B_1,
	bsCmd_C_2,
	bsCmd_Cs2,
	bsCmd_D_2,
	bsCmd_Ds2,
	bsCmd_E_2,
	bsCmd_F_2,
	bsCmd_Fs2,
	bsCmd_G_2,
	bsCmd_Gs2,
	bsCmd_A_2,
	bsCmd_As2,
	bsCmd_B_2,
	bsCmd_C_3,
	bsCmd_Cs3,
	bsCmd_D_3,
	bsCmd_Ds3,
	bsCmd_E_3,
	bsCmd_F_3,
	bsCmd_Fs3,
	bsCmd_G_3,
	bsCmd_Gs3,
	bsCmd_A_3,
	bsCmd_As3,
	bsCmd_B_3,
	bsCmd_C_4,
	bsCmd_Cs4,
	bsCmd_D_4,
	bsCmd_Ds4,
	bsCmd_E_4,
	bsCmd_F_4,
	bsCmd_Fs4,
	bsCmd_G_4,
	bsCmd_Gs4,
	bsCmd_A_4,
	bsCmd_As4,
	bsCmd_B_4,
	bsCmd_C_5,
	bsCmd_Cs5,
	bsCmd_D_5,
	bsCmd_Ds5,
	bsCmd_E_5,
	bsCmd_F_5,
	bsCmd_Fs5,
	bsCmd_G_5,
	bsCmd_Gs5,
	bsCmd_A_5,
	bsCmd_As5,
	bsCmd_B_5,
	bsCmd_C_6,
	bsCmd_Cs6,
	bsCmd_D_6,
	bsCmd_Ds6,
	bsCmd_E_6,
	bsCmd_F_6,
	bsCmd_Fs6,
	bsCmd_G_6,
	bsCmd_Gs6,
	bsCmd_A_6,
	bsCmd_As6,
	bsCmd_B_6,
	bsCmd_C_7,
	bsCmd_Cs7,
	bsCmd_D_7,
	bsCmd_Ds7,
	bsCmd_E_7,
	bsCmd_F_7,
	bsCmd_Fs7,
	bsCmd_G_7,
	bsCmd_Gs7,
	bsCmd_A_7,
	bsCmd_As7,
	bsCmd_B_7,
	bsCmd_C_8,
	bsCmd_Cs8,
	bsCmd_D_8,
	bsCmd_Ds8,
	bsCmd_E_8,
	bsCmd_F_8,
	bsCmd_Fs8,
	bsCmd_G_8,
	bsCmd_Gs8,
	bsCmd_A_8,
	bsCmd_As8,
	bsCmd_B_8,
	bsCmd_NotesEnd,
	bsCmd_Instrument = bsCmd_NotesEnd, // change instrument for this voice
	bsCmd_ChangeNote = bsCmd_Instrument + bsMaxInstruments, // Change note without restarting instrument
	bsCmd_Wait_1
}

// Instrument Commands
.enum {
	bsInst_End,				// end of instrument script
	bsInst_Wait_1,				// want # frames
	bsInst_Effects = bsMaxInstrumentWait, // instrument effects begin here
	bsInst_Control = bsInst_Effects, // Control, use for waveform and to trigger release
	bsInst_Pulse,				// Followed by two bytes pulse width
	bsInst_PulseDelta,			// Followed by signed byte pulse delta
	bsInst_FilterCutoff,		// Set filter cut off frequency bits 3-11
	bsInst_FilterResonance,	// Set filter resonance, followed by preshifted byte
	bsInst_FilterEnable,		// Enable filter for voice
	bsInst_FilterDisable,		// Disable filter for voice
	bsInst_FilterMode,			// Filter mode, followed by $10 (lo), $20 (band), $40 (high)
	bsInst_FilterDelta,		// Set Filter Frequency Delta followed by signed byte
	bsInst_Arpeggio,			// Set arpeggio index for instrument
	bsInst_Goto				// Followed by intrument index
}

// SONG FUNCTIONS AND MACROS

.function bsPatternNum(track) { (*-track)>>1 }

.macro bsSetInstrument(instrument) {
	.byte bsCmd_Instrument + instrument
}
.macro bsPatternWait(frames) {
	.byte bsCmd_Wait_1 + frames-1
}
.macro bsPatternEnd() {
	.byte bsCmd_End
}
.macro bsNote(note) {
	.byte note
}
.macro bsInstEnd() {
	.byte bsInst_End
}
.macro bsInstWait(frames) {
	.byte bsInst_Wait_1 + frames - 1
}
.macro bsInstGoto(instrument, where) {
	.byte bsInst_Goto, where - instrument
}


.macro bsInstSetup(waveform, Attack, Decay, Sustain, Release) {
	.byte bsCtrl_VoiceOn | waveform, (Attack<<4)|Decay, (Sustain<<4)|Release
}
.macro bsInstControl(value) {
	.byte bsInst_Control, value
}
.macro bsInstSetPulse(pulse) {
	.byte bsInst_Pulse
	.word pulse
}
.macro bsChangeNote(note) {
	.byte bsCmd_ChangeNote, note
}
.macro bsInstSetFilterCutoff(freq) {
	.byte bsInst_FilterCutoff, freq
}
.macro bsInstSetFilterResonance(res) {
	.byte bsInst_FilterResonance, res
}
.macro bsInstFilterEnable() {
	.byte bsInst_FinterEnable
}
.macro bsInstSetFilterMode(mode) {
	.byte bsInst_FilterMode, mode
}
.macro bsInstFilterDelta(delta) {
	.byte bsInst_FilterDelta, delta
}
.macro bsInstArpeggio(index) {
	.byte bsInst_Arpeggio, index
}
.macro bsInstPulseDelta(delta) {
	.byte bsInst_PulseDelta, delta
}
