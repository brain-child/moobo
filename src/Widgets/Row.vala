public class Row : Gtk.ListBoxRow {

    public signal void delete_row (int index);
    public signal void renamed (string title);

    public Gtk.Grid source_color { private set; get; }
    public string label { set; get; default = _("Board"); }
    public Gtk.Label display_name_label { set; get; }
    public Gtk.EventBox delete_eventbox { private set; get; }
    public Gtk.Grid grid { private set; get; }
    public Gtk.EventBox grid_eventbox { private set; get; }
    public Gtk.Image delete_button { private set; get; }
    public Gtk.Menu menu { private set; get; }
    public Gtk.MenuItem rename_item { private set; get; }
    public MenuItemColor menu_item { private set; get; }

    private BoardController board_controller;
    private Gtk.CssProvider listrow_provider;
    private string color;

    public Row (BoardController board_controller, string name, string color) {
        this.board_controller = board_controller;
        label = name;
        this.display_name_label.label = label;
        this.display_name_label.label = label;
        this.color = color;
        create_menu ();
    }

    construct {
        listrow_provider = new Gtk.CssProvider ();
        listrow_provider.load_from_resource ("com/github/brain_child/moobo/styles/SourceRow.css");

        source_color = new Gtk.Grid () {
            halign = Gtk.Align.START,
        };

        var source_color_context = source_color.get_style_context ();
        source_color_context.add_class ("source-color");
        source_color_context.add_provider (listrow_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        display_name_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            hexpand = true,
        };

        delete_button = new Gtk.Image.from_icon_name ("", Gtk.IconSize.BUTTON) {
            halign = Gtk.Align.END,
            margin = 0
        };

        delete_eventbox = new Gtk.EventBox () {
            halign = Gtk.Align.END
        };
        delete_eventbox.add (delete_button);

        grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 12,
            margin_end = 6
        };
        grid.attach (source_color, 0, 0);
        grid.attach (display_name_label, 1, 0);
        grid.attach (delete_eventbox, 2, 0);

        grid_eventbox = new Gtk.EventBox ();
        grid_eventbox.add (grid);

        add (grid_eventbox);
        show_all ();
    }

    private void create_menu () {

        rename_item = new Gtk.MenuItem ();
        rename_item.add (new Granite.AccelLabel (
            _("Rename"),
            "F2"
        ));

        menu_item = new MenuItemColor ();
        menu_item.check_color (Colors.from_name_to_index (color));

        menu = new Gtk.Menu ();
        menu.add (rename_item);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (menu_item);
        menu.show_all ();
    }

}
