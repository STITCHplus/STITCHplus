D2.7.11.1: Matching persoonsnamen met VIAF

Bevat ruby bronmodules voor:
 - Het doen van een zoekvraag bij VIAF open search naar een label
 - Het matchen van de teruggegeven labels (preferred en alternative) met het lokale label
 - Het matchen van geboortejaar en jaar van overlijden tussen lokaal en VIAF authority data

Gebruik:
-------
De ViafMatcher module kan vanuit een ruby script worden aangeroepen als volgt:
ViafMatcher.scores(labels, year_of_birth, year_of_death[, is_verbose, delay])

Voorbeeld
scores = ViafMatcher.scores(["naam a", "naam b", "naam c"], 1913, 1945)

De returnwaarde ziet er als volgt uit:
scores = [
 {:score => 77, :label => "naam a", :uri => "http://viaf.org/foo/bar/"},
 {:score => 50, :label => "naam saa", :uri => "http://viaf.org/foo/bar/"},
]
