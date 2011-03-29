/*
 *    ListIdentifiers: Does ListIdentifiers request to OAI endpoint + stores identifiers
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

package oai;

import harvester.HarvesterStatus;
import harvester.HarvesterConfig;
import simplexpath.*;
import httpget.*;

import java.util.List;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Calendar;
import java.util.Date;

import java.io.IOException;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import org.w3c.dom.NodeList;


/*
 *
 *  ListIdentifiers: Does ListIdentifiers request to OAI endpoint + stores identifiers
 */
public class ListIdentifiers {
    private HarvesterConfig config;
    private HarvesterStatus status;
    List<RecordIdentifier> identifiers;

    public ListIdentifiers(HarvesterConfig config, HarvesterStatus status) throws OAIException {
        this.config = config;
        this.status = status;
    }

    private String buildUrl() {
        String url = config.getUrl() + "?verb=ListIdentifiers";
        if(config.usesResumptionToken()) {
            if(status.getResumptionToken() == null || status.getResumptionToken().equals("")) {
                if(config.getSet() != null && !config.getSet().equals(""))
                    url += "&set=" + config.getSet();
                if(config.getIdentifierMetadataPrefix() != null && !config.getIdentifierMetadataPrefix().equals(""))
                    url += "&metadataPrefix=" + config.getIdentifierMetadataPrefix();
                if(status.getFromDate() != null && !status.getFromDate().equals(""))
                    url += "&from=" + status.getFromDate();
            } else {
                url += "&resumptionToken=" + status.getResumptionToken();
            }
        } else {
            if(config.getSet() != null && !config.getSet().equals(""))
                url += "&set=" + config.getSet();
            if(config.getIdentifierMetadataPrefix() != null && !config.getIdentifierMetadataPrefix().equals(""))
                url += "&metadataPrefix=" + config.getIdentifierMetadataPrefix();
            url += "&from=" + status.getFromDate();
            url += "&until=" + status.getUntilDate();
        }        
        return url;
    }

    public boolean retrieveList() throws OAIException, ParseException {
        retrieve();
        if(config.usesResumptionToken()) {
            if(status.getResumptionToken() != null && !status.getResumptionToken().equals(""))
                return true;
        } else {
            if(new SimpleDateFormat("yyyy-MM-dd").parse(status.getFromDate()).before(new Date()))
                return true;
            else {
                status.setFromDate(new SimpleDateFormat("yyyy-MM-dd").format(new Date()));
                setUntilDate(new Date());
                status.save();
            }
        }
        return false;
    }

    private void retrieve() throws OAIException {
        try {
            HttpGet get = new HttpGet(buildUrl());
            XpathParser parser = new XpathParser(get.getInputStream());
            String errorCode = parser.firstHit("//error/@code");
            if(errorCode != null && !errorCode.equals("noRecordsMatch")) {
                String errorSummary = parser.firstHit("//error/text()");
                throw new OAIException("Response error bij ophalen identifiers", errorCode + ": " + errorSummary);
            } else {
                identifiers = new LinkedList<RecordIdentifier>();
                NodeList idNodes = parser.parse("//header");
                for(int i = 0; i < idNodes.getLength(); ++i)
                    identifiers.add(new RecordIdentifier(idNodes.item(i), config.getIdentifierDateFormat()));
            }
            if(config.usesResumptionToken()) {
                String rToken = parser.firstHit("//resumptionToken/text()");
                status.setResumptionToken(rToken);
                if(rToken == null || rToken.equals(""))
                    status.setFromDate(new SimpleDateFormat("yyyy-MM-dd").format(new Date()));
            } else {
                incrementDates();
            }
            status.save();
        } catch(HttpGetException e) {
            throw(new OAIException("Kan URL niet bereiken om identifierlijst op te halen", e));
        } catch(SimpleXpathException e) {
            throw(new OAIException("Kan OAI repsonse niet parsen", e));
        } catch(OAIException e) {
            throw e;
        } catch(ParseException e) {
            throw new OAIException("Kan datum niet parsen", e);
        }
    }
    
    private void incrementDates() throws ParseException {
        Date newFromDate = new SimpleDateFormat("yyyy-MM-dd").parse(status.getUntilDate());
        Calendar cal = Calendar.getInstance();
        cal.setTime(newFromDate);
        cal.add(Calendar.DATE, 1);
        status.setFromDate(new SimpleDateFormat("yyyy-MM-dd").format(cal.getTime()));
        setUntilDate(cal.getTime());
    }

    private void setUntilDate(Date d) {
        Calendar cal = Calendar.getInstance();
        cal.setTime(d);
        cal.add(Calendar.DATE, 7);
        status.setUntilDate(new SimpleDateFormat("yyyy-MM-dd").format(cal.getTime()));
    }

    public void save() throws OAIException {
        ListIterator i = identifiers.listIterator();
        while(i.hasNext()) {
            RecordIdentifier id = (RecordIdentifier) i.next();
            try {
                id.save(config.getBaseDir() + "/identifiers", true);
            } catch(IOException e) {
                throw new OAIException("Kan niet wegschrijven naar identifier lijst", e);
            }
        }
    }
}