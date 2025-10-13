/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Pierre Fabarius <pierre@fabarius.xyz>
 */

public class WidgetFactory {

    public enum WidgetType {
        TEXT,
        LABEL,
        IMAGE
    }

    public static WidgetType get_widget_type_from_string (string type_name) {
        switch (type_name) {
            case "TextWidget":
                return WidgetType.TEXT;
            case "LabelWidget":
                return WidgetType.LABEL;
            case "ImageWidget":
                return WidgetType.IMAGE;
            default:
                warning ("Unknown widget type: %s", type_name);
                return WidgetType.TEXT;
        }
    }

    public static string get_string_from_widget_type (WidgetType type) {
        switch (type) {
            case WidgetType.TEXT:
                return "TextWidget";
            case WidgetType.LABEL:
                return "LabelWidget";
            case WidgetType.IMAGE:
                return "ImageWidget";
            default:
                return "TextWidget";
        }
    }

    public static WidgetType get_widget_type_from_class (Type class_type) {
        if (class_type == typeof (TextWidget)) {
            return WidgetType.TEXT;
        } else if (class_type == typeof (LabelWidget)) {
            return WidgetType.LABEL;
        } else if (class_type == typeof (ImageWidget)) {
            return WidgetType.IMAGE;
        } else {
            warning ("Unknown widget class type: %s", class_type.name ());
            return WidgetType.TEXT;
        }
    }

    public static Type get_class_type_from_widget_type (WidgetType type) {
        switch (type) {
            case WidgetType.TEXT:
                return typeof (TextWidget);
            case WidgetType.LABEL:
                return typeof (LabelWidget);
            case WidgetType.IMAGE:
                return typeof (ImageWidget);
            default:
                return typeof (TextWidget);
        }
    }

    public static BaseModel create_model (WidgetType type) {
        switch (type) {
            case WidgetType.TEXT:
                return new TextModel ();
            case WidgetType.LABEL:
                return new LabelModel ();
            case WidgetType.IMAGE:
                return new ImageModel ();
            default:
                return new TextModel ();
        }
    }

    public static BaseModel create_model_from_string (string type_name) {
        return create_model (get_widget_type_from_string (type_name));
    }

    public static BaseModel create_model_from_class (Type class_type) {
        return create_model (get_widget_type_from_class (class_type));
    }

    public static WidgetController create_controller (WidgetType type, BoardController board_controller, int x, int y, BaseModel? model = null) {
        BaseModel actual_model = model ?? create_model (type);

        switch (type) {
            case WidgetType.TEXT:
                return new TextController (board_controller, x, y, (TextModel) actual_model);
            case WidgetType.LABEL:
                return new LabelController (board_controller, x, y, (LabelModel) actual_model);
            case WidgetType.IMAGE:
                return new ImageController (board_controller, x, y, (ImageModel) actual_model);
            default:
                return new TextController (board_controller, x, y, (TextModel) actual_model);
        }
    }

    public static WidgetController create_controller_from_string (string type_name, BoardController board_controller, int x, int y, BaseModel? model = null) {
        return create_controller (get_widget_type_from_string (type_name), board_controller, x, y, model);
    }

    public static WidgetController create_controller_from_class (Type class_type, BoardController board_controller, int x, int y, BaseModel? model = null) {
        return create_controller (get_widget_type_from_class (class_type), board_controller, x, y, model);
    }

    public static Movable create_widget (WidgetType type, BoardController board_controller, int x, int y, BaseModel? model = null) {
        var controller = create_controller (type, board_controller, x, y, model);
        return controller.get_movable ();
    }

    public static Movable create_widget_from_string (string type_name, BoardController board_controller, int x, int y, BaseModel? model = null) {
        return create_widget (get_widget_type_from_string (type_name), board_controller, x, y, model);
    }

    public static Movable create_widget_from_class (Type class_type, BoardController board_controller, int x, int y, BaseModel? model = null) {
        return create_widget (get_widget_type_from_class (class_type), board_controller, x, y, model);
    }

    public static void focus_widget (Movable widget) {
        if (widget is TextWidget) {
            var text_widget = widget as TextWidget;
            text_widget.textview.grab_focus ();
        } else if (widget is LabelWidget) {
            var label_widget = widget as LabelWidget;
            label_widget.textview.grab_focus ();
        }
        // ImageWidget doesn't need focus handling
    }

    public static void remove_widget_from_model (Movable widget, Gee.ArrayList<BaseModel> widgets) {
        if (widget is TextWidget) {
            var text_widget = widget as TextWidget;
            widgets.remove (text_widget.controller.model);
        } else if (widget is LabelWidget) {
            var label_widget = widget as LabelWidget;
            widgets.remove (label_widget.controller.model);
        } else if (widget is ImageWidget) {
            var image_widget = widget as ImageWidget;
            widgets.remove (image_widget.controller.model);
        }
    }

    public static void add_widget_to_model (Movable widget, Gee.ArrayList<BaseModel> widgets) {
        if (widget is TextWidget) {
            var text_widget = widget as TextWidget;
            widgets.add (text_widget.controller.model);
        } else if (widget is LabelWidget) {
            var label_widget = widget as LabelWidget;
            widgets.add (label_widget.controller.model);
        } else if (widget is ImageWidget) {
            var image_widget = widget as ImageWidget;
            widgets.add (image_widget.controller.model);
        }
    }

    public static void reorder_widget_in_model (Movable widget, Gee.ArrayList<BaseModel> widgets) {
        remove_widget_from_model (widget, widgets);
        add_widget_to_model (widget, widgets);
    }
}
