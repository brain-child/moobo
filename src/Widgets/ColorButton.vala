private class ColorButton : Gtk.CheckButton {
    private static Gtk.CssProvider css_provider;
    public string color_name { get; construct; }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("com/github/brain-child/moobo/styles/ColorButton.css");
    }

    public ColorButton (string color_name) {
        Object (color_name: color_name);
    }

    construct {
        var style_context = get_style_context ();
        style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        style_context.add_class (color_name);
    }
}
