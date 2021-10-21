namespace DemoBoard {

    private const string text_a = _("Widget selection");
    private const string text_b = _("Double click anywhere to add a widget");
    private const string text_c = _("Change font size: ctrl +/-\nsave and close app: ctrl q/w");
    private const string text_d = _("Right click on widget for\ncontext menu.\n(when 'grabbing cursor' appears)");
    private const string text_e = _("Create new board");
    private const string text_f = _("Right click to edit");

    public string get_demo_board () {
        return """
            [
              {
                "title" : "Demo",
                "color" : "mint",
                "active" : true,
                "widgets" : [
                  {
                    "model" : "TextWidget",
                    "x" : 915,
                    "y" : 695,
                    "font-size" : 150,
                    "content" : "%s -->"
                  },
                  {
                    "model" : "LabelWidget",
                    "x" : 149,
                    "y" : 136,
                    "font-size" : 150,
                    "content" : "%s",
                    "color" : "rgb(32,74,135)"
                  },
                  {
                    "model" : "LabelWidget",
                    "x" : 645,
                    "y" : 261,
                    "font-size" : 150,
                    "content" : "%s",
                    "color" : "rgb(255,255,255)"
                  },
                  {
                    "model" : "TextWidget",
                    "x" : 407,
                    "y" : 441,
                    "font-size" : 170,
                    "content" : "%s"
                  },
                  {
                    "model" : "TextWidget",
                    "x" : 1,
                    "y" : 728,
                    "font-size" : 120,
                    "content" : "<-- %s"
                  },
                  {
                    "model" : "TextWidget",
                    "x" : 1,
                    "y" : 25,
                    "font-size" : 130,
                    "content" : "<-- %s"
                  },
                  {
                    "model" : "TextWidget",
                    "x" : 474,
                    "y" : 117,
                    "font-size" : 210,
                    "content" : "🙃️"
                  }
                ]
              }
            ]
        """.printf (text_a, text_b, text_c, text_d, text_e, text_f);
    }
}
