/* spek-object.vala
 * NPM: was once spek-window.vala
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

using Gdk;

namespace Spek {
	public class SpekApp : GLib.Object {
		private Spectrogram spectrogram;
		private string cur_dir;

		public SpekApp (string? file_name) {
			spectrogram = new Spectrogram ();
			cur_dir = Environment.get_home_dir ();

			if (file_name != null) {
				print (_("Spekle: calling open_file(%s)\n"), file_name);
				open_file (file_name);
// Note that if save_spectrogram() called synchronously, you get this behavior and a spectrogram file that 
// includes the markings and other info, but does not have the spectrogram drawn:
// Spekle: calling draw() in Spectrogram.start()...
// Spekle: Spectrogram.data_cb(0)
// Spekle: calling save_spectrogram(/home/npm/.kde/share/apps/amarok/podcasts/That's What People Play/33.m4a)
// Spekle: Spectrogram.data_cb(1)
// Spekle: Spectrogram.data_cb(2)
// Spekle: Spectrogram.data_cb(3)
// Spekle: Spectrogram.data_cb(4)
// Spekle: Spectrogram.data_cb(5)
// Spekle: Spectrogram.data_cb(6)
//				print (_("Spekle: calling save_spectrogram(%s)\n"), file_name);
//				save_spectrogram(file_name);

//				print (_("Spekle: segments %i\n"), spectrogram.seg_count);
			}
		}

		private void open_file(string file_name) {
			cur_dir = GLib.Path.get_dirname(file_name);
			spectrogram.open(file_name);
		}

		public void wait_till_all_segments_processed_and_save() {
			var mloop
				= new GLib.MainLoop();
			var to 
				= Timeout.add(1000, () => { // every second, check if done computing
						if (spectrogram.still_processing_p()) {
							print (_("."));
							return (true);
						}
						else {
							print (_(". DONE!\n"));
							spectrogram.save();
							mloop.quit(); // quit the main loop...
							return (false);
						}
					});

			mloop.run();
		}

//		private void save_spectrogram (string file_name) {
//			cur_dir = GLib.Path.get_dirname (file_name);
//			var fname = GLib.Path.get_basename (spectrogram.file_name ?? _("Untitled"));
//			fname += ".png";
//			spectrogram.save (fname);
//		}
	}
}
