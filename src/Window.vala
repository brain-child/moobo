public class Window : Hdy.ApplicationWindow {

    public Type fab_selection { private set; get; default = typeof (TextWidget); }
    public Gtk.ListBox listbox { private set; get; }
    public Hdy.HeaderBar board_header { private set; get; }
    public Hdy.Deck deck { private set; get; }

    private GLib.Settings settings;

    public Window (Gtk.Application application) {
        Object (
            application: application
        );

        delete_event.connect (() => {
            save ();
            return false;
        });
    }

    static construct {
        Hdy.init ();
    }

    construct {
        settings = new GLib.Settings (Const.APP_ID);
        move (settings.get_int ("win-x"), settings.get_int ("win-y"));

        var sidebar_header = new Hdy.HeaderBar () {
            decoration_layout = "close",
            show_close_button = true
        };
        sidebar_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        deck = new Hdy.Deck () {
            transition_type = Hdy.DeckTransitionType.SLIDE,
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            vexpand = true
        };

        listbox = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.BROWSE,
        };

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            expand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled_window.add (listbox);

        var add_button = new Gtk.Button () {
            image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            always_show_image = true,
            focus_on_click = true,
            label = _("New Board"),
        };

        add_button.button_release_event.connect (() => {
            var board = create_new_board ();
            board.controller.row.activate ();
            return false;
        });

        var actionbar = new Gtk.ActionBar ();
        actionbar.add (add_button);

        var actionbar_style_context = actionbar.get_style_context ();
        actionbar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var label = new Gtk.Label (_("Boards")) {
            halign = Gtk.Align.START,
            margin_start = 8
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var sidebar_grid = new Gtk.Grid ();
        sidebar_grid.attach (sidebar_header, 0, 0);
        sidebar_grid.attach (label, 0, 1);
        sidebar_grid.attach (scrolled_window, 0, 2);
        sidebar_grid.attach (actionbar, 0, 3);

        var style_context = sidebar_grid.get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_SIDEBAR);

        var floating_button = new FloatingButton ();
        var floating_button_controller = new FloatingButtonController (floating_button);
        floating_button_controller.selection.connect ( (type) => {
            fab_selection = type;
        });

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (deck);
        overlay.add_overlay (floating_button);

        board_header = new Hdy.HeaderBar () {
            has_subtitle = true,
            decoration_layout = "",
            show_close_button = true,
            title = Const.APP_NAME
        };

        var board_header_context = board_header.get_style_context ();
        board_header_context.add_class ("default-decoration");
        board_header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var listview_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true
        };

        var board_grid = new Gtk.Grid () {
            column_homogeneous = true
        };
        board_grid.attach (board_header, 0, 0);
        board_grid.attach (overlay, 0, 1);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (sidebar_grid, false, false);
        paned.pack2 (board_grid, true, false);

        load_boards ();
        add (paned);
        show_all ();
    }

    public Board create_new_board (BoardModel model = new BoardModel ()) {
        var board_controller = new BoardController (this, model);

        listbox.add (board_controller.row);
        deck.add (board_controller.board);

        if (model.is_active) {
            board_controller.row.activate ();
            model.is_active = false;
        }
        return board_controller.board;
    }

    private void load_boards () {
        try {
            var list = Deserializer.from_json ();
            if (list.size == 0) {
                create_new_board ();
            } else {
                foreach (var model in list) {
                    create_new_board (model);
                }
            }
        } catch (Error e) {
            warning ("Failed to load boards: %s", e.message);
            
            // Show user-friendly error message
            ErrorHandler.show_error_dialog (
                this,
                _("Failed to Load Boards"),
                _("Could not load your saved boards. A new board has been created."),
                _("Error details: %s").printf (e.message)
            );
            
            // Create a default board
            create_new_board ();
        }
    }

    public void save () {
        try {
            int x, y;
            get_position (out x, out y);

            settings.set_int ("win-x", x);
            settings.set_int ("win-y", y);

            var active_board = (Board) deck.get_visible_child ();
            if (active_board != null) {
                active_board.controller.model.is_active = true;
            }
            Serializer.to_json (deck.get_children ());
        } catch (Error e) {
            warning ("Failed to save boards: %s", e.message);
            
            // Show user-friendly error message
            ErrorHandler.show_error_dialog (
                this,
                _("Failed to Save Boards"),
                _("Could not save your boards. Your changes may be lost."),
                _("Error details: %s").printf (e.message)
            );
        }
    }

    public void rename_selected_board () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null) {
            active_board.controller.row_controller.rename ();
        }
    }

    public void move_selected_widget_to_foreground () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null && active_board.controller.selected_widget != null) {
            active_board.controller.move_widget_to_foreground (active_board.controller.selected_widget);
        }
    }

    public void move_selected_widget_to_background () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null && active_board.controller.selected_widget != null) {
            active_board.controller.move_widget_to_background (active_board.controller.selected_widget);
        }
    }

    public void add_image_widget () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null) {
            // Get the center of the board
            int board_width = active_board.get_allocated_width ();
            int board_height = active_board.get_allocated_height ();
            
            // If board size is not available, use default center position
            int x = board_width > 0 ? board_width / 2 : 400;
            int y = board_height > 0 ? board_height / 2 : 300;
            
            // Create image model
            var image_model = new ImageModel () {
                x = x,
                y = y,
                scale_factor = 1.0
            };
            
            // Create image controller and widget
            var image_controller = new ImageController (active_board.controller, x, y, image_model);
            var image_widget = image_controller.get_movable ();
            
            // Add to model
            WidgetFactory.add_widget_to_model (image_widget, active_board.controller.model.widgets);
            
            // Set z_index for new widget to be on top
            int max_z_index = 0;
            foreach (var model_widget in active_board.controller.model.widgets) {
                if (model_widget.z_index > max_z_index) {
                    max_z_index = model_widget.z_index;
                }
            }
            image_model.z_index = max_z_index + 1;
            
            // Add to overlay
            active_board.overlay.add_overlay (image_widget);
            
            // Focus the new widget
            WidgetFactory.focus_widget (image_widget);
        }
    }

    public void add_text_widget () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null) {
            // Get current cursor position relative to the window
            int x, y;
            var display = get_display ();
            var seat = display.get_default_seat ();
            var pointer = seat.get_pointer ();
            var window = get_window ();
            if (window != null) {
                window.get_device_position (pointer, out x, out y, null);
            } else {
                x = y = 0; // Fallback
            }
            
            // Convert window coordinates to board coordinates
            int board_x, board_y;
            if (!translate_coordinates (active_board, x, y, out board_x, out board_y)) {
                // Fallback to center if translation fails
                int board_width = active_board.get_allocated_width ();
                int board_height = active_board.get_allocated_height ();
                board_x = board_width > 0 ? board_width / 2 : 400;
                board_y = board_height > 0 ? board_height / 2 : 300;
            }
            
            x = board_x;
            y = board_y;
            
            // Ensure coordinates are within board bounds
            int board_width = active_board.get_allocated_width ();
            int board_height = active_board.get_allocated_height ();
            
            if (x < 0) x = 0;
            if (y < 0) y = 0;
            if (x >= board_width) x = board_width - 1;
            if (y >= board_height) y = board_height - 1;
            
            // Create text model
            var text_model = new TextModel () {
                x = x,
                y = y
            };
            
            // Create text controller and widget
            var text_controller = new TextController (active_board.controller, x, y, text_model);
            var text_widget = text_controller.get_movable ();
            
            // Add to model
            WidgetFactory.add_widget_to_model (text_widget, active_board.controller.model.widgets);
            
            // Set z_index for new widget to be on top
            int max_z_index = 0;
            foreach (var model_widget in active_board.controller.model.widgets) {
                if (model_widget.z_index > max_z_index) {
                    max_z_index = model_widget.z_index;
                }
            }
            text_model.z_index = max_z_index + 1;
            
            // Add to overlay
            active_board.overlay.add_overlay (text_widget);
            
            // Focus the new widget
            WidgetFactory.focus_widget (text_widget);
        }
    }

    public void add_label_widget () {
        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null) {
            // Get current cursor position relative to the window
            int x, y;
            var display = get_display ();
            var seat = display.get_default_seat ();
            var pointer = seat.get_pointer ();
            var window = get_window ();
            if (window != null) {
                window.get_device_position (pointer, out x, out y, null);
            } else {
                x = y = 0; // Fallback
            }
            
            // Convert window coordinates to board coordinates
            int board_x, board_y;
            if (!translate_coordinates (active_board, x, y, out board_x, out board_y)) {
                // Fallback to center if translation fails
                int board_width = active_board.get_allocated_width ();
                int board_height = active_board.get_allocated_height ();
                board_x = board_width > 0 ? board_width / 2 : 400;
                board_y = board_height > 0 ? board_height / 2 : 300;
            }
            
            x = board_x;
            y = board_y;
            
            // Ensure coordinates are within board bounds
            int board_width = active_board.get_allocated_width ();
            int board_height = active_board.get_allocated_height ();
            
            if (x < 0) x = 0;
            if (y < 0) y = 0;
            if (x >= board_width) x = board_width - 1;
            if (y >= board_height) y = board_height - 1;
            
            // Create label model
            var label_model = new LabelModel () {
                x = x,
                y = y
            };
            
            // Create label controller and widget
            var label_controller = new LabelController (active_board.controller, x, y, label_model);
            var label_widget = label_controller.get_movable ();
            
            // Add to model
            WidgetFactory.add_widget_to_model (label_widget, active_board.controller.model.widgets);
            
            // Set z_index for new widget to be on top
            int max_z_index = 0;
            foreach (var model_widget in active_board.controller.model.widgets) {
                if (model_widget.z_index > max_z_index) {
                    max_z_index = model_widget.z_index;
                }
            }
            label_model.z_index = max_z_index + 1;
            
            // Add to overlay
            active_board.overlay.add_overlay (label_widget);
            
            // Focus the new widget
            WidgetFactory.focus_widget (label_widget);
        }
    }

}
