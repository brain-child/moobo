namespace LazyLoader {
    
    public class LazyWidget {
        public BaseModel model;
        public BoardController board_controller;
        public Movable? widget;
        public bool is_loaded;
        public bool is_visible;
        public int x;
        public int y;
        
        public LazyWidget (BaseModel model, BoardController board_controller, int x, int y) {
            this.model = model;
            this.board_controller = board_controller;
            this.x = x;
            this.y = y;
            this.is_loaded = false;
            this.is_visible = false;
        }
        
        public void load_widget () {
            if (is_loaded) {
                return;
            }
            
            widget = WidgetFactory.create_widget_from_string (model.model, board_controller, x, y, model);
            if (widget != null) {
                is_loaded = true;
                if (is_visible) {
                    board_controller.overlay.add_overlay (widget);
                }
            }
        }
        
        public void unload_widget () {
            if (!is_loaded || widget == null) {
                return;
            }
            
            if (is_visible) {
                board_controller.overlay.remove (widget);
            }
            
            widget.destroy ();
            widget = null;
            is_loaded = false;
        }
        
        public void show_widget () {
            if (!is_loaded) {
                load_widget ();
            }
            
            if (widget != null && !is_visible) {
                board_controller.overlay.add_overlay (widget);
                is_visible = true;
            }
        }
        
        public void hide_widget () {
            if (widget != null && is_visible) {
                board_controller.overlay.remove (widget);
                is_visible = false;
            }
        }
        
        public bool is_in_viewport (int viewport_x, int viewport_y, int viewport_width, int viewport_height) {
            return (x >= viewport_x - 100 && x <= viewport_x + viewport_width + 100 &&
                    y >= viewport_y - 100 && y <= viewport_y + viewport_height + 100);
        }
    }
    
    public class LazyLoadingManager {
        private Gee.ArrayList<LazyWidget> lazy_widgets;
        private BoardController board_controller;
        private int viewport_x;
        private int viewport_y;
        private int viewport_width;
        private int viewport_height;
        private bool is_enabled;
        
        public LazyLoadingManager (BoardController board_controller) {
            this.board_controller = board_controller;
            this.lazy_widgets = new Gee.ArrayList<LazyWidget> ();
            this.is_enabled = true;
            this.viewport_x = 0;
            this.viewport_y = 0;
            this.viewport_width = 800;
            this.viewport_height = 600;
        }
        
        public void add_widget (BaseModel model, int x, int y) {
            var lazy_widget = new LazyWidget (model, board_controller, x, y);
            lazy_widgets.add (lazy_widget);
            
            if (is_enabled && lazy_widget.is_in_viewport (viewport_x, viewport_y, viewport_width, viewport_height)) {
                lazy_widget.show_widget ();
            }
        }
        
        public void remove_widget (BaseModel model) {
            for (int i = 0; i < lazy_widgets.size; i++) {
                if (lazy_widgets[i].model == model) {
                    lazy_widgets[i].unload_widget ();
                    lazy_widgets.remove_at (i);
                    break;
                }
            }
        }
        
        public void update_viewport (int x, int y, int width, int height) {
            viewport_x = x;
            viewport_y = y;
            viewport_width = width;
            viewport_height = height;
            
            if (!is_enabled) {
                return;
            }
            
            foreach (var lazy_widget in lazy_widgets) {
                bool should_be_visible = lazy_widget.is_in_viewport (x, y, width, height);
                
                if (should_be_visible && !lazy_widget.is_visible) {
                    lazy_widget.show_widget ();
                } else if (!should_be_visible && lazy_widget.is_visible) {
                    lazy_widget.hide_widget ();
                }
            }
        }
        
        public void load_all_widgets () {
            foreach (var lazy_widget in lazy_widgets) {
                lazy_widget.show_widget ();
            }
        }
        
        public void unload_all_widgets () {
            foreach (var lazy_widget in lazy_widgets) {
                lazy_widget.unload_widget ();
            }
        }
        
        public void set_enabled (bool enabled) {
            is_enabled = enabled;
            
            if (enabled) {
                update_viewport (viewport_x, viewport_y, viewport_width, viewport_height);
            } else {
                load_all_widgets ();
            }
        }
        
        public int get_loaded_count () {
            int count = 0;
            foreach (var lazy_widget in lazy_widgets) {
                if (lazy_widget.is_loaded) {
                    count++;
                }
            }
            return count;
        }
        
        public int get_total_count () {
            return lazy_widgets.size;
        }
        
        public void cleanup_unused_widgets () {
            foreach (var lazy_widget in lazy_widgets) {
                if (lazy_widget.is_loaded && !lazy_widget.is_visible) {
                    // Unload widgets that haven't been visible for a while
                    lazy_widget.unload_widget ();
                }
            }
        }
    }
}
