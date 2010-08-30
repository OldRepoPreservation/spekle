/* spek-spectrogram.vala
 *
 * Copyright (C) 2010  Alexander Kojevnikov <alexander@kojevnikov.com>
 * Copyright (C) 2010  Niels Mayer ( http://nielsmayer.com )
 *
 * Spekle is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Spekle is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Spekle.  If not, see <http://www.gnu.org/licenses/>.
 */

using Cairo;
using Gdk;
using Pango;
using Posix;

namespace Spek {
	class Spectrogram : GLib.Object {

		// Added by NPM in converting to Gtk-less, Cairo-only...
		private int my_width = -1; // NPM: should be set by still_processing_p() before draw() or a warning given
		private int my_height = 300; // NPM
		private int seg_count = -1;	 // NPM
		private int last_count = -1;	 // NPM
		private ImageSurface my_image = null; // NPM

		public string file_name { get; private set; }
		private Pipeline pipeline;
		private const int THRESHOLD = -92;
		private const int NFFT = 2048;
		private const int BANDS = NFFT / 2 + 1;

		private ImageSurface image = null;
		private ImageSurface palette;

		private const int LPAD = 60;
		private const int TPAD = 60;
		private const int RPAD = 60;
		private const int BPAD = 40;
		private const int GAP = 10;
		private const int RULER = 10;
		private double FONT_SCALE = 1.0;

		public Spectrogram () {
			// Pango/Quartz fonts are smaller than on X.
			if (Config.HOST_OS.down ().has_prefix ("darwin")) {
				FONT_SCALE = 1.4;
			}

			// Pre-draw the palette.
			palette = new ImageSurface (Format.RGB24, RULER, BANDS);
			for (int y = 0; y < BANDS; y++) {
				var color = get_color (y / (double) BANDS);
				for (int x = 0; x < RULER; x++) {
					put_pixel (palette, x, y, color);
				}
			}
		}

		public void open (string file_name) {
			this.file_name = file_name;

            //print (_("Spekle: calling start() in Spectrogram.open()\n"));
			start ();
		}

		/*
		 * NPM: "Iterator" to determine if FFT processing of segments has
		 * completed. Note that first run, which should occur after the
		 * media is retrieved (TODO, add lock for this, as right now it
		 * just assumes enough of the media could be retrieved to determine
		 * the size.) ,,,
		*/
		public bool still_processing_p() {
//			print (_("Spekle: still_processing_p() my_width=%i duration=%.2f s. description='%s'\n"),
//				   this.my_width,
//				   pipeline.duration,
//				   pipeline.description);
			if (this.last_count == this.seg_count) { // if stasis, then done...
				this.last_count = this.seg_count;
				return (false);
			}
			else {
				this.last_count = this.seg_count;
				return (true);
			}
		}

		// NPM: this only gets called when all processing finished, After start() called, 'image' is created,
		// and all data has been processed into 'image'.
		public void save() {
//			var s = new ImageSurface(Format.RGB24, my_width, my_height); //-->created on first call to still_processing_p() to base size on media
			var iname = GLib.Path.get_basename (this.file_name);
			iname += ".png";

			if (this.my_image != null) {
				print (_("Spekle: save() my_width=%i duration=%.2f s. description='%s'.."),
					   this.my_width,
					   pipeline.duration,
					   pipeline.description);
				draw (new Cairo.Context(this.my_image)); // NPM: this.my_image created on first run of still_processing_p()
				print (_(". DONE!\nSpekle: saving '%s'.."), iname);
				this.my_image.write_to_png(iname);
				print (_(". DONE!\n"));

			}
			else {
				print (_("Spekle: WARNING save() called before my_image created: my_width=%i duration=%.2f s. description='%s'\n"),
					   this.my_width,
					   pipeline.duration,
					   pipeline.description);
				print (_(". INTERNAL ERROR! NOTHING DONE\n"));
			}
		}

//		public void save (string image_fname) {
//			var surface = new ImageSurface (Format.RGB24, my_width, my_height);
//			draw (new Cairo.Context (surface));
//			surface.write_to_png (image_fname);
//		}

		private void start () {
			if (pipeline != null) {
				pipeline.stop ();
			}
			print (_("Spekle: start()ing...\n"));

			// The number of samples is the number of pixels available for the image.
			// The number of bands is fixed, FFT results are very different for
			// different values but we need some consistency.
//			int samples = my_width - LPAD - RPAD;
//			if (samples > 0) {

				// NPM: nb: compared to "spek 0.6" I removed "samples", the
				// third parameter, the number of samples for the given
				// image surface of the spectrogram. In 'spekle' the number
				// of samples is based on media length, so delay the
				// computation of exact spectrogram width until media
				// information is known.  The creation of these data is now
				// in still_processing_p() in this file.
//				image = new ImageSurface (Format.RGB24, samples, BANDS);
			pipeline = new Pipeline (file_name, BANDS, 0, THRESHOLD, data_cb, media_retrieved_cb);
			pipeline.start ();
//			} else {
//				image = null;
//				pipeline = null;
//			}
		}

//		private int prev_width = -1;
//		private override void size_allocate (Gdk.Rectangle allocation) {
//			base.size_allocate (allocation);
//
//			bool width_changed = prev_width != my_width;
//			prev_width = my_width;
//
//			if (file_name != null && width_changed) {
//				start ();
//			}
//		}

		// callback out of spek-pipeline sizing the image based on media length.
		private void media_retrieved_cb (int num_samples, double duration) { // NPM
			if (num_samples > 0)
				print (_("Spekle: media_retrieved_cb(num_samples=%i, duration=%.2f)\n"),
					   num_samples,
					   duration);
			else {
				print (_("Spekle: Internal error in media retrieval or processing, exiting...\n"));
				Posix.exit(254);
			}
			
			this.my_width = num_samples;
			this.my_image = new ImageSurface(Format.RGB24,
											 this.my_width,
											 this.my_height);
			// NPM: creation of 'image' was originally in start()
			// in original spek 0.6
			this.image  = new ImageSurface(Format.RGB24,
										   this.my_width - LPAD - RPAD,
										   BANDS);
		}

		private double log10_threshold = Math.log10 (-THRESHOLD);
		private void data_cb (int sample, float[] values) {
			if (image == null) {
				print (_("Spekle: Internal error, data_cb() called before image created; exiting...\n"));
				Posix.exit(254);
			}
//			else {
//			print (_("Spekle: data_cb(sample=%i) my_width=%i duration=%.2f s. description='%s'\n"),
//				   sample,
//				   this.my_width,
//				   pipeline.duration,
//				   pipeline.description);
//			}

			for (int y = 0; y < BANDS; y++) {
				var level = double.min (
					1.0, Math.log10 (1.0 - THRESHOLD + values[y]) / log10_threshold);
				put_pixel (image, sample, y, get_color (level));
			}
			this.seg_count = sample;
		}

//		private override bool expose_event (EventExpose event) {
//			var cr = cairo_create (my_cairo_surface);
//
//			// Clip to the exposed area.
//			cr.rectangle (event.area.x, event.area.y, event.area.width, event.area.height);
//			cr.clip ();
//
//			draw (cr);
//			return true;
//		}

		private void draw (Cairo.Context cr) {
			if (this.my_width < 0) {
				print (_("Spekle: Internal error draw() called before image width set; exiting...\n"));
				Posix.exit(254);
			}
			double w = my_width;
			double h = my_height;
			int text_width, text_height;

			// Clean the background.
			cr.set_source_rgb (0, 0, 0);
			cr.paint ();

			// Spek version
			cr.set_source_rgb (1, 1, 1);
			var layout = cairo_create_layout (cr);
			layout.set_font_description (FontDescription.from_string (
				"Sans " + (9 * FONT_SCALE).to_string ()));
			layout.set_width (RPAD * Pango.SCALE);
			layout.set_text ("v" + Config.PACKAGE_VERSION, -1);
			layout.get_pixel_size (out text_width, out text_height);
			int line_height = text_height;
			cr.move_to (w - (RPAD + text_width) / 2, TPAD - GAP);
			cairo_show_layout_line (cr, layout.get_line (0));
			layout.set_font_description (FontDescription.from_string (
				 "Sans Bold " + (10 * FONT_SCALE).to_string ()));
			layout.set_text (Config.PACKAGE_NAME, -1);
			layout.get_pixel_size (out text_width, out text_height);
			cr.move_to (w - (RPAD + text_width) / 2, TPAD - 2 * GAP - line_height);
			cairo_show_layout_line (cr, layout.get_line (0));

			if (image != null) {
				// Draw the spectrogram.
				cr.translate (LPAD, h - BPAD);
				cr.scale (1, -(h - TPAD - BPAD) / image.get_height ());
				cr.set_source_surface (image, 0, 0);
				cr.paint ();
				cr.identity_matrix ();

				// Prepare to draw the rulers.
				cr.set_source_rgb (1, 1, 1);
				cr.set_line_width (1);
				cr.set_antialias (Antialias.NONE);
				layout.set_font_description (FontDescription.from_string (
					"Sans " + (8 * FONT_SCALE).to_string ()));
				layout.set_width (-1);

				// Time ruler.
				var duration_seconds = (int) pipeline.duration;
				var time_ruler = new Ruler (
					"00:00",
					{1, 2, 5, 10, 20, 30, 1*60, 2*60, 5*60, 10*60, 20*60, 30*60},
					duration_seconds,
					1.5,
					unit => (w - LPAD - RPAD) * unit / duration_seconds,
					unit => "%d:%02d".printf (unit / 60, unit % 60));
				cr.translate (LPAD, h - BPAD);
				time_ruler.draw (cr, layout, true);
				cr.identity_matrix ();

				// Frequency ruler.
				var freq = pipeline.sample_rate / 2;
				var rate_ruler = new Ruler (
					"00 kHz",
					{1000, 2000, 5000, 10000, 20000},
					freq,
					3.0,
					unit => (h - TPAD - BPAD) * unit / freq,
					unit => "%d kHz".printf (unit / 1000));
				cr.translate (LPAD, TPAD);
				rate_ruler.draw (cr, layout, false);
				cr.identity_matrix ();

				// File properties.
				cr.move_to (LPAD, TPAD - GAP);
				layout.set_font_description (FontDescription.from_string (
					"Sans " + (9 * FONT_SCALE).to_string ()));
				layout.set_width ((int) (w - LPAD - RPAD) * Pango.SCALE);
				layout.set_ellipsize (EllipsizeMode.END);
				layout.set_text (pipeline.description, -1);
				cairo_show_layout_line (cr, layout.get_line (0));
				layout.get_pixel_size (out text_width, out text_height);

				// File name.
				cr.move_to (LPAD, TPAD - 2 * GAP - text_height);
				layout.set_font_description (FontDescription.from_string (
					"Sans Bold " + (10 * FONT_SCALE).to_string ()));
				layout.set_width ((int) (w - LPAD - RPAD) * Pango.SCALE);
				layout.set_ellipsize (EllipsizeMode.START);
				layout.set_text (file_name, -1);
				cairo_show_layout_line (cr, layout.get_line (0));
			}

			// Border around the spectrogram.
			cr.set_source_rgb (1, 1, 1);
			cr.set_line_width (1);
			cr.set_antialias (Antialias.NONE);
			cr.rectangle (LPAD, TPAD, w - LPAD - RPAD, h - TPAD - BPAD);
			cr.stroke ();

			// The palette.
			cr.translate (w - RPAD + GAP, h - BPAD);
			cr.scale (1, -(h - TPAD - BPAD) / palette.get_height ());
			cr.set_source_surface (palette, 0, 0);
			cr.paint ();
			cr.identity_matrix ();
		}

		private void put_pixel (ImageSurface surface, int x, int y, uint32 color) {
			var i = y * surface.get_stride () + x * 4;
			unowned uchar[] data = surface.get_data ();

			// Translate uchar* to uint32* to avoid dealing with endianness.
			uint32 *p = (uint32 *) (&data[i]);
			*p = color;
		}

		// Modified version of Dan Bruton's algorithm:
		// http://www.physics.sfasu.edu/astro/color/spectra.html
		private uint32 get_color (double level) {
			level *= 0.6625;
			double r = 0.0, g = 0.0, b = 0.0;
			if (level >= 0 && level < 0.15) {
				r = (0.15 - level) / (0.15 + 0.075);
				g = 0.0;
				b = 1.0;
			} else if (level >= 0.15 && level < 0.275) {
				r = 0.0;
				g = (level - 0.15) / (0.275 - 0.15);
				b = 1.0;
			} else if (level >= 0.275 && level < 0.325) {
				r = 0.0;
				g = 1.0;
				b = (0.325 - level) / (0.325 - 0.275);
			} else if (level >= 0.325 && level < 0.5) {
				r = (level - 0.325) / (0.5 - 0.325);
				g = 1.0;
				b = 0.0;
			} else if (level >= 0.5 && level < 0.6625) {
				r = 1.0;
				g = (0.6625 - level) / (0.6625 - 0.5f);
				b = 0.0;
			}

			// Intensity correction.
			double cf = 1.0;
			if (level >= 0.0 && level < 0.1) {
				cf = level / 0.1;
			}
			cf *= 255.0;

			// Pack RGB values into Cairo-happy format.
			uint32 rr = (uint32) (r * cf + 0.5);
			uint32 gg = (uint32) (g * cf + 0.5);
			uint32 bb = (uint32) (b * cf + 0.5);
			return (rr << 16) + (gg << 8) + bb;
		}
	}
}
