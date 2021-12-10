public class BoardController {

    public Board board { private set; get; }
    public Row row { private set; get; }
    public BoardModel model { private set; get; }
    public Gtk.Overlay overlay { private set; get; }
    public Movable selected_widget { set; get; }
    public Window window { private set; get; }

    public RowController row_controller;

    public BoardController (Window window, BoardModel model) {
        this.window = window;
        this.model = model;
        this.board = new Board (this);
        this.overlay = board.overlay;
        this.row_controller = new RowController (this, "Board", model.color);
        row = row_controller.row;

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

        foreach (var widget in widgets) {
            Gtk.Widget w = null;
            switch (widget.model) {
                case "TextWidget":
                    var controller = new TextController (this, widget.x, widget.y, (TextModel) widget);
                    w = controller.movable;
                    break;
                case "LabelWidget":
                    var controller = new LabelController (this, widget.x, widget.y, (LabelModel) widget);
                    w = controller.movable;
                    break;
                case "ImageWidget":
                    var controller = new ImageController (this, widget.x, widget.y, (ImageModel) widget);
                    w = controller.movable;
                    break;
            }
            overlay.add_overlay (w);
        }
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

        if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
            var selection = window.fab_selection;

            var x = (int) event.x;
            var y = (int) event.y;
            Movable widget = null;

            switch (selection.name ()) {
                case "TextWidget":
                    var controller = new TextController (this, x, y);
                    model.widgets.add (controller.model);
                    widget = controller.movable;
                    break;
                case "LabelWidget":
                    var controller = new LabelController (this, x, y);
                    model.widgets.add (controller.model);
                    widget = controller.movable;
                    break;
                case "ImageWidget":
                    var controller = new ImageController (this, x, y);
                    model.widgets.add (controller.model);
                    widget = controller.movable;
                    break;
            }

            widget.rel_pos_x = widget.margin_start = x;
            widget.rel_pos_y = widget.margin_top = y;

            overlay.add_overlay (widget);

            switch (selection.name ()) {
                case "TextWidget":
                    var text_widget = widget as TextWidget;
                    text_widget.textview.grab_focus ();
                    break;
                case "LabelWidget":
                    var label_widget = widget as LabelWidget;
                    label_widget.textview.grab_focus ();
                    break;
            }
        }
        
        return true;
    }

    private void on_activate () {
        window.board_header.title = board.title;
        if (window.deck.get_visible_child () != board) {
            window.deck.set_visible_child (board);
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

}
