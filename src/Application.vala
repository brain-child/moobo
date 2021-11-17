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
        window.set_size_request (Const.WIN_WIDTH, Const.WIN_HEIGHT);

        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q", "<Control>w"});

        var rename_action = new SimpleAction ("rename", null);
        add_action (rename_action);
        set_accels_for_action ("app.rename", {"F2"});

        add_window (window);
        window.show_all ();

        quit_action.activate.connect (() => {
            window.save ();
            window.destroy ();
        });

        rename_action.activate.connect (() => {
            window.rename_selected_board ();
        });
    }

}
