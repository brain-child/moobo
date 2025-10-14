public class ImageController : WidgetController {

    public ImageWidget movable { private set; get; }
    public ImageModel model { private set; get; }

    private string app_dir = "%s/com.github.brain_child.moobo".printf (Environment.get_user_data_dir ());
    private int width;
    private int height;

    public ImageController (BoardController board_controller, int x, int y, ImageModel model = new ImageModel ()) {
        base (board_controller, x, y);
        this.movable = new ImageWidget (this);
        this.model = model;

        if (model.path == "") {
            var placeholder = new Gtk.Image.from_icon_name ("image-x-generic", Gtk.IconSize.DIALOG) {
                valign = Gtk.Align.START,
                halign = Gtk.Align.START,
                margin_start = x,
                margin_top = y
            };
            board_controller.overlay.add_overlay (placeholder);
            placeholder.show ();
            model.path = get_file ();
            board_controller.overlay.remove (placeholder);
        }

        Gdk.Pixbuf.get_file_info (model.path, out width, out height);

        movable.init ();
        update_widget ();
        movable.handle_events (board_controller);
        board_controller.board.scale.value_changed.connect (on_value_changed);
    }

    public string get_file () {
        string file_path = "";
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
                movable.destroy ();
                return "";
            }
            
            file_path = copy_file (source_file);
            if (file_path == "") {
                ErrorHandler.show_error_dialog (
                    board_controller.window,
                    _("Failed to Add Image"),
                    _("Could not copy the selected image file."),
                    _("Please check that you have permission to access the file and sufficient disk space.")
                );
                movable.destroy ();
                return "";
            }
        } else {
            movable.destroy ();
        }
        return file_path;
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

        // Validate file exists before loading
        if (!ErrorHandler.validate_file_path (model.path)) {
            debug ("Image file not found: %s", model.path);
            show_missing_image_placeholder ();
            return;
        }

        // Use image cache for better performance
        var cache_manager = ImageCache.ImageCacheManager.get_instance ();
        var pixbuf = cache_manager.get_image (model.path, scaled_width, scaled_height);
        
        if (pixbuf != null) {
            movable.pixbuf = pixbuf;
            movable.image.pixbuf = pixbuf;
        } else {
            warning ("Failed to load image from cache: %s", model.path);
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

    private string copy_file (File source_file) {
        try {
            // Validate source file exists and is readable
            if (!source_file.query_exists ()) {
                throw new FileError.NOENT ("Source file does not exist: %s".printf (source_file.get_path ()));
            }
            
            var source_info = source_file.query_info ("access::can-read", FileQueryInfoFlags.NONE);
            if (!source_info.get_attribute_boolean ("access::can-read")) {
                throw new FileError.ACCES ("Cannot read source file: %s".printf (source_file.get_path ()));
            }
            
            // Ensure app directory exists
            var app_dir_file = File.new_for_path (app_dir);
            if (!app_dir_file.query_exists ()) {
                app_dir_file.make_directory_with_parents ();
            }
            
            var target_file_path = "%s/%d".printf (app_dir, (int) source_file.hash ());
            var target_file = File.new_for_path (target_file_path);
            
            // Check if file already exists
            if (target_file.query_exists ()) {
                // Verify the existing file is valid
                try {
                    var test_pixbuf = new Gdk.Pixbuf.from_file (target_file_path);
                    if (test_pixbuf != null) {
                        return target_file_path;
                    }
                } catch (Error e) {
                    // Existing file is corrupted, remove it
                    target_file.delete ();
                }
            }
            
            // Copy the file
            source_file.copy (target_file, FileCopyFlags.OVERWRITE);
            
            // Verify the copy was successful
            if (!target_file.query_exists ()) {
                throw new FileError.IO ("Failed to copy file");
            }
            
            return target_file_path;
        } catch (Error e) {
            warning ("Failed to copy file %s: %s", source_file.get_path (), e.message);
            return "";
        }
    }

    private void on_value_changed () {
        if (board_controller.selected_widget == movable) {
            var scale_val = board_controller.board.scale.get_value ();
            var new_width = (int) (scale_val * width);
            var new_height = (int) (scale_val * height);

            // Validate file exists before scaling
            if (!ErrorHandler.validate_file_path (model.path)) {
                debug ("Image file not found during scaling: %s", model.path);
                show_missing_image_placeholder ();
                return;
            }

            // Use image cache for better performance
            var cache_manager = ImageCache.ImageCacheManager.get_instance ();
            var scaled_pixbuf = cache_manager.get_image (model.path, new_width, new_height);
            
            if (scaled_pixbuf != null) {
                movable.image.pixbuf = scaled_pixbuf;
                model.scale_factor = scale_val;
            } else {
                warning ("Failed to get scaled image from cache");
                show_missing_image_placeholder ();
            }
        }
    }
}
