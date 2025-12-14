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

public class Press.Compressor : Object {
    // note: ^\.?(?<name>\/[^\/\n]+)+(?<ext>\.[A-z0-9\._-]+)$

    private delegate void FileCallback(File file);

    public string format_extension;
    public int bitrate;

    private File source_folder;
    private File target_folder;

    public signal void working_on_file(string path);
    public signal void cancelled();

    private bool process_cancel = false;

    public async void compress_library_async(string source_path, string target_path) {
        this.process_cancel = false;
        this.source_folder = File.new_for_path (source_path);
        this.target_folder = File.new_for_path (target_path);

        assert (this.source_folder.query_exists (null));
        assert (this.target_folder.query_exists (null));

        this.run_for_child (this.source_folder, (file) => {
            this.process_file (file);
        });
    }

    // run callback for each child of provided folder
    private void run_for_child(File folder, FileCallback callback) {
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
                    this.run_for_child (file, callback);
                } else {
                    callback (file);
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
    }

    public void cancel_process() {
        this.process_cancel = true;
    }

}
