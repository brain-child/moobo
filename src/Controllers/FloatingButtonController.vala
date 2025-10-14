public class FloatingButtonController {

    public signal void selection (Type type);

    private FloatingButton floating_button;

    public FloatingButtonController (FloatingButton floating_button) {
        this.floating_button = floating_button;
        floating_button.mode_button.mode_changed.connect ( () => {
            var index = floating_button.mode_button.selected;
            WidgetFactory.WidgetType widget_type;
            switch (index) {
                case 0:
                    widget_type = WidgetFactory.WidgetType.TEXT;
                    break;
                case 1:
                    widget_type = WidgetFactory.WidgetType.LABEL;
                    break;
                case 2:
                    widget_type = WidgetFactory.WidgetType.IMAGE;
                    break;
                default:
                    widget_type = WidgetFactory.WidgetType.TEXT;
                    break;
            }
            selection (WidgetFactory.get_class_type_from_widget_type (widget_type));
        });
    }

}
