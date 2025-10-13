namespace MemoryManager {
    
    public class MemoryMonitor {
        private static MemoryMonitor? instance = null;
        private Timer monitor_timer;
        private int64 last_memory_usage;
        private int64 peak_memory_usage;
        private bool is_monitoring;
        
        // Memory thresholds
        private int64 warning_threshold = 100 * 1024 * 1024; // 100MB
        private int64 critical_threshold = 200 * 1024 * 1024; // 200MB
        
        public signal void memory_warning (int64 current_usage, int64 threshold);
        public signal void memory_critical (int64 current_usage, int64 threshold);
        
        public static MemoryMonitor get_instance () {
            if (instance == null) {
                instance = new MemoryMonitor ();
            }
            return instance;
        }
        
        private MemoryMonitor () {
            is_monitoring = false;
            last_memory_usage = 0;
            peak_memory_usage = 0;
        }
        
        public void start_monitoring () {
            if (is_monitoring) {
                return;
            }
            
            is_monitoring = true;
            monitor_timer = new Timer ();
            
            // Monitor every 30 seconds
            Timeout.add_seconds (30, monitor_memory);
        }
        
        public void stop_monitoring () {
            is_monitoring = false;
        }
        
        private bool monitor_memory () {
            if (!is_monitoring) {
                return false; // Stop the timeout
            }
            
            var current_usage = get_current_memory_usage ();
            
            if (current_usage > peak_memory_usage) {
                peak_memory_usage = current_usage;
            }
            
            // Check thresholds
            if (current_usage > critical_threshold) {
                memory_critical (current_usage, critical_threshold);
                trigger_cleanup ();
            } else if (current_usage > warning_threshold) {
                memory_warning (current_usage, warning_threshold);
            }
            
            last_memory_usage = current_usage;
            return true; // Continue monitoring
        }
        
        private int64 get_current_memory_usage () {
            try {
                var file = File.new_for_path ("/proc/self/status");
                var stream = file.read ();
                var data_stream = new DataInputStream (stream);
                string line;
                
                while ((line = data_stream.read_line (null)) != null) {
                    if (line.has_prefix ("VmRSS:")) {
                        // Extract memory usage in KB
                        var parts = line.split (" ");
                        if (parts.length >= 2) {
                            return int64.parse (parts[1]) * 1024; // Convert to bytes
                        }
                    }
                }
            } catch (Error e) {
                warning ("Failed to read memory usage: %s", e.message);
            }
            
            return 0;
        }
        
        private void trigger_cleanup () {
            // Clean up image cache
            var image_cache = ImageCache.ImageCacheManager.get_instance ();
            image_cache.clear_cache ();
            
            // Force garbage collection
            Gtk.main_iteration ();
        }
        
        public int64 get_peak_memory_usage () {
            return peak_memory_usage;
        }
        
        public int64 get_last_memory_usage () {
            return last_memory_usage;
        }
        
        public void set_warning_threshold (int64 threshold) {
            warning_threshold = threshold;
        }
        
        public void set_critical_threshold (int64 threshold) {
            critical_threshold = threshold;
        }
        
        public string format_memory_size (int64 bytes) {
            if (bytes < 1024) {
                return "%lld B".printf (bytes);
            } else if (bytes < 1024 * 1024) {
                return "%.1f KB".printf (bytes / 1024.0);
            } else if (bytes < 1024 * 1024 * 1024) {
                return "%.1f MB".printf (bytes / (1024.0 * 1024.0));
            } else {
                return "%.1f GB".printf (bytes / (1024.0 * 1024.0 * 1024.0));
            }
        }
    }
    
    public class ResourceManager {
        private static ResourceManager? instance = null;
        private Gee.ArrayList<GLib.Object> tracked_objects;
        private bool is_cleanup_scheduled;
        
        public static ResourceManager get_instance () {
            if (instance == null) {
                instance = new ResourceManager ();
            }
            return instance;
        }
        
        private ResourceManager () {
            tracked_objects = new Gee.ArrayList<GLib.Object> ();
            is_cleanup_scheduled = false;
        }
        
        public void track_object (GLib.Object obj) {
            tracked_objects.add (obj);
            obj.weak_ref (on_object_destroyed);
        }
        
        private void on_object_destroyed (GLib.Object obj) {
            tracked_objects.remove (obj);
        }
        
        public void schedule_cleanup () {
            if (is_cleanup_scheduled) {
                return;
            }
            
            is_cleanup_scheduled = true;
            Idle.add (perform_cleanup);
        }
        
        private bool perform_cleanup () {
            // Clean up any null references
            var to_remove = new Gee.ArrayList<GLib.Object> ();
            foreach (var obj in tracked_objects) {
                if (obj == null) {
                    to_remove.add (obj);
                }
            }
            
            foreach (var obj in to_remove) {
                tracked_objects.remove (obj);
            }
            
            // Force garbage collection
            Gtk.main_iteration ();
            
            is_cleanup_scheduled = false;
            return false; // Don't repeat
        }
        
        public int get_tracked_object_count () {
            return tracked_objects.size;
        }
        
        public void clear_all_tracked_objects () {
            tracked_objects.clear ();
        }
    }
}

