public class ImageController {

    public ImageWidget movable { private set; get; }
    public ImageModel model { private set; get; }

    private BoardController board_controller;
    private string app_dir = "%s/com.github.brain_child.moobo".printf (Environment.get_user_data_dir ());
    private int width;
    private int height;

    public ImageController (BoardController board_controller, int x, int y, ImageModel model = new ImageModel ()) {
        this.board_controller = board_controller;
        this.movable = new ImageWidget (this);
        this.model = model;

        if (model.path == "") {
            var placeholder = new Gtk.Image.from_icon_name ("image-x-generic", Gtk.IconSize.DIALOG) {
                valign = Gtk.Align.START,
                halign = Gtk.Align.START,
                margin_start = x,
                margin_top = y
            };
            board_controller.overlay.add_overlay (placeholder);
            placeholder.show ();
            model.path = get_file ();
            board_controller.overlay.remove (placeholder);
        }

        Gdk.Pixbuf.get_file_info (model.path, out width, out height);

        if (model.path != "") {
            movable.init (model.path);
            update_widget ();
            movable.handle_events (board_controller);
            board_controller.board.scale.value_changed.connect (on_value_changed);
        } else {
            movable.destroy ();
        }
    }

    public string get_file () {
        string file_path = "";
        var file_chooser = new Gtk.FileChooserNative (
            _("Open File"),
            board_controller.window,
            Gtk.FileChooserAction.OPEN,
            _("Open"),
            _("Cancel")
        );
        var filter = new Gtk.FileFilter ();
        filter.add_pixbuf_formats ();
        file_chooser.set_transient_for (board_controller.window);
        file_chooser.filter = filter;
        var res = file_chooser.run ();
        if (res == Gtk.ResponseType.ACCEPT) {
            var source_file = file_chooser.get_file ();
            file_path = copy_file (source_file);
        } else {
            movable.destroy ();
        }
        return file_path;
    }

    private void update_widget () {
        movable.rel_pos_x = movable.margin_start = model.x;
        movable.rel_pos_y = movable.margin_top = model.y;

        var scaled_width = (int) (width * model.scale_factor);
        var scaled_height = (int) (height * model.scale_factor);

        movable.pixbuf = movable.pixbuf.scale_simple (scaled_width, scaled_height, Gdk.InterpType.HYPER);
    }

    private string copy_file (File source_file) {
        var target_file_path = "%s/%d".printf (app_dir, (int) source_file.hash ());
        var target_file = File.new_for_path (target_file_path);
        var is_existing = target_file.query_exists ();
        if (is_existing == true) {
           return target_file_path;
        }
        try {
            source_file.copy (target_file, GLib.FileCopyFlags.NONE, null, null);
        } catch (Error e) {
            warning (e.message);
        }
        return target_file_path;
    }

    private void on_value_changed () {
        if (board_controller.selected_widget == movable) {
            var scale_val = board_controller.board.scale.get_value ();
            var new_width = (int) (scale_val * width);
            var new_height = (int) (scale_val * height);

            try {
                movable.image.pixbuf = new Gdk.Pixbuf.from_file_at_size (model.path, new_width, new_height);
            } catch (Error e) {
                warning (e.message);
            }
            model.scale_factor = scale_val;
        }
    }
}
