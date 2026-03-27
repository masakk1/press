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

    private Press.CompressConfig config;

    private File source_folder;
    private File target_folder;

    public signal void working_on_file(string path);
    public signal void cancelled();

    private bool process_cancel = false;
    private bool process_running = false;

    private Regex file_extension_regex;

    public Compressor () {
        try {
            this.file_extension_regex = new Regex ("(?<=\\.)[A-z0-9_-]+$");
        } catch ( Error err ){
            error (@"Error initializing regex for file extensions. Cannot continue.\nMessage: $(err.message)");
        }
    }

    private void start_process() {
        this.process_cancel = false;
        this.process_running = true;
    }

    private void stop_process() {
        this.process_cancel = false;
        this.process_running = false;
    }

    public async void compress_library_async(Press.CompressConfig config) {
        if( this.process_running )return;
        this.start_process ();

        this.config = config;

        this.source_folder = File.new_for_path (config.source_path);
        this.target_folder = File.new_for_path (config.target_path);

        assert (this.source_folder.query_exists (null));
        assert (this.target_folder.query_exists (null));

        var children = this.get_children (this.source_folder);


        // Inside the try, every thread is added to the pool
        // When the try {} block is done, it starts running them.
        try {
            // TODO: if ThreadPool throws an error, it might not allow the yield to ever continue
            var pool = new ThreadPool<File>.with_owned_data((file) => {
                if( !this.process_cancel ){
                    Idle.add (() => {
                        this.working_on_file (file.get_basename ());
                        return Source.REMOVE;
                    });
                    this.process_file (file);
                }
            }, (int) GLib.get_num_processors (), false);

            foreach( File file in children ){
                pool.add (file);
            }

            new Thread<void>("wait_thread", () => {
                ThreadPool.free ((owned) pool, false, true);
                Idle.add (() => {
                    compress_library_async.callback ();
                    return Source.REMOVE;
                });
            });

            yield;
        } catch ( ThreadError err ){
            critical ("Error creating thread pool in compressor. %s", err.message);
        }

        // if we are continuing because the process has been cancelled
        if( this.process_cancel ){
            this.cancelled ();
        }

        this.stop_process ();
    }

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
            message ("Error: %s\n", err.message);
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

        bool is_audio;
        bool is_video;
        this.check_streams (source_file, out is_audio, out is_video);
        if( is_audio ){
            try {
                target_file_path = this.file_extension_regex.replace (
                    target_file_path,
                    target_file_path.length,
                    0,
                    config.quality_config.format.extension);
            } catch ( Error err ){
                error ("Error trying to change extension name. Message: %s\n",
                       err.message);
            }
        }

        File target_file = File.new_for_path (target_file_path);
        bool valid_folder = this.ensure_directory_exists (target_file);
        bool file_exists = target_file.query_exists ();

        if( valid_folder && (config.replace_destination_files || !file_exists)){
            if( is_audio ){
                this.convert_file (source_file, target_file, is_video && config.quality_config.format.attach_video);
            } else if( config.copy_noaudio_files ){
                this.copy_file (source_file, target_file);
            }
        } else {
            debug (@"Skipping file: $(target_file.get_path())\n");
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

    private void check_streams(File file, out bool is_audio, out bool is_video) {
        string command = @"ffprobe -loglevel error -show_entries stream=codec_type -of default=nw=1 \"$(file.get_path())\"";
        is_audio = false;
        is_video = false;

        try {
            string standard_output = "";
            string standard_error = "";
            int wait_status = 0;
            Process.spawn_command_line_sync (command,
                                             out standard_output,
                                             out standard_error,
                                             out wait_status);
            is_audio = standard_output.contains ("codec_type=audio");
            is_video = standard_output.contains ("codec_type=video");

        } catch ( Error err ){
            warning (@"Error checking if file is audio/video. $(err.message)");
            is_audio = false;
            is_video = false;
        }
    }

    private void convert_file(File source_file, File target_file, bool attach_video) {
        // if it's a video, include a -map v:0 (any video channels to 0)
        // TODO: it could error if a sound file had more than 1 video channel...
        // that's an edge case, though.
        string command = attach_video
            ? @"ffmpeg -v warning -i \"$(source_file.get_path())\" -map a:0 -ar $(config.quality_config.samplerate) -c:a $(config.quality_config.format.codec) -b:a $(config.quality_config.bitrate)k -c:v mjpeg -map v:0 -movflags +faststart \"$(target_file.get_path())\" -y"
            : @"ffmpeg -v warning -i \"$(source_file.get_path())\" -map a:0 -ar $(config.quality_config.samplerate) -c:a $(config.quality_config.format.codec) -b:a $(config.quality_config.bitrate)k \"$(target_file.get_path())\" -y";
        // TODO: reformat into multiple lines

        debug (@"Command: $command");
        try {
            string standard_output = "";
            string standard_error = "";
            int wait_status = 0;
            Process.spawn_command_line_sync (command,
                                             out standard_output,
                                             out standard_error,
                                             out wait_status);

            debug (@"\nOutput: $standard_output\n");
            debug (@"\nError: $standard_error\n");
            debug (@"\nWait status: $wait_status\n");
        } catch ( Error err ){
            warning (@"Error trying to convert file $(source_file.get_path()). Message: $(err.message)");
        }

        return;
    }

    private void copy_file(File source_file, File target_file) {
        source_file.copy_async.begin (
            target_file,
            FileCopyFlags.ALL_METADATA | FileCopyFlags.OVERWRITE,
            Priority.DEFAULT,
            null,
            null,
            (obj, res) => {
            try {
                source_file.copy_async.end (res);
            } catch ( Error err ){
                warning (@"Error trying to copy "
                         + @"$(source_file.get_path()) to $(target_file.get_path()). "
                         + @"Message: $(err.message)");
            }
        });
    }

    public void cancel_process() {
        this.process_cancel = true;
    }

}
