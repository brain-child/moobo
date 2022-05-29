public class LabelModel : BaseModel {

    public int font_size { set; get; }
    public string content { set; get; }
    public string color { set; get; }

    public LabelModel () {
        model = "LabelWidget";
        font_size = 150;
        content = "";
        color = "";
    }

}
