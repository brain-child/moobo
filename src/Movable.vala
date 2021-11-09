public abstract class Movable : Gtk.EventBox {

    public int rel_pos_x { set; get; }
    public int rel_pos_y { set; get; }
    public int overlay_width { set; get; }
    public int overlay_height { set; get; }

    private BoardController controller;
    private Gee.ArrayList<BaseModel> widgets;
    private Gtk.Revealer revealer;
    private Gtk.Scale scale;
    private Gtk.Overlay overlay;
    private int abs_pos_x;
    private int abs_pos_y;

    public void handle_events (BoardController controller) {
        this.controller = controller;
        this.widgets = controller.model.widgets;
        this.revealer = controller.board.revealer;
        this.scale = controller.board.scale;
        this.overlay = controller.overlay;

        valign = Gtk.Align.START;
        halign = Gtk.Align.START;

        button_press_event.connect (on_button_press);
        button_release_event.connect (on_button_release);
        enter_notify_event.connect (on_enter_notify);

        show_all ();
    }

    private bool on_button_press (Gtk.Widget widget, Gdk.EventButton event) {
        can_focus = false;

        if (widget is TextWidget) {
            var text_widget = widget as TextWidget;
            var model = text_widget.controller.model;
            widgets.remove (model);
            widgets.add (model);
        }
        else if (widget is LabelWidget) {
            var label_widget = widget as LabelWidget;
            var model = label_widget.controller.model;
            widgets.remove (model);
            widgets.add (model);
        }
        else if (widget is ImageWidget) {
            can_focus = true;
            grab_focus ();
            var image_widget = widget as ImageWidget;
            image_widget.grab_focus ();
            var model = image_widget.controller.model;
            widgets.remove (model);
            widgets.add (model);
        }

        if (event.button == 1) {
            motion_notify_event.connect (on_motion_notify);
            var display = get_display ();
            var cursor = new Gdk.Cursor.from_name (display, "grabbing");
            get_window ().set_cursor (cursor);
        }

        if (event.button == 3) {
            Gtk.Menu menu = new Gtk.Menu ();
            Gtk.MenuItem color = new Gtk.MenuItem.with_label (_("Change Color")) {
                sensitive = false
            };
            color.activate.connect (() => {
                var dialog = new Gtk.ColorChooserDialog (null, null);
                dialog.response.connect ((id) => {
                    if (id == -5) {
                        if (widget is LabelWidget) {
                            var label_widget = (LabelWidget) widget;
                            var rgba = dialog.get_rgba ();
                            label_widget.controller.change_color (rgba);
                            label_widget.controller.model.color = rgba.to_string ();
                        }
                    }
                    dialog.close ();
                });
                dialog.run ();
            });

            var font = new Gtk.MenuItem.with_label ("Change Font") {
                sensitive = false
            };
            font.activate.connect (() => {
                var dialog = new Gtk.FontChooserDialog (null, null);
                dialog.response.connect ((id) => {
                    if (id == -5) {
                        dialog.get_font ();
                    }
                    dialog.close ();
                });
                dialog.run ();
            });

            var resize = new Gtk.MenuItem.with_label (_("Scale")) {
                sensitive = false
            };
            resize.activate.connect (() => {
                overlay.reorder_overlay (controller.board.revealer, -2);
                var image_widget = widget as ImageWidget;
                var scale_val = image_widget.controller.model.scale_factor;

                int width;
                int height;
                Gdk.Pixbuf.get_file_info (image_widget.controller.model.path, out width, out height);

                var max_x = (double) Const.IMG_MAX_WIDTH;
                var max_y = (double) Const.IMG_MAX_HEIGHT;
                var max_scale = Const.MAX_SCALE;

                max_scale = max_x / width;
                var tmp = max_y / height;
                if (tmp < max_scale) { max_scale = tmp; }
                scale.set_range (0.1, max_scale);

                scale.set_value (scale_val);
                revealer.reveal_child = true;
            });

            Gtk.MenuItem delete_item = new Gtk.MenuItem.with_label (_("Delete"));
            delete_item.activate.connect (() => {
                if (widget is TextWidget) {
                    var text_widget = widget as TextWidget;
                    widgets.remove (text_widget.controller.model);
                }
                else if (widget is LabelWidget) {
                    var label_widget = widget as LabelWidget;
                    widgets.remove (label_widget.controller.model);
                }
                else if (widget is ImageWidget) {
                    var image_widget = widget as ImageWidget;
                    widgets.remove (image_widget.controller.model);
                }
                this.destroy ();
            });
            menu.attach_to_widget (widget, null);
            menu.add (color);
            // menu.add (font);
            menu.add (resize);
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (delete_item);
            menu.show_all ();
            menu.popup_at_pointer (event);

            if (widget is LabelWidget) {
                color.sensitive = true;
                font.sensitive = true;
            }
            if (widget is TextWidget) {
                font.sensitive = true;
            }
            if (widget is ImageWidget) {
                resize.sensitive = true;
            }
        }

        widget.grab_focus ();

        revealer.reveal_child = false;

        abs_pos_x = (int) event.x_root;
        abs_pos_y = (int) event.y_root;

        overlay.reorder_overlay (widget, -2);
        controller.selected_widget = this;
        return true;
    }

    private bool on_button_release (Gtk.Widget widget, Gdk.EventButton event) {
        motion_notify_event.disconnect (on_motion_notify);

        var display = get_display ();
        var cursor = new Gdk.Cursor.from_name (display, "grab");
        get_window ().set_cursor (cursor);

        widget.set_opacity (1);

        double dx = event.x_root - abs_pos_x;
        double dy = event.y_root - abs_pos_y;

        double x = rel_pos_x + dx;
        double y = rel_pos_y + dy;

        int dw = overlay.get_allocated_width () - get_allocated_width ();
        int dh = overlay.get_allocated_height () - get_allocated_height ();

        if (x > dw) { x = dw; }
        if (y > dh) { y = dh; }

        if (x < 1) { x = 1; }
        if (y < 1) { y = 1; }

        rel_pos_x = (int) x;
        rel_pos_y = (int) y;

        var type = widget.name;
        switch (type) {
            case "TextWidget":
                var text_widget = widget as TextWidget;
                text_widget.controller.model.x = rel_pos_x;
                text_widget.controller.model.y = rel_pos_y;
                break;
            case "LabelWidget":
                var label_widget = widget as LabelWidget;
                label_widget.controller.model.x = rel_pos_x;
                label_widget.controller.model.y = rel_pos_y;
                break;
            case "ImageWidget":
                var image_widget = widget as ImageWidget;
                image_widget.controller.model.x = rel_pos_x;
                image_widget.controller.model.y = rel_pos_y;
                break;
        }

        return false;
    }

    private bool on_motion_notify (Gtk.Widget widget, Gdk.EventMotion event) {
        widget.set_opacity (0.7);

        var display = get_display ();
        var cursor = new Gdk.Cursor.from_name (display, "grabbing");
        get_window ().set_cursor (cursor);

        var dx = event.x_root - abs_pos_x;
        var dy = event.y_root - abs_pos_y;

        int x = (int) (rel_pos_x + dx);
        int y = (int) (rel_pos_y + dy);

        int dw = overlay.get_allocated_width () - get_allocated_width ();
        int dh = overlay.get_allocated_height () - get_allocated_height ();

        if (x > dw) { x = dw; }
        if (y > dh) { y = dh; }

        if (x < 1) { x = 1; }
        if (y < 1) { y = 1; }

        margin_start = x;
        margin_top = y;

        return true;
    }

    private bool on_enter_notify () {
        var display = get_display ();
        var cursor = new Gdk.Cursor.from_name (display, "grab");
        get_window ().set_cursor (cursor);
        return true;
    }

}
