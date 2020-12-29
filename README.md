# Bullshit Player
 C64 music player for easy modification

## What is this?

Source code music and sound effects player for Commodore 64. Created for my own use
and as an example or starting point for anyone interested in creating a custom player
for C64

## How is the Bullshit Player used

Enter simple instrument and pattern commands as source code, assemble and play back with a call to UpdateMusicPlayer each frame. Modify code as desired to optimize features and size.

## Basic overview of the files

### music.i

music.i contains shared definitions between the music player, music creation and host code.
* The top of the file contains SID register addresses and global flags to control features of the player.
* The next segment is hard coded constants for number of music voices and sound effect voices. If needed custom code to reserve a music voice for temporarily playing sound effects.
The number of instruments and wait steps can also be customized here.
* Next are enumerations for bsCtrl (SID Control register flags), bsFilter (SID Filter Mode), bsCmd (Pattern commands including notes), bsInst (Instrument commands).
* Next follows macros to help type in music (see below)

### music.s

* At the top are all the variables needed for the player. This block can be relocated to BSS memory and initialized with all 0 except bsTrackerTempoWait and bsPatternVoiceWait which should be initialized to 1, and bsVolume which should be default to 15
* After that are constants, these can be relocated to where they fit best
* After that is UpdateMusicPlayer which is the single call needed for playing music
* The next block after update is the Instrument code which is entirely handled by UpdateMusicPlayer except if sound effects are played using bsSfx
* The next block is the Tracker update code

## Supported Features

* Basic instrument ADSR
* Instrument scripting
* Pulse width sliding
* Filter setup
* Filter cutoff frequency sliding
* Arpeggio support (relative halfnotes)
* Changing note without restarting instruments
* Declare music voices and sound effect voices
* Pause voices
* Play instrument as a sound effect
* Multi song support

## Creating instruments and music

A music project must contain:

* Instrument List: InstrumentsLo, InstrumentsHi
  - Array of pointers to instruments
  - Instruments start with a bsInstSetup (waveform, extra control bits, envelope)
  - Instrument script starts immediately after, minimally requires a bsInstEnd
  - Use bsInstWait \<frames\> to wait for a certain number of frames
  - Use bsInstGoto to jump to a byte in a script for looping effects
  - Use bsInstControl \<waveform\> to trigger envelope release
* Track List per Voice: VoiceTracksLo, VoiceTracksHi
  - Needs one array of Patterns for each Music Voice
  - Multi song support by having sequential lists in each track,
	then overwrite bsVoiceTrackIndex and set bsTrackerTempoWait and bsPatternVoiceWait to 1
* Patterns
  - Patterns are lists of bsCmd commands which includes setting instruments,
	playing notes, changing note on a plaing instrument, waiting and ending a pattern
  - Patterns can be up to 255 bytes, number of tracker steps doesn't matter
  - Patterns in different voices doesn't need to be the same length

Optional project parts

* Arpeggio Table (if code support enabled)
  - All instruments share a single 255 byte table and indexes into it to make the code simpler

To support typing in patterns and instruments there are a selection of macros available

### Pattern Commands

* bsSetInstrument instrument
  - set the current instrument by 0-based index into the instrument list
* bsPatternWait steps
  - wait for a number of steps/lines (tempo * steps frames)
* bsPatternEnd
  - end this pattern, the voice track will step to the next pattern and start from the top
* bsNote note
  - note is from bsCmd enum, start the instrument at the given note

### Instrument Commands

* bsInstSetup
  - Initial instrument setup command
* bsInstControl value
  - Change the SID control register for this voice, uses bsCtrl flags combined with | (or)
* bsInstWait frames
  - Wait a number of frames before continuing the script
* bsInstEnd
  - End the script for this instrument
* bsInstGoto instrument, where
  - Jump to a point in the current instrument script
* bsInstSetPulse pulse
  - Set a pulse width for playing rectangle waveform sounds (bsCtrl.Rectangle)
* bsChangeNote note
  - If change note supported, change the instrument note without restarting it
* bsInstSetFilterCutoff frequency
  - If filter supported, sets the upper 8 bits of the SID filter cutoff frequency
* bsInstSetFilterResonance resonance
  - If filter supported, set the resonance of the SID filter
* bsInstFilterEnable
  - If filter supported, enable it for this instrument
* bsInstFilterDisable
  - If filter supported, disable it for this instrument
* bsInstSetFilterMode mode
  - If filter supported set the filter mode (bsFilter.LowPass, bsFilter.BandPass or bsFilter.HighPass)
* bsInstFilterDelta delta
  - If filter and filter delta supported, delta value of upper filter cutoff frequency per frame, signed
* bsInstArpeggio index
  - If Arpeggio enabled, start playing at the given index into the global arpeggio table
* bsInstPulseDelta delta
  - If PulseDelta supported, add/subtract this value each frame to the pulse width of the voice this instrument is playing on.

