namespace Deserializer {

    public Gee.ArrayList<BoardModel> from_json () {
        var app_dir = Environment.get_user_data_dir () + Const.APP_PATH;
        var path = "%s/%s".printf (app_dir, "boards.json");

        var boards_list = new Gee.ArrayList<BoardModel> ();

        try {
            // Check if file exists
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                info ("Boards file does not exist, creating new board");
                create_default_board (boards_list);
                return boards_list;
            }

            // Validate file is readable
            var file_info = file.query_info ("access::can-read", FileQueryInfoFlags.NONE);
            if (!file_info.get_attribute_boolean ("access::can-read")) {
                warning ("Cannot read boards file: %s", path);
                create_default_board (boards_list);
                return boards_list;
            }

            var parser = new Json.Parser ();
            parser.load_from_file (path);
            var root = parser.get_root ();

            if (root == null) {
                warning ("JSON file is empty or invalid");
                create_default_board (boards_list);
                return boards_list;
            }

            parse_board (root, boards_list);
            
        } catch (Error e) {
            warning ("Failed to load boards: %s", e.message);
            
            var settings = new GLib.Settings (Const.APP_ID);
            var first_time_running = settings.get_boolean ("first-run");

            if (first_time_running) {
                try {
                    File dir = File.new_for_path (app_dir);
                    if (!dir.query_exists ()) {
                        dir.make_directory_with_parents ();
                    }
                } catch (Error dir_error) {
                    warning ("Failed to create app directory: %s", dir_error.message);
                }
                settings.set_boolean ("first-run", false);
            }
            
            create_default_board (boards_list);
        }
        return boards_list;
    }
    
    private void create_default_board (Gee.ArrayList<BoardModel> boards_list) {
        var default_board = new BoardModel ();
        default_board.title = _("My Board");
        default_board.color = "#ffffff";
        default_board.is_active = true;
        boards_list.add (default_board);
    }

    private void parse_board (Json.Node node, Gee.ArrayList<BoardModel> boards_list) {
        if (node.get_node_type () != Json.NodeType.ARRAY) {
            warning ("Expected JSON array for boards, got %s", node.get_node_type ().to_string ());
            return;
        }
        
        var array = node.get_array ();
        array.foreach_element ((array, index, node) => {
            try {
                if (node.get_node_type () != Json.NodeType.OBJECT) {
                    warning ("Board at index %u is not an object, skipping", index);
                    return;
                }
                
                var board_model = new BoardModel ();
                var object = node.get_object ();
                
                // Parse title with fallback
                if (object.has_member ("title")) {
                    board_model.title = object.get_string_member ("title");
                } else {
                    board_model.title = _("Untitled Board");
                }
                
                // Parse color with fallback
                if (object.has_member ("color")) {
                    board_model.color = object.get_string_member ("color");
                } else {
                    board_model.color = "#ffffff";
                }
                
                // Parse active status with fallback
                if (object.has_member ("active")) {
                    board_model.is_active = object.get_boolean_member ("active");
                } else {
                    board_model.is_active = false;
                }
                
                // Parse widgets with validation
                if (object.has_member ("widgets")) {
                    var widgets_node = object.get_member ("widgets");
                    if (widgets_node.get_node_type () == Json.NodeType.ARRAY) {
                        var widgets = widgets_node.get_array ();
                        foreach (var item in widgets.get_elements ()) {
                            if (item.get_node_type () == Json.NodeType.OBJECT) {
                                var widget_model = parse_widgets (item.get_object ());
                                if (widget_model != null) {
                                    board_model.widgets.add (widget_model);
                                }
                            } else {
                                warning ("Widget is not an object, skipping");
                            }
                        }
                    } else {
                        warning ("Widgets member is not an array");
                    }
                }

                boards_list.add (board_model);
            } catch (Error e) {
                warning ("Failed to parse board at index %u: %s", index, e.message);
            }
        });
    }

    private BaseModel? parse_widgets (Json.Object node) {
        try {
            // Validate model type
            if (!node.has_member ("model")) {
                warning ("Widget missing 'model' field, skipping");
                return null;
            }
            
            var name = node.get_string_member ("model");
            if (name == null || name == "") {
                warning ("Widget has empty model name, skipping");
                return null;
            }
            
            var widget_type = WidgetFactory.get_widget_type_from_string (name);
            
            // Get z_index with default value of 0 if not present
            int z_index = 0;
            if (node.has_member ("z-index")) {
                z_index = (int) node.get_int_member ("z-index");
            }
            
            // Get x, y coordinates with defaults
            int x = 0;
            int y = 0;
            if (node.has_member ("x")) {
                x = (int) node.get_int_member ("x");
            }
            if (node.has_member ("y")) {
                y = (int) node.get_int_member ("y");
            }
            
            BaseModel model = null;
            switch (widget_type) {
                case WidgetFactory.WidgetType.TEXT:
                    int font_size = 12;
                    if (node.has_member ("font-size")) {
                        font_size = (int) node.get_int_member ("font-size");
                    }
                    
                    string content = "";
                    if (node.has_member ("content")) {
                        content = node.get_string_member ("content");
                    }
                    
                    model = new TextModel () {
                        x = x,
                        y = y,
                        z_index = z_index,
                        font_size = font_size,
                        content = content
                    };
                    break;
                    
                case WidgetFactory.WidgetType.LABEL:
                    int font_size = 12;
                    if (node.has_member ("font-size")) {
                        font_size = (int) node.get_int_member ("font-size");
                    }
                    
                    string content = "";
                    if (node.has_member ("content")) {
                        content = node.get_string_member ("content");
                    }
                    
                    string color = "#000000";
                    if (node.has_member ("color")) {
                        color = node.get_string_member ("color");
                    }
                    
                    model = new LabelModel () {
                        x = x,
                        y = y,
                        z_index = z_index,
                        font_size = font_size,
                        content = content,
                        color = color
                    };
                    break;
                    
                case WidgetFactory.WidgetType.IMAGE:
                    string path = "";
                    if (node.has_member ("path")) {
                        path = node.get_string_member ("path");
                    }
                    
                    string base64_data = "";
                    if (node.has_member ("base64_data")) {
                        base64_data = node.get_string_member ("base64_data");
                    }
                    
                    double scale_factor = 1.0;
                    if (node.has_member ("scale-factor")) {
                        scale_factor = node.get_double_member ("scale-factor");
                    }
                    
                    // Validate image data exists (either base64 or file path)
                    if (base64_data == "" && path == "") {
                        debug ("Image widget has no data, skipping");
                        return null;
                    }
                    
                    // For backward compatibility, validate file path if no base64 data
                    if (base64_data == "" && path != "" && !ErrorHandler.validate_file_path (path)) {
                        debug ("Image file not found: %s, skipping widget", path);
                        return null;
                    }
                    
                    model = new ImageModel () {
                        x = x,
                        y = y,
                        z_index = z_index,
                        path = path,
                        base64_data = base64_data,
                        scale_factor = scale_factor
                    };
                    break;
                    
                default:
                    warning ("Unknown widget type: %s, skipping", name);
                    return null;
            }
            return model;
        } catch (Error e) {
            warning ("Failed to parse widget: %s", e.message);
            return null;
        }
    }

}
