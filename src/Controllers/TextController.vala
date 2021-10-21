public class TextController {

    public TextWidget movable { private set; get; }
    public TextModel model { private set; get; }
    private BoardController board_controller;
    private Gtk.Overlay overlay;

    public TextController (BoardController board_controller, int x, int y, TextModel model = new TextModel ()) {
        this.board_controller = board_controller;
        this.overlay = board_controller.overlay;
        this.movable = new TextWidget (this);
        this.model = model;
        model.x = x;
        model.y = y;

        movable.textview.key_press_event.connect (on_key_press);
        movable.textview.key_release_event.connect (on_key_release);

        update_widget ();

        set_font_size (movable.font_size);
        movable.handle_events (board_controller);
    }

    private bool on_key_press (Gdk.EventKey event) {
       var key_name = event.state.to_string ();

       // if (event.state == Gdk.ModifierType.CONTROL_MASK && event.str == "+") {
       if (key_name == "GDK_CONTROL_MASK" && event.str == "+") {
           movable.font_size += 10;
           set_font_size (movable.font_size);
       }
       // if (event.state == Gdk.ModifierType.CONTROL_MASK && event.str == "-") {
       if (key_name == "GDK_CONTROL_MASK" && event.str == "-") {
           movable.font_size -= 10;
           set_font_size (movable.font_size);
       }
       return false;
    }

    public bool on_key_release () {
        model.content = movable.buffer.text;
        return false;
    }

     private void update_widget () {
        movable.rel_pos_x = movable.margin_start = model.x;
        movable.rel_pos_y = movable.margin_top = model.y;
        movable.buffer.text = model.content;
        movable.font_size = model.font_size;
     }

     private void set_font_size (int font_size) {
        model.font_size = font_size;
        string style = "textview {
                font-size: %d%;
            }".printf(font_size);

        var style_provider = new Gtk.CssProvider ();
        try {
            style_provider.load_from_data (style, style.length);
            var style_context = movable.textview.get_style_context ();
            style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
     }

}
