---
aliases: 
  - Make a new parameter in the tts tool
up: "[[conversation]]"
type: 
status: 
down: 
prev: 
next: 
same: 
project: 
area: 
tags: []
created: 2026-05-29
due: 
---

# Make a new parameter in the tts tool

## Description

# Make a new parameter in the tts tool that will solve the problem when the subtitle track, even after the stage of adjusting to the duration of the subtitle from the source srt file from which we create the recording, overlaps the next subtitle, when the audio of two adjacent subtitles is superimposed on each other, the idea is that when this parameter is turned on, it would not be the recording to the subtitle, but, on the contrary, the subtitle to the recording, at the stage when all recordings are to subtitles tts are generated and before audio adjustment, before assembly into a file, before final conversion into an mp4 file.

## Description

Here we also need to provide for when we launch 2 srt files within one processing, selecting them and sending them to Sent to, they can have different durations, I think we need to generate for each record, evaluate their resulting durations and then decide how best to change the durations, timeline of the files. You need to understand that usually such synthetic files initially have the same timeline and differ only in their content (en and its translation into ru, for example), but there may also be files downloaded that may have a different number of subtitles and slightly different timelines, different structures, this can be postponed to the next phase of refinement, this algorithm. Adjusting speed should be done based on the first subtitles, based on this, the second and subsequent subtitles of the created recordings, in turn, rely on the first subtitles, because it is the first, foreign subtitles that are most important for me to have the highest quality, original (as TTS gives), without adjustment, and the subsequent ones are an appendix, an addition to them and I understand them better and they are not the main goal, these are auxiliary artifacts of the work. ~~We also need to provide for the following thing: if there is already a file 20260528165459-name.mp4 of the main subtitles, then we do not use this new option, since these are authentic, most likely subtitles, not synthesized (we believe so).~~ This is not very relevant, because we will create it in a new ZID folder.

[[20260528112827-сделать-в-tts-инструменте|Сделать в tts инструменте новый параметр, который позволит решить проблему когда дорожка субтитра даже после этапа подгонки под длительность субтитра по исходному файлу srt, по которому мы создаем запись, перекрывает следующий субтитр, когда происходит наложение аудио друг на друга двух соседних субтитров, идея в том, чтобы при включении этого параметра происходила бы подгонка не записи под субтитр, а наоборот, субтитра под запись, на этапе когда все записи к субтитрам сгенерированы tts и до подгонки аудио, до сборки в файл, до итоговой конвертации в mp4-файл.]]



## MOC.



## Notes


