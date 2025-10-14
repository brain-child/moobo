public abstract class BaseModel : GLib.Object {

    public string model { set; get; }
    public int x { set; get; }
    public int y { set; get; }
    public int z_index { set; get; default = 0; }

}
