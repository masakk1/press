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

// TODO: Create proper constructor

/**
 * To create deep copies of itself
 */
public interface Press.Clonable<T> {
    /**
     * Create a deep copy of ``this``
     */
    public abstract T clone();

}

public struct Press.FormatConfig {
    public string name;
    public string extension;
    public bool attach_video;
    public string codec;
}

public struct Press.QualityConfig {
    public string name;
    public Press.FormatConfig format;
    public int bitrate;
    public int samplerate;
}

public class Press.CompressConfig : Press.Clonable<Press.CompressConfig> {
    public string source_path { get; set; }
    public string target_path { get; set; }
    public Press.QualityConfig quality_config;
    public bool copy_noaudio_files { get; set; }
    public bool replace_destination_files { get; set; }

    public CompressConfig () {
    }

    public CompressConfig clone() {
        var config = new CompressConfig ();
        config.source_path = this.source_path;
        config.target_path = this.target_path;
        config.quality_config = this.quality_config;
        config.copy_noaudio_files = this.copy_noaudio_files;
        config.replace_destination_files = this.replace_destination_files;
        return config;
    }

}
