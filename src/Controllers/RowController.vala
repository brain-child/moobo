public class RowController {

    public Row row { private set; get; }
    private BoardController board_controller;
    private string name;
    private string color;

    public RowController (BoardController board_controller, string name, string color) {
        row = new Row (board_controller, name, color);
        this.board_controller = board_controller;
        this.name = name;
        this.color = color;

        row.state_flags_changed.connect (on_state_flags_changed);
        row.delete_eventbox.button_press_event.connect (on_delete_button_press);
        row.grid_eventbox.button_press_event.connect (on_button_press);
        row.rename_item.activate.connect (on_activate);
        row.menu_item.color_changed.connect (on_color_changed);
    }

    private void on_color_changed (string color) {
        change_color (color);
    }

    private void on_activate () {
        rename ();
    }

    private bool on_delete_button_press () {
        show_delete_dialog ();
        return false;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.button == 3) {
            row.menu.popup_at_pointer ();
        }
        return false;
    }

    private void on_state_flags_changed () {
        var flag_string = row.get_state_flags ().to_string ();
        if (flag_string == "GTK_STATE_FLAG_PRELIGHT") {
            var b = row.grid.get_child_at (2, 0);
                row.delete_button.set_from_icon_name ("application-exit-symbolic", Gtk.IconSize.BUTTON);
            if (b == null) {
            }
        } else {
            if (flag_string != "GTK_STATE_FLAG_ACTIVE") {
                row.delete_button.set_from_icon_name ("", Gtk.IconSize.BUTTON);
            }
        }
    }

    private void change_color (string color_name) {
        var color = Colors.from_name (color_name);
        string style = """
            @define-color colorAccent %s;
            @define-color accent_color %s;
        """.printf (color, color);

        var style_provider = new Gtk.CssProvider ();
        try {
            style_provider.load_from_data (style, style.length);
        } catch (Error e) {
            warning (e.message);
        }
        unowned Gtk.StyleContext style_context = row.source_color.get_style_context ();
        style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        board_controller.model.color = color_name;
    }

    private void rename () {
        row.display_name_label.hide ();
        var textview = new Gtk.TextView () {
            wrap_mode = Gtk.WrapMode.NONE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            can_focus = true,
            hexpand = true,
        };
        textview.grab_focus ();
        var textbuffer = textview.get_buffer ();
        textbuffer.set_text (row.display_name_label.label);
        
        textview.focus_out_event.connect (() => {
            if (textbuffer.text.strip () == "") {
                textbuffer.text = "Board";
            }
            textview.hide ();
            board_controller.model.title = textbuffer.text;
            row.display_name_label.label = textbuffer.text;
            row.display_name_label.show ();
            row.renamed (textbuffer.text);
            return false;
        });
        
        textview.key_press_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Return) {
                board_controller.board.grab_focus ();
                return true;
            }
            return false;
        });

        Gtk.TextIter start_iter, end_iter;
        textview.buffer.get_start_iter (out start_iter);
        textview.buffer.get_end_iter (out end_iter);
        textview.buffer.select_range (start_iter, end_iter);

        textview.get_style_context ().add_class ("editable-label");
        row.grid.attach (textview, 1, 0);
        textview.show ();
        textview.grab_focus ();
    }

    private void show_delete_dialog () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Do you want to delete \"%s\"?").printf (row.display_name_label.label),
            _("The content of this board will be deleted completely and cannot be restored."),
            "dialog-warning",
            Gtk.ButtonsType.CANCEL
        );
        message_dialog.transient_for = row.get_toplevel () as Gtk.Window;

        var suggested_button = new Gtk.Button.with_label (_("Delete"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        message_dialog.show_all ();
        row.activate ();
        board_controller.window.sensitive = false;
        message_dialog.response.connect ((response_id) => {
           if (response_id == Gtk.ResponseType.ACCEPT) {
               row.delete_row (row.get_index ());
               if (board_controller.window.listbox.get_children ().length () == 1) {
                   board_controller.window.create_new_board ();
               }
               board_controller.board.destroy ();
               row.destroy ();
           } else {
               board_controller.window.sensitive = true;
           }
           message_dialog.close ();
        });
    }

}
