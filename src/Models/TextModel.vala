public class TextModel : BaseModel {

    public int font_size { set; get; }
    public string content { set; get; }

    public TextModel () {
        model = "TextWidget";
        font_size = 150;
        content = "";
    }

}
