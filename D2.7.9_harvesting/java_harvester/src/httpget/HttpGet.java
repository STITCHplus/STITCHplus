/*
 *    HttpGet: wrapper for doing GET requests via HTTP
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

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.UnknownHostException;
import java.net.SocketTimeoutException;

import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.OutputStream;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import org.apache.log4j.Logger;

import org.apache.commons.codec.binary.Base64;

/**
 *
 *  HttpGet: wrapper for doing GET requests via HTTP
 */
public class HttpGet {
    private URL url;
    private HttpURLConnection connection;
    private BufferedReader bufferedReader;
    private InputStream inputStream;
    private int responseCode;
    private String[] redirected_from;
    private int nRedirects;
    private int maxTimeout;
    private Map requestHeaders;
    private String mimeType;

    static Logger logger = Logger.getLogger(HttpGet.class);
    public HttpGet(String url_str, int maxTimeout, Map requestHeaders) throws HttpGetException {
        this.init(url_str, maxTimeout, requestHeaders);
    }

    public HttpGet(String url_str, String uName, String uPass) throws HttpGetException {
        Map<String, String> authHeader = new HashMap<String, String>();
        authHeader.put("Authorization", "Basic " + Base64.encodeBase64String(new String(uName + ":" + uPass).getBytes()).trim());
        this.init(url_str, 30, authHeader);
    }

    public HttpGet(String url_str, Map requestHeaders) throws HttpGetException {
        this.init(url_str, 30, requestHeaders);
    }


    public HttpGet(String url_str) throws HttpGetException {
        this.init(url_str, 30, null);
    }

    private void init(String url_str, int maxTimeout, Map requestHeaders) throws HttpGetException {
        this.requestHeaders = requestHeaders;
        this.nRedirects = 0;
        this.maxTimeout = maxTimeout;
        this.redirected_from = new String[256];
        this.setUrl(url_str);
        this.obtainConnection();
    }

    public String getResponseString() throws HttpGetException {
        String inputLine;
        String returnLine = "";
        this.getBufferedReader();
        try {
            while((inputLine = this.bufferedReader.readLine()) != null)
                returnLine += inputLine;
        } catch (IOException e) {
            throw(new HttpGetException("Probleem met lezen remote data", this.url.toString(), e, redirected_from));
        }
        return returnLine;
    }
    
    @Override
    protected void finalize() throws Throwable {
        if(this.bufferedReader != null) this.bufferedReader.close();
        if(this.connection != null) this.connection.disconnect();
        super.finalize();
    }

    private void setUrl(String url_str) throws HttpGetException {
        try {
            this.url = new URL(url_str);
        } catch(MalformedURLException e) {
            throw(new HttpGetException("Ongeldige URL meegegeven", url_str, e, redirected_from) );
        }
    }
    private void obtainConnection() throws HttpGetException {
        try {
            this.connection = (HttpURLConnection) url.openConnection();
            this.connection.setInstanceFollowRedirects(true);
            this.connection.setReadTimeout(this.maxTimeout * 1000);
            if(this.requestHeaders != null) {
                Iterator i = this.requestHeaders.entrySet().iterator();
                while(i.hasNext()) {
                    Map.Entry pair = (Map.Entry) i.next();
                    this.connection.setRequestProperty((String) pair.getKey(), (String) pair.getValue());
                }
            }
            this.connection.connect();
            this.responseCode = this.connection.getResponseCode();
            if(this.responseCode == HttpURLConnection.HTTP_SEE_OTHER ||
               this.responseCode == HttpURLConnection.HTTP_MOVED_TEMP ||
               this.responseCode == HttpURLConnection.HTTP_MOVED_PERM) {
                this.redirected_from[this.nRedirects++] = this.url.toString();
                if(this.connection.getHeaderField("location") != null)
                    this.setUrl(this.connection.getHeaderField("location"));
                else
                    this.setUrl(this.redirectFromResponse());
                this.obtainConnection();
            }

            if(this.responseCode == HttpURLConnection.HTTP_FORBIDDEN) {
                throw new HttpGetException("Toegang verboden (403)", this.url.toString(), new Exception("Toegang verboden (403)"), redirected_from);
            }
            String mimeParts[] = this.connection.getContentType().split(";");
            this.mimeType = mimeParts[0];
        } catch(SocketTimeoutException e) {
            throw(new HttpGetException("Timeout bij ophalen gegevens", this.url.toString(), e, redirected_from));
        } catch(IOException e) {
            throw(new HttpGetException("Probleem met verbinden", this.url.toString(), e, redirected_from));
        }
    }
    private String redirectFromResponse() throws HttpGetException {
        String inputLine, responseStr = null;
        this.getBufferedReader();

        try {
            while((inputLine = this.bufferedReader.readLine()) != null) {
                if(inputLine.matches(".*<a.*href=\"[^>]+\".*>.*")) {
                    Pattern p1 = Pattern.compile(".*<a.*href=\"");
                    Pattern p2 = Pattern.compile("\".*>.*");
                    Matcher m1 = p1.matcher(inputLine);
                    responseStr = m1.replaceAll("");
                    Matcher m2 = p2.matcher(responseStr);
                    responseStr = m2.replaceAll("");
                    break;
                }
            }
        } catch(IOException e) {
            throw(new HttpGetException("Redirect (code " + this.responseCode + ") aangegeven door pagina maar pagina niet leesbaar", this.url.toString(), e, redirected_from));
        }

        if(responseStr == null)
            throw(new HttpGetException("Redirect (code " + this.responseCode + ") aangegeven door pagina maar geen valide redirect-locatie", this.url.toString(), new Exception(), redirected_from));

        try { 
            this.bufferedReader.close();
        } catch(Exception e) {
            e.printStackTrace();
        }
        
        return responseStr;
    }

    public BufferedReader getBufferedReader() throws HttpGetException {
        this.bufferedReader = new BufferedReader(new InputStreamReader(this.getInputStream()));
        return this.bufferedReader;
    }

    public InputStream getInputStream() throws HttpGetException {
        try {
            this.inputStream = this.connection.getInputStream();
        } catch (UnknownHostException e) {
            logger.error("Http Fout", e);
            throw(new HttpGetException("Probleem met verbinden", this.url.toString(), e, redirected_from));
        } catch (IOException e) {
            logger.error("Http Fout", e);
            throw(new HttpGetException("Probleem met verbinden", this.url.toString(), e, redirected_from));
        } catch(IllegalArgumentException e) {
            logger.error("Http Fout", e);
            throw(new HttpGetException("Probleem met verbinden", this.url.toString(), e, redirected_from));
        } catch(Exception e) {
            logger.error("Http Fout", e);
            throw(new HttpGetException("Probleem met verbinden", this.url.toString(), e, redirected_from));
        }
        return this.inputStream;
    }

    public void saveResponse(String filename) throws HttpGetException, IOException {
        File f = new File(filename);
        if(this.inputStream == null)
            this.getInputStream();
        try {
            OutputStream out = new FileOutputStream(f);
            byte buf[]=new byte[1024];
            int len;
            while((len=inputStream.read(buf))>0)
                out.write(buf,0,len);
            out.close();
        } catch(FileNotFoundException e) {
            throw new HttpGetException("Bestand niet gevonden", filename, e, redirected_from);
        }
    }

    public String getMimeType() {
        return mimeType;
    }
}
