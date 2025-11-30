/* MIT License
 *
 * Copyright (c) 2025 Masakk1
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
 */

[GtkTemplate (ui = "/io/github/masakk1/press/window.ui")]
public class Press.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ComboRow quality_selection;

    [GtkChild]
    private unowned Adw.ActionRow source_directory_row;

    [GtkChild]
    private unowned Gtk.Button source_directory_button;

    public Window (Gtk.Application app) {
        application = app;

        // Quality Presets
        var presets_list = new Gtk.StringList (null);
        foreach(QualityPreset preset in QualityPresets.list){
            presets_list.append (preset.name);
        }
        presets_list.append (QualityPresets.custom);
        quality_selection.model = presets_list;

        quality_selection.notify["selected"].connect (this.selected_quality_preset);

        // Source Directory
        source_directory_button.clicked.connect (this.set_source_directory);
    }

    private void set_source_directory() {
        this.select_directory ((folder) => {
            string ? subtitle = folder != null ? folder.get_path () : null;

            source_directory_row.subtitle = subtitle;
        });
    }

    private File ? select_directory(Func<File> callback) {
        var dialog = new Gtk.FileDialog ();
        File ? folder = null;
        dialog.select_folder.begin (this, null, (obj, res) => {
            try {
                folder = dialog.select_folder.end (res);
                callback (folder);
            } catch ( Error err ){
                stderr.printf ("Error trying to open folder");
            }
        });
        return folder;
    }

    private void selected_quality_preset() {
        var selected_item = quality_selection.selected_item;
        var str_obj = selected_item as Gtk.StringObject;

        if( str_obj.get_string () == QualityPresets.custom ){

        }
    }

}
