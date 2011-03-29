/*
 *    RecordIdentifier: reflects the metadata of a OAI record identifier
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

import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.io.IOException;
import java.io.FileWriter;
import java.io.BufferedWriter;

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;

import org.apache.log4j.Logger;

/**
 *
 * RecordIdentifier: reflects the metadata of a OAI record identifier
 */
public class RecordIdentifier {
    private Date dateStamp;
    private String identifier;
    private String set;
    private String modifiedLong;
    private boolean deleted;
    static Logger logger = Logger.getLogger(RecordIdentifier.class);

    public RecordIdentifier(String identifierLine) throws ParseException, OAIException {
        String[] parts = identifierLine.split(";");
        if(parts.length > 0 && parts[0] != null)
            this.identifier = parts[0];
        if(parts.length > 1 && parts[1] != null) {
            this.dateStamp = new SimpleDateFormat("yyyy-MM-dd").parse(parts[1]);
            this.modifiedLong = parts[1];
        } if(parts.length > 2 && parts[2] != null)
            this.set = parts[2];
        if(this.identifier == null || this.dateStamp == null)
            throw new OAIException("Identifierveld of datumveld ontbreekt in: " + identifierLine, new Exception());
    }

    public RecordIdentifier(Node idNode, String dateFormat) throws OAIException {
        try {
            NodeList idNodes = idNode.getChildNodes();
            for(int i = 0; i < idNodes.getLength(); ++i) {
                Node n = idNodes.item(i);
                if(n.getNodeName().equalsIgnoreCase("identifier"))
                    this.identifier = n.getTextContent();
                else if(idNodes.item(i).getNodeName().equalsIgnoreCase("datestamp")) {
                    this.dateStamp = new SimpleDateFormat(dateFormat).parse(n.getTextContent());
                    this.modifiedLong = n.getTextContent();
                } else if(n.getNodeName().equalsIgnoreCase("setSpec"))
                    this.set = n.getTextContent();
            }
            NamedNodeMap attrs = idNode.getAttributes();
            this.deleted = false;
            for(int i = 0; i < attrs.getLength(); ++i) {
                if(attrs.item(i).getNodeName().equalsIgnoreCase("status") && attrs.item(i).getNodeValue().equals("deleted"))
                    this.deleted = true;
            }
        } catch(Exception e) {
            throw(new OAIException("Probleem met verwerken van identifier xml", e));
        }
    }

    public void save(String filename, boolean append) throws IOException {
        if(!deleted) {
            logger.debug("Saving identifier " +  this.identifier + " to file: " + filename);
            FileWriter outputFile = new FileWriter(filename, append);
            BufferedWriter writer = new BufferedWriter(outputFile);
            writer.append(this.toString() + System.getProperty("line.separator"));
            writer.flush();
            writer.close();
            logger.debug("Succesfully saved identifier");
        }
    }

    public String getIdentifier() {
        return identifier;
    }

    public Date getDateStamp() {
        return dateStamp;
    }

    @Override
    public String toString() {
        return this.identifier + ";" + this.modifiedLong + ";" + this.set;
    }

    public String getModifiedLong() {
        return modifiedLong;
    }
    
}
