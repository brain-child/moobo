public class ImageModel : BaseModel {

    public string path { set; get; }
    public double scale_factor { set; get; }

    public ImageModel () {
        model = "ImageWidget";
        path = "";
        scale_factor = 1.0;
    }

}
