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

