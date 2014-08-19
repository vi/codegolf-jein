codegolf-jein
=============

Toolset and example solution of "Yes or no" codegolf.

Implement your own voice recognition program.
The program should read `train/no0.wav`, `train/yes0.wav`, `train/no1.wav` and so on 
and learn to discriminate them, then read all 
`inputs/0.wav`, `inputs/1.wav` (until file not found) and output `yes` or `no` as guess.
The program may output any other line like "jein" as intermediate answer counting as half of a match.

All files are 
little endian 16-bit stereo WAV files, recorded from my laptops' microphone. 
Files' content is me saying "yes", "yeah" or "no", 
in voice or whisper, with varied intonation. 
No noise filtering or other editing was performed 
(just splitting from big recording into individual samples).

* Training dataset: http://vi-server.org/pub/codegolf-jein-train.tar.xz
* Examination dataset: http://vi-server.org/pub/codegolf-jein-exam.tar.xz (will be available later)

There is a tool for automatic accuracy measurement: `tools/runner`.

You can examine your solution using training data:

```
$ tools/runner solutions/example train train/key 
Accuracy: 548 ‰
```

or using actual examination samples, if you have them:

```
$ tools/runner solutions/example examination examination/key 
Accuracy: 532 ‰

```
