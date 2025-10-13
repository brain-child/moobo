public class ImageWidget : Movable {

    public ImageController controller { private set; get; }
    public Gtk.Image image { set; get; }
    public Gdk.Pixbuf pixbuf { set; get; }
    
    // Resize handle constants
    private const int RESIZE_HANDLE_SIZE = 8;
    private const int RESIZE_THRESHOLD = 12;
    
    public enum ResizeHandle {
        NONE,
        TOP_LEFT,
        TOP_RIGHT,
        BOTTOM_LEFT,
        BOTTOM_RIGHT,
        TOP,
        BOTTOM,
        LEFT,
        RIGHT
    }
    
    public ResizeHandle current_handle { private set; get; default = ResizeHandle.NONE; }
    private bool is_resizing = false;
    private int resize_start_x;
    private int resize_start_y;
    private int resize_start_width;
    private int resize_start_height;
    private double resize_start_scale_factor;

    public ImageWidget (ImageController controller) {
        this.controller = controller;
        image = new Gtk.Image ();
    }

    public void init (string path) {
        var max_x = Const.IMG_MAX_WIDTH;
        var max_y = Const.IMG_MAX_HEIGHT;

        int width;
        int height;
        Gdk.Pixbuf.get_file_info (path, out width, out height);
        var scale_factor = controller.model.scale_factor;

        if (width * scale_factor > max_x) {
            scale_factor = ((double) max_x / width);
        }
        if (height * scale_factor > max_y) {
            scale_factor = ((double) max_y / height);
        }
        width = (int) (scale_factor * width);
        height = (int) (scale_factor * height);

        try {
            pixbuf = new Gdk.Pixbuf.from_file_at_size (path, width, height);
        } catch (Error e) {
            warning (e.message);
        }
        image = new Gtk.Image.from_pixbuf (pixbuf);

        add (image);
    }
    
    public ResizeHandle get_resize_handle_at_position (double x, double y) {
        int width = get_allocated_width ();
        int height = get_allocated_height ();
        
        // Check corner handles first
        if (x <= RESIZE_THRESHOLD && y <= RESIZE_THRESHOLD) {
            return ResizeHandle.TOP_LEFT;
        } else if (x >= width - RESIZE_THRESHOLD && y <= RESIZE_THRESHOLD) {
            return ResizeHandle.TOP_RIGHT;
        } else if (x <= RESIZE_THRESHOLD && y >= height - RESIZE_THRESHOLD) {
            return ResizeHandle.BOTTOM_LEFT;
        } else if (x >= width - RESIZE_THRESHOLD && y >= height - RESIZE_THRESHOLD) {
            return ResizeHandle.BOTTOM_RIGHT;
        }
        // Check edge handles
        else if (y <= RESIZE_THRESHOLD) {
            return ResizeHandle.TOP;
        } else if (y >= height - RESIZE_THRESHOLD) {
            return ResizeHandle.BOTTOM;
        } else if (x <= RESIZE_THRESHOLD) {
            return ResizeHandle.LEFT;
        } else if (x >= width - RESIZE_THRESHOLD) {
            return ResizeHandle.RIGHT;
        }
        
        return ResizeHandle.NONE;
    }
    
    public string get_cursor_name_for_handle (ResizeHandle handle) {
        switch (handle) {
            case ResizeHandle.TOP_LEFT:
            case ResizeHandle.BOTTOM_RIGHT:
                return "nw-resize";
            case ResizeHandle.TOP_RIGHT:
            case ResizeHandle.BOTTOM_LEFT:
                return "ne-resize";
            case ResizeHandle.TOP:
            case ResizeHandle.BOTTOM:
                return "ns-resize";
            case ResizeHandle.LEFT:
            case ResizeHandle.RIGHT:
                return "ew-resize";
            default:
                return "grab";
        }
    }
    
    public void start_resize (ResizeHandle handle, double x, double y) {
        current_handle = handle;
        is_resizing = true;
        resize_start_x = (int) x;
        resize_start_y = (int) y;
        resize_start_width = get_allocated_width ();
        resize_start_height = get_allocated_height ();
        resize_start_scale_factor = controller.model.scale_factor;
    }
    
    public void update_resize (double x, double y) {
        if (!is_resizing || current_handle == ResizeHandle.NONE) {
            return;
        }
        
        double dx = x - resize_start_x;
        double dy = y - resize_start_y;
        
        // Get original image dimensions
        int orig_width, orig_height;
        Gdk.Pixbuf.get_file_info (controller.model.path, out orig_width, out orig_height);
        
        double new_scale_factor = resize_start_scale_factor;
        
        // Calculate new scale factor based on handle
        switch (current_handle) {
            case ResizeHandle.BOTTOM_RIGHT:
                new_scale_factor = resize_start_scale_factor * (1.0 + dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.BOTTOM_LEFT:
                new_scale_factor = resize_start_scale_factor * (1.0 - dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.TOP_RIGHT:
                new_scale_factor = resize_start_scale_factor * (1.0 + dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.TOP_LEFT:
                new_scale_factor = resize_start_scale_factor * (1.0 - dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.RIGHT:
                new_scale_factor = resize_start_scale_factor * (1.0 + dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.LEFT:
                new_scale_factor = resize_start_scale_factor * (1.0 - dx / (orig_width * resize_start_scale_factor));
                break;
            case ResizeHandle.BOTTOM:
                new_scale_factor = resize_start_scale_factor * (1.0 + dy / (orig_height * resize_start_scale_factor));
                break;
            case ResizeHandle.TOP:
                new_scale_factor = resize_start_scale_factor * (1.0 - dy / (orig_height * resize_start_scale_factor));
                break;
        }
        
        // Apply constraints
        new_scale_factor = double.max (0.1, new_scale_factor);
        new_scale_factor = double.min (3.0, new_scale_factor);
        
        // Check maximum size constraints
        int new_width = (int) (orig_width * new_scale_factor);
        int new_height = (int) (orig_height * new_scale_factor);
        
        if (new_width > Const.IMG_MAX_WIDTH) {
            new_scale_factor = (double) Const.IMG_MAX_WIDTH / orig_width;
        }
        if (new_height > Const.IMG_MAX_HEIGHT) {
            new_scale_factor = double.min (new_scale_factor, (double) Const.IMG_MAX_HEIGHT / orig_height);
        }
        
        // Update the model and widget
        controller.model.scale_factor = new_scale_factor;
        controller.update_widget ();
    }
    
    public void end_resize () {
        is_resizing = false;
        current_handle = ResizeHandle.NONE;
    }
    
    public bool get_is_resizing () {
        return is_resizing;
    }

}
