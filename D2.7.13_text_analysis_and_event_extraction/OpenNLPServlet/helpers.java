/*
    Copyright (c) 2010 KB, Koninklijke Bibliotheek.

    Maintainer : Willem Jan Faber
    Requestor : Theo van Veen

    This file is part of kbSRU.

    kbSRU is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    kbSRU is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with kbSRU. If not, see <http://www.gnu.org/licenses/>.

*/

public class helpers {

    public static String xmlEncode(String s) {
        boolean      changed=false;
        char         c;
        StringBuffer sb=null;
        for(int i=0; i<s.length(); i++) {
            c=s.charAt(i);
            if(c<0xa) {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                    changed=true;
                }
                sb.append("&#x").append(Integer.toHexString(c)).append(';');
            }
            else if(c=='<') {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                    changed=true;
                }
                sb.append("&lt;");
            }
            else if(c=='>') {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                    changed=true;
                }
                sb.append("&gt;");
            }
            else if(c=='"') {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                    changed=true;
                }
                sb.append("&quot;");
            }
            else if(c=='&') {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                        changed=true;
                }
                sb.append("&amp;");
            }
            else  if(c=='\'') {
                if(!changed) {
                    if(i>0)
                        sb=new StringBuffer(s.substring(0, i));
                    else
                        sb=new StringBuffer();
                    changed=true;
                }
                sb.append("&apos;");
            }
            else
                if(changed)
                    sb.append(c);
        }
        if(!changed)
            return s;
        return sb.toString();
    }
}