public class LabelWidget : Movable {

    public int font_size { set; get; }
    public Gtk.TextBuffer buffer { private set; get; }
    public Gtk.TextView textview { private set; get; }
    public LabelController controller { private set; get; }
    public Gtk.Grid card { private set; get; }

    public LabelWidget (LabelController controller) {
        this.controller = controller;
        init ();
    }

    private void init () {
        textview = new Gtk.TextView () {
            wrap_mode = Gtk.WrapMode.NONE,
            vexpand = true,
            margin = 10,
        };
        buffer = textview.get_buffer ();

        card = new Gtk.Grid () {
            margin = 5
        };
        var card_context = card.get_style_context ();
        card_context.add_class (Granite.STYLE_CLASS_CARD);
        card_context.add_class (Granite.STYLE_CLASS_ROUNDED);

        card.add (textview);
        add (card);

        show_all ();
    }

}
