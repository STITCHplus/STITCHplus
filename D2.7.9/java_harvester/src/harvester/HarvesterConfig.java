/*
 *    HarvesterConfig: reads information from harvester configuration file
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

package harvester;


import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;
import org.apache.log4j.Logger;

/**
 *
 *  HarvesterConfig: reads information from harvester configuration file
 */
public class HarvesterConfig {
    private String name;
    private String ownerId;
    private String url;
    private String set;
    private boolean usesResumptionToken;
    private String fromDate;
    private String identifierDateFormat;
    private String identifierMetadataPrefix;
    private String recordMetadataPrefix;
    private String baseDir;
    static Logger logger = Logger.getLogger(HarvesterConfig.class);

    public HarvesterConfig(String baseDir) throws IOException {
        this.baseDir = baseDir;
        String filename = this.baseDir + "/config";
        this.usesResumptionToken = false;
        logger.debug("Reading config from: " + filename);
        FileReader input = new FileReader(filename);
        BufferedReader bufRead = new BufferedReader(input);
        String line = "";
        while(line != null) {
            addSetting(line);
            line = bufRead.readLine();
        }
        bufRead.close();
        logger.debug("Config read succesfully");
    }

    private void addSetting(String line) {
        String[] settings = line.split(";");
        if(settings.length == 2) {
            if(settings[0].equals("name"))
                this.name = settings[1].trim();
            else if(settings[0].equals("owner_id"))
                this.ownerId = settings[1].trim();
            else if(settings[0].equals("url"))
                this.url = settings[1].trim();
            else if(settings[0].equals("set"))
                this.set = settings[1].trim();
            else if(settings[0].equals("usesResumptionToken") && settings[1].trim().equals("true"))
                this.usesResumptionToken = true;
            else if(settings[0].equals("fromDate"))
                this.fromDate = settings[1].trim();
            else if(settings[0].equals("identifierDateFormat"))
                this.identifierDateFormat = settings[1].trim();
            else if(settings[0].equals("identifierMetadataPrefix"))
                this.identifierMetadataPrefix = settings[1].trim();
            else if(settings[0].equals("recordMetadataPrefix"))
                this.recordMetadataPrefix = settings[1].trim();
            logger.debug(settings[0] + ": " + settings[1].trim());
        }
    }

    public String getRecordMetadataPrefix() {
        return recordMetadataPrefix;
    }
    

    public String getFromDate() {
        return fromDate;
    }

    public String getIdentifierMetadataPrefix() {
        return identifierMetadataPrefix;
    }

    public String getSet() {
        return set;
    }


    public String getUrl() {
        return url;
    }

    public boolean usesResumptionToken() {
        return usesResumptionToken;
    }

    public String getIdentifierDateFormat() {
        return identifierDateFormat;
    }

    public String getName() {
        return name;
    }

    public String getOwnerId() {
        return ownerId;
    }

    public String getBaseDir() {
        return baseDir;
    }
}
