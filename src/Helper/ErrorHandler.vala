namespace ErrorHandler {
    
    public class ErrorDialog : Gtk.Dialog {
        private Gtk.Label message_label;
        private Gtk.TextView details_text;
        private Gtk.Expander details_expander;
        
        public ErrorDialog (Gtk.Window? parent, string title, string message, string? details = null) {
            this.title = title;
            transient_for = parent;
            modal = true;
            resizable = false;
            
            var content_area = get_content_area ();
            content_area.spacing = 12;
            content_area.margin = 20;
            
            // Main message
            message_label = new Gtk.Label (message) {
                wrap = true,
                max_width_chars = 50,
                justify = Gtk.Justification.CENTER
            };
            content_area.add (message_label);
            
            // Details expander (if details provided)
            if (details != null && details != "") {
                details_text = new Gtk.TextView () {
                    editable = false,
                    wrap_mode = Gtk.WrapMode.WORD,
                    height_request = 150
                };
                details_text.buffer.text = details;
                
                details_expander = new Gtk.Expander.with_mnemonic (_("_Show Details")) {
                    expanded = false
                };
                details_expander.add (details_text);
                content_area.add (details_expander);
            }
            
            // Buttons
            add_button (_("_OK"), Gtk.ResponseType.OK);
            
            show_all ();
        }
    }
    
    public void show_error_dialog (Gtk.Window? parent, string title, string message, string? details = null) {
        var dialog = new ErrorDialog (parent, title, message, details);
        dialog.run ();
        dialog.destroy ();
    }
    
    public void show_warning_dialog (Gtk.Window? parent, string title, string message) {
        var dialog = new Gtk.MessageDialog (
            parent,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.WARNING,
            Gtk.ButtonsType.OK,
            "%s", message
        );
        dialog.title = title;
        dialog.run ();
        dialog.destroy ();
    }
    
    public void show_info_dialog (Gtk.Window? parent, string title, string message) {
        var dialog = new Gtk.MessageDialog (
            parent,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.INFO,
            Gtk.ButtonsType.OK,
            "%s", message
        );
        dialog.title = title;
        dialog.run ();
        dialog.destroy ();
    }
    
    public bool confirm_dialog (Gtk.Window? parent, string title, string message) {
        var dialog = new Gtk.MessageDialog (
            parent,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.QUESTION,
            Gtk.ButtonsType.YES_NO,
            "%s", message
        );
        dialog.title = title;
        var response = dialog.run ();
        dialog.destroy ();
        return response == Gtk.ResponseType.YES;
    }
    
    public string get_user_friendly_error_message (Error error) {
        switch (error.code) {
            case FileError.NOENT:
                return _("File not found. The file may have been moved or deleted.");
            case FileError.ACCES:
                return _("Permission denied. You don't have permission to access this file.");
            case FileError.ISDIR:
                return _("Expected a file but found a directory.");
            case FileError.NOTDIR:
                return _("Expected a directory but found a file.");
            case FileError.NOSPC:
                return _("No space left on device.");
            case FileError.ROFS:
                return _("Read-only file system.");
            case FileError.EXIST:
                return _("File already exists.");
            case FileError.INVAL:
                return _("Invalid argument.");
            case FileError.IO:
                return _("Input/output error occurred.");
            default:
                return error.message;
        }
    }
    
    public bool validate_file_path (string path) {
        if (path == null || path == "") {
            return false;
        }
        
        var file = File.new_for_path (path);
        return file.query_exists ();
    }
    
    public bool validate_image_file (string path) {
        if (!validate_file_path (path)) {
            return false;
        }
        
        try {
            var file = File.new_for_path (path);
            var info = file.query_info ("standard::content-type", FileQueryInfoFlags.NONE);
            var content_type = info.get_content_type ();
            
            // Check if it's an image type
            return content_type.has_prefix ("image/");
        } catch (Error e) {
            return false;
        }
    }
    
    public string? get_safe_filename (string original_path) {
        if (original_path == null || original_path == "") {
            return null;
        }
        
        var file = File.new_for_path (original_path);
        var basename = file.get_basename ();
        
        // Remove potentially dangerous characters
        var safe_name = basename.replace ("/", "_")
                              .replace ("\\", "_")
                              .replace (":", "_")
                              .replace ("*", "_")
                              .replace ("?", "_")
                              .replace ("\"", "_")
                              .replace ("<", "_")
                              .replace (">", "_")
                              .replace ("|", "_");
        
        return safe_name;
    }
}
