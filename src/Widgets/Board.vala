public class Board : Gtk.EventBox {

    public string title { set; get; default = "Board"; }
    public Gtk.Overlay overlay { private set; get; }
    public BoardController controller { private set; get; }
    public Gtk.Revealer revealer { private set; get; }
    public Gtk.Scale scale { set; get; }

    public Board (BoardController controller) {
        this.controller = controller;
        can_focus = true;

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.1, 2, 0.1) {
            value_pos = Gtk.PositionType.BOTTOM,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            draw_value = false,
        };
        scale.add_mark (1, Gtk.PositionType.BOTTOM, null);
        scale.set_value (1);
        scale.set_size_request (300, -1);

        revealer = new Gtk.Revealer () {
            valign = Gtk.Align.END,
            margin = 30,
        };
        revealer.add (scale);

        overlay = new Gtk.Overlay ();
        overlay.add (draw_grid ());
        overlay.add_overlay (revealer);

        add (overlay);
        show_all ();
    }

    private Gtk.DrawingArea draw_grid () {
        var drawing_area = new Gtk.DrawingArea ();
        drawing_area.draw.connect ((widget, context) => {
            var width = get_allocated_width ();
            var height = get_allocated_height ();
            context.set_source_rgb(0.7, 0.7, 0.7);
            context.fill();
            var spacing = 20;
            var y = 0;
            var x = spacing;
            context.set_line_width (2.0);
            while (x <= width ) {
                while (y <= height) {
                    context.move_to(x, y);
                    context.line_to(x, y + 2);
                    y += spacing;
                }
                y = 0;
                x += spacing;
            }
            context.stroke ();
            return true;
        });


        return drawing_area;
    }

}
