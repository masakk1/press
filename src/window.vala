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
    private unowned Adw.ActionRow source_directory_row;

    [GtkChild]
    private unowned Gtk.Button source_directory_button;

    [GtkChild]
    private unowned Adw.ActionRow target_directory_row;

    [GtkChild]
    private unowned Gtk.Button target_directory_button;

    [GtkChild]
    private unowned Adw.ComboRow quality_preset_selection;

    [GtkChild]
    private unowned Adw.PreferencesGroup custom_quality_group;

    [GtkChild]
    private unowned Adw.ComboRow custom_quality_format;

    [GtkChild]
    private unowned Adw.ButtonRow compress_button;

    public Window (Gtk.Application app) {
        application = app;

        // Quality Presets
        var presets_list = new Gtk.StringList (null);
        foreach(var preset in QualityPresets.list){
            presets_list.append (preset.name);
        }
        presets_list.append (QualityPresets.custom);
        quality_preset_selection.model = presets_list;

        quality_preset_selection.notify["selected"].connect (this.selected_quality_preset);

        // Quality Formats
        var format_list = new Gtk.StringList (null);

        foreach(var format in QualityFormats.list){
            format_list.append (format.name);
        }

        custom_quality_format.model = format_list;

        // Source Directory
        source_directory_button.clicked.connect (this.set_source_directory);

        // Target Directory
        target_directory_button.clicked.connect (this.set_target_directory);
    }

    private void set_source_directory() {
        this.select_directory ((folder) => {
            string ? subtitle = folder != null ? folder.get_path () : null;

            source_directory_row.subtitle = subtitle;
        });
    }

    private void set_target_directory() {
        this.select_directory ((folder) => {
            string ? subtitle = folder != null ? folder.get_path () : null;

            target_directory_row.subtitle = subtitle;
        });
    }

    private void select_directory(Func<File> callback) {
        var dialog = new Gtk.FileDialog ();
        dialog.select_folder.begin (this, null, (obj, res) => {
            try {
                File folder = dialog.select_folder.end (res);
                callback (folder);
            } catch ( Error err ){
                stderr.printf ("Error trying to open folder");
            }
        });
    }

    private void selected_quality_preset() {
        var selected_item = quality_preset_selection.selected_item;
        var str_obj = selected_item as Gtk.StringObject;

        if( str_obj.get_string () == QualityPresets.custom ){
            custom_quality_group.visible = true;
        } else {
            print (@"$(QualityFormats.flac.name)");
            custom_quality_group.visible = false;
        }
    }

}
