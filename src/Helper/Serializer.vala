namespace Serializer {

    public void to_json (GLib.List<unowned Gtk.Widget> widgets) {
        var node_array = new Json.Array ();

        foreach (var widget in widgets) {
            var board = (Board) widget;
            var node = serilize_board (board.controller.model);
            node_array.add_element (node);
        }

        var object = new Json.Object ();
        object.set_array_member ("boards", node_array);
        write_file (object.get_member ("boards"));
    }

    private Json.Node serilize_board (BoardModel model) {
        var widgets = model.widgets;
        var title = model.title;
        var color = model.color;
        var is_active = model.is_active;

        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("title");
        builder.add_string_value (title);
        builder.set_member_name ("color");
        builder.add_string_value (color);
        builder.set_member_name ("active");
        builder.add_boolean_value (is_active);

        builder.set_member_name ("widgets");
        builder.begin_array ();
        foreach (var widget in widgets) {
            BaseModel base_model = null;
            switch (widget.model) {
                case "TextWidget":
                    base_model = widget as TextModel;
                    var text_model = base_model as TextModel;
                    text_model.content = text_model.content.strip ();
                    if (text_model.content == "") { continue; }
                    break;
                case "LabelWidget":
                    base_model = widget as LabelModel;
                    var label_model = base_model as LabelModel;
                    label_model.content = label_model.content.strip ();
                    if (label_model.content == "") { continue; }
                    break;
                case "ImageWidget":
                    base_model = widget as ImageModel;
                    var image_model = base_model as ImageModel;
                    if (image_model.path == "") { continue; }
                    break;
            }
            var r = Json.gobject_serialize (base_model);
            builder.add_value (r);
        }
        builder.end_array ();
        builder.end_object ();

        return builder.get_root ();
    }

    private void write_file (Json.Node node) {
        var generator = new Json.Generator () {
            pretty = true,
            root = node
        };

        var app_dir = Environment.get_user_data_dir () + Const.APP_PATH;
        var path = "%s/%s.json".printf (app_dir, "boards");
        try {
            generator.to_file (path);
        } catch (Error e) {
            warning (e.message);
        }
    }

}
