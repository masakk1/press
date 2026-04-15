/* MIT License
 *
 * Copyright (c) 2026 Masakk1
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

/**
 * The main configuration page. It actively updates a {@link Press.CompressConfig} as ``config``.
 *
 * There's an accessible {@link Gtk.Button} called ``compress_button``, which isn't hooked to anything. A third party
 * should be in charge of adding the button logic.
 */
[GtkTemplate (ui = "/io/github/masakk1/press/config_page.ui")]
public class Press.ConfigPage : Adw.NavigationPage {
    [GtkChild] private unowned Adw.ActionRow source_directory_row;
    [GtkChild] private unowned Adw.ActionRow target_directory_row;

    [GtkChild] private unowned Adw.PreferencesGroup custom_quality_group;
    [GtkChild] private unowned Adw.ComboRow quality_preset_selection;
    [GtkChild] private unowned Adw.ComboRow custom_format_selection;
    [GtkChild] private unowned Adw.SwitchRow replace_destination_files_switch;
    [GtkChild] private unowned Adw.SwitchRow copy_noaudio_files_switch;
    [GtkChild] private unowned Gtk.Image samplerate_tooltip;

    /**
     * The button that should initialize the compression.
     */
    [GtkChild] public unowned Gtk.Button compress_button;

    /**
     * A HashMap of formats with their keywords, as in the presets file. They keywords aren't the display names.
     */
    public HashMap<string, Press.FormatConfig?> format_list { get; private set; }

    /**
     * A HashMap of Quality with their keywords, as in the presets file. They keywords aren't the display names.
     */
    public HashMap<string, Press.QualityConfig?> quality_list { get; private set; }

    /**
     * The current configuration. ''Do not modify this object directly'', clone it (``.clone()``) if needed.
     *
     * This property is updated as things are selected on the {@link Press.ConfigPage}.
     */
    public Press.CompressConfig config { get; private set; }

    /**
     * Whether the selected {@link Press.QualityConfig} is a custom one.
     */
    public bool is_custom_config { get; private set; }
    /**
     * The //keyword// of the custom {@link Press.QualityConfig}.
     */
    private const string CUSTOM_QUALITY_NAME = "custom";

    /**
     * {@inheritDoc}
     */
    construct {
        // Compress Config
        config = new Press.CompressConfig ();
        config.replace_destination_files = replace_destination_files_switch.active;
        config.copy_noaudio_files = copy_noaudio_files_switch.active;

        quality_list = new HashMap<string, Press.QualityConfig?> ();
        format_list = new HashMap<string, Press.FormatConfig?> ();

        load_presets ();
    }


    [GtkCallback]
    private void on_source_directory_clicked (Gtk.Button button) {
        select_directory ((folder) => {
            string path = folder != null ? folder.get_path () : "nothing";

            config.source_path = path;
            source_directory_row.subtitle = path;
        });
    }

    [GtkCallback]
    private void on_target_directory_clicked (Gtk.Button button) {
        select_directory ((folder) => {
            string? path = folder != null ? folder.get_path () : "nothing";

            config.target_path = path;
            target_directory_row.subtitle = path;
        });
    }

    /**
     * Opens a {@link Gtk.FileDialog} to choose a folder from. Once done, calls ``callback``.
     *
     * The ``callback`` must take a {@link GLib.File}, the selected folder.
     */
    private void select_directory (Func<File> callback) {
        var dialog = new Gtk.FileDialog ();
        dialog.select_folder.begin (null, null, (obj, res) => {
            try {
                File folder = dialog.select_folder.end (res);
                callback (folder);
            } catch (Error err) {
                warning ("Error trying to open folder. Message: " + err.message);
            }
        });
    }

    /**
     * Use {@link Press.PresetsLoader} to load the presets.
     *
     * Sets the model for ``quality_preset_selection`` and ``custom_format_selection``.
     */
    private void load_presets () {
        try {
            PresetsLoader loader = new Press.PresetsLoader ();

            loader.load ();
            loader.add_custom_quality (CUSTOM_QUALITY_NAME, _("Custom"));

            quality_list = loader.quality_list;
            format_list = loader.format_list;

            quality_preset_selection.model = loader.get_quality_list_model ();
            custom_format_selection.model = loader.get_format_list_model ();
        } catch (Press.PresetsLoaderError err) {
            critical (@"Could not load presets. Error: $(err.message)");
        }
    }

    /**
     * Update the custom quality with a modified quality.
     *
     * This is a helper function to modify the quality, since it's a struct.
     */
    private void update_custom_quality (Press.QualityConfig new_quality) {
        quality_list[CUSTOM_QUALITY_NAME] = new_quality;
        config.quality_config = new_quality;
    }

    [GtkCallback]
    private void on_quality_preset_selected (GLib.Object obj, GLib.ParamSpec pspec) {
        var combo_row = obj as Adw.ComboRow;
        var str_obj = combo_row.selected_item as Gtk.StringObject;
        string selected_quality_name = str_obj.get_string ();
        var selected_quality = quality_list.first_match (x =>
                                                         x.value.name == selected_quality_name);

        is_custom_config = (selected_quality != null && selected_quality.key == CUSTOM_QUALITY_NAME);
        custom_quality_group.visible = is_custom_config;

        if (selected_quality == null)
            error (@"Couldn't find quality $(selected_quality_name) from quality list.");

        config.quality_config = selected_quality.value;
    }

    [GtkCallback]
    private void on_format_selected (GLib.Object obj, GLib.ParamSpec pspec) {
        var combo_row = obj as Adw.ComboRow;
        var str_obj = combo_row.selected_item as Gtk.StringObject;
        string selected_format_name = str_obj.get_string ();
        var selected_format = format_list.first_match (x =>
                                                       x.value.name == selected_format_name);

        if (selected_format == null)
            error (@"Couldn't find format $(selected_format_name) from format list.");

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.format = selected_format.value;
        update_custom_quality (custom_quality);
    }

    [GtkCallback]
    private void on_bitrate_changed (GLib.Object obj, GLib.ParamSpec pspec) {
        var spin_row = obj as Adw.SpinRow;
        var value = (int) spin_row.value;

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.bitrate = value;
        update_custom_quality (custom_quality);
    }

    [GtkCallback]
    private void on_samplerate_changed (GLib.Object obj, GLib.ParamSpec pspec) {
        var spin_row = obj as Adw.SpinRow;
        var value = (int) spin_row.value;

        var custom_quality = quality_list[CUSTOM_QUALITY_NAME];
        custom_quality.samplerate = value;
        update_custom_quality (custom_quality);

        // Not a common samplerate
        samplerate_tooltip.visible = !(value == 44100 || value == 48000);
    }

    [GtkCallback]
    private void on_replace_destination_files_switched (GLib.Object obj, GLib.ParamSpec pspec) {
        var switch_row = obj as Adw.SwitchRow;
        config.replace_destination_files = switch_row.active;
    }

    [GtkCallback]
    private void on_copy_noaudio_files_switched (GLib.Object obj, GLib.ParamSpec pspec) {
        var switch_row = obj as Adw.SwitchRow;
        config.copy_noaudio_files = switch_row.active;
    }
}
