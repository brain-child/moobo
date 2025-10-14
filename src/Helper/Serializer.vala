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
            BaseModel base_model = widget;
            var widget_type = WidgetFactory.get_widget_type_from_string (widget.model);
            
            switch (widget_type) {
                case WidgetFactory.WidgetType.TEXT:
                    var text_model = base_model as TextModel;
                    text_model.content = text_model.content.strip ();
                    if (text_model.content == "") { continue; }
                    break;
                case WidgetFactory.WidgetType.LABEL:
                    var label_model = base_model as LabelModel;
                    label_model.content = label_model.content.strip ();
                    if (label_model.content == "") { continue; }
                    break;
                case WidgetFactory.WidgetType.IMAGE:
                    var image_model = base_model as ImageModel;
                    if (image_model.base64_data == "" && image_model.path == "") { continue; }
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
            // Ensure directory exists
            var dir = File.new_for_path (app_dir);
            if (!dir.query_exists ()) {
                dir.make_directory_with_parents ();
            }
            
            // Create backup of existing file
            var file = File.new_for_path (path);
            if (file.query_exists ()) {
                var backup_path = "%s.backup".printf (path);
                var backup_file = File.new_for_path (backup_path);
                file.copy (backup_file, FileCopyFlags.OVERWRITE);
            }
            
            // Write to temporary file first
            var temp_path = "%s.tmp".printf (path);
            var temp_file = File.new_for_path (temp_path);
            generator.to_file (temp_path);
            
            // Move temp file to final location
            temp_file.move (file, FileCopyFlags.OVERWRITE);
            
        } catch (Error e) {
            warning ("Failed to save boards: %s", e.message);
            
            // Try to restore backup if it exists
            var backup_path = "%s.backup".printf (path);
            var backup_file = File.new_for_path (backup_path);
            if (backup_file.query_exists ()) {
                try {
                    backup_file.copy (File.new_for_path (path), FileCopyFlags.OVERWRITE);
                    info ("Restored backup file");
                } catch (Error restore_error) {
                    warning ("Failed to restore backup: %s", restore_error.message);
                }
            }
        }
    }

}
