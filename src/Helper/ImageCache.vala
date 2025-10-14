namespace ImageCache {
    
    public class CacheEntry {
        public Gdk.Pixbuf original_pixbuf;
        public Gee.HashMap<string, Gdk.Pixbuf> scaled_cache;
        public int64 last_accessed;
        public int access_count;
        
        public CacheEntry (Gdk.Pixbuf pixbuf) {
            this.original_pixbuf = pixbuf;
            this.scaled_cache = new Gee.HashMap<string, Gdk.Pixbuf> ();
            this.last_accessed = get_monotonic_time ();
            this.access_count = 1;
        }
        
        public void touch () {
            this.last_accessed = get_monotonic_time ();
            this.access_count++;
        }
        
        public string get_cache_key (int width, int height) {
            return "%dx%d".printf (width, height);
        }
        
        public Gdk.Pixbuf? get_scaled (int width, int height) {
            var key = get_cache_key (width, height);
            return scaled_cache.get (key);
        }
        
        public void set_scaled (int width, int height, Gdk.Pixbuf pixbuf) {
            var key = get_cache_key (width, height);
            scaled_cache.set (key, pixbuf);
        }
    }
    
    public class ImageCacheManager {
        private static ImageCacheManager? instance = null;
        private Gee.HashMap<string, CacheEntry> cache;
        private int max_cache_size;
        private int64 max_cache_age; // in microseconds
        private Timer cleanup_timer;
        
        public static ImageCacheManager get_instance () {
            if (instance == null) {
                instance = new ImageCacheManager ();
            }
            return instance;
        }
        
        private ImageCacheManager () {
            cache = new Gee.HashMap<string, CacheEntry> ();
            max_cache_size = 50; // Maximum number of images to cache
            max_cache_age = 5 * 60 * 1000000; // 5 minutes in microseconds
            cleanup_timer = new Timer ();
            
            // Start periodic cleanup
            Timeout.add_seconds (60, cleanup_expired_entries);
        }
        
        public Gdk.Pixbuf? get_image (string path, int? width = null, int? height = null) {
            if (path == null || path == "") {
                return null;
            }
            
            var entry = cache.get (path);
            if (entry == null) {
                // Load image from file
                try {
                    var pixbuf = new Gdk.Pixbuf.from_file (path);
                    if (pixbuf == null) {
                        return null;
                    }
                    entry = new CacheEntry (pixbuf);
                    cache.set (path, entry);
                } catch (Error e) {
                    warning ("Failed to load image %s: %s", path, e.message);
                    return null;
                }
            } else {
                entry.touch ();
            }
            
            // Return scaled version if requested
            if (width != null && height != null) {
                var scaled = entry.get_scaled (width, height);
                if (scaled == null) {
                    // Create scaled version
                    try {
                        scaled = entry.original_pixbuf.scale_simple (width, height, Gdk.InterpType.BILINEAR);
                        entry.set_scaled (width, height, scaled);
                    } catch (Error e) {
                        warning ("Failed to scale image: %s", e.message);
                        return entry.original_pixbuf;
                    }
                }
                return scaled;
            }
            
            return entry.original_pixbuf;
        }
        
        public void preload_image (string path) {
            if (path == null || path == "" || cache.has_key (path)) {
                return;
            }
            
            try {
                var pixbuf = new Gdk.Pixbuf.from_file (path);
                if (pixbuf != null) {
                    var entry = new CacheEntry (pixbuf);
                    cache.set (path, entry);
                }
            } catch (Error e) {
                warning ("Failed to preload image %s: %s", path, e.message);
            }
        }
        
        public void remove_image (string path) {
            cache.unset (path);
        }
        
        public void clear_cache () {
            cache.clear ();
        }
        
        public int get_cache_size () {
            return cache.size;
        }
        
        public int64 get_cache_memory_usage () {
            int64 total_size = 0;
            foreach (var entry in cache.values) {
                // Estimate memory usage (rough calculation)
                total_size += entry.original_pixbuf.get_byte_length ();
                foreach (var scaled in entry.scaled_cache.values) {
                    total_size += scaled.get_byte_length ();
                }
            }
            return total_size;
        }
        
        private bool cleanup_expired_entries () {
            var now = get_monotonic_time ();
            var to_remove = new Gee.ArrayList<string> ();
            
            foreach (var entry in cache.entries) {
                if (now - entry.value.last_accessed > max_cache_age) {
                    to_remove.add (entry.key);
                }
            }
            
            foreach (var key in to_remove) {
                cache.unset (key);
            }
            
            // If cache is still too large, remove least recently used entries
            if (cache.size > max_cache_size) {
                var entries_list = new Gee.ArrayList<Gee.Map.Entry<string, CacheEntry>> ();
                foreach (var entry in cache.entries) {
                    entries_list.add (entry);
                }
                
                // Sort by last_accessed (oldest first)
                entries_list.sort ((a, b) => {
                    return (int) (a.value.last_accessed - b.value.last_accessed);
                });
                
                var to_remove_lru = new Gee.ArrayList<string> ();
                for (int i = 0; i < entries_list.size - max_cache_size; i++) {
                    to_remove_lru.add (entries_list[i].key);
                }
                
                foreach (var key in to_remove_lru) {
                    cache.unset (key);
                }
            }
            
            return true; // Continue the timeout
        }
        
        public void set_max_cache_size (int size) {
            max_cache_size = size;
        }
        
        public void set_max_cache_age (int64 age_microseconds) {
            max_cache_age = age_microseconds;
        }
    }
}

