/*
 *    HttpGetException
 *    Copyright (C) 2011  R. van der Ark
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/


package httpget;

/**
 *
 * HttpGetException
 */
public class HttpGetException extends Exception {
    private String type, url;
    private Exception e;
    private String[] redirects;

    public HttpGetException(String type, String url_str, Exception e, String[] redirects) {
      this.type = type;
      this.e = e;
      this.url = url_str;
      this.redirects = redirects;
    }

    public String getType() {
       return this.type;
    }

    public String getUrl() {
        return this.url;
    }

    public String[] getRedirects() {
        return this.redirects;
    }

    @Override
    public String getMessage() {
        String m = this.type + ": " + this.url;
        for(int i = 0; i < this.redirects.length && this.redirects[i] != null; ++i)
            m += "Redirect van: " + this.redirects[i];
        return m + System.getProperty("line.separator");
    }
}
