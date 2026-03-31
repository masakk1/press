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

[GtkTemplate (ui = "/io/github/masakk1/press/config_page.ui")]
public class Press.ConfigPage : Adw.NavigationPage {
    [GtkChild] private unowned Adw.ActionRow source_directory_row;
    [GtkChild] private unowned Adw.ActionRow target_directory_row;

    [GtkChild] private unowned Adw.PreferencesGroup custom_quality_group;
    [GtkChild] private unowned Adw.ComboRow quality_preset_selection;
    [GtkChild] private unowned Adw.ComboRow custom_format_selection;
    [GtkChild] private unowned Adw.SwitchRow replace_destination_files_switch;
    [GtkChild] private unowned Adw.SwitchRow copy_noaudio_files_switch;

    [GtkChild] public unowned Gtk.Button compress_button;

    public HashMap<string, Press.FormatConfig ?> format_list;
    public HashMap<string, Press.QualityConfig ?> quality_list;
    public Press.CompressConfig config { get; private set; }

    public bool is_custom_config { get; private set; }
    private const string CUSTOM_QUALITY_NAME = "custom";

    construct {
        // Compress Config
        config = new Press.CompressConfig ();
        config.replace_destination_files = replace_destination_files_switch.active;
        config.copy_noaudio_files = copy_noaudio_files_switch.active;

        quality_list = new HashMap<string, Press.QualityConfig ?>();
        format_list = new HashMap<string, Press.FormatConfig ?>();

        load_presets ();

    }


    [GtkCallback]
    private void on_source_directory_clicked(Gtk.Button button) {
        this.select_directory ((folder) => {
            string path = folder != null ? folder.get_path () : "nothing";

            config.source_path = path;
            source_directory_row.subtitle = path;
        });
    }

    [GtkCallback]
    private void on_target_directory_clicked(Gtk.Button button) {
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
                parse_presets_file_quality (root_obj);

                assert (format_list.size > 0);
                assert (quality_list.size > 0);

                add_custom_quality ();
                load_presets_into_ui ();
            }
        }
    }

    private void add_custom_quality() {
        // Will error unless there's an mp3 format
        quality_list[CUSTOM_QUALITY_NAME] = { _ ("Other..."), null, 128, 44100 };
    }

    private void load_presets_into_ui() {
        var quality_list_model = new Gtk.StringList (null);
        var format_list_model = new Gtk.StringList (null);
        foreach(var format in format_list.values){
            format_list_model.append (format.name);
        }
        foreach(var quality in quality_list.values){
            quality_list_model.append (quality.name);
        }

        quality_preset_selection.model = quality_list_model;
        custom_format_selection.model = format_list_model;
    }

    private void parse_presets_file_formats(Json.Object root_obj) {
        Json.Object formats_obj = root_obj.get_object_member ("formats");

        foreach(string member in formats_obj.get_members ()){
            Json.Object format_obj = formats_obj.get_object_member (member);

            // Find the filters
            var filters_obj = format_obj.get_array_member ("filters");
            var filters = new ArrayList<string>();
            foreach(var filter_node in filters_obj.get_elements ()){
                filters.add (filter_node.get_string ());
            }

            // Load encoder properties
            Json.Object encoder_properties_obj = format_obj.get_object_member ("encoderProperties");
            HashMap<string, Value ?> encoder_properties = new HashMap<string, Value ?>();
            if( encoder_properties_obj != null ){
                encoder_properties_obj.foreach_member ((obj, key, node) => {
                    encoder_properties[key] = node.get_value ();
                });
            }

            Press.FormatConfig format = Press.FormatConfig () {
                name = format_obj.get_string_member ("name"),
                extension = format_obj.get_string_member ("extension"),
                encoder = format_obj.get_string_member ("encoder"),
                filters = filters.to_array (),
                bitrate_multiplier = (int32) format_obj.get_int_member ("bitrateMult"),
                encoder_properties = encoder_properties
            };

            format_list[member] = format;
        }
    }

    private void parse_presets_file_quality(Json.Object root_obj) {
        Json.Object quality_list_obj = root_obj.get_object_member ("quality_presets");

        foreach(string member in quality_list_obj.get_members ()){
            Json.Object quality_obj = quality_list_obj.get_object_member (member);

            Press.FormatConfig ? format = format_list[quality_obj.get_string_member ("format")];

            if( format == null ){
                warning (
                    "Couldn't load quality preset %s. Format %s doesn't exist.",
                    quality_obj.get_string_member ("name"),
                    quality_obj.get_string_member ("format")
                    );
            } else {
                Press.QualityConfig quality = Press.QualityConfig () {
                    name = quality_obj.get_string_member ("name"),
                    format = format,
                    bitrate = (int32) quality_obj.get_int_member ("bitrate"),
                    samplerate = (int32) quality_obj.get_int_member ("samplerate")
                };

                quality_list[member] = quality;
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

    private void update_custom_quality(Press.QualityConfig new_quality) {
        quality_list[CUSTOM_QUALITY_NAME] = new_quality;
        config.quality_config = new_quality;
    }

    [GtkCallback]
    private void on_quality_preset_selected(GLib.Object obj, GLib.ParamSpec pspec) {
        var combo_row = obj as Adw.ComboRow;
        var str_obj = combo_row.selected_item as Gtk.StringObject;
        string selected_quality_name = str_obj.get_string ();
        var selected_quality = quality_list.first_match (x =>
                                                         x.value.name == selected_quality_name);

        is_custom_config = (selected_quality != null && selected_quality.key == CUSTOM_QUALITY_NAME);
        custom_quality_group.visible = is_custom_config;

        if( selected_quality == null )
            error (@"Couldn't find quality $(selected_quality_name) from quality list.");

        config.quality_config = selected_quality.value;
    }

    [GtkCallback]
    private void on_format_selected(GLib.Object obj, GLib.ParamSpec pspec) {
        var combo_row = obj as Adw.ComboRow;
        var str_obj = combo_row.selected_item as Gtk.StringObject;
        string selected_format_name = str_obj.get_string ();
        var selected_format = format_list.first_match (x =>
                                                       x.value.name == selected_format_name);

        if( selected_format == null )
            error (@"Couldn't find format $(selected_format_name) from format list.");

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.format = selected_format.value;
        update_custom_quality (custom_quality);
    }

    [GtkCallback]
    private void on_bitrate_changed(GLib.Object obj, GLib.ParamSpec pspec) {
        var spin_row = obj as Adw.SpinRow;
        var value = (int) spin_row.value;

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.bitrate = value;
        update_custom_quality (custom_quality);
    }

    [GtkCallback]
    private void on_samplerate_changed(GLib.Object obj, GLib.ParamSpec pspec) {
        var spin_row = obj as Adw.SpinRow;
        var value = (int) spin_row.value;

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.samplerate = value;
        update_custom_quality (custom_quality);
    }

    [GtkCallback]
    private void on_replace_destination_files_switched(GLib.Object obj, GLib.ParamSpec pspec) {
        var switch_row = obj as Adw.SwitchRow;
        config.replace_destination_files = switch_row.active;
    }

    [GtkCallback]
    private void on_copy_noaudio_files_switched(GLib.Object obj, GLib.ParamSpec pspec) {
        var switch_row = obj as Adw.SwitchRow;
        config.copy_noaudio_files = switch_row.active;
    }

}
