#Include "audiocontroller.bi"

#Include "hashmap.bi"
#Include "primitive.bi"
#Include "bass.bi"
#Include "debuglog.bi"

Const As Single FADE_VELOCITY_PER_SEC = 0.1
Const As Single AUDIO_FADE_DISTANCE = 1000.0
Const As Single DISTANCE_DELTA_SCALE = 0.01
Const As Single SAMPLE_RATE = 44100

DECLARE_DARRAY(Integer_)
dsm_HashMap_define(ZString, Integer_)

Dim As DArray_Integer_ AudioController.samples_
Dim As DArray_Integer_ AudioController.musics_
Dim As dsm.HashMap(ZString, Integer_) AudioController.sampleCache_
Dim As dsm.HashMap(ZString, Integer_) AudioController.musicCache_
Dim As Single AudioController.musicVolume_ = 1.0
Dim As Boolean AudioController.fadeIn_ = TRUE
Dim As Boolean AudioController.musicPaused_ = FALSE
Dim As Integer AudioController.currentMusicHandle_ = -1
Dim As Integer AudioController.currentMusicChannel_ = -1
Dim As Single AudioController.musicVol_ = 1.0
Dim As Double AudioController.freqMul_ = 1.0
Dim As Double AudioController.sampleRate_ = SAMPLE_RATE 'const

Const As Integer BASS_TRUE = 1
Const As Integer BASS_FALSE = 0

Sub AudioControllerConstructor() Constructor
	If (HiWord(BASS_GetVersion()) <> BASSVERSION) Then
		Print "Mismatched BASS library. Expected: " & Str(BASSVERSION) & " found " & Str(HiWord(BASS_GetVersion()))
		End
	End If
	If (BASS_Init(-1, SAMPLE_RATE, 0, 0, 0) <> BASS_TRUE) Then
		Print "Audio initialization at 44.1kHz failed with error: " & BASS_ErrorGetCode()
		End
	End If
End Sub

Sub AudioControllerDestructor() Constructor
	For i As Integer = 0 To AudioController.samples_.size() - 1
		BASS_SampleFree(AudioController.samples_[i])
	Next i
	For i As Integer = 0 To AudioController.musics_.size() - 1
		BASS_SampleFree(AudioController.musics_[i])
	Next i
	BASS_Free()	
End Sub

Constructor AudioController()
	''
End Constructor

Static Sub AudioController.setMusicVol(v As Single)
	musicVol_ = v
End Sub

Static Function AudioController.getSample(audioFile As ZString Ptr) As Integer
	Dim As Integer_ sampleRef = Any
  If Not sampleCache_.retrieve(*audioFile, sampleRef) Then
    DArray_Integer__Emplace(samples_, BASS_SampleLoad(0, audioFile, 0, 0, 4, 0))
    sampleRef = samples_.back()
    DEBUG_ASSERT(samples_.back() <> -1)
    sampleCache_.insert(*audioFile, sampleRef)
  EndIf
  Return sampleRef.getValue()
End Function

Static Function AudioController.getMusic(audioFile As ZString Ptr) As Integer
	Dim As Integer_ musicRef = Any
  If Not musicCache_.retrieve(*audioFile, musicRef) Then
    DArray_Integer__Emplace(musics_, BASS_SampleLoad(0, audioFile, 0, 0, 1, BASS_SAMPLE_LOOP))
    musicRef = musics_.back()
    DEBUG_ASSERT(musics_.back() <> -1)
    musicCache_.insert(*audioFile, musicRef)
  EndIf
  Return musicRef.getValue()
End Function

Static Sub AudioController.cacheMusic(audioFile As ZString Ptr)
	getMusic(audioFile)
End Sub

Static Sub AudioController.cacheSample(audioFile As ZString Ptr)
	getSample(audioFile)
End Sub
 	
Static Sub AudioController.update(dt As Double)
	musicVolume_ += IIf(fadeIn_, FADE_VELOCITY_PER_SEC, -FADE_VELOCITY_PER_SEC)*dt
	If musicVolume_ > musicVol_ Then
		musicVolume_ = musicVol_
	ElseIf musicVolume_ < 0.0 Then
		musicVolume_ = 0.0
	EndIf
	If currentMusicChannel_ <> -1 Then
		BASS_ChannelSetAttribute(currentMusicChannel_, BASS_ATTRIB_VOL, musicVolume_)
		BASS_ChannelSetAttribute(currentMusicChannel_, BASS_ATTRIB_FREQ, sampleRate_*freqMul_)
	End If
End Sub
 	
Static Sub AudioController.fadeOut()
	fadeIn_ = FALSE
End Sub

Static Sub AudioController.fadeIn()
	fadeIn_ = TRUE
End Sub
 	
Static Sub AudioController.switchMusic(audioFile As ZString Ptr, playbackPosition As LongInt)
	If audioFile <> NULL Then
		Dim As Integer musicHandle = getMusic(audioFile) 'const
		If currentMusicHandle_ <> musicHandle Then
			If currentMusicChannel_ <> -1 Then 
				BASS_ChannelStop(currentMusicChannel_)
			EndIf
			currentMusicHandle_ = musicHandle
			currentMusicChannel_ = BASS_SampleGetChannel(currentMusicHandle_, FALSE)
			DEBUG_ASSERT(currentMusicChannel_ <> -1)
		EndIf
	EndIf
	
	If playbackPosition <> -1 Then
		DEBUG_ASSERT(currentMusicChannel_ <> -1)
		BASS_ChannelSetPosition(currentMusicHandle_, playbackPosition, BASS_POS_BYTE)
	EndIf
	
	If audioFile <> NULL Then	
		BASS_ChannelPlay(currentMusicChannel_, 0)
	EndIf
	
	If musicPaused_ Then BASS_ChannelPause(currentMusicChannel_)
End Sub

Static Function AudioController.getPlaybackPosition() As LongInt
	DEBUG_ASSERT(currentMusicChannel_ <> -1)
	Dim As LongInt retValue = BASS_ChannelGetPosition(currentMusicChannel_, BASS_POS_BYTE) 'const
	DEBUG_ASSERT(retValue <> -1)
	Return retValue
End Function
 	
Static Sub AudioController.playSample(audioFile As ZString Ptr, ByRef offset As Vec2F)
	Dim As Integer sampleHandle = getSample(audioFile) 'const
	Dim As Integer sampleChannel = BASS_SampleGetChannel(sampleHandle, FALSE)	'const
	DEBUG_ASSERT(sampleChannel <> -1)
	
	Dim As Single vol = 1.0 - offset.m() / AUDIO_FADE_DISTANCE
	If vol < 0 Then vol = 0
	vol *= vol
	
	Dim As Single pan = Atn(offset.x*DISTANCE_DELTA_SCALE) / 1.5708	
	
	If BASS_ChannelSetAttribute(sampleChannel, BASS_ATTRIB_VOL, vol) = BASS_FALSE Then
		DEBUG_LOG("Failed to set volume on channel " + Str(sampleChannel))
	EndIf
	If BASS_ChannelSetAttribute(sampleChannel, BASS_ATTRIB_PAN, pan) = BASS_FALSE Then
		DEBUG_LOG("Failed to set panning on channel " + Str(sampleChannel))	
	EndIf
	If BASS_ChannelPlay(sampleChannel, 0) = BASS_FALSE Then
		DEBUG_LOG("Failed to play channel " + Str(sampleChannel))		
	EndIf
End Sub

Static Sub AudioController.resetFrequencyMul()
	freqMul_ = 1.0
End Sub

Static Sub AudioController.setFrequencyMul(m As Double)
	freqMul_ = m
End Sub

Static Sub AudioController.pauseMusic()
	If currentMusicChannel_ <> -1 Then 
		BASS_ChannelPause(currentMusicChannel_)
	End If
	musicPaused_ = TRUE
End Sub

Static Sub AudioController.playMusic() 	
	If currentMusicChannel_ <> -1 Then BASS_ChannelPlay(currentMusicChannel_, BASS_FALSE)
	musicPaused_ = FALSE
End Sub

