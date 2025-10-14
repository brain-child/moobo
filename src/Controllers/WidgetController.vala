/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Pierre Fabarius <pierre@fabarius.xyz>
 */

public abstract class WidgetController {

    public abstract Movable get_movable ();
    public abstract BaseModel get_model ();

    protected BoardController board_controller;
    protected int x;
    protected int y;

    protected WidgetController (BoardController board_controller, int x, int y) {
        this.board_controller = board_controller;
        this.x = x;
        this.y = y;
    }

    public abstract void update_widget ();
    public abstract void handle_key_press (Gdk.EventKey event);
    public abstract void handle_key_release ();
}
