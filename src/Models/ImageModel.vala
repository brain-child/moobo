public class ImageModel : BaseModel {

    public string path { set; get; }
    public string base64_data { set; get; }
    public double scale_factor { set; get; }

    public ImageModel () {
        model = "ImageWidget";
        path = "";
        base64_data = "";
        scale_factor = 1.0;
    }

}
