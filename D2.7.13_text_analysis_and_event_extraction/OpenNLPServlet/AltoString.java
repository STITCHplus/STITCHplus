/*
 * AltoString.java: Represents a String node in alto xml
 * Copyright (C) 2011 R. van der Ark, Koninklijke Bibliotheek - National Library of the Netherlands
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>..
 */


/**
 *
 * @author  R. van der Ark
 */
public class AltoString {
    private String content;
    private int x;
    private int y;
    private int w;
    private int h;
    private boolean flagged = false;

    public boolean isFlagged() {
        return flagged;
    }

    public void setFlagged(boolean flagged) {
        this.flagged = flagged;
    }

    public AltoString(String content, int x, int y, int w, int h) {
        this.content = content;
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }

    public String getContent() {
        return content;
    }

    public int getH() {
        return h;
    }

    public int getW() {
        return w;
    }

    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }
}
