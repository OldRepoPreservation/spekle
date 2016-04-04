## Spekle: Vala-based FFMPEG Spectrum Analysis of Audio Video Media ##



&lt;A href="http://www.spek-project.org/"&gt;

Spek

&lt;/A&gt;

 is a 

&lt;A href="http://live.gnome.org/Vala"&gt;

Vala

&lt;/A&gt;

 and Gtk-based interactive program to display spectrograms of audio using a variety of codecs supported by [ffmpeg library and libavcodec](http://www.ffmpeg.org/). Spekle is a fork of Alexander Kojevnikov's "

&lt;A href="http://versia.com/2010/07/13/spek-0-6-release/"&gt;

spek 0.6

&lt;/A&gt;

" which doesn't require an X $DISPLAY to be set, takes numerous command-line-options, and is desgined to operate in "batch" mode. It's basically a brute-force cleansing of all Gtk code, leaving behind the ffmpeg based decoding,  avfft spectrograms, and a fast-and effective Vala-based implementation.

Planned future work includes adding 

&lt;A href="http://omras2.org/SonicAnnotator"&gt;

Sonic Annotator

&lt;/A&gt;

 and 

&lt;A href="http://vamp-plugins.org/"&gt;

Vamp Plugins

&lt;/A&gt;

 into the analysis pipeline, and using automated video 

&lt;A href="http://code.google.com/p/ffmpegthumbnailer/"&gt;

thumbnailing

&lt;/A&gt;

 based on audio events.


&lt;A href="http://code.google.com/p/ffmpegsource/"&gt;

FFmpegSource

&lt;/A&gt;

 looks useful as well.

The following describes the 

&lt;A href="http://versia.com/2010/07/04/gstreamer-ffmpeg-and-spek/"&gt;

architectural features present in the 0.6 version of 'spek'

&lt;/A&gt;

 which is the origin of 'spekle.'
<blockquote>
Next version of Spek will use FFmpeg libraries to decode audio files. There are several reasons for the switch from GStreamer:<br>
<br>
GStreamer is a fantastic framework for building complex multimedia pipelines, however what Spek really needs is a simple decoder and FFmpeg’s libavformat and libavcodec do just that.<br>
<br>
To handle some audio formats (e.g. APE and DTS), GStreamer relies on FFmpeg anyway, so the switch will result in lesser dependencies. It doesn’t matter too much on GNU/Linux, but this will reduce the size of the Windows and Mac OS X installers.<br>
<br>
Spek used GStreamer’s spectrum plugin to perform the actual spectral analysis, with FFmpeg I had to implement it myself. The code I ended up with is very compact and gives room for a lot of experimentation, from using different window functions (it’s still Hamming) and working on performance optimisations to switching to a faster FFT library.<br>
<br>
The last bit is actually done, Spek now uses FFTW which in my tests is 1.5x to 2x faster than Kiss FFT used by GStreamer. Apart from that, FFTW can scale to multiple threads with near linear performance increase, future versions of Spek will take advantage of this.<br>
<br>
UPDATE: As one of commenters pointed out, FFTs on small number of samples are not very parallelisable and my benchmarks confirm this. Also, I switched from FFTW to avfft which is built into FFmpeg. It’s a little bit faster than FFTW for my particular use case. Lastly, 1.5x to 2x speed up was actually caused by a faster decoder, not by a faster FFT library.<br>
</blockquote>

Current status: As of now, it produces pretty spectrograms as large images like this (see also [SpekleGallery](SpekleGallery.md) [RAPodcastSpectrograms](RAPodcastSpectrograms.md)):

![http://nielsmayer.com/npm/33.m4a.png](http://nielsmayer.com/npm/33.m4a.png)

taken from a podcast:

<blockquote>
<a href='http://www.whatpeopleplay.com/tracks/podcasts/33.m4a'>http://www.whatpeopleplay.com/tracks/podcasts/33.m4a</a> Mon, 16 Aug 2010 14:34:55 +0200 www.whatpeopleplay.com podcast #33 for whatpeopleplay.com 16082010 Marcel Knopf started his own imprint Clap Your Hands which has reached it's 4th release now. On this show Marcel introduces the label and delivers a fresh 1-hour-Dj set including his own track next to a bunch of other clubby tunes reaching from Slam on Soma, Sascha Funke & Nina Kraviz to Mood 2 Swing, Soul Phiction, Shlomi Aber and many more...Enjoy this! no 01:03:03<br>
</blockquote>

Like this:

```
$ spekle http://www.whatpeopleplay.com/tracks/podcasts/33.m4a
http://www.whatpeopleplay.com/tracks/podcasts/33.m4a
Spekle: calling open_file(http://www.whatpeopleplay.com/tracks/podcasts/33.m4a)
Spekle: start()ing...
[0;33m[mov,mp4,m4a,3gp,3g2,mj2 @ 0x221ce60]multiple edit list entries, a/v desync might occur, patch welcome
[0m[0;33m[mov,mp4,m4a,3gp,3g2,mj2 @ 0x221ce60]max_analyze_duration reached
[0mSpekle: media_retrieved_cb(num_samples=3787, duration=3787.06)
Spekle: processing http://www.whatpeopleplay.com/tracks/podcasts/33.m4a .............................................( 42961 mS )... DONE!
Spekle: save() my_width=3787 duration=3787.06 s. description='Advanced Audio Coding, 128 kbps, 44100 Hz, 2 channels'... DONE!
Spekle: saving '33.m4a.png'... DONE!
```

Note that the podcast claims "01:03:03" whereas spekle returns "3787.06 s" == "01:03:07.060" ...

For instructions on obtaining source, prerequisites, compiling/installing:
http://spekle.googlecode.com/svn/trunk/README