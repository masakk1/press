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
using Gee;
using Json;

// TODO: I remember there being issues when no default bitrate and samplerate were displayed
// there was a chance to run the thing compression, without having set those things.
// we should probably do some validation.

[GtkTemplate (ui = "/io/github/masakk1/press/config_page.ui")]
public class Press.ConfigPage : Adw.NavigationPage {
    [GtkChild] private unowned Adw.ActionRow source_directory_row;
    [GtkChild] private unowned Gtk.Button source_directory_button;
    [GtkChild] private unowned Adw.ActionRow target_directory_row;
    [GtkChild] private unowned Gtk.Button target_directory_button;
    [GtkChild] private unowned Adw.SwitchRow replace_destination_files_switch;
    [GtkChild] private unowned Adw.SwitchRow copy_noaudio_files_switch;
    [GtkChild] public unowned Gtk.Button compress_button;

    /*
       public string source_directory_path { get; private set; default = ""; }
       public string target_directory_path { get; private set; default = ""; }

       public bool replace_destination_files { get {
                                                return replace_destination_files_switch.active;
                                            } }
       public bool copy_noaudio_files { get {
                                         return copy_noaudio_files_switch.active;
                                     } }
     */

    [GtkChild] private unowned Adw.PreferencesGroup custom_quality_group;
    [GtkChild] private unowned Adw.ComboRow quality_preset_selection;
    [GtkChild] private unowned Adw.ComboRow custom_quality_format;
    [GtkChild] private unowned Adw.SpinRow custom_quality_bitrate;
    [GtkChild] private unowned Adw.SpinRow custom_quality_samplerate;

    /*
       private Json.Object quality_preset_data_object;
       private Json.Object selected_quality_preset_data_object;
       private Json.Object format_data_object;
       private Json.Object selected_format_data_object;
       private int bitrate = 128; // default parameter
       private int samplerate = 44100; // default parameter
       private string quality_preset_custom_name = "nothing";
     */

    public HashMap<string, Press.FormatConfig> format_list;
    public HashMap<string, Press.QualityConfig> quality_list;
    public Press.QualityConfig selected_quality { get; private set; } // TODO: check if we need an unowned referece here.

    public Press.CompressConfig config;

    public ConfigPage () {
        // Selecting source/target folders
        source_directory_button.clicked.connect (set_source_directory);
        target_directory_button.clicked.connect (set_target_directory);

        // Compress Config
        config = new Press.CompressConfig ();
        quality_list = new HashMap<string, Press.QualityConfig>();
        format_list = new HashMap<string, Press.FormatConfig>();
        load_presets ();
        // select_quality_preset (); // make sure the default one is chosen

        // TODO: use signals instead
        custom_quality_format.notify["selected"].connect (this.select_custom_format);
        custom_quality_bitrate.notify["value"].connect (this.select_custom_bitrate);
        custom_quality_samplerate.notify["value"].connect (this.select_custom_samplerate);
    }

    private void set_source_directory() {
        this.select_directory ((folder) => {
            string path = folder != null ? folder.get_path () : "nothing";

            config.source_path = path;
            source_directory_row.subtitle = path;
        });
    }

    private void set_target_directory() {
        this.select_directory ((folder) => {
            string ? path = folder != null ? folder.get_path () : "nothing";

            config.target_path = path;
            target_directory_row.subtitle = path;
        });
    }

    private void select_directory(Func<File> callback) {
        var dialog = new Gtk.FileDialog ();
        dialog.select_folder.begin (null, null, (obj, res) => {
            try {
                File folder = dialog.select_folder.end (res);
                callback (folder);
            } catch ( Error err ){
                warning ("Error trying to open folder. Message: " + err.message);
            }
        });
    }

    private void load_presets() {
        File ? presets_file = search_presets_file ();
        if( presets_file == null ){
            warning (@"Couldn't find presets.json file.");

        } else {
            bool can_read_file = true;
            Json.Parser parser = new Json.Parser ();

            // Try to load the file onto the parser
            try {
                parser.load_from_file (presets_file.get_path ());
            } catch ( Error err ){
                warning (@"Could not read file from path $(presets_file.get_path ()). File should exists.");
                can_read_file = false;
            }

            if( !can_read_file ){
                warning (@"Couldn't read $(presets_file.get_path()), but file exists.");

            } else {
                Json.Object root_obj = parser.get_root ().get_object ();
                parse_presets_file_formats (root_obj);

            }
        }
    }

    private void parse_presets_file_formats(Json.Object root_obj) {
        Json.Object formats_obj = root_obj.get_object_member ("formats");

        foreach(string member in formats_obj.get_members ()){
            Json.Object format_obj = formats_obj.get_object_member (member);

            Press.FormatConfig format = new Press.FormatConfig () {
                name = format_obj.get_string_member ("name"),
                extension = format_obj.get_string_member ("extension"),
                attach_video = format_obj.get_boolean_member ("video"),
                codec = format_obj.get_string_member ("codec")
            };
            format_list[format.name] = format;
        }
    }

    private void parse_presets_file_quality(Json.Object root_obj) {
        Json.Object quality_list_obj = root_obj.get_object_member ("quality_presets");

        foreach(string member in quality_list_obj.get_members ()){
            Json.Object quality_obj = quality_list_obj.get_object_member (member);

            // TODO: Test if HashMap[index] errors if there's no match.
            Press.FormatConfig ? format = format_list[quality_obj.get_string_member ("format")];

            if( format == null ){
                warning (
                    "Couldn't load quality preset %s. Format %s doesn't exist.",
                    quality_obj.get_string_member ("name"),
                    quality_list_obj.get_string_member ("format")
                    );
            } else {
                Press.QualityConfig quality = new Press.QualityConfig () {
                    name = quality_obj.get_string_member ("name"),
                    format = format,
                    bitrate = (int32) quality_obj.get_int_member ("bitrate"),
                    samplerate = (int32) quality_obj.get_int_member ("samplerate")
                };
                quality_list[quality.name] = quality;
            }
        }
    }

    private File ? search_presets_file() {
        File ? presets_file = null;

        foreach(var dir in GLib.Environment.get_system_data_dirs ()){
            string search_filename = GLib.Path.build_filename (dir, "presets.json");
            var search_file = File.new_for_path (search_filename);
            if( search_file.query_exists ()){
                presets_file = search_file;
                break;
            }
        }

        return presets_file;
    }

    /*
       private void load_presets() {
        File ? presets_file = null;

        foreach(var dir in GLib.Environment.get_system_data_dirs ()){
            string search_filename = GLib.Path.build_filename (dir, "presets.json");
            var search_file = File.new_for_path (search_filename);
            if( search_file.query_exists ()){
                presets_file = search_file;
                break;
            }
        }

        if( presets_file == null ){
            warning ("Could not find presets.json file, which contains the presets.");

        } else {

            bool can_read_file = true;
            var parser = new Json.Parser ();

            // Try to load the file onto the parser
            try {
                parser.load_from_file (presets_file.get_path ());
            } catch ( Error err ){
                warning (@"Could not read file from path $(presets_file.get_path ()). File should exists.");
                can_read_file = false;
            }

            if( can_read_file ){
                var format_list = new Gtk.StringList (null);
                var quality_preset_list = new Gtk.StringList (null);
                var root_object = parser.get_root ().get_object ();

                var formats_object = root_object.get_object_member ("formats");
                var format_member_names = formats_object.get_members ();

                foreach(string member_name in format_member_names){
                    var format = formats_object.get_object_member (member_name);
                    string name = format.get_string_member ("name");
                    format_list.append (name);
                }

                this.format_data_object = formats_object;
                custom_quality_format.model = format_list;

                var quality_presets_object = root_object.get_object_member ("quality_presets");
                var quality_presets_member_names = quality_presets_object.get_members ();

                this.quality_preset_custom_name = quality_presets_object
                                                   .get_object_member ("other")
                                                   .get_string_member ("name");

                foreach(string member_name in quality_presets_member_names){
                    var quality_preset = quality_presets_object.get_object_member (member_name);
                    string name = quality_preset.get_string_member ("name");
                    quality_preset_list.append (name);
                }

                this.quality_preset_data_object = quality_presets_object;
                quality_preset_selection.model = quality_preset_list;
            }
        }
       }

       private void select_quality_preset() {
        var selected_item = this.quality_preset_selection.selected_item;
        var str_obj = selected_item as Gtk.StringObject;
        var selected_quality_preset_name = str_obj.get_string ();

        if( selected_quality_preset_name == quality_preset_custom_name ){
            custom_quality_group.visible = true;
        } else {
            custom_quality_group.visible = false;
        }

        this.load_quality_preset (selected_quality_preset_name);
       }

       private void load_quality_preset(string name) {
        foreach(string member_name in this.quality_preset_data_object.get_members ()){
            var quality_preset_object = this.quality_preset_data_object.get_object_member (member_name);
            string quality_preset_name = quality_preset_object.get_string_member ("name");

            if( name == quality_preset_name ){
                this.selected_quality_preset_data_object = quality_preset_object;

                string format_name = quality_preset_object.get_string_member ("format");
                var format_object = this.format_data_object.get_object_member (format_name);
                this.selected_format_data_object = format_object;

                this.bitrate = (int32) quality_preset_object.get_int_member ("bitrate");
                this.samplerate = (int32) quality_preset_object.get_int_member ("samplerate");
            }
        }
       }

       private void select_custom_format() {
        var selected_item = this.custom_quality_format.selected_item;
        var str_obj = selected_item as Gtk.StringObject;
        var selected_format_name = str_obj.get_string ();

        this.load_custom_format (selected_format_name);
       }

       private void load_custom_format(string name) {
        foreach(string member_name in this.format_data_object.get_members ()){
            var format_object = this.format_data_object.get_object_member (member_name);
            string format_name = format_object.get_string_member ("name");

            if( name == format_name ){
                this.selected_format_data_object = format_object;
            }
        }
       }
     */

    private void select_custom_bitrate() {
        int value = (int) this.custom_quality_bitrate.value;
        this.bitrate = value;
    }

    private void select_custom_samplerate() {
        int value = (int) this.custom_quality_samplerate.value;
        this.samplerate = value;
    }

    [GtkCallback]
    private void on_quality_preset_selected(Adw.ComboRow row) {
        var str_obj = row.selected_item as Gtk.StringObject;
        string selected_quality_name = str_obj.get_string ();

        // TODO: create a constant
        custom_quality_group.visible = selected_quality_name == "other";

        selected_quality = quality_list[selected_quality_name];

        if( selected_quality == null ){
            error (@"Couldn't find quality $(selected_quality_name) from quality list.");
        }
    }

}
