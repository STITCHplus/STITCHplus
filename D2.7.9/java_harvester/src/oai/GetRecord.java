/*
 *    GetRecord: does GetRecord request + response storage for OAI
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

import harvester.HarvesterConfig;
import java.text.ParseException;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.File;

import org.apache.log4j.Logger;

import httpget.*;
import simplexpath.*;

/**
 *
 *  GetRecord: does GetRecord request + response storage for OAI
 */
public class GetRecord {
    static Logger logger = Logger.getLogger(GetRecord.class);
    private RecordIdentifier identifier;
    private String saveDir;
    private HarvesterConfig config;

    public GetRecord(String identifierLine, String saveDir, HarvesterConfig config) throws OAIException, IOException {
        try {
            logger.debug("Parsing record identifier: " + identifierLine);
            this.identifier = new RecordIdentifier(identifierLine);
            this.saveDir = saveDir;
            this.config = config;
            this.identifier.save(this.saveDir + "/identifier.txt", false);
        } catch(ParseException e) {
            throw new OAIException("Kan datumveld niet parsen in: " + identifierLine, e);
        }
    }

    private String buildUrl() {
        return this.config.getUrl() + "?verb=GetRecord&identifier=" + this.identifier.getIdentifier() + "&metadataPrefix=" + this.config.getRecordMetadataPrefix();
    }

    public void retrieve() throws HttpGetException, IOException {
        logger.debug("Attempting to retrieve record from URL: " + buildUrl());
        HttpGet get = new HttpGet(buildUrl());
        get.saveResponse(saveDir + "/oai_response.xml");
        logger.debug("Record saved succesfully");
    }

    public void saveMetadata() throws SimpleXpathException, OAIException, GetRecordException, IOException {
        XpathParser parser = new XpathParser(new FileInputStream(saveDir + "/oai_response.xml"));
        String errorCode = parser.firstHit("//error/@code");
        if(errorCode != null) {
            String errorSummary = parser.firstHit("//error/text()");
            throw new OAIException("Response error bij ophalen identifiers", errorCode + ": " + errorSummary);
        }
        String deleted = parser.firstHit("//header/@status");
        if(deleted != null && deleted.equals("deleted"))
            throw new GetRecordException("Record was deleted on oai server");

        parser.saveNodeContent("//GetRecord/record/metadata/RDF", saveDir + "/metadata.xml");
    }

    public void deleteOAIResponse() {
        new File(saveDir + "/oai_response.xml").delete();
    }

    public RecordIdentifier getIdentifier() {
        return identifier;
    }
}
