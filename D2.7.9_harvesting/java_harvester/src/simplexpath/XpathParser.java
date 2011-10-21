/*
 *    XPathParser: wrapper class for doing xpath statements on XML easily
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
package simplexpath;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathFactory;
import javax.xml.xpath.XPathConstants;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.Result;
import javax.xml.transform.stream.StreamResult;
import javax.xml.namespace.NamespaceContext;
import org.w3c.dom.NamedNodeMap;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Element;
import java.io.InputStream;
import java.io.File;

/**
 *
 * XPathParser: wrapper class for doing xpath statements on XML easily
 */
public class XpathParser {
    private Document doc;
    private XPath xpath;

    public XpathParser(InputStream inputSource) throws SimpleXpathException {
        init(inputSource, null);
    }

    public XpathParser(InputStream inputSource, NamespaceContext nsCtx) throws SimpleXpathException {
        init(inputSource, nsCtx);
    }

    private void init(InputStream inputSource, NamespaceContext nsCtx) throws SimpleXpathException {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            if(nsCtx == null) factory.setNamespaceAware(false);
            else factory.setNamespaceAware(true);
            doc = factory.newDocumentBuilder().parse(inputSource);
            xpath = XPathFactory.newInstance().newXPath();
            if(nsCtx != null) xpath.setNamespaceContext(nsCtx);
        } catch(Exception e) {

            throw new SimpleXpathException("Probleem met lezen XML", e);
        }
    }

    public NodeList parse(String expression) throws SimpleXpathException {
        try {
            XPathExpression expr = xpath.compile(expression);
            return (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
        } catch(Exception e) {
            throw new SimpleXpathException("Probleem met lezen XML", e);
        }
    }

    public String firstHit(String expression) throws SimpleXpathException {
        try {
            return (String) parse(expression).item(0).getNodeValue();
        } catch(NullPointerException e) {
            return null;
        }        
    }

    public void saveNodeContent(String expression, String filename) throws SimpleXpathException {
        try {
            Element root = (Element) parse(expression).item(0);

            // Add namespace declarations from the document root to the new root node
            Element docRoot = doc.getDocumentElement();
            NamedNodeMap attributes = docRoot.getAttributes();
            for(int i = 0; i < attributes.getLength(); ++i) {
                if(attributes.item(i).getNodeName().startsWith("xmlns:"))
                    root.setAttributeNS("http://www.w3.org/2000/xmlns/", attributes.item(i).getNodeName(), attributes.item(i).getNodeValue());
            }

            DOMSource source = new DOMSource(root);
            File file = new File(filename);
            Result result = new StreamResult(file);
            Transformer xformer = TransformerFactory.newInstance().newTransformer();
            xformer.setOutputProperty(OutputKeys.INDENT, "yes");
            xformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
            xformer.transform(source, result);
        } catch(Exception e) {
            e.printStackTrace();
            throw new SimpleXpathException("Probleem met lezen/schrijven XML", e);
        }
    }
}
