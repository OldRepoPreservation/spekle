bin_PROGRAMS = spekle

# NPM: spek 0.6's spek.vala --> spekle.vala
# NPM: removed spek 0.6 'spek-message-bar.vala'
# NPM: spek 0.6's spek-window.vala --> spek-object.vala
spekle_SOURCES = \
	spekle.vala \
	spek-audio.c \
	spek-fft.c \
	spek-pipeline.vala \
	spek-platform.c \
	spek-ruler.vala \
	spek-spectrogram.vala \
	spek-object.vala

INCLUDES = \
	-include config.h \
	$(SPEKLE_CFLAGS) \
	$(IGE_MAC_CFLAGS) \
	-DLOCALEDIR=\""$(localedir)"\" \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DPKGLIBDIR=\""$(pkglibdir)"\"

VALAFLAGS = \
	--thread \
	--vapidir=$(srcdir)/../vapi \
	--pkg config \
	--pkg spek-audio \
	--pkg spek-fft \
	--pkg spek-platform \
	@SPEKLE_PACKAGES@

spekle_LDADD = \
	$(SPEKLE_LIBS) \
	$(IGE_MAC_LIBS)

EXTRA_DIST = \
	spek-audio.h \
	spek-fft.h \
	spek-platform.h
