/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Pierre Fabarius <pierre@fabarius.xyz>
 */

public class Application : Gtk.Application {

    public static int main (string[] args) {
        return new Application ().run (args);
    }

    protected override void activate () {

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("com/github/brain_child/moobo/styles/Style.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER
        );

        var gtk_settings = Gtk.Settings.get_default ();

        var granite_settings = Granite.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;


        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var window = new Window (this) {
            resizable = false,
        };
        calc_window_size_from_screen_resolution (window);

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "<Control>w"});

        var rename_action = new SimpleAction ("rename", null);
        add_action (rename_action);
        set_accels_for_action ("app.rename", {"F2"});

        var help_action = new SimpleAction ("help", null);
        add_action (help_action);
        set_accels_for_action ("app.help", {"Escape"});

        add_window (window);
        window.show_all ();

        quit_action.activate.connect (() => {
            window.save ();
            window.destroy ();
        });

        rename_action.activate.connect (() => {
            window.rename_selected_board ();
        });

        help_action.activate.connect (() => {
            help_window (window).show_all ();
        });
    }

    private void calc_window_size_from_screen_resolution (Window window) {
        var display = Gdk.Screen.get_default ().get_display ();
        var monitor = display.get_monitor_at_window (window.get_window ());
        var rect = monitor.get_geometry ();

        var width = (int) (rect.width * Const.WIN_SCALE_X);
        var height = (int) (rect.height * Const.WIN_SCALE_Y);
        window.set_size_request (width, height);
    }

    private Hdy.Window help_window (Hdy.ApplicationWindow main_window) {

        var layout = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
        };

        var shortcut_window = new Hdy.Window () {
            skip_taskbar_hint = true,
            resizable = false,
        };
        
        shortcut_window.set_keep_above (true);
        shortcut_window.focus_out_event.connect (() => {
            shortcut_window.destroy ();
            return true;
        });

        shortcut_window.key_press_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                shortcut_window.destroy ();
            }
            return true;
        });
        
        

        var headerbar = new Gtk.HeaderBar () {
            title = _("Shortcuts"),
            has_subtitle = false,
            show_close_button = true
        };
        unowned Gtk.StyleContext headerbar_context = headerbar.get_style_context ();
        headerbar_context.add_class ("default-decoration");
        headerbar_context.add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar_context.add_class (Gtk.STYLE_CLASS_TITLEBAR);

        layout.add (headerbar);

        var shortcuts = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            column_spacing = 12,
            row_spacing = 12,
            margin = 36,
            margin_top = 12
        };

        shortcuts.attach (new Granite.HeaderLabel (_("Application")), 0, 0, 2);
        shortcuts.attach (new Gtk.Label ("Save and Quit:"){ halign = Gtk.Align.END }, 1, 1);
        shortcuts.attach (new Granite.AccelLabel ("", "<Ctrl>W"){ halign = Gtk.Align.START },2, 1);
        shortcuts.attach (new Granite.AccelLabel ("", "<Ctrl>Q"){ halign = Gtk.Align.START }, 2, 2);
        shortcuts.attach (new Granite.HeaderLabel (_("Board")), 0, 3, 2);
        shortcuts.attach (new Gtk.Label ("Rename:"){ halign = Gtk.Align.END }, 1, 4);
        shortcuts.attach (new Granite.AccelLabel ("", "F2"){ halign = Gtk.Align.START }, 2, 4);
        shortcuts.attach (new Granite.HeaderLabel (_("Widgets")), 0, 5, 2);
        shortcuts.attach (new Gtk.Label ("Increase font:"){ halign = Gtk.Align.END }, 1, 6);
        shortcuts.attach (new Granite.AccelLabel ("", "<Ctrl>plus"){ halign = Gtk.Align.START }, 2, 6);
        shortcuts.attach (new Gtk.Label ("Decrease font:"){ halign = Gtk.Align.END }, 1, 7);
        shortcuts.attach (new Granite.AccelLabel ("", "<Ctrl>minus"){ halign = Gtk.Align.START }, 2, 7);

        layout.add (shortcuts);

        shortcut_window.add (layout);

        return shortcut_window;
    }

}
