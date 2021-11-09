public class FloatingButtonController {

    public signal void selection (Type type);

    private FloatingButton floating_button;

    public FloatingButtonController (FloatingButton floating_button) {
        this.floating_button = floating_button;
        floating_button.mode_button.mode_changed.connect ( () => {
            var index = floating_button.mode_button.selected;
            switch (index) {
                case 0:
                    selection ( typeof (TextWidget) );
                    break;
                case 1:
                    selection ( typeof (LabelWidget) );
                    break;
                case 2:
                    selection ( typeof (ImageWidget) );
                    break;
            }
        });
    }

}
