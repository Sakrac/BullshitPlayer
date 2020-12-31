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
.const bsPulseDeltaSupport = 0			// enables bsInst.PulseDelta instrument command
.const bsArpeggioSupport = 0				// enables bsInst.Arpeggio instrument command and requires an ArpeggioTable to be defined
.const bsFilterDeltaSupport = 0			// enables bsInst.FilterDelta instrument command
.const bsChangeNoteSupport = 0			// enables bsCmd.ChangeNote track command (changes note without restarting instrument)

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

bsCtrl:
{
.enum {						// SID Control register bits
	VoiceOn = 1,			// AKA Gate
	SyncOn = 2,
	RingOn = 4,
	Disable = 8,
	Triangle = 16,			// Set Triangle Waveform
	SawTooth = 32,			// Set SawTooth Waveform
	Rectangle = 64,			// Set Rectangle Waveform, uses the Pulse register
	Noise = 128				// Set Noise Waveform
}
}

// Filter types, used with bsInst
bsFilter: {
.enum {				// use with bsInstSetFilterMode .macro
	LowPass = $10,
	BandPass = $20,
	HighPass = $40
}
}

// pattern commands (unused notes can be removed as long as FreqTablePalLo & FreqTablePalHi matches with order)
bsCmd: {
.enum {
	End,	// end pattern / 
	Notes, // start of notes
	C_1 = bsCmd.Notes,
	Cs1,
	D_1,
	Ds1,
	E_1,
	F_1,
	Fs1,
	G_1,
	Gs1,
	A_1,
	As1,
	B_1,
	C_2,
	Cs2,
	D_2,
	Ds2,
	E_2,
	F_2,
	Fs2,
	G_2,
	Gs2,
	A_2,
	As2,
	B_2,
	C_3,
	Cs3,
	D_3,
	Ds3,
	E_3,
	F_3,
	Fs3,
	G_3,
	Gs3,
	A_3,
	As3,
	B_3,
	C_4,
	Cs4,
	D_4,
	Ds4,
	E_4,
	F_4,
	Fs4,
	G_4,
	Gs4,
	A_4,
	As4,
	B_4,
	C_5,
	Cs5,
	D_5,
	Ds5,
	E_5,
	F_5,
	Fs5,
	G_5,
	Gs5,
	A_5,
	As5,
	B_5,
	C_6,
	Cs6,
	D_6,
	Ds6,
	E_6,
	F_6,
	Fs6,
	G_6,
	Gs6,
	A_6,
	As6,
	B_6,
	C_7,
	Cs7,
	D_7,
	Ds7,
	E_7,
	F_7,
	Fs7,
	G_7,
	Gs7,
	A_7,
	As7,
	B_7,
	C_8,
	Cs8,
	D_8,
	Ds8,
	E_8,
	F_8,
	Fs8,
	G_8,
	Gs8,
	A_8,
	As8,
	B_8,
	NotesEnd,
	Instrument = bsCmd.NotesEnd, // change instrument for this voice
	ChangeNote = bsCmd.Instrument + bsMaxInstruments, // Change note without restarting instrument
	Wait_1,
}
}

// Instrument Commands
bsInst: {
.enum {
	End,				// end of instrument script
	Wait_1,				// want # frames
	Effects = bsMaxInstrumentWait, // instrument effects begin here
	Control = bsInst.Effects, // Control, use for waveform and to trigger release
	Pulse,				// Followed by two bytes pulse width
	PulseDelta,			// Followed by signed byte pulse delta
	FilterCutoff,		// Set filter cut off frequency bits 3-11
	FilterResonance,	// Set filter resonance, followed by preshifted byte
	FilterEnable,		// Enable filter for voice
	FilterDisable,		// Disable filter for voice
	FilterMode,			// Filter mode, followed by $10 (lo), $20 (band), $40 (high)
	FilterDelta,		// Set Filter Frequency Delta followed by signed byte
	Arpeggio,			// Set arpeggio index for instrument
	Goto,				// Followed by intrument index
}
}

// SONG FUNCTIONS AND MACROS

.function bsPatternNum(track) { (*-track)>>1 }

.macro bsSetInstrument(instrument) {
	dc.b bsCmd.Instrument + instrument
}
.macro bsPatternWait(frames) {
	dc.b bsCmd.Wait_1 + frames-1
}
.macro bsPatternEnd() {
	dc.b bsCmd.End
}
.macro bsNote(note) {
	dc.b note
}
.macro bsInstEnd() {
	dc.b bsInst.End
}
.macro bsInstWait(frames) {
	dc.b bsInst.Wait_1 + frames - 1
}
.macro bsInstGoto(instrument, where) {
	dc.b bsInst.Goto, where - instrument
}


.macro bsInstSetup(waveform, Attack, Decay, Sustain, Release) {
	dc.b bsCtrl.VoiceOn | waveform, (Attack<<4)|Decay, (Sustain<<4)|Release
}
.macro bsInstControl(value) {
	dc.b bsInst.Control, value
}
.macro bsInstSetPulse(pulse) {
	dc.b bsInst.Pulse
	dc.w pulse
}
.macro bsChangeNote(note) {
	dc.b bsCmd.ChangeNote, note
}
.macro bsInstSetFilterCutoff(freq) {
	dc.b bsInst.FilterCutoff, freq
}
.macro bsInstSetFilterResonance(res) {
	dc.b bsInst.FilterResonance, res
}
.macro bsInstFilterEnable() {
	dc.b bsInst.FinterEnable
}
.macro bsInstSetFilterMode(mode) {
	dc.b bsInst.FilterMode, mode
}
.macro bsInstFilterDelta(delta) {
	dc.b bsInst.FilterDelta, delta
}
.macro bsInstArpeggio(index) {
	dc.b bsInst.Arpeggio, index
}
.macro bsInstPulseDelta(delta) {
	dc.b bsInst.PulseDelta, delta
}
