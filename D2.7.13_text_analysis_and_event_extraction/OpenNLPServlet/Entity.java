/*
 * Entity.java: Represents an OpenNLP Named Entity
 * Copyright (C) 2011 R. van der Ark, Koninklijke Bibliotheek - National Library of the Netherlands
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>..
 */

/**
 *
 * @author R. van der Ark
 */
public class Entity {
    private String word, type;
    private int startIndex;
    private int endIndex;
    private int sentenceIndex;
    
    public Entity(String word, int startIndex, int endIndex, int sentenceIndex, String type) {
        this.word = word;
        this.startIndex = startIndex;
        this.endIndex = endIndex;
        this.sentenceIndex = sentenceIndex;
        this.type = type;
    }

    public int getSentenceIndex() {
        return sentenceIndex;
    }

    public String getType() {
        return type;
    }

    public int getEndIndex() {
        return endIndex;
    }

    public int getStartIndex() {
        return startIndex;
    }

    public String getWord() {
        return word;
    }

    public String toXML() {
        String retVal = "<" + this.type + " startindex=\"" + this.startIndex + "\" endindex=\"" + this.endIndex + "\" sentenceindex=\"" + this.sentenceIndex + "\">";
        retVal += helpers.xmlEncode(this.word);
        retVal += "</" + this.type + ">\n";
        return retVal;
    }

    public String toJSON() {
        String retVal = "{ \"type\": \"" + this.type + "\",";
        retVal += "\"start_index\": " + this.startIndex + ",";
        retVal += "\"end_index\": " + this.endIndex + ",";
        retVal += "\"sentence_index\": " + this.sentenceIndex + ",";
        retVal += "\"entity\": \"" + helpers.xmlEncode(this.word) + "\"}";
        return retVal;
    }
}
