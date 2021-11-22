namespace Deserializer {

    public Gee.ArrayList<BoardModel> from_json () {
        var app_dir = Environment.get_user_data_dir () + Const.APP_PATH;
        var path = "%s/%s".printf (app_dir, "boards.json");

        var boards_list = new Gee.ArrayList<BoardModel> ();

        try {
            var parser = new Json.Parser ();
            parser.load_from_file (path);
            var root = parser.get_root ();

            parse_board (root, boards_list);
        } catch (Error e) {
            info (e.message);

            File dir = File.new_for_path (app_dir);

            if (!dir.query_exists ()) {
                try {
                    dir.make_directory ();
                    // var parser = new Json.Parser ();
                    // parser.load_from_data (DemoBoard.get_demo_board ());
                    // var root = parser.get_root ();
                    // parse_board (root, boards_list);
                } catch (Error e) {
                    warning (e.message);
                }
            }

        }
        return boards_list;
    }

    private void parse_board (Json.Node node, Gee.ArrayList<BoardModel> boards_list) {
        var array = node.get_array ();
        array.foreach_element ((array, index, node) => {
            var board_model = new BoardModel ();
            var object = node.get_object ();
            var widgets = object.get_array_member ("widgets");
            foreach (var item in widgets.get_elements ()) {
                var n = item.get_object ();
                board_model.widgets.add (parse_widgets (n));
            }
            board_model.title = object.get_string_member ("title");
            board_model.color = object.get_string_member ("color");
            board_model.is_active = object.get_boolean_member ("active");

            boards_list.add (board_model);
        });
    }

    private BaseModel parse_widgets (Json.Object node) {
        BaseModel model = null;
        var name = node.get_string_member ("model");
        switch (name) {
            case "TextWidget":
                model = new TextModel () {
                    x = (int) node.get_int_member ("x"),
                    y = (int) node.get_int_member ("y"),
                    font_size = (int) node.get_int_member ("font-size"),
                    content = node.get_string_member ("content")
                };
                break;
            case "LabelWidget":
                model = new LabelModel () {
                    x = (int) node.get_int_member ("x"),
                    y = (int) node.get_int_member ("y"),
                    font_size = (int) node.get_int_member ("font-size"),
                    content = node.get_string_member ("content"),
                    color = node.get_string_member ("color")
                };
                break;
            case "ImageWidget":
                model = new ImageModel () {
                    x = (int) node.get_int_member ("x"),
                    y = (int) node.get_int_member ("y"),
                    path = node.get_string_member ("path"),
                    scale_factor = node.get_double_member ("scale-factor"),
                };
                break;
        }
        return model;
    }

}
