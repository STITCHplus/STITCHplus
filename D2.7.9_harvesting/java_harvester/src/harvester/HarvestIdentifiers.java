/*
 *    HarvestIdentifiers main class: scheduled job to retrieve identifier list from OAI endpoint
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

import oai.ListIdentifiers;
import oai.OAIException;
import java.io.File;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

/**
 * HarvestIdentifiers main class: scheduled job to retrieve identifier list from OAI endpoint
 */
public class HarvestIdentifiers {

    /**
     * Main method: does ListIdentifier requests to OAI endpoint in configuration file
     * and saves identifiers until there is no more resumption token
     * @param args:
     *  0: Base storage directory of the harvester (containing log4j.conf)
     *  1: Subdirectory containing the retrieved identifiers for the current owner
     *
     * Will only run when harvester status is not set to "get_records"
     * see text file: /base/dir/owner/status
     */
    static Logger logger = Logger.getLogger(HarvestIdentifiers.class);
    public static void main(String[] args) {
        PropertyConfigurator.configure(args[0] + "/log4j.conf");
        try {            
            HarvesterConfig config = new HarvesterConfig(args[0] + args[1]);
            HarvesterStatus status;
            if(new File(args[0] + args[1] + "/status").exists())
                status = new HarvesterStatus(args[0] + args[1] + "/status");
            else
                status = new HarvesterStatus(config);

            if(!status.checkState(HarvesterStatus.STATE_GETRECORD)) {
                status.setState(HarvesterStatus.STATE_HARVEST_IDENTIFIERS);
                status.save();
                ListIdentifiers identifierList = new ListIdentifiers(config, status);
                boolean moreRecords = identifierList.retrieveList();
                while(moreRecords) {
                    identifierList.save();
                    moreRecords = identifierList.retrieveList();
                }
                status.setState(HarvesterStatus.STATE_IDLE);
                status.save();
            } else {
                logger.info("Harvester not started: currently retrieving records");
            }
        } catch(OAIException e) {
            logger.fatal("Er is een fout opgetreden", e);
        } catch(Exception e) {
            logger.fatal("Er is een fout opgetreden", e);
        }
    }
}
