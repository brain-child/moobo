namespace DemoBoard {

    private const string TITLE = _("Demo");
    private const string TEXT_A = _("Widget selection");
    private const string TEXT_B = _("Double click anywhere to add a widget");
    private const string TEXT_C = _("Change font size: ctrl +/-\nsave and close app: ctrl q/w");
    private const string TEXT_D = _("Right click on widget for\ncontext menu.\n(when 'grabbing cursor' appears)");
    private const string TEXT_E = _("Create new board");
    private const string TEXT_F = _("Right click to edit");

    private const string TEXT_G = _("HELLAS");

    public string get_demo_board () {
        return """
            [
              {
                "title" : "%s",
                "color" : "mint",
                "active" : true,
                "widgets" : [
                  {
                    "model" : "LabelWidget",
                    "x" : 1,
                    "y" : 1,
                    "font-size" : 150,
                    "content" : "%s",
                    "color" : "rgb(32,74,135)"
                  }
                ]
              }
            ]
        """.printf (TITLE, TEXT_G);
    }

    // public string get_demo_board () {
    //     return """
    //         [
    //           {
    //             "title" : "%s",
    //             "color" : "mint",
    //             "active" : true,
    //             "widgets" : [
    //               {
    //                 "model" : "TextWidget",
    //                 "x" : 915,
    //                 "y" : 695,
    //                 "font-size" : 150,
    //                 "content" : "%s -->"
    //               },
    //               {
    //                 "model" : "LabelWidget",
    //                 "x" : 149,
    //                 "y" : 136,
    //                 "font-size" : 150,
    //                 "content" : "%s",
    //                 "color" : "rgb(32,74,135)"
    //               },
    //               {
    //                 "model" : "LabelWidget",
    //                 "x" : 645,
    //                 "y" : 261,
    //                 "font-size" : 150,
    //                 "content" : "%s",
    //                 "color" : "rgb(255,255,255)"
    //               },
    //               {
    //                 "model" : "TextWidget",
    //                 "x" : 407,
    //                 "y" : 441,
    //                 "font-size" : 170,
    //                 "content" : "%s"
    //               },
    //               {
    //                 "model" : "TextWidget",
    //                 "x" : 1,
    //                 "y" : 728,
    //                 "font-size" : 120,
    //                 "content" : "<-- %s"
    //               },
    //               {
    //                 "model" : "TextWidget",
    //                 "x" : 1,
    //                 "y" : 25,
    //                 "font-size" : 130,
    //                 "content" : "<-- %s"
    //               },
    //               {
    //                 "model" : "TextWidget",
    //                 "x" : 474,
    //                 "y" : 117,
    //                 "font-size" : 210,
    //                 "content" : "🙃️"
    //               }
    //             ]
    //           }
    //         ]
    //     """.printf (TITLE, TEXT_A, TEXT_B, TEXT_C, TEXT_D, TEXT_E, TEXT_F);
    // }
}
