public class TextWidget : Movable {

    public int font_size { set; get; }
    public Gtk.TextBuffer buffer { private set; get; }
    public Gtk.TextView textview { private set; get; }
    public TextController controller { private set; get; }

    public TextWidget (TextController controller) {
        this.controller = controller;
        init ();
    }

    private void init () {
        textview = new Gtk.TextView () {
            wrap_mode = Gtk.WrapMode.NONE,
            vexpand = true,
            margin = 10
        };

        var style_context = textview.get_style_context ();
        style_context.add_class ("transparent");
        style_context.add_class ("font-size");

        buffer = textview.get_buffer ();

        add (textview);
        show_all ();
    }

}
