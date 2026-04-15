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

namespace Press {

    public errordomain CompressError {
        PIPELINE_FAIL,
        ELEMENT_NULL,
        ELEMENT_LINK,
        IGNORED_FILE,
        PRE_PROCESS,
        PROCESS
    }

    /**
     * A utility class that processes files and writes to a destination
     */
    public interface FileHandler : Object {
        /**
         * Grab the source file, process it, and output to the target
         *
         * The target file doesn't have to exist already. It will be created or
         * overwritten.
         *
         * @param source An existing file to process
         * @param target The file to write to
         */
        public abstract void process (File source, File target) throws CompressError.PROCESS;
    }

    /**
     * A utility class that converts files and writes to a destination
     */
    public class FileConverter : Object, FileHandler {
        private string[] filters;
        private string encoder_name;
        private Press.QualityConfig quality;

        private Gst.Pipeline pipeline;
        private Gst.Element source;
        private Gst.Element sink;
        private Gst.Element decodebin;
        private Gst.Element encoder;
        private Gst.Element samplerate_capsfilter;
        private Gst.Element element_after_decodebin;

        public FileConverter (Press.QualityConfig quality) {
            assert (quality.format.encoder != null);
            assert (quality.format.filters != null);
            filters = quality.format.filters;
            encoder_name = quality.format.encoder;
            this.quality = quality;
        }

        /**
         * {@inheritDoc}
         */
        private void process (File source, File target)
        throws CompressError.PROCESS {
            try {
                pipeline = create_pipeline ("convert-pipeline-" + source.get_basename ());

                add_pipeline_filters ();

                decodebin.pad_added.connect (decodebin_pad_added);

                configure_elements (source, target);

                pipeline.set_state (Gst.State.PLAYING);
                play ();
                pipeline.set_state (Gst.State.NULL);
            } catch (CompressError err) {
                throw new CompressError.PROCESS (@"Failed to process file: $(err.message)");
            }

            pipeline = null;
        }

        /**
         * Builds a {@link Gst.Pipeline}, creates the necessary {@link Gst.Element}s, and links them together.
         *
         * ``sink`` and ``decodebin`` haven't been linked yet.
         *
         * @param name The name of the pipeline. Used for debugging purposes only.
         * @return The resulting pipeline
         */
        private Gst.Pipeline create_pipeline (string name)
        throws CompressError.PIPELINE_FAIL, CompressError.ELEMENT_LINK, CompressError.ELEMENT_NULL {
            Gst.Pipeline? pipeline = new Gst.Pipeline (name);

            if (pipeline == null)
                throw new CompressError.PIPELINE_FAIL ("Failed to create a pipeline");

            source = Gst.ElementFactory.make ("filesrc");
            sink = Gst.ElementFactory.make ("filesink", "sink");

            decodebin = Gst.ElementFactory.make ("decodebin", "decodebin");
            Gst.Element? audioconvert = Gst.ElementFactory.make ("audioconvert", "audioconvert");
            Gst.Element? audioresample = Gst.ElementFactory.make ("audioresample", "audioresample");
            samplerate_capsfilter = Gst.ElementFactory.make ("capsfilter", "samplerate-capsfilter");
            encoder = Gst.ElementFactory.make (this.encoder_name, "encoder");

            Gst.Element?[] elements = {
                source, sink, decodebin, audioconvert, audioresample, samplerate_capsfilter, encoder
            };
            foreach (Gst.Element ? element in elements) {
                if (elements == null)
                    throw new CompressError.ELEMENT_NULL (@"Failed to create a necessary element of pipeline");

                pipeline.add (element);
            }

            if (!source.link (decodebin) || !audioconvert.link_many (audioresample, samplerate_capsfilter, encoder))
                throw new CompressError.ELEMENT_LINK (@"Failed to link necessary elements of pipeline");

            this.element_after_decodebin = audioconvert;
            return pipeline;
        }

        /**
         * Adds the parametrized filters to the pipeline, and links them along the sink.
         */
        private void add_pipeline_filters ()
        throws CompressError.ELEMENT_NULL, CompressError.ELEMENT_LINK {
            Gst.Element last_element = this.encoder;

            foreach (string filter_name in filters) {
                Gst.Element? filter = Gst.ElementFactory.make (filter_name, null);
                if (filter == null)
                    throw new CompressError.ELEMENT_NULL (@"Failed to create $filter_name");

                pipeline.add (filter);

                if (!last_element.link (filter))
                    throw new CompressError.ELEMENT_LINK (@"Failed to link filter $filter_name with the last element");

                last_element = filter;
            }

            if (!last_element.link (sink))
                throw new CompressError.ELEMENT_LINK (@"Failed to link the las element with the sink");
        }

        /**
         * Checks added pads, if it has capability ``audio/x-raw``, link it to the next item in-line.
         */
        private void decodebin_pad_added (Gst.Element src, Gst.Pad pad) {
            Gst.Pad sink_pad = element_after_decodebin.get_static_pad ("sink");

            if (sink_pad.is_linked ())
                return;

            Gst.Caps caps = pad.query_caps (null);
            if (caps == null || caps.is_empty ())
                return;

            unowned Gst.Structure structure = caps.get_structure (0);
            string pad_type = structure.get_name ();
            if (!pad_type.has_prefix ("audio/x-raw"))
                return;

            if (pad.link (sink_pad) != Gst.PadLinkReturn.OK)
                return;
        }

        /**
         * Configures the created elements. Adds encoder properties, links the samplerate caps filter.
         */
        private void configure_elements (File source_file, File target_file) {
            source.set ("location", source_file.get_path ());
            sink.set ("location", target_file.get_path ());
            samplerate_capsfilter.set ("caps", Gst.Caps.from_string (@"audio/x-raw,rate=$(quality.samplerate)"));
            encoder.set ("bitrate", quality.bitrate * quality.format.bitrate_multiplier);

            // Encoder properties
            foreach (var property in quality.format.encoder_properties ) {
                switch (property.value.type ()) {
                case Type.STRING :
                    encoder.set (property.key, property.value.get_string ());
                    break;
                case Type.INT64 :
                    encoder.set (property.key, property.value.get_int64 ());
                    break;
                case Type.BOOLEAN :
                    encoder.set (property.key, property.value.get_boolean ());
                    break;

                    default :
                    warning (@"Property $(property.key) has an unknown type: $(property.value.type())");
                    break;
                }
            }
        }

        /**
         * Starts the conversion process
         *
         * It is called play, because the pipeline says this is the "PLAYING" state.
         */
        private void play ()
        throws CompressError.PROCESS {
            Gst.Bus bus = pipeline.get_bus ();
            Gst.Message msg = bus.timed_pop_filtered (Gst.CLOCK_TIME_NONE, Gst.MessageType.ERROR | Gst.MessageType.EOS);

            if (msg != null && msg.type == Gst.MessageType.ERROR) {
                GLib.Error err;
                string debug_info;
                msg.parse_error (out err, out debug_info);

                throw new CompressError.PROCESS (@"Failed to convert. "
                                                 + @" - Element: $(msg.src.name)."
                                                 + @" - Error: $(err.message)"
                                                 + @" - Debug info: $debug_info");
            }

            bus = null;
        }
    }

    /**
     * A utility class that copies files and writes to a destination
     */
    public class FileDuplicator : Object, FileHandler {
        public FileDuplicator () {
        }

        /**
         * {@inheritDoc}
         */
        public void process (File source, File target)
        throws CompressError.PROCESS {
            try {
                source.copy (target, FileCopyFlags.ALL_METADATA | FileCopyFlags.OVERWRITE);
            } catch (Error err) {
                throw new CompressError.PROCESS (@"Failed to copy: $(err.message)");
            }
        }
    }

    /**
     * Compresses files on a directory, given the target quality
     */
    public class Compressor : Object {
        private Press.CompressConfig config;

        private File source_folder;
        private File target_folder;

        /**
         * Called when a file is about to be processed.
         */
        public signal void working_on_file (string path);

        private bool running = false;
        public bool cancelled { get; private set; }

        private Regex file_extension_regex;
        private int discoverer_timeout;

        /**
         * Initializes a Compressor object
         *
         * @param discoverer_timeout The maximum time given to check whether a file has audio
         */
        public Compressor (int discoverer_timeout = 3) {
            try {
                file_extension_regex = new Regex ("(?<=\\.)[A-z0-9_-]+$");
                discoverer_timeout = discoverer_timeout;
                running = false;
                cancelled = false;
            } catch (Error err) {
                error (@"Error initializing regex for file extensions. Cannot continue. - Message: $(err.message)");
            }
        }

        /**
         * Begins compressing a library. The source and target folders must exist.
         *
         * This is the main entry point. A callback will be sent once it has completed. Once it's done, you can check
         * if it was cancelled using the public property ``cancelled``.
         *
         * Only a single compression can run at a time, although many files can be processed simultaneously
         *
         * It uses multi threading to speed the process time.
         */
        public async void compress_library_async (Press.CompressConfig config) {
            if (running)
                return;

            this.config = config;

            source_folder = File.new_for_path (config.source_path);
            target_folder = File.new_for_path (config.target_path);

            if (!source_folder.query_exists () || !target_folder.query_exists ())
                return;

            running = true;
            cancelled = false;

            var children = get_children (source_folder);

            try {
                var pool = new ThreadPool<File>.with_owned_data ((file) => {
                    if (!cancelled) {
                        Idle.add (() => {
                            this.working_on_file (file.get_basename ());
                            return Source.REMOVE;
                        });

                        debug (@"Processing file $(file.get_path ())");

                        try {
                            process_file (file);
                        } catch (CompressError.IGNORED_FILE err) {
                            debug (@"Skipping $(file.get_path ()). Reason: $(err.message)");
                        } catch (CompressError.PROCESS err) {
                            warning (@"Failed during processing on $(file.get_path ()). Error: $(err.message)");
                        } catch (Error err) {
                            warning (@"Failed to process $(file.get_path ()). Error: $(err.message)");
                        }
                    }
                }, (int) GLib.get_num_processors (), false);

                foreach (File file in children) {
                    pool.add (file);
                }

                new Thread<void> ("wait_thread", () => {
                    ThreadPool.free ((owned) pool, false, true);
                    Idle.add (() => {
                        compress_library_async.callback ();
                        return Source.REMOVE;
                    });
                });

                yield;
            } catch (ThreadError err) {
                critical ("Error creating thread pool in compressor. %s", err.message);
            }

            running = false;
        }

        /**
         * Returns the children in a given folder.
         *
         * The children parameter is internal.
         */
        private ArrayList<File> get_children (File folder, ArrayList<File> _children = new ArrayList<File> ())
        requires (folder.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) // vala-lint:block-opening-brace-space-before
        {
            try {
                var enumerator = folder.enumerate_children (FileAttribute.STANDARD_NAME + ","
                                                            + FileAttribute.STANDARD_TYPE,
                                                            FileQueryInfoFlags.NONE,
                                                            null);

                FileInfo info = enumerator.next_file ();
                while (info != null) {
                    string name = info.get_name ();
                    File file = folder.get_child (name);

                    bool is_folder = info.get_file_type () == FileType.DIRECTORY;

                    if (is_folder) {
                        get_children (file, _children);
                    } else {
                        _children.add (file);
                    }

                    info = enumerator.next_file ();
                }

                enumerator.close ();
            } catch (Error err) {
                message ("Error: %s\n", err.message);
            }

            return _children;
        }

        /**
         * Processes a {@link GLib.File}. Uses {@link Press.Compressor.FileConverter} for conversions,
         * and {@link Press.Compressor.FileDuplicator} for file copies.
         *
         * Will throw ``CompressError.IGNORED_FILE`` if the file didn't meet the criteria, or other
         * {@link Press.CompressError} if the operation finished unsuccessfully.
         *
         * The duplicator will be called for files that don't have audio, and only if ``copy_noaudio_files`` is
         * enabled in the ``config``.
         *
         * The target bitrate and samplerate, are limited to the existing properties for each file. If bitrate is
         * configured to be 192 kbps, but the file is actually 96 kbps, it will stay with the lower 96 kbps for that
         * File.
         *
         * If the detected samplerate is 0, the file will be ignored, as it's likely corrupted in some way.
         */
        private void process_file (File source_file)
        throws Error, RegexError, CompressError {
            string source_folder_path = source_folder.get_path ();
            string target_folder_path = target_folder.get_path ();
            string source_file_path = source_file.get_path ();

            string relative_path = source_file_path.replace (source_folder_path, "");
            string target_file_path = target_folder_path + relative_path;

            bool is_audio;
            int bitrate;
            int samplerate;
            check_streams (source_file, out is_audio, out bitrate, out samplerate);
            Press.CompressConfig file_config = config.clone ();

            if (is_audio) {
                if (samplerate == 0)
                    throw new CompressError.PRE_PROCESS (@"Samplerate of file $(source_file.get_path()) is 0. "
                                                         + "It's likely corrupted.");

                if (bitrate < config.quality_config.bitrate || samplerate < config.quality_config.samplerate) {
                    file_config.quality_config.bitrate = min (bitrate, file_config.quality_config.bitrate);
                    file_config.quality_config.samplerate = min (samplerate, file_config.quality_config.samplerate);
                }

                target_file_path = file_extension_regex.replace (target_file_path,
                                                                 target_file_path.length,
                                                                 0,
                                                                 file_config.quality_config.format.extension);
            }

            File target_file = File.new_for_path (target_file_path);
            ensure_directory_exists (target_file);
            bool file_exists = target_file.query_exists ();

            if (file_exists && !file_config.replace_destination_files)
                throw new CompressError.IGNORED_FILE ("File exists, and replace destination files is disabled");

            FileHandler file_handler;
            if (is_audio) {
                file_handler = new FileConverter (file_config.quality_config);
                file_handler.process (source_file, target_file);
            } else if (file_config.copy_noaudio_files) {
                file_handler = new FileDuplicator ();
                file_handler.process (source_file, target_file);
            }
        }

        /**
         * Returns the lesser number of the two
         */
        private int min (int a, int b) {
            return a < b ? a : b;
        }

        /**
         * Makes sure the directory for a target file exists. Will create folders as necessary.
         *
         * Fails if the operation was unsuccessful.
         */
        private void ensure_directory_exists (File target_file)
        throws Error {
            File? target_parent = target_file.get_parent ();

            // NOTE: parent can be null for '/'
            if (target_parent != null && !target_parent.query_exists ()) {
                target_parent.make_directory_with_parents ();
            }
        }

        /**
         * Creates a {@link Gst.PbUtils.Discoverer} and tries to look for audio properties in a {@link GLib.File}.
         *
         * If a samplerate is 0, this means the file is //likely corrupted//, or there was an issue parsing it.
         *
         * The Discoverer will look for it for as long as ``discoverer_timeout``.
         *
         * A new Discoverer is created each time this method is called.
         */
        private void check_streams (File file, out bool is_audio, out int bitrate, out int samplerate) {
            is_audio = false;
            bitrate = 0;
            samplerate = 0;

            try {
                var discoverer = new Gst.PbUtils.Discoverer (discoverer_timeout * Gst.SECOND);
                Gst.PbUtils.DiscovererInfo info = discoverer.discover_uri (file.get_uri ());

                var audio_streams = info.get_audio_streams ();
                is_audio = audio_streams.length () > 0;

                if (is_audio) {
                    var audio_info = audio_streams.data as Gst.PbUtils.DiscovererAudioInfo;

                    bitrate = (int) audio_info.get_bitrate () / 1000;
                    if (bitrate == 0) {
                        bitrate = calculate_bitrate (file, info);
                    }

                    // NOTE: samplerate of 0 means it's corrupted
                    samplerate = (int) audio_info.get_sample_rate ();
                }
            } catch (Error err) {
                debug (@"Failed to discover the information of file $(file.get_path()) - Message: $(err.message)");
            }
        }

        /**
         * Tries to estimate the bitrate, based on length and size.
         *
         * It's not very precise, since it doesn't account for the size of metadata, such as attached images.
         */
        private int calculate_bitrate (File file, Gst.PbUtils.DiscovererInfo info) {
            uint64 file_size = get_file_size (file);
            uint64 duration_ns = info.get_duration ();

            double duration_s = duration_ns / (double) Gst.SECOND;

            return (int) ((file_size * 8.0) / duration_s / 1000.0);
        }

        /**
         * Gets the file's size, in bytes.
         */
        private int64 get_file_size (File file) {
            int64 size = 0;

            try {
                FileInfo info = file.query_info (FileAttribute.STANDARD_SIZE,
                                                 FileQueryInfoFlags.NONE,
                                                 null);

                size = info.get_size ();
            } catch (Error err) {
                debug (@"Failed to get file size for $(file.get_path ()). Message: $(err.message)");
            }

            return size;
        }

        /**
         * Cancel a running process.
         *
         * The running processes will gracefully finish, and not stopped mid-way.
         */
        public void cancel () {
            cancelled = true;
        }
    }
}
