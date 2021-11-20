public class BoardModel : GLib.Object {

    public signal void changed_event (Gee.ArrayList widgets, string color, string title);

    public Gee.ArrayList<BaseModel> widgets { set; get; }
    public string color { set; get; }
    public string title { set; get; }
    public bool is_active { set; get; }

    public BoardModel () {
        widgets = new Gee.ArrayList<BaseModel> ();
        color = "transparent";
        title = _("Board");
        is_active = false;
    }

    public void changed_trigger () {
        changed_event (widgets, color, title);
    }
}
