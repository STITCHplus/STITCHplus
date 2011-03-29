/*
 *    GetRecords main class: latent process to read harvested identifiers and retrieve xml
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

import java.io.File;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;

import java.util.List;
import java.util.LinkedList;

import oai.GetRecord;
import oai.GetRecordException;
import oai.OAIException;

import simplexpath.SimpleXpathException;
import httpget.HttpGetException;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
/**
 *
 * GetRecords main class: latent process to read harvested identifiers and retrieve xml
 */
public class GetRecords {

    /**
     * Main method: does GetRecord request to OAI endpoint in configuration file
     * and saves record xml until max records is reached
     * @param args:
     *  0: Base storage directory of the harvester (containing log4j.conf)
     *  1: Subdirectory containing the retrieved xml for the current owner
     *  2: Maximum amount of records to store
     * 
     * Will only run when harvester status is not set to "harvest_identifiers"
     * see text file: /base/dir/owner/status
     */
    static Logger logger = Logger.getLogger(GetRecords.class);
    public static void main(String[] args) {
        PropertyConfigurator.configure(args[0] + "/log4j.conf");
        try {
            HarvesterConfig config = new HarvesterConfig(args[0] + args[1]);
            int maxDocs = Integer.parseInt(args[2]);
            while(true) {
                if(!new File(config.getBaseDir() + "/status").exists()) continue;

                if(!new File(config.getBaseDir() + "/identifiers").exists()) continue;

                if(new File(config.getBaseDir() + "/identifiers").length() == 0) continue;

                int processingRecordCount = countRecords(args[0] + args[1]);

                if(processingRecordCount >= maxDocs) continue;

                int nDocs = maxDocs - processingRecordCount;
                HarvesterStatus status = new HarvesterStatus(args[0] + args[1] + "/status");
                if(status.checkState(HarvesterStatus.STATE_HARVEST_IDENTIFIERS)) continue;

                status.setState(HarvesterStatus.STATE_GETRECORD);
                BufferedReader identifiers = new BufferedReader(new FileReader(config.getBaseDir() + "/identifiers"));
                List<String> remainingRecords = new LinkedList<String>();
                for(int i = 0; i < nDocs ; ++i) {
                    String nextLine = identifiers.readLine();
                    if(nextLine == null) break;
                    logger.info(nextLine);
                    String identifierLine = nextLine.trim();
                    String[] parts = identifierLine.split(";");
                    String recordDir = config.getBaseDir() + "/" + replaceIllegalFileChars(parts[0]);
                    if(new File(recordDir).exists() || new File(recordDir).mkdir())
                        logger.debug("Succesfully created directory: " + recordDir);
                    else
                        throw new IOException("Kon geen directory aanmaken voor record: " + recordDir);

                    try {
                        GetRecord record = new GetRecord(identifierLine, recordDir, config);
                        record.retrieve();
                        record.saveMetadata();

                    } catch(SimpleXpathException e) {
                        remainingRecords.add(identifierLine);
                        logger.error("Fout bij parsen oai response: " + identifierLine, e);
                    } catch(HttpGetException e) {
                        remainingRecords.add(identifierLine);
                        logger.error("Fout bij ophalen recordmetadata: " + identifierLine, e);
                    }  catch(GetRecordException e) {
                        logger.info("Caught non-fatal exception: " + e.getMessage());
                        logger.info("Deleting dir: " + recordDir);
                    }
                }
                String nextLine;
                while((nextLine = identifiers.readLine()) != null)
                    remainingRecords.add(nextLine.trim());
                identifiers.close();
                BufferedWriter idWriter = new BufferedWriter(new FileWriter(config.getBaseDir() + "/identifiers", false));
                for(int i = 0; i < remainingRecords.size(); ++i) {
                    String line = remainingRecords.get(i);
                    idWriter.append(line + System.getProperty("line.separator"));
                    idWriter.flush();
                }
                idWriter.close();
                status.setState(HarvesterStatus.STATE_IDLE);
            }
        } catch(IOException e) {
            logger.fatal("Fout bij lezen/schrijven", e);
        } catch(OAIException e) {
            logger.fatal("Fout bij laden configuratiebestand", e);
        }
    }

    private static int countRecords(String dir) {
        return new File(dir).list().length - 3;
    }
    
    public static String replaceIllegalFileChars(String fileName) {
        fileName = fileName.replaceAll("\\W|_", "-");
        while(fileName.contains("--"))
            fileName = fileName.replaceAll("--", "-");

        return fileName;
    }
}
