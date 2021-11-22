public class FloatingButton : Gtk.MenuButton {

    public Granite.Widgets.ModeButton mode_button { private set; get; }

    public FloatingButton () {
        mode_button = create_mode_button ();
        var popover = create_popover ();

        var button = new Gtk.Button.from_icon_name (
            "list-add-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        );
        button.get_style_context ().add_class ("white_label");
        add (button);

        get_style_context ().add_class ("fab");
        this.popover = popover;
    }

    construct {
        direction = Gtk.ArrowType.NONE;
        valign = Gtk.Align.END;
        halign = Gtk.Align.END;
        height_request = 40;
        width_request = 40;
        margin = 30;
    }

    private Granite.Widgets.ModeButton create_mode_button () {
        mode_button = new Granite.Widgets.ModeButton () {
            orientation = Gtk.Orientation.VERTICAL,
            homogeneous = false,
            margin = 5
        };
        mode_button.append_text (_("Text"));
        mode_button.append_text (_("Label"));
        mode_button.append_text (_("Image"));
        mode_button.set_active (0);
        mode_button.show_all ();
        return mode_button;
    }

    private Gtk.Popover create_popover () {
        var popover = new Gtk.Popover (null);
        popover.add (mode_button);
        return popover;
    }

}
