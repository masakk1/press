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

namespace Press{

    public errordomain PresetsLoaderError {
        FILE_MISSING
    }

    public class PresetsLoader {

        public HashMap<string, Press.QualityConfig ?> quality_list;
        public HashMap<string, Press.FormatConfig ?> format_list;

        private string custom_quality_name;

        private const string PRESETS_FILENAME = "presets.json";

        public PresetsLoader (string custom_quality_name) {
            this.custom_quality_name = custom_quality_name;

            quality_list = new HashMap<string, Press.QualityConfig ?>();
            format_list = new HashMap<string, Press.FormatConfig ?>();
        }

        /**
         * TODO
         */
        public void load_presets()
        throws PresetsLoaderError {
            File ? presets_file = search_presets_file ();

            Json.Parser parser = new Json.Parser ();

            try {
                parser.load_from_file (presets_file.get_path ());

                Json.Object root_obj = parser.get_root ().get_object ();
                parse_presets_file_formats (root_obj);
                parse_presets_file_quality (root_obj);

                assert (format_list.size > 0);
                assert (quality_list.size > 0);

                add_custom_quality ();
                load_presets_into_ui ();
            } catch ( Error err ){
                warning (@"Could not read file from path $(presets_file.get_path ()). File should exists.");
            }
        }

        /**
         * Adds the custom quality using the custom_quality_name given on
         * the constructor.
         *
         * @param name should be sent already translated
         */
        public void add_custom_quality(string name) {
            // Will error unless there's an mp3 format
            quality_list[custom_quality_name] = { name, null, 128, 44100 };
        }

        /**
         * Returns the quality_list as a {@link Gtk.StringList} for models
         */
        public Gtk.StringList get_quality_list_model() {
            var quality_list_model = new Gtk.StringList (null);
            foreach(var quality in quality_list.values){
                quality_list_model.append (quality.name);
            }
            return quality_list_model;
        }

        /**
         * Returns the format_list as a {@link Gtk.StringList} for models
         */
        public Gtk.StringList get_format_list_model() {
            var format_list_model = new Gtk.StringList (null);
            foreach(var format in format_list.values){
                format_list_model.append (format.name);
            }

            return format_list_model;
        }

        /**
         * Takes the {@link Json.Object} root object of the presets.json file
         * and parses the formats into ``format_list``
         */
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
                    name = _ (format_obj.get_string_member ("name")),
                    extension = format_obj.get_string_member ("extension"),
                    encoder = format_obj.get_string_member ("encoder"),
                    filters = filters.to_array (),
                    bitrate_multiplier = (int32) format_obj.get_int_member ("bitrateMult"),
                    encoder_properties = encoder_properties
                };

                format_list[member] = format;
            }
        }

        /**
         * Takes the {@link Json.Object} root object of the presets.json file
         * and parses the quality presets into ``quality_list``
         */
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
                        name = _ (quality_obj.get_string_member ("name")),
                        format = format,
                        bitrate = (int32) quality_obj.get_int_member ("bitrate"),
                        samplerate = (int32) quality_obj.get_int_member ("samplerate")
                    };

                    quality_list[member] = quality;
                }
            }
        }

        /**
         * Tries to look for the presets JSON file in XDG_DATA_DIRS and returns it
         */
        private File ? search_presets_file()
        throws PresetsLoaderError.FILE_MISSING {
            File ? presets_file = null;

            foreach(var dir in GLib.Environment.get_system_data_dirs ()){
                string search_filename = GLib.Path.build_filename (dir, PRESETS_FILENAME);
                var search_file = File.new_for_path (search_filename);
                if( search_file.query_exists ()){
                    presets_file = search_file;
                    break;
                }
            }

            if( presets_file == null )
                throw new PresetsLoaderError.FILE_MISSING ("Failed to find the presets file ({PRESETS_FILENAME})");

            return presets_file;
        }

    }

}
