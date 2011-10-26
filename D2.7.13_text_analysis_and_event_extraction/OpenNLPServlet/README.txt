A Wrapper Servlet for the OpenNLP toolkit's namefinder

Code dependencies:
A Servlet container (i.e. Tomcat 6)
opennlp-tools-1.5.0.jar
maxent-3.0.0.jar
See: http://blog.dpdearing.com/2011/05/opennlp-1-5-0-basics-sentence-detection-and-tokenizing/

Resource dependencies:
1/more namefinder model(s), a sentence model and a tokenizer model for OpenNLP
http://opennlp.sourceforge.net/models-1.5/

We used the Alpino trained:
 nl-token.bin
 nl-sent.bin
 nl-ner-*.bin

For more details on Alpino, see:
http://www.let.rug.nl/vannoord/alp/Alpino/

See source of NLPServlet.java for more details
