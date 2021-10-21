namespace Colors {

    public string from_index (int index) {
        string color = "transparent";
        switch (index) {
            case 0:
                break;
            case 1:
                color = "strawberry";
                break;
            case 2:
                color = "orange";
                break;
            case 3:
                color = "banana";
                break;
            case 4:
                color = "lime";
                break;
            case 5: 
                color = "mint";
                break;
            case 6:
                color = "blueberry";
                break;
            case 7:
                color = "grape";
                break;
            case 8:
                color = "bubblegum";
                break;
            case 9:
                color = "cocoa";
                break;
            case 10:
                color = "slate";
                break;
        }
        return color;
    }
    
    public string from_name (string color_name) {
        var color = "transparent";
        switch (color_name) {
            case "transparent":
                break;
            case "strawberry":
                color = "#c6262e";
                break;
            case "orange":
                color = "#f37329";
                break;
            case "banana":
                color = "#e6a92a";
                break;
            case "lime":
                color = "#68b723";
                break;
            case "mint":
                color = "#0e9a83";
                break;
            case "blueberry":
                color = "#3689e6";
                break;
            case "grape":
                color = "#a56de2";
                break;
            case "bubblegum":
                color = "#de3e80";
                break;
            case "cocoa":
                color = "#8a715e";
                break;
            case "slate":
                color = "#667885";
                break;
        }
        return color;
    }
    
    public int from_name_to_index (string color_name) {
        var index = 0;
        switch (color_name) {
            case "transparent":
                break;
            case "strawberry":
                index = 1;
                break;
            case "orange":
                index = 2;
                break;
            case "banana":
                index = 3;
                break;
            case "lime":
                index = 4;
                break;
            case "mint":
                index = 5;
                break;
            case "blueberry":
                index = 6;
                break;
            case "grape":
                index = 7;
                break;
            case "bubblegum":
                index = 8;
                break;
            case "cocoa":
                index = 9;
                break;
            case "slate":
                index = 10;
                break;
        }
        return index;
    }

}
