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
 * Application object. In charge of anything that isn't related to the interface. Such as shortcuts, or creating the
 * window in {@link Press.Window}.
 */
public class Press.Application : Adw.Application {
    public Application () {
        application_id = "io.github.masakk1.press";
        flags = ApplicationFlags.DEFAULT_FLAGS;
        resource_base_path = "/io/github/masakk1/press";

        ActionEntry[] action_entries = {
            { "presets-location", this.open_presets_location },
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", { "<control>q" });
    }

    /**
     * {@inheritDoc}
     */
    public override void activate () {
        base.activate ();
        var win = this.active_window ?? new Press.Window (this);
        win.present ();
    }

    private void on_about_action () {
        string[] developers = { "Masakk1" };
        var about = new Adw.AboutDialog () {
            application_name = "press",
            application_icon = "io.github.masakk1.press",
            developer_name = "Masakk1",
            // Note to Translators: Add your name here
            translator_credits = _("translator-credits"),
            version = "0.2.0",
            developers = developers,
            copyright = "MIT © 2026 Masakk1",
        };

        about.present (this.active_window);
    }

    /**
     * Currently, there are no preferences. This function does nothing.
     * 
     * The menu entry is commented, too.
     */
    private void on_preferences_action () {
        message ("app.preferences action activated");
    }

    /**
     * Open the system's file explorer where the presets file is located in.
     */
    private void open_presets_location () {
        PresetsLoader loader = new Press.PresetsLoader ();

        try {
            File presets_file = loader.search_presets_file ();

            Gtk.FileLauncher launcher = new Gtk.FileLauncher (presets_file.get_parent ());

            launcher.launch.begin (this.active_window, null, () => {});
        } catch (Press.PresetsLoaderError err) {
            // TODO: show a toast
            critical (@"Failed to find the presets file. Error: $(err.message)");
        }
    }
}
