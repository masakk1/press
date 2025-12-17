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

public class Press.Compressor : Object {
    // note: ^\.?(?<name>\/[^\/\n]+)+(?<ext>\.[A-z0-9\._-]+)$

    public string format_extension;
    public int bitrate;

    private File source_folder;
    private File target_folder;

    public signal void working_on_file(string path);
    public signal void cancelled();

    private bool process_cancel = false;

    private Regex file_extension_regex;

    public Compressor () {
        try {
            this.file_extension_regex = new Regex ("(?<=\\.)[A-z0-9_-]+$");
        } catch ( Error err ){
            error (@"Error initializing regex for file extensions. Cannot continue.\nMessage: $(err.message)");
        }
    }

    public async void compress_library_async(string source_path, string target_path) {
        this.process_cancel = false;
        this.source_folder = File.new_for_path (source_path);
        this.target_folder = File.new_for_path (target_path);

        assert (this.source_folder.query_exists (null));
        assert (this.target_folder.query_exists (null));

        var children = this.get_children (this.source_folder);

        var compress_thread = new Thread<void>("compress_thread", () => {
            foreach(File file in children){
                this.process_file (file);
            }
            Idle.add (compress_library_async.callback);
        });

        yield;
    }

    // run callback for each child of provided folder
    private ArrayList<File> get_children(File folder) {
        var children = new ArrayList<File>();
        this._get_children (folder, children);

        return children;
    }

    private void _get_children(File folder, ArrayList<File> children) {
        return_if_fail (folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY);

        try {
            var enumerator = folder.enumerate_children (
                FileAttribute.STANDARD_NAME + "," +
                FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NONE,
                null);

            FileInfo info;
            while((info = enumerator.next_file ()) != null ){
                string name = info.get_name ();
                File file = folder.get_child (name);

                bool is_folder = info.get_file_type () == FileType.DIRECTORY;

                if( is_folder ){
                    this._get_children (file, children);
                } else {
                    children.add (file);
                }
            }

            enumerator.close ();

        } catch ( Error err ){
            print ("Error: %s\n", err.message);
        }
    }

    // public async void compress_file_async(string source_file_path, string target_file_path) {

    // }

    private void process_file(File source_file) {
        string source_folder_path = this.source_folder.get_path ();
        string target_folder_path = this.target_folder.get_path ();
        string source_file_path = source_file.get_path ();

        string relative_path = source_file_path.replace (source_folder_path, "");
        string target_file_path = target_folder_path + relative_path;

        try {
            target_file_path = this.file_extension_regex.replace (
                target_file_path,
                target_file_path.length,
                0,
                this.format_extension);
        } catch ( Error err ){
            warning ("Error trying to change extension name. Message: %s\n", err.message);
        }

        File target_file = File.new_for_path (target_file_path);
        bool valid_folder = this.ensure_directory_exists (target_file);

        if( valid_folder ){
            bool is_audio = this.is_audio (source_file);

            if( is_audio ){
                this.convert_file (source_file, target_file);
            } else {
                // TODO: Copy file over entirely
            }
        }
    }

    private bool ensure_directory_exists(File target_file) {
        File ? target_parent = target_file.get_parent ();

        bool exists = false;

        // NOTE: parent can be null for '/'
        if( target_parent != null ){
            exists = target_parent.query_exists (null);

            if( !exists ){
                try {
                    target_parent.make_directory_with_parents (null);
                    exists = true;
                } catch ( Error err ){
                    warning (@"Error creating folders for target file. Message: $(err.message)");
                }
            }
        }

        return exists;
    }

    private bool is_audio(File file) {
        string command = @"ffprobe -loglevel error -show_entries stream=codec_type -of default=nw=1 \"$(file.get_path())\"";
        bool is_audio = false;

        try {
            string standard_output = "";
            string standard_error = "";
            int wait_status = 0;
            Process.spawn_command_line_sync (command,
                                             out standard_output,
                                             out standard_error,
                                             out wait_status);
            is_audio = standard_output.contains ("codec_type=audio");

        } catch ( Error err ){
            warning (@"Error checking if file is audio. $(err.message)");
            is_audio = false;
        }

        return is_audio;
    }

    private void convert_file(File source_file, File target_file) {
        string command = @"ffmpeg -v warning -i \"$(source_file.get_path())\" -map a:0 -b:a $(this.bitrate)k \"$(target_file.get_path())\" -y";
        print ("------------------------------------------------------------------------------------\n");
        print (@"Command: $command");
        try {
            string standard_output = "";
            string standard_error = "";
            int wait_status = 0;
            Process.spawn_command_line_sync (command,
                                             out standard_output,
                                             out standard_error,
                                             out wait_status);

            print (@"\nOutput: $standard_output\n");
            print (@"\nError: $standard_error\n");
            print (@"\nWait status: $wait_status\n");
        } catch ( Error err ){
            warning (@"Error trying to convert file $(source_file.get_path()). Message: $(err.message)");
        }

        return; // TODO
    }

    public void cancel_process() {
        this.process_cancel = true;
    }

}
