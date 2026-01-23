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

    private string source_directory_path;
    private string target_directory_path;

    [GtkChild]
    private unowned Adw.PreferencesGroup custom_quality_group;
    [GtkChild]
    private unowned Adw.ComboRow quality_preset_selection;
    [GtkChild]
    private unowned Adw.ComboRow custom_quality_format;
    [GtkChild]
    private unowned Adw.SpinRow custom_quality_bitrate;

    private Json.Object quality_preset_data_object;
    private Json.Object selected_quality_preset_data_object;
    private Json.Object format_data_object;
    private Json.Object selected_format_data_object;
    private int bitrate = 128; // default parameter
    private string quality_preset_custom_name = "nothing";

    [GtkChild]
    private unowned Gtk.Button compress_button;
    [GtkChild]
    private unowned Adw.AlertDialog confirm_dialog;
    [GtkChild]
    private unowned Gtk.Button cancel_compressing_button;
    [GtkChild]
    private unowned Adw.AlertDialog cancel_dialog;
    [GtkChild]
    private unowned Adw.StatusPage compressing_status_page;
    [GtkChild]
    private unowned Gtk.Button done_page_back_button;

    [GtkChild]
    private unowned Adw.NavigationView navigation_view;

    private Press.Compressor compressor;

    public Window (Gtk.Application app) {
        application = app;
        compressor = new Compressor ();

        // Source Directory
        source_directory_button.clicked.connect (this.set_source_directory);

        // Target Directory
        target_directory_button.clicked.connect (this.set_target_directory);

        // Presets
        load_presets ();
        select_quality_preset (); // make sure the default one is chosen
        quality_preset_selection.notify["selected"].connect (this.select_quality_preset);
        custom_quality_format.notify["selected"].connect (this.select_custom_format);
        custom_quality_bitrate.notify["value"].connect (this.select_custom_bitrate);

        // Compress button
        compress_button.clicked.connect (this.open_confirm_dialog);
        confirm_dialog.response.connect (this.answer_confirm_dialog);

        // In compressing page
        cancel_compressing_button.clicked.connect (this.open_cancel_dialog);
        cancel_dialog.response.connect (this.answer_cancel_dialog);
        this.compressor.working_on_file.connect (this.change_working_on);

        // In done page
        done_page_back_button.clicked.connect (this.return_config_page);
    }

    private bool load_presets() {
        var test_file_flatpak = File.new_for_path ("/app/share/presets.json");
        var test_file_regular = File.new_for_path ("/usr/local/share");

        var presets_file = test_file_flatpak.query_exists () ? test_file_flatpak : test_file_regular;

        var format_list = new Gtk.StringList (null);
        var quality_preset_list = new Gtk.StringList (null);

        bool file_exists = presets_file.query_exists ();
        bool can_read_file = true;

        var parser = new Json.Parser ();

        if( !file_exists ){
            warning ("Could not find presets.json file, which contains the presets. "
                     + "Try compiling for flatpak or install the app with meson.");
        }

        if( file_exists ){
            try {
                parser.load_from_file (presets_file.get_path ());
            } catch ( Error err ){
                warning (@"Could not read file from path $(presets_file.get_path ()). File should exists.");
                can_read_file = false;
            }
        }

        if( file_exists && can_read_file ){
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

        return file_exists && can_read_file;
    }

    private void set_source_directory() {
        this.select_directory ((folder) => {
            string path = folder != null ? folder.get_path () : "nothing";

            this.source_directory_path = path;
            source_directory_row.subtitle = path;
        });
    }

    private void set_target_directory() {
        this.select_directory ((folder) => {
            string ? path = folder != null ? folder.get_path () : "nothing";

            this.target_directory_path = path;
            target_directory_row.subtitle = path;
        });
    }

    private void select_directory(Func<File> callback) {
        var dialog = new Gtk.FileDialog ();
        dialog.select_folder.begin (this, null, (obj, res) => {
            try {
                File folder = dialog.select_folder.end (res);
                callback (folder);
            } catch ( Error err ){
                warning ("Error trying to open folder. Message: " + err.message);
            }
        });
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

    private void select_custom_bitrate() {
        int value = (int) this.custom_quality_bitrate.value;
        this.bitrate = value;
    }

    private void open_confirm_dialog() {
        confirm_dialog.present (this);
    }

    private void answer_confirm_dialog(string response) {
        if( response == "compress" ){
            this.begin_compression ();
        }
    }

    private void open_cancel_dialog() {
        cancel_dialog.present (this);
    }

    private void answer_cancel_dialog(string response) {
        if( response == "cancel" ){
            this.cancel_compression ();
        }
    }

    private void change_working_on(string job) {
        this.compressing_status_page.description = _ (@"Working on $job");
    }

    private void begin_compression() {

        var source_folder = File.new_for_path (this.source_directory_path);
        var target_folder = File.new_for_path (this.target_directory_path);
        bool folders_exist = source_folder.query_exists (null) && target_folder.query_exists (null);

        if( folders_exist ){
            navigation_view.push_by_tag ("compressing_page");

            string extension = this.selected_format_data_object.get_string_member ("extension");

            this.compressor.format_extension = extension;
            this.compressor.bitrate = this.bitrate;

            this.compressor.compress_library_async.begin (
                this.source_directory_path,
                this.target_directory_path,
                (obj, res) => {
                this.compressor.compress_library_async.end (res);
                navigation_view.push_by_tag ("done_page");
            });
        } else {
            // TODO: show a warning toast
            warning (_ ("Configured folders don't exist"));
        }
    }

    private void cancel_compression() {
        compressor.cancel_process ();
        navigation_view.pop_to_tag ("config_page");
    }

    private void return_config_page() {
        navigation_view.pop_to_tag("config_page");
    }
}
