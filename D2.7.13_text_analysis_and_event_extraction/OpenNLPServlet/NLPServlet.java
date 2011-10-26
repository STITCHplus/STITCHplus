/*
 * NLPServlet.java: Webservice for OpenNLP named entity recognition
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


import java.io.IOException;
import java.io.PrintWriter;
import java.io.BufferedReader;
import java.util.List;
import java.util.LinkedList;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.SocketException;

import java.io.FileInputStream;
import java.io.InputStreamReader;

import opennlp.tools.namefind.NameFinderME;
import opennlp.tools.namefind.TokenNameFinderModel;
import opennlp.tools.sentdetect.SentenceModel;
import opennlp.tools.tokenize.TokenizerModel;
import opennlp.tools.sentdetect.SentenceDetectorME;
import opennlp.tools.tokenize.TokenizerME;
import opennlp.tools.util.Span;
import org.w3c.dom.NodeList;
import org.w3c.dom.Element;

import simplexpath.*;


/**
 *
 * @author R. van der Ark
 */
public class NLPServlet extends HttpServlet {
    // Location of the sentence and token models
    // (http://opennlp.sourceforge.net/models-1.5/)
    private static String resourceDir = "/resources/opennlp/";
    private static String sentenceModel = "nl-sent.bin";
    private static String tokenModel = "nl-token.bin";

    // HashMap containing response formats
    private final static HashMap responseFormats = new HashMap();
    static {
        responseFormats.put("xml", "text/xml;charset=UTF-8");
        responseFormats.put("html", "text/html;charset=UTF-8");
        responseFormats.put("json", "application/json;charset=UTF-8");
        responseFormats.put("text", "text/plain;charset=UTF-8");
    }

    /**
     * Find named entities in an array of sentences
     * @param model the currently used OpenNLP namefinder model (Person, Place, Organisation)
     * @param sentence the array of tokens making up the sentence
     * @param sentenceIndex the index of the current sentence
     * @param names the full list of recognized entities
     * @param type place, person or organisation
     */
    private static List<Entity> find(TokenNameFinderModel model, String[] sentence, int sentenceIndex, List<Entity> names, String type) {
        NameFinderME nameFinder = new NameFinderME(model);
        Span spans[] = nameFinder.find(sentence);
        for(int i = 0; i < spans.length; ++i) {
            String name = "";
            for(int j = spans[i].getStart(); j < spans[i].getEnd(); ++j) {
                name += sentence[j];
                if(j < spans[i].getEnd() - 1)
                    name += " ";
            }
            names.add(new Entity(name, spans[i].getStart(), spans[i].getEnd(), sentenceIndex, type));
        }
        nameFinder.clearAdaptiveData();
        return names;
    }

    /**
     * Prints an XML response
     * @param names the recognised named entities
     * @param tokenizedSentences the complete list of sentences as arrays of tokens
     * @param out the response writer
     * @param altoWords in case alto xml was offered as input
     */
    private static void printXML(List<Entity> names, List<String[]> tokenizedSentences, PrintWriter out, List<AltoString> altoWords) {
        out.println("<?xml version=\"1.0\" ?>");
        out.println("<openNLPResponse>");
        out.println("<entities>");
        for(int i = 0; i < names.size(); ++i)
            out.print(names.get(i).toXML());

        out.println("</entities>");
        for(int i = 0; i < tokenizedSentences.size(); ++i) {
            out.println("<sentence index=\"" + i + "\">");
            for(int j = 0; j < tokenizedSentences.get(i).length; ++j) {
                String token = tokenizedSentences.get(i)[j];
                out.print("<token index=\"" + j + "\"");
                for(int k = 0; k < altoWords.size(); ++k) {
                    AltoString w = altoWords.get(k);
                    if(w.getContent().equals(token) && !w.isFlagged()) {
                        w.setFlagged(true);
                        out.print(
                            " x=\"" + w.getX() + "\"" +
                            " y=\"" + w.getY() + "\"" +
                            " w=\"" + w.getW() + "\"" +
                            " h=\"" + w.getH() + "\""
                        );
                        break;
                    }
                }
                out.println(">" + helpers.xmlEncode(token) + "</token>");
            }
            out.println("</sentence>");
        }
        out.println("</openNLPResponse>");
    }

    /**
     * Prints a JSON response
     * @param names the recognised named entities
     * @param tokenizedSentences the complete list of sentences as arrays of tokens
     * @param out the response writer
     * @param altoWords in case alto xml was offered as input
     */
    private static void printJSON(List<Entity> names, List<String[]> tokenizedSentences, PrintWriter out, List<AltoString> altoWords) {
        out.println("{");
        out.println(" \"entities\": [");
        for(int i = 0; i < names.size(); ++i) {
            out.print(names.get(i).toJSON());
            if(i < names.size() - 1)
                out.println(",");
        }

        out.println("], \"sentences\": [");

        for(int i = 0; i < tokenizedSentences.size(); ++i) {
            out.println("[");
            for(int j = 0; j < tokenizedSentences.get(i).length; ++j) {
                if(altoWords.size() > 1) {
                    String token = tokenizedSentences.get(i)[j];
                    out.print("{\"token\": " + "\"" + token + "\"");
                    for(int k = 0; k < altoWords.size(); ++k) {
                        AltoString w = altoWords.get(k);
                        if(w.getContent().equals(token) && !w.isFlagged()) {
                            w.setFlagged(true);
                            out.print(
                              ", \"x\":" + w.getX() +
                              ", \"y\":" + w.getY() +
                              ", \"w\":" + w.getW() +
                              ", \"h\":" + w.getH()
                            );
                            break;
                        }
                    }
                    out.print("}");
                } else {
                    out.print("\"" + helpers.xmlEncode(tokenizedSentences.get(i)[j]) + "\"");
                }
                if(j < tokenizedSentences.get(i).length - 1)
                    out.print(",");
            }
            out.println("]");
            if(i < tokenizedSentences.size() - 1)
                out.println(",");
        }
 
        out.println("]}");
    }

    /**
     * Prints an HTML response
     * @param names the recognised named entities
     * @param sent the complete list of sentences as arrays of tokens
     * @param out
     */
    private static void printHTML(List<Entity> names, List<String[]> sent, PrintWriter out) {
        out.println("<html><head></head><body>");
        for(int sentIndex = 0; sentIndex < sent.size(); ++sentIndex) {
            String tokens[] = sent.get(sentIndex);
            int skip = 0;
            for(int tokenIndex = 0; tokenIndex < tokens.length; ++tokenIndex) {
                for(int i = 0; i < names.size(); ++i) {
                    Entity w = names.get(i);
                    if(w.getStartIndex() == tokenIndex && w.getSentenceIndex() == sentIndex) {
                        skip = w.getEndIndex() - w.getStartIndex();
                        out.print("<a href=\"#\" title=\"" + w.getType() + "\">" + w.getWord() + "</a> ");
                        break;
                    }
                }
                if(skip == 0)
                    out.print(tokens[tokenIndex] + " ");
                else
                    skip--;
            }
        }
        out.println("</html>");
    }

    /** 
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code> methods.
     * @param request servlet request ([format: response format, mode: can be alto xml as input], url: url to the text to be analyzed)
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        String format = request.getParameter("format");
        String mode = request.getParameter("mode");
        if(format == null || responseFormats.get(format) == null) format = "xml";
        if(mode == null) mode = "default";
        response.setContentType((String) responseFormats.get(format));
        PrintWriter out = response.getWriter();
        try {
            URL url = new URL(request.getParameter("url"));
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            String content = "", line = "";
            List<AltoString> altoWords = new LinkedList();
            if(mode.equals("alto")) {
                XpathParser parser = new XpathParser(url.openStream());
                NodeList inWords = parser.parse("//String");
                for(int i = 0; i < inWords.getLength(); ++i) {
                    Element inWord = (Element) inWords.item(i);
                    altoWords.add(new AltoString(
                            inWord.getAttribute("CONTENT"),
                            Integer.parseInt(inWord.getAttribute("HPOS")),
                            Integer.parseInt(inWord.getAttribute("VPOS")),
                            Integer.parseInt(inWord.getAttribute("WIDTH")),
                            Integer.parseInt(inWord.getAttribute("HEIGHT"))
                    ));
                    content += inWord.getAttribute("CONTENT") + " ";
                }
                
            } else {
                BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                while((line = reader.readLine()) != null)
                    content += line.replaceAll("\\<.*?>"," ").replaceAll("^", " ").replaceAll("/", " ");
            }
            conn.disconnect();

            SentenceModel sentModel = new SentenceModel(new FileInputStream(resourceDir + sentenceModel));
            TokenizerModel tokModel = new TokenizerModel(new FileInputStream(resourceDir + tokenModel));

            TokenNameFinderModel personModel = new TokenNameFinderModel(new FileInputStream(resourceDir + "nl-ner-person.bin"));
            TokenNameFinderModel miscModel = new TokenNameFinderModel(new FileInputStream(resourceDir + "nl-ner-misc.bin"));
            TokenNameFinderModel locationModel = new TokenNameFinderModel(new FileInputStream(resourceDir + "nl-ner-location.bin"));
            TokenNameFinderModel organisationModel = new TokenNameFinderModel(new FileInputStream(resourceDir + "nl-ner-organization.bin"));
            SentenceDetectorME sentenceDetector = new SentenceDetectorME(sentModel);
            TokenizerME tokenizer = new TokenizerME(tokModel);

            String sentences[] = sentenceDetector.sentDetect(content);
            List <String[]> tokenizedSentences = new LinkedList();
            List <Entity> words = new LinkedList();

            for(int i = 0; i < sentences.length; ++i) {
                String sentence[] = tokenizer.tokenize(sentences[i]);
                find(personModel, sentence, i, words, "person");
                find(locationModel, sentence, i, words, "location");
                find(miscModel, sentence, i, words, "organization");
                find(organisationModel, sentence, i, words, "misc");
                tokenizedSentences.add(sentence);
            }
            if(format.equals("json")) {
                printJSON(words, tokenizedSentences, out, altoWords);
            } else if(format.equals("html")) {
                printHTML(words, tokenizedSentences, out);
            } else
                printXML(words, tokenizedSentences, out, altoWords);
            
        } catch(MalformedURLException e) {
            response.sendError(400, "URL invalid");
        } catch(SocketException e) {
            response.sendError(400, "Socket exception");
        } catch(IOException e) {
            response.sendError(400, "Input/Output error");
        } catch(SimpleXpathException e) {
            response.sendError(400, "Malformed xml");
        }
    } 

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /** 
     * Handles the HTTP <code>GET</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        processRequest(request, response);
    } 

    /** 
     * Handles the HTTP <code>POST</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        processRequest(request, response);
    }

    /** 
     * Returns a short description of the servlet.
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
