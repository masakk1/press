public struct QualityPreset {
    public string name;
    public string format;
    public int bitrate;
    public string codec;
}

public class QualityPresets : Object {
    private static QualityPreset[] _list = {
    };
    public static QualityPreset[] list {
        get {
            if( _list == null ){
                _list = {
                    QualityPreset () {
                        name = "High Quality", format = "opus", bitrate = 192, codec = "libopus"
                    },
                    QualityPreset () {
                        name = "Standard", format = "mp3", bitrate = 128, codec = "libmp3lame"
                    },
                    QualityPreset () {
                        name = "Low Size", format = "aac", bitrate = 96, codec = "aac"
                    }
                };
            }
            return _list;
        }
    }
    public const string custom = "Other...";
}
