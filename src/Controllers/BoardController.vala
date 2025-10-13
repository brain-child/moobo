public class BoardController {

    public Board board { private set; get; }
    public Row row { private set; get; }
    public BoardModel model { private set; get; }
    public Gtk.Overlay overlay { private set; get; }
    public Movable selected_widget { set; get; }
    private int selection_z_index = 10000; // High value for selected widgets
    private int original_z_index = 0; // Store original z_index of selected widget
    public Window window { private set; get; }

    public RowController row_controller;
    private LazyLoader.LazyLoadingManager? lazy_loader;

    public BoardController (Window window, BoardModel model) {
        this.window = window;
        this.model = model;
        this.board = new Board (this);
        this.overlay = board.overlay;
        this.row_controller = new RowController (this, "Board", model.color);
        row = row_controller.row;
        
        // Initialize lazy loading for performance
        this.lazy_loader = new LazyLoader.LazyLoadingManager (this);

        row.focus_in_event.connect (on_focus_in);
        board.enter_notify_event.connect (on_enter_notify);
        row.activate.connect (on_activate);
        row.delete_row.connect (on_delete);
        row.renamed.connect (on_rename);
        board.button_press_event.connect (on_button_press);
        model.changed_event.connect (changed_handler);
        model.changed_trigger ();
    }

    public void changed_handler (Gee.ArrayList<BaseModel> widgets, string color, string title) {
        board.title = title;

        // Clear existing lazy widgets
        if (lazy_loader != null) {
            lazy_loader.unload_all_widgets ();
        }

        // Add widgets using lazy loading for better performance
        foreach (var widget in widgets) {
            if (lazy_loader != null) {
                lazy_loader.add_widget (widget, widget.x, widget.y);
            } else {
                // Fallback to immediate loading if lazy loading is disabled
                var w = WidgetFactory.create_widget_from_string (widget.model, this, widget.x, widget.y, widget);
                overlay.add_overlay (w);
            }
        }
        
        // Apply proper layering based on z_index
        update_widget_layering ();
        
        row.display_name_label.label = title;
        set_color (color);
    }

    private bool on_focus_in () {
        row.activate ();
        return false;
    }

    private bool on_enter_notify () {
        if (window.listbox.get_selected_row () != row) {
            row.activate ();
        }
        return false;
    }

    private bool on_button_press (Gdk.EventButton event) {
        board.grab_focus ();
        board.revealer.reveal_child = false;
        
        // Deselect any previously selected widget
        deselect_widget ();

        if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
            var selection = window.fab_selection;

            var x = (int) event.x;
            var y = (int) event.y;
            
            var widget = WidgetFactory.create_widget_from_class (selection, this, x, y);
            WidgetFactory.add_widget_to_model (widget, model.widgets);

            widget.rel_pos_x = widget.margin_start = x;
            widget.rel_pos_y = widget.margin_top = y;

            // Set z_index for new widget to be on top
            BaseModel widget_model = get_widget_model (widget);
            if (widget_model != null) {
                int max_z_index = 0;
                foreach (var model_widget in model.widgets) {
                    if (model_widget.z_index > max_z_index) {
                        max_z_index = model_widget.z_index;
                    }
                }
                widget_model.z_index = max_z_index + 1;
            }

            overlay.add_overlay (widget);
            WidgetFactory.focus_widget (widget);
        }
        
        return true;
    }

    private void on_activate () {
        window.board_header.title = board.title;
        if (window.deck.get_visible_child () != board) {
            window.deck.set_visible_child (board);
        }
        
        // Update viewport for lazy loading when board becomes active
        if (lazy_loader != null) {
            int width, height;
            board.get_size_request (out width, out height);
            if (width <= 0) width = 800;
            if (height <= 0) height = 600;
            lazy_loader.update_viewport (0, 0, width, height);
        }
    }

    private void on_delete (int index) {
        var children = window.deck.get_children ();
        if (children.nth_data (0) != board) {
            if (window.deck.get_visible_child () == board) {
                window.deck.set_visible_child (children.nth_data (index - 1));
                var board = children.nth_data (index - 1) as Board;
                board.controller.row.activate ();
            }
        }
    }

    private void on_rename (string name) {
        board.title = name;
        if (window.deck.get_visible_child () == board) {
            window.board_header.title = board.title;
        }
    }

    private void set_color (string color) {
        var hex_color = Colors.from_name (color);

        string style = """
            @define-color colorAccent %s;
            @define-color accent_color %s;
        """.printf (hex_color, hex_color);

        var style_provider = new Gtk.CssProvider ();
        try {
            style_provider.load_from_data (style, style.length);
        } catch (Error e) {
            warning (e.message);
        }
        unowned Gtk.StyleContext style_context = row.source_color.get_style_context ();
        style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void move_widget_to_foreground (Movable widget) {
        // Find the highest z_index among all widgets (excluding selection z_index)
        int max_z_index = 0;
        foreach (var model in model.widgets) {
            if (model.z_index > max_z_index && model.z_index < selection_z_index) {
                max_z_index = model.z_index;
            }
        }
        
        // Set the widget's z_index to be higher than all others
        BaseModel widget_model = get_widget_model (widget);
        if (widget_model != null) {
            widget_model.z_index = max_z_index + 1;
            
            // If this widget is currently selected, update the original_z_index too
            if (selected_widget == widget) {
                original_z_index = widget_model.z_index;
            }
            
            update_widget_layering ();
        }
    }

    public void move_widget_to_background (Movable widget) {
        // Find the lowest z_index among all widgets (excluding selection z_index)
        int min_z_index = 0;
        foreach (var model in model.widgets) {
            if (model.z_index < min_z_index && model.z_index < selection_z_index) {
                min_z_index = model.z_index;
            }
        }
        
        // Set the widget's z_index to be lower than all others
        BaseModel widget_model = get_widget_model (widget);
        if (widget_model != null) {
            widget_model.z_index = min_z_index - 1;
            
            // If this widget is currently selected, update the original_z_index too
            if (selected_widget == widget) {
                original_z_index = widget_model.z_index;
            }
            
            update_widget_layering ();
        }
    }

    private BaseModel? get_widget_model (Movable widget) {
        if (widget is TextWidget) {
            var text_widget = widget as TextWidget;
            return text_widget.controller.model;
        } else if (widget is LabelWidget) {
            var label_widget = widget as LabelWidget;
            return label_widget.controller.model;
        } else if (widget is ImageWidget) {
            var image_widget = widget as ImageWidget;
            return image_widget.controller.model;
        }
        return null;
    }

    public void select_widget (Movable widget) {
        // Deselect previous widget if any
        if (selected_widget != null && selected_widget != widget) {
            deselect_widget ();
        }
        
        // Select new widget
        selected_widget = widget;
        
        // Store original z_index and temporarily bring to foreground
        BaseModel widget_model = get_widget_model (widget);
        if (widget_model != null) {
            original_z_index = widget_model.z_index;
            widget_model.z_index = selection_z_index;
            update_widget_layering ();
        }
    }
    
    public void deselect_widget () {
        if (selected_widget != null) {
            // Restore original z_index for deselected widget
            BaseModel widget_model = get_widget_model (selected_widget);
            if (widget_model != null) {
                widget_model.z_index = original_z_index;
                update_widget_layering ();
            }
            selected_widget = null;
        }
    }

    private void update_widget_layering () {
        // Sort widgets by z_index and reorder them in the overlay
        var sorted_widgets = new Gee.ArrayList<Movable> ();
        
        // Get all movable widgets from the overlay
        var children = overlay.get_children ();
        foreach (var child in children) {
            if (child is Movable) {
                sorted_widgets.add ((Movable) child);
            }
        }
        
        // Sort by z_index (ascending order - lower z_index first)
        sorted_widgets.sort ((a, b) => {
            BaseModel? model_a = get_widget_model (a);
            BaseModel? model_b = get_widget_model (b);
            if (model_a == null || model_b == null) return 0;
            return model_a.z_index - model_b.z_index;
        });
        
        // Reorder widgets in the overlay
        foreach (var widget in sorted_widgets) {
            overlay.reorder_overlay (widget, -1);
        }
    }

}
