public class ImageWidget : Movable {

    public ImageController controller { private set; get; }
    public Gtk.Image image { set; get; }
    public Gdk.Pixbuf pixbuf { set; get; }

    public ImageWidget (ImageController controller) {
        this.controller = controller;
        image = new Gtk.Image ();
    }

    public void init (string path) {
        var max_x = Const.IMG_MAX_WIDTH;
        var max_y = Const.IMG_MAX_HEIGHT;

        int width;
        int height;
        Gdk.Pixbuf.get_file_info (path, out width, out height);
        var scale_factor = controller.model.scale_factor;

        if (width * scale_factor > max_x) {
            scale_factor = ((double) max_x / width);
        }
        if (height * scale_factor > max_y) {
            scale_factor = ((double) max_y / height);
        }
        width = (int) (scale_factor * width);
        height = (int) (scale_factor * height);

        try {
            pixbuf = new Gdk.Pixbuf.from_file_at_size (path, width, height);
        } catch (Error e) {
            warning (e.message);
        }
        image = new Gtk.Image.from_pixbuf (pixbuf);

        add (image);
    }

}
