public class ImageController : WidgetController {

    public ImageWidget movable { private set; get; }
    public ImageModel model { private set; get; }

    private int width;
    private int height;

    public ImageController (BoardController board_controller, int x, int y, ImageModel model = new ImageModel ()) {
        base (board_controller, x, y);
        this.movable = new ImageWidget (this);
        this.model = model;

        if (model.base64_data == "" && model.path == "") {
            var placeholder = new Gtk.Image.from_icon_name ("image-x-generic", Gtk.IconSize.DIALOG) {
                valign = Gtk.Align.START,
                halign = Gtk.Align.START,
                margin_start = x,
                margin_top = y
            };
            board_controller.overlay.add_overlay (placeholder);
            placeholder.show ();
            var success = load_image_from_file ();
            board_controller.overlay.remove (placeholder);
            
            if (!success) {
                movable.destroy ();
                return;
            }
        }

        // Get image dimensions from either base64 data or file path
        if (model.base64_data != "") {
            try {
                var pixbuf = get_pixbuf_from_base64 (model.base64_data);
                if (pixbuf != null) {
                    width = pixbuf.get_width ();
                    height = pixbuf.get_height ();
                } else {
                    movable.destroy ();
                    return;
                }
            } catch (Error e) {
                warning ("Failed to get image dimensions from base64: %s", e.message);
                movable.destroy ();
                return;
            }
        } else if (model.path != "") {
            Gdk.Pixbuf.get_file_info (model.path, out width, out height);
        } else {
            movable.destroy ();
            return;
        }

        movable.init ();
        update_widget ();
        movable.handle_events (board_controller);
        board_controller.board.scale.value_changed.connect (on_value_changed);
    }

    public bool load_image_from_file () {
        var file_chooser = new Gtk.FileChooserNative (
            _("Select Image"),
            board_controller.window,
            Gtk.FileChooserAction.OPEN,
            _("Open"),
            _("Cancel")
        );
        
        // Set up image file filter
        var filter = new Gtk.FileFilter ();
        filter.add_pixbuf_formats ();
        filter.set_name (_("Image Files"));
        file_chooser.filter = filter;
        
        // Add all files filter
        var all_filter = new Gtk.FileFilter ();
        all_filter.add_pattern ("*");
        all_filter.set_name (_("All Files"));
        file_chooser.add_filter (all_filter);
        
        file_chooser.set_transient_for (board_controller.window);
        file_chooser.set_modal (true);
        
        var res = file_chooser.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var source_file = file_chooser.get_file ();
            
            // Validate the selected file
            if (!ErrorHandler.validate_image_file (source_file.get_path ())) {
                ErrorHandler.show_error_dialog (
                    board_controller.window,
                    _("Invalid Image File"),
                    _("The selected file is not a valid image or cannot be read."),
                    _("Please select a valid image file (PNG, JPEG, GIF, etc.)")
                );
                return false;
            }
            
            // Convert image to base64
            var success = encode_image_to_base64 (source_file);
            if (!success) {
                ErrorHandler.show_error_dialog (
                    board_controller.window,
                    _("Failed to Add Image"),
                    _("Could not process the selected image file."),
                    _("Please check that you have permission to access the file and sufficient disk space.")
                );
                return false;
            }
            return true;
        }
        return false;
    }

    public override Movable get_movable () {
        return movable;
    }

    public override BaseModel get_model () {
        return model;
    }

    public override void handle_key_press (Gdk.EventKey event) {
        // ImageController doesn't handle key events
    }

    public override void handle_key_release () {
        // ImageController doesn't handle key events
    }

    public override void update_widget () {
        movable.rel_pos_x = movable.margin_start = model.x;
        movable.rel_pos_y = movable.margin_top = model.y;

        var scaled_width = (int) (width * model.scale_factor);
        var scaled_height = (int) (height * model.scale_factor);

        Gdk.Pixbuf? pixbuf = null;

        // Load image from base64 data if available
        if (model.base64_data != "") {
            try {
                var original_pixbuf = get_pixbuf_from_base64 (model.base64_data);
                if (original_pixbuf != null) {
                    // Scale the pixbuf if needed
                    if (scaled_width != original_pixbuf.get_width () || scaled_height != original_pixbuf.get_height ()) {
                        pixbuf = original_pixbuf.scale_simple (scaled_width, scaled_height, Gdk.InterpType.BILINEAR);
                    } else {
                        pixbuf = original_pixbuf;
                    }
                }
            } catch (Error e) {
                warning ("Failed to load image from base64: %s", e.message);
            }
        }
        // Fallback to file path for backward compatibility
        else if (model.path != "" && ErrorHandler.validate_file_path (model.path)) {
            // Use image cache for better performance
            var cache_manager = ImageCache.ImageCacheManager.get_instance ();
            pixbuf = cache_manager.get_image (model.path, scaled_width, scaled_height);
        }
        
        if (pixbuf != null) {
            movable.pixbuf = pixbuf;
            movable.image.pixbuf = pixbuf;
        } else {
            warning ("Failed to load image");
            show_missing_image_placeholder ();
        }
    }
    
    private void show_missing_image_placeholder () {
        try {
            // Create a placeholder image
            var placeholder_pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 200, 150);
            placeholder_pixbuf.fill (0x80808080u); // Gray background
            
            // Create a simple "missing image" icon using a basic pattern
            // Draw a simple "X" pattern to indicate missing image
            var pixels = placeholder_pixbuf.get_pixels ();
            var rowstride = placeholder_pixbuf.get_rowstride ();
            var n_channels = placeholder_pixbuf.get_n_channels ();
            
            // Draw a simple X pattern
            for (int y = 0; y < 150; y++) {
                for (int x = 0; x < 200; x++) {
                    unowned uchar[] pixel = pixels[y * rowstride + x * n_channels:3];
                    
                    // Draw X pattern
                    if ((x - 100) * (x - 100) + (y - 75) * (y - 75) < 1000) {
                        if ((x - y).abs () < 3 || (x + y - 200).abs () < 3) {
                            pixel[0] = 0x00; // Red
                            pixel[1] = 0x00; // Green  
                            pixel[2] = 0x00; // Blue
                        }
                    }
                }
            }
            
            movable.pixbuf = placeholder_pixbuf;
            movable.image.pixbuf = placeholder_pixbuf;
        } catch (Error e) {
            warning ("Failed to create placeholder image: %s", e.message);
        }
    }

    private bool encode_image_to_base64 (File source_file) {
        try {
            // Validate source file exists and is readable
            if (!source_file.query_exists ()) {
                throw new FileError.NOENT ("Source file does not exist: %s".printf (source_file.get_path ()));
            }
            
            var source_info = source_file.query_info ("access::can-read", FileQueryInfoFlags.NONE);
            if (!source_info.get_attribute_boolean ("access::can-read")) {
                throw new FileError.ACCES ("Cannot read source file: %s".printf (source_file.get_path ()));
            }
            
            // Load the image file
            var pixbuf = new Gdk.Pixbuf.from_file (source_file.get_path ());
            if (pixbuf == null) {
                throw new FileError.INVAL ("Failed to load image from file");
            }
            
            // Get image dimensions
            width = pixbuf.get_width ();
            height = pixbuf.get_height ();
            
            // Save pixbuf to PNG format in memory
            uint8[] buffer;
            pixbuf.save_to_buffer (out buffer, "png");
            
            // Encode to base64
            var base64_string = Base64.encode (buffer);
            model.base64_data = base64_string;
            
            // Clear the path since we're now using base64
            model.path = "";
            
            return true;
        } catch (Error e) {
            warning ("Failed to encode image to base64 %s: %s", source_file.get_path (), e.message);
            return false;
        }
    }
    
    public Gdk.Pixbuf? get_pixbuf_from_base64 (string base64_data) throws Error {
        if (base64_data == "") {
            throw new FileError.INVAL ("Empty base64 data");
        }
        
        // Decode base64 data
        uint8[] buffer = Base64.decode (base64_data);
        
        if (buffer == null || buffer.length == 0) {
            throw new FileError.INVAL ("Failed to decode base64 data");
        }
        
        // Create pixbuf from buffer
        var pixbuf = new Gdk.Pixbuf.from_stream (new MemoryInputStream.from_data (buffer, null));
        if (pixbuf == null) {
            throw new FileError.INVAL ("Failed to create pixbuf from base64 data");
        }
        
        return pixbuf;
    }

    private void on_value_changed () {
        if (board_controller.selected_widget == movable) {
            var scale_val = board_controller.board.scale.get_value ();
            var new_width = (int) (scale_val * width);
            var new_height = (int) (scale_val * height);

            Gdk.Pixbuf? scaled_pixbuf = null;

            // Load and scale image from base64 data if available
            if (model.base64_data != "") {
                try {
                    var original_pixbuf = get_pixbuf_from_base64 (model.base64_data);
                    if (original_pixbuf != null) {
                        scaled_pixbuf = original_pixbuf.scale_simple (new_width, new_height, Gdk.InterpType.BILINEAR);
                    }
                } catch (Error e) {
                    warning ("Failed to load image from base64 during scaling: %s", e.message);
                }
            }
            // Fallback to file path for backward compatibility
            else if (model.path != "" && ErrorHandler.validate_file_path (model.path)) {
                // Use image cache for better performance
                var cache_manager = ImageCache.ImageCacheManager.get_instance ();
                scaled_pixbuf = cache_manager.get_image (model.path, new_width, new_height);
            }
            
            if (scaled_pixbuf != null) {
                movable.image.pixbuf = scaled_pixbuf;
                model.scale_factor = scale_val;
            } else {
                warning ("Failed to get scaled image");
                show_missing_image_placeholder ();
            }
        }
    }
}
