public class MenuItemColor : Gtk.MenuItem {
    public signal void color_changed (string color);
    private Gee.ArrayList<ColorButton> color_buttons;
    private const int COLORBOX_SPACING = 3;

    construct {
        var color_button_remove = new ColorButton ("none");
        color_buttons = new Gee.ArrayList<ColorButton> ();
        color_buttons.add (new ColorButton ("red"));
        color_buttons.add (new ColorButton ("orange"));
        color_buttons.add (new ColorButton ("yellow"));
        color_buttons.add (new ColorButton ("green"));
        color_buttons.add (new ColorButton ("mint"));
        color_buttons.add (new ColorButton ("blue"));
        color_buttons.add (new ColorButton ("purple"));
        color_buttons.add (new ColorButton ("pink"));
        color_buttons.add (new ColorButton ("brown"));
        color_buttons.add (new ColorButton ("slate"));

        var colorbox = new Gtk.Grid () {
            column_spacing = COLORBOX_SPACING,
            margin_start = 3,
            halign = Gtk.Align.START
        };

        colorbox.add (color_button_remove);

        for (int i = 0; i < color_buttons.size; i++) {
            colorbox.add (color_buttons[i]);
        }

        add (colorbox);

        try {
            string css = ".nohover { background: none; }";

            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_data (css, -1);

            var style_context = get_style_context ();
            style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            style_context.add_class ("nohover");
        } catch (GLib.Error e) {
            warning ("Failed to parse css style : %s", e.message);
        }

        show_all ();

        button_press_event.connect (button_pressed_cb);

    }

    private void clear_checks () {
        color_buttons.foreach ((b) => { b.active = false; return true;});
    }

    public void check_color (int color) {
        if (color == 0 || color > color_buttons.size) {
            return;
        }
        color_buttons[color - 1].active = true;
    }

    private bool button_pressed_cb (Gtk.Widget widget, Gdk.EventButton event) {

        var color_button_width = color_buttons[0].get_allocated_width ();

        int y0 = (get_allocated_height () - color_button_width) / 2;
        int x0 = COLORBOX_SPACING + color_button_width;

        if (event.y < y0 || event.y > y0 + color_button_width) {
            return true;
        }

        if (Gtk.StateFlags.DIR_RTL in get_style_context ().get_state ()) {
            var width = get_allocated_width ();
            int x = width - 27;
            for (int i = 0; i < 10; i++) {
                if (event.x <= x && event.x >= x - color_button_width) {
                    color_changed (Colors.from_index (i));
                    clear_checks ();
                    check_color (i);
                    break;
                }

                x -= x0;
            }
        } else {
            int x = 27;
            for (int i = 0; i <= 10; i++) {
                if (event.x >= x && event.x <= x + color_button_width) {
                    color_changed (Colors.from_index (i));
                    clear_checks ();
                    check_color (i);
                    break;
                }

                x += x0;
            }
        }

        return true;
    }

}
