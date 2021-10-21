public class LabelModel : BaseModel {

    // public signal void changed_event (int x, int y, int font_size, string content, string color);

    public int font_size { set; get; }
    public string content { set; get; }
    public string color { set; get; }

    public LabelModel () {
        model = "LabelWidget";
        font_size = 150;
        content = "";
        color = "";
    }

    // public void update_pos (int x, int y) {
    //     this.x = x;
    //     this.y = y;
    // }

    // public void update_content (string content) {
    //     this.content = content;
    // }

    // public void update_font_size (int font_size) {
    //     this.font_size = font_size;
    // }

    // public void changed_trigger () {
    //     changed_event (x, y, font_size, content, color);
    // }

}
