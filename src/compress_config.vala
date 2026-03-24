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

public struct Press.FormatConfig {
    public string name { get; set; }
    public string extension { get; set; }
    public bool attach_video { get; set; }
    public string codec { get; set; }
}

public struct Press.QualityConfig {
    public string name { get; set; }
    public Press.FormatConfig format { get; set; }
    public int bitrate { get; set; }
    public int samplerate { get; set; }
}

public struct Press.CompressConfig {
    public string source_path { get; set; }
    public string target_path { get; set; }
    public Press.QualityConfig quality_config { get; set; }
    public bool copy_noaudio_files { get; set; }
    public bool replace_destination_files { get; set; }
}
