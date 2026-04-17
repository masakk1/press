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

/**
 * The main window. It's in charge of orchestrating between pages and the Compressor.
 */
[GtkTemplate (ui = "/io/github/masakk1/press/window.ui")]
public class Press.Window : Adw.ApplicationWindow {

    [GtkChild] private unowned Press.ConfigPage config_page;

    [GtkChild] private unowned Adw.AlertDialog confirm_dialog;
    [GtkChild] private unowned Gtk.Button cancel_compressing_button;
    [GtkChild] private unowned Adw.AlertDialog cancel_dialog;
    [GtkChild] private unowned Adw.StatusPage compressing_status_page;
    [GtkChild] private unowned Gtk.Button done_page_back_button;

    [GtkChild] private unowned Adw.NavigationView navigation_view;

    [GtkChild] private unowned Adw.ToastOverlay toast_overlay;

    private Compressor compressor;

    /**
     * Creates the main Window
     */
    public Window (Gtk.Application app) {
        application = app;
        compressor = new Compressor ();


        // Compress button
        config_page.compress_button.clicked.connect (compress_button_clicked);
        confirm_dialog.response.connect (answer_confirm_dialog);

        // In compressing page
        cancel_compressing_button.clicked.connect (open_cancel_dialog);
        cancel_dialog.response.connect (answer_cancel_dialog);
        compressor.working_on_file.connect (change_working_on);

        // In done page
        done_page_back_button.clicked.connect (return_config_page);
    }

    private void compress_button_clicked () {
        if (config_page.config.replace_destination_files) {
            open_confirm_dialog ();
        } else {
            begin_compression ();
        }
    }

    private void open_confirm_dialog () {
        confirm_dialog.present (this);
    }

    private void answer_confirm_dialog (string response) {
        if (response == "compress") {
            begin_compression ();
        }
    }

    private void open_cancel_dialog () {
        cancel_dialog.present (this);
    }

    private void answer_cancel_dialog (string response) {
        if (response == "cancel") {
            cancel_compression ();
        }
    }

    private void change_working_on (string job) {
        compressing_status_page.description = _("Working on %s").printf (job);
    }

    /**
     * Begins the compression.
     *
     * It clones the configuration, and feeds it to the compressor.
     */
    private void begin_compression () {
        // Clone the config
        Press.CompressConfig config = config_page.config.clone ();

        var source_folder = File.new_for_path (config.source_path);
        var target_folder = File.new_for_path (config.target_path);
        bool folders_exist = source_folder.query_exists (null) && target_folder.query_exists (null);

        if (folders_exist) {
            navigation_view.push_by_tag ("compressing_page");

            compressor.compress_library_async.begin (
                                                     config, (obj, res) => {
                compressor.compress_library_async.end (res);

                if (compressor.cancelled)
                    navigation_view.pop_to_tag ("config_page");
                else
                    navigation_view.push_by_tag ("done_page");
            });
        } else {
            toast_overlay.add_toast (new Adw.Toast (_("Selected folders don't exist")));
        }
    }

    private void cancel_compression () {
        compressor.cancel ();
        change_working_on (_("cancelling"));
    }

    private void return_config_page () {
        navigation_view.pop_to_tag ("config_page");
    }
}
