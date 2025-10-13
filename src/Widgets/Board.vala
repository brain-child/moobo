public class Board : Gtk.EventBox {

    public string title { set; get; default = _("Board"); }
    public Gtk.Overlay overlay { private set; get; }
    public BoardController controller { private set; get; }
    public Gtk.Revealer revealer { private set; get; }
    public Gtk.Scale scale { set; get; }
    private Gtk.Revealer drag_indicator { private set; get; }

    public Board (BoardController controller) {
        this.controller = controller;
        can_focus = true;
        
        // Enable drag and drop
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.COPY);
        Gtk.drag_dest_add_uri_targets (this);
        drag_data_received.connect (on_drag_data_received);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.1, 2, 0.1) {
            value_pos = Gtk.PositionType.BOTTOM,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            draw_value = false,
        };
        scale.add_mark (1, Gtk.PositionType.BOTTOM, null);
        scale.set_value (1);
        scale.set_size_request (300, -1);

        revealer = new Gtk.Revealer () {
            valign = Gtk.Align.END,
            margin = 30,
        };
        revealer.add (scale);

        overlay = new Gtk.Overlay ();
        overlay.add (draw_grid ());
        overlay.add_overlay (revealer);
        
        // Create drag indicator
        var drag_label = new Gtk.Label (_("Drop image files here")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        drag_label.get_style_context ().add_class ("drag-indicator");
        
        drag_indicator = new Gtk.Revealer () {
            valign = Gtk.Align.FILL,
            halign = Gtk.Align.FILL,
            reveal_child = false
        };
        drag_indicator.add (drag_label);
        overlay.add_overlay (drag_indicator);

        add (overlay);
        show_all ();
    }

    private Gtk.DrawingArea draw_grid () {
        var drawing_area = new Gtk.DrawingArea ();
        drawing_area.draw.connect ((widget, context) => {
            var width = get_allocated_width ();
            var height = get_allocated_height ();
            context.set_source_rgb (0.7, 0.7, 0.7);
            context.fill ();
            var spacing = 20;
            var y = 0;
            var x = spacing;
            context.set_line_width (2.0);
            while (x <= width ) {
                while (y <= height) {
                    context.move_to (x, y);
                    context.line_to (x, y + 2);
                    y += spacing;
                }
                y = 0;
                x += spacing;
            }
            context.stroke ();
            return true;
        });


        return drawing_area;
    }

    private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time) {
        // Hide drag indicator
        drag_indicator.reveal_child = false;
        
        if (selection_data.get_length () >= 0) {
            string[] uris = selection_data.get_uris ();
            
            foreach (string uri in uris) {
                // Convert URI to file path
                var file = File.new_for_uri (uri);
                string file_path = file.get_path ();
                
                if (file_path != null && is_image_file (file_path)) {
                    create_image_widget_from_file (file_path, x, y);
                }
            }
            
            Gtk.drag_finish (context, true, false, time);
        } else {
            Gtk.drag_finish (context, false, false, time);
        }
    }
    
    private bool on_drag_motion (Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time) {
        // Show drag indicator
        drag_indicator.reveal_child = true;
        
        // Set visual feedback based on whether we can accept the drop
        Gdk.drag_status (context, Gdk.DragAction.COPY, time);
        
        return true;
    }
    
    private void on_drag_leave (Gtk.Widget widget, Gdk.DragContext context, uint time) {
        // Hide drag indicator
        drag_indicator.reveal_child = false;
    }
    
    private bool is_image_file (string file_path) {
        string[] image_extensions = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff", ".svg", ".webp"};
        string lower_path = file_path.down ();
        
        foreach (string ext in image_extensions) {
            if (lower_path.has_suffix (ext)) {
                return true;
            }
        }
        return false;
    }
    
    private void create_image_widget_from_file (string file_path, int x, int y) {
        try {
            // Validate the image file
            if (!ErrorHandler.validate_image_file (file_path)) {
                ErrorHandler.show_error_dialog (
                    controller.window,
                    _("Invalid Image File"),
                    _("The dropped file is not a valid image or cannot be read."),
                    _("Please drop a valid image file (PNG, JPEG, GIF, etc.)")
                );
                return;
            }
            
            // Create image model with the file path
            var image_model = new ImageModel () {
                path = file_path,
                x = x,
                y = y,
                scale_factor = 1.0
            };
            
            // Create image controller and widget
            var image_controller = new ImageController (controller, x, y, image_model);
            var image_widget = image_controller.get_movable ();
            
            // Add to model
            WidgetFactory.add_widget_to_model (image_widget, controller.model.widgets);
            
            // Set z_index for new widget to be on top
            int max_z_index = 0;
            foreach (var model_widget in controller.model.widgets) {
                if (model_widget.z_index > max_z_index) {
                    max_z_index = model_widget.z_index;
                }
            }
            image_model.z_index = max_z_index + 1;
            
            // Add to overlay
            overlay.add_overlay (image_widget);
            
            // Focus the new widget
            WidgetFactory.focus_widget (image_widget);
            
        } catch (Error e) {
            warning ("Failed to create image widget from dropped file: %s", e.message);
            ErrorHandler.show_error_dialog (
                controller.window,
                _("Failed to Add Image"),
                _("Could not add the dropped image file."),
                _("Please check that the file is a valid image and try again.")
            );
        }
    }

}
