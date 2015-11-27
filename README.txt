_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-

Progetto Lisp A.A. 2014 / 2015.
Cognome: Manfredelli
Nome: Mauro
Matricola: 781266

_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-

Le prime istruzioni sono quelle date e servono per la define-class e la 
gestione dei metodi.
Le funzioni sono descritte nell'ordine con cui appaiono nel codice.
________________________________________________________________________________

Le principali funzioni da utilizzare sono tre: define-class, new e get-slot.
Per quanto riguarda i metodi, si possono invocare con istanze per cui il metodo 
è definito, eventualmente aggiungendo dei parametri, usando la seguente forma:
(<method-name> <istanza> <patrametri>) dove i parametri non devono essere
espressi sotto forma di lista, ma uno di seguito all'altro.
________________________________________________________________________________

define-class definisce la struttura di una classe e la memorizza in 
una locazione centralizzata (una variabile globale).
'(' define-class <class-name> <parent> <slot-value>* ')'
<class-name> sarà il nome della classe, <parent> la classe genitore (se
presente, nil altrimenti), <slot-value> sono gli attributi o metodi
della classe (utilizzo &rest perchè una classe può non avere attributi
oppure averne un numero indefinito).
Se dopo aver definito una classe ho intenzione di cambiare le sue specifiche,
non è necessario cancellare la classe, ma basta richiamare define-class con 
lo stesso class-name e la vecchia classe verrà sovrascritta con quella nuova.
Solitamente quando si dichiara la classe gli attributi sono inizializzati 
con valori di default come "undefine". 
Nelle definizioni è importante l'ultilizzo del quote altrimenti si genereranno
errori.
________________________________________________________________________________

prepara-slots è una funzione ausiliaria di define-class e new.
Il suo scopo è quello di preparare gli slots degli attributi della classe
unendo quelli del parent e quelli del figlio, stando attenta alle ridefinizioni
del figlio.
Per i metodi lo slot sarà diverso e dunque utilizza una funzione apposita 
d'ausilio. 
________________________________________________________________________________

controllo-slots è una funzione ausiliaria della prepara-slots e serve a 
verificare se un attributo della classe figlia è presente anche nel parent.
Se è presente torna true altrimenti nil.
________________________________________________________________________________

rimuovi-slots è una funzione ausiliaria della prepara-slots e serve a
rimuovere dalla lista del parent, lo slot uguale a quello passato.
La lista ritornata avrà uno slot in meno.
________________________________________________________________________________

riempi-slots è una funzione ausiliaria di define-class e new.
Il suo scopo è quello di scrivere gli attributi nella forma:
((chiave valore) (chaive valore)...) come dato dalle specifiche.
Se la lista che passata ha lunghezza dispari, allora è impossibile
scriverla nella forma a coppie.
________________________________________________________________________________

new: crea una nuova istanza di una classe. La sintassi è:
'(' new <class-name> [<slot-name> <value>]* ')'
dove <class-name> e <slot-name> sono simboli, mentre <value> è un qualunque 
valore Common Lisp.
Il valore ritornato da new è la nuova istanza di <class-name>.
Ogni istanza inizia con 'ool-instance ed è nella forma di lista.
Se essa non inizia con 'ool-instance il programma la riconoscerà come istanza
valida.
________________________________________________________________________________

get-slot: estrae il valore di un campo da una classe. La sintassi è:
'(' 'get-slot' <instance> <slot-name> ')'
dove <instance> è una istanza di una classe e <slot-name> è un simbolo.
Il valore ritornato è il valore associato a <slot-name> nell'istanza 
(tale valore potrebbe anche essere ereditato dalla classe o da uno dei suoi 
antenati). Se <slot-name> non esiste nella classe dell'istanza 
(ovvero se non è ereditato) allora viene segnalato un errore.
Non si fa uso di funzioni d'appoggio, ma solo di ricorsione su instance.
________________________________________________________________________________

forse-method è una funzione ausiliaria della prepara-slots.
Serve a trattare con particolare attenzione le funzioni che dovrò scrivere
nella forma (nome-metodo (method ((parametri) corpo))). Al suo interno
uso la funzione process-method.
________________________________________________________________________________

process-method è una funzione che serve a definire il metodo in modo tale
da renderlo utilizzabile da prompt.
Crea una funzione anonima "trampolino" a cui aggiunge come parametro 'this'
(istanza corrente) e le assegna il method-name (in questo modo posso trattare
i metodi come se fossero delle funzioni).
________________________________________________________________________________

rewrite-method-code la uso per inserire nei parametri del metodo il valore this
per poter usare gli attributi dell'istanza. Al sui interno utilizzo anche la
funzione correggi-args che serve ad evitare che all'interno della lista
ci siano delle ripetizioni di argomenti.
________________________________________________________________________________

Gli errori sono gestiti con appositi messaggi per evidenziare in che punto del
codice l'esecuzione è fallita. Alcuni possono sembrare ridondanti, ma in realtà
servono per evidenziare errori di diverse esecuzioni.
I punti chiave del codice sono spiegati da appositi commenti.
________________________________________________________________________________
End of file.