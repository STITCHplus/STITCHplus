/*
 *    HarvesterStatus: reads/writes information from/to harvester status file
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

import oai.*;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;

import org.apache.log4j.Logger;

/**
 *
 *  HarvesterStatus: reads/writes information from/to harvester status file
 */
public class HarvesterStatus {
    private String state;
    private String fromDate;
    private String untilDate;
    private String resumptionToken;
    private String filename;
    static Logger logger = Logger.getLogger(HarvesterStatus.class);
    public static final String STATE_IDLE = "idle";
    public static final String STATE_HARVEST_IDENTIFIERS = "harvestIdentifiers";
    public static final String STATE_GETRECORD = "getRecord";

    public HarvesterStatus(HarvesterConfig config) {
        this.filename = config.getBaseDir() + "/status";
        this.fromDate = config.getFromDate();
        this.state = STATE_IDLE;
        if(!config.usesResumptionToken())
            this.untilDate = this.fromDate;
    }

    public HarvesterStatus(String filename) throws OAIException {
        this.filename = filename;
        this.state = STATE_IDLE;
        try {
//            logger.debug("Reading status from: " + filename);
            FileReader input = new FileReader(filename);
            BufferedReader bufRead = new BufferedReader(input);
            String line = "";
            while(line != null) {
                addSetting(line);
                line = bufRead.readLine();
            }
            bufRead.close();
//            logger.debug("Status file read succesfully");
        } catch(IOException e) {
            throw new OAIException("Probleem met lezen statusbestand: " + filename, e);
        }
    }

    public void save() throws OAIException {
        try {
            logger.debug("Writing status to file: " + filename);
            FileWriter output = new FileWriter(filename);
            BufferedWriter writer = new BufferedWriter(output);
            if(this.state != null) {
                writer.append("state;" + this.state + System.getProperty("line.separator"));
                logger.debug("state: " + this.state);
            }
            if(this.fromDate != null) {
                writer.append("fromDate;" + this.fromDate + System.getProperty("line.separator"));
                logger.debug("fromDate: " + this.fromDate);
            }
            
            if(this.untilDate != null) {
                writer.append("untilDate;" + this.untilDate + System.getProperty("line.separator"));
                logger.debug("untilDate: " + this.untilDate);
            }

            if(this.resumptionToken != null) {
                writer.append("resumptionToken;" + this.resumptionToken + System.getProperty("line.separator"));
                logger.debug("resumptionToken: " + this.resumptionToken);
            }

            writer.flush();
            writer.close();
            logger.debug("Succesfully wrote status to file: " + filename);

        } catch(Exception e) {
            throw new OAIException("Probleem met schrijven naar statusbestand: " + filename, e);
        }
    }

    private void addSetting(String line) {
        String[] settings = line.split(";");
        if(settings.length == 2) {
            if(settings[0].equals("resumptionToken"))
                this.resumptionToken = settings[1].trim();
            else if(settings[0].equals("untilDate"))
                this.untilDate = settings[1].trim();
            else if(settings[0].equals("fromDate"))
                this.fromDate = settings[1].trim();
            else if(settings[0].equals("state"))
                this.state = settings[1].trim();
            logger.debug(settings[0] + ": " + settings[1]);
        }
    }


    public String getFromDate() {
        return fromDate;
    }

    public String getResumptionToken() {
        return resumptionToken;
    }

    public String getUntilDate() {
        return untilDate;
    }

    public void setFromDate(String fromDate) {
        this.fromDate = fromDate;
    }

    public void setResumptionToken(String resumptionToken) {
        this.resumptionToken = resumptionToken;
    }

    public void setUntilDate(String untilDate) {
        this.untilDate = untilDate;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public boolean checkState(String s) {
        return this.state.equals(s);
    }
    
}
