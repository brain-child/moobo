public class Window : Hdy.ApplicationWindow {

    public Type fab_selection { private set; get; default = typeof (TextWidget); }
    public Gtk.ListBox listbox { private set; get; }
    public Hdy.HeaderBar board_header { private set; get; }
    public Hdy.Deck deck { private set; get; }

    private GLib.Settings settings;

    public Window (Gtk.Application application) {
        Object (
            application: application,
            title: (Const.APP_NAME)
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
            halign = Gtk.Align.START
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
        var board_controller = new BoardController.with_model (this, model);

        listbox.add (board_controller.row);
        deck.add (board_controller.board);

        if (model.is_active) {
            board_controller.row.activate ();
            model.is_active = false;
        }
        return board_controller.board;
    }

    private void load_boards () {
        var list = Deserializer.from_json ();
        if (list.size == 0) {
            create_new_board ();
        }
        foreach (var model in list) {
            create_new_board (model);
        }
    }

    public void save () {
        int x, y;
        get_position (out x, out y);

        settings.set_int ("win-x", x);
        settings.set_int ("win-y", y);

        var active_board = (Board) deck.get_visible_child ();
        if (active_board != null) {
            active_board.controller.model.is_active = true;
        }
        Serializer.to_json (deck.get_children ());
    }

}
