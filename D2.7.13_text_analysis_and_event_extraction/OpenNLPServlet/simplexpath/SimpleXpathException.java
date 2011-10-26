/*
 * SimpleXpathException.java: Exception handler for XpathParser.java
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



package simplexpath;

/**
 *
 * @author rar011
 */
public class SimpleXpathException extends Exception {

    private String type;
    private String responseError;
    private Exception e;

    public SimpleXpathException(String type, Exception e) {
      this.type = type;
      this.e = e;
      this.responseError = "";
    }

       public String getType() {
       return this.type;
    }

    @Override
    public String getMessage() {
        return "Xpath fout: " + this.type;
    }

}
