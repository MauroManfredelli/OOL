;;;; Manfredelli Mauro 781266
;;;; Linguaggi di programmazione
;;;; Progetto Lisp 2014-15
;
; Queste prime tre istruzioni sono prese dal pdf 
; e verranno usate dalle principali funzioni del progetto
;
; Le classi diventano delle variabili globali con una hash-table assocciata
(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
    (setf (gethash name *classes-specs*) class-spec))

(defun get-class-spec (name)
    (gethash name *classes-specs*))
;
; define-class definisce la struttura di una classe e la memorizza in 
; una locazione centralizzata (una variabile globale).
; '(' define-class <class-name> <parent> <slot-value>* ')'
; <class-name> sarà il nome della classe, <parent> la classe genitore (se
; presente, nil altrimenti), <slot-value> sono gli attributi o metodi
; della classe (utilizzo &rest perchè una classe può non avere attributi
; oppure averne un numero indefinito).
;  
(defun define-class (class-name parent &rest slot-value)
  ; i primi sono controlli per l'errore:
  (cond ((or (not (symbolp class-name))    ; verifico se class-name 
             (not (symbolp parent))        ; e parent hanno valori corretti,
             (null class-name))		   ; altrimenti errore.
         (error "ERRORE: class-name o parent non validi"))
        
        ((equalp class-name parent)		; una classe non può essere
         (error "ERRORE: class-name = parent")) ; parent di se stessa
        
        ((and (not (null parent))               ; se il parent non è nil
              (null (get-class-spec parent)))   ; deve avere delle specifiche
         (error "ERRORE: parent non valido")
         )
        ; se non ho trovato errori allora :
        (T        
	 ; con remash rimuovo una chiave/valore;
	 ; effetto: la definizione della vecchia classe viene rimossa.
         ; e aggiungo quella nuova. 
         (remhash class-name *classes-specs*) 
	 ; uso progn per eseguire più linee di codice
	 ; e ritornare il risultato dell'ultima, ossia class-name
	 ; come richiesto.
         (progn
	   ; utilizzo add-class-spec per definire la classe :
           (add-class-spec class-name
			   ; i primi due valori sono il nome della classe
			   ; e il parent
                           (list class-name parent
				; mi appoggio a prepara-slots per scrivere
				; gli attributi e metodi nella forma corretta
				; insieme alla riempi-slots.
                                 (prepara-slots
				 ; questo 'giro' serve a prendere i 
				 ; parametri del parent.
                                  (car (cdr (cdr (get-class-spec parent))))
                                  (riempi-slots slot-value)
                                  )
                                 )
                           
                           )
           
           class-name   ; ritorno il nome della classe (progn)
           
           )
         )
        )
  )
;
; Le liste passate sono lp attributi del parent e ls attributi del figlio.
; Rimuovo dal parent gli attributi e metodi ridefiniti nel figlio.
;
(defun prepara-slots (lp ls)
  ;  serie di condizioni:
  (cond ((and (null lp) (null ls))  ; entrambe le liste vuote
         nil)			    ;  ho finito.
        
        ((null lp)				; lp vuota finisco di 
         (cons (forse-method (car ls))		; copiare ls.
               (prepara-slots NIL (cdr ls)))
         )
        
        ((null ls)				; ls vuota
         (cons (forse-method (car lp))		; finisco di copiare lp
               (prepara-slots (cdr lp) NIL))
         )
        
        (T						
         (cond ((controllo-slots lp (car (car ls))) ; mi appoggio a 
						    ; controllo-slots.
		; se ho un metodo, esso avrà un trattamento speciale
		; con forse-method (se non lo è ritorno lo slot inalterato).
                (cons (forse-method (car ls))		
		      ; ricorsione in coda.
                      (prepara-slots
		       ; rimuovo l'attributo duplicato. 
                       (rimuovi-slots lp (car (car ls)))
                       (cdr ls))
                      ))
		   ; non ho duplicazione dunque non utilizo rimuovi-slots.
               (T
                (cons (forse-method (car ls))
                      (prepara-slots lp (cdr ls))
                      ))
               )
         )
        )
	; alla fine di questa funzione la classe è definita con successo.
  )
;
; controllo-slots ritorna true se nella lista di attributi 'l', compare
; anche x, altrimenti torno nil.
; utile per gestire i duplicati e ridefinizioni. 
;
(defun controllo-slots (l x)
  (cond ((not (symbolp x))	; lo slot passato deve essere  valido
         (error "ERRORE: slot-name non valido"))
        
        ((null l) nil)	; per terminare la ricorsione:
                        ; non ho trovato  uno slot-name uguale a x
        (T (cond ((equalp (car (car l)) x) ; se il primo elemento della 
					   ; lista ha slot-name uguale a x
                  T)			   ; torno true.
             
                 (T (controllo-slots (cdr l) x)); ripeto il controllo
						; ricorsivamente sul resto 
             )					; della lista.
           )
          )
  )
;
; Utilizzo rimuovi-slots nella prepara-slots:
; lo slot 'x' è ridefinito dal figlio dunque lo elimino dal parent per 
; evitare di avere duplicati. 'l' è la lista degli slot del parent, 'x' lo
; slot da rimuovere. Lo slot 'x' dovrebbe essere presente per il controllo
; effettuato dalla controllo-slots.
;
(defun rimuovi-slots (l x)
  (cond ((null l) nil)	; condizione per terminare la ricorsione
        (T (cond ((equalp (car (car l)) x)  ; ho trovao lo slot da rimuovere
                  
                  (rimuovi-slots (cdr l) x))	; non copio il (car l) per
						; rimuoverlo
                 (T (cons (car l)		; altrimenti mantengo (car l)
                          (rimuovi-slots (cdr l) x)))	; e continuo 
                 )				; ricorsivamente sulla coda
           )
        )
  )
;
; riempi-slots prende come parametro una lista che dovrò scrivere nella forma:
; ((chiave1 . valore1) (chiave2 . valore2) ...). Il caso dei metodi è gestito
; nella prepara-slots.
;
(defun riempi-slots (l)
  (cond ((null l) NIL)	; lista vuota torno nil
        
	; se la lista ha lunghezza pari allora è impossibile scrivere i valori
	; nella forma specificata sopra.
        ((oddp (length l))
        (error "ERRORE: impossibile scrivere i valori nella forma desiderata"))
        
	; se invece è tutto corretto
        ((symbolp (car l))
	; definisco il primo slot
         (cons (cons (car l) 
                     (car (cdr l))
                     )
		     ; e ricorsivamente tutti gli altri.
               (riempi-slots (cdr (cdr l)))
               )
         )
        ; se il controllo precedente non va a buon fine, errore.
        (T (error "ERRORE: formato di uno slot non valido"))
        )
  )
;
; new: crea una nuova istanza di una classe. La sintassi è:
; '(' new <class-name> [<slot-name> <value>]* ')'
; dove <class-name> e <slot-name> sono simboli, mentre <value> è un qualunque 
; valore Common Lisp.
; Il valore ritornato da new è la nuova istanza di <class-name>.
; Per utilizzarla efficacemente è necesario scrivere:
; (defparameter <istanza> (new 'class-name ...)).
; in questo modo creo un'istanza con identificatore <istanza>.
;
(defun new (class-name &rest slot-value)
  (cond ((get-class-spec class-name) ; la classe deve esistere
         (cons 'ool-instance	     ; ogni istanza inizia con 'ool-instance
               (cons class-name	     ; inserisco il resto.
                     (prepara-slots
                      (car (cdr (cdr (get-class-spec class-name))))
                      (riempi-slots slot-value))
                     )
               )
		; come per define-class genero la lista dei valori nel
		; modo corretto.
         )
        
        (T (error "ERRORE: class-name non definita"))	; non c'è la classe.
        
        )
  )
;
; get-slot: estrae il valore di un campo da una classe. La sintassi è:
; '(' 'get-slot' <instance> <slot-name> ')'
; dove <instance> è una istanza di una classe e <slot-name> è un simbolo.
; Il valore ritornato è il valore associato a <slot-name> nell'istanza 
; (tale valore potrebbe anche essere ereditato dalla classe o da uno dei suoi 
; antenati). Se <slot-name> non esiste nella classe dell'istanza 
; (ovvero se non è ereditato) allora viene segnalato un errore.
; Non si fa uso di funzioni d'appoggio, ma solo di ricorsione su instance.
;
(defun get-slot (instance slot-name)
  (cond ((not (symbolp slot-name))			; solito controllo.
         (error "ERRORE: slot-name non valido"))	
        
        ((not (equalp 'ool-instance (car instance))); se non inizia con
         (error "ERRORE: istanza non corretta"))    ; ool-instance allora
                                                    ; non è un'istanza.
        ((null (cdr (cdr instance)))		    ; ho finito di esaminare
         (error "ERRORE: slot-name non trovato"))   ; l'istanza e dunque
						    ; lo slot-name non esiste
	; ho trovato lo slot-name:
        ((equalp (car (car (cdr (cdr instance)))) slot-name)
		; il valore assocciato a slot-name è un atomo dunque lo ritorno 
		; semplicemente.
         (cond ((atom (cdr (car (cdr (cdr instance))))) 
                (cdr (car (cdr (cdr instance)))))	
        
		; lo slot-name è associato a un metodo
		; torno "method".
               ((equalp 'method (car (cdr (car (cdr (cdr instance))))))
                (car (cdr (cdr (car (cdr (cdr instance)))))))
                ; se è un'altra cosa (come per esempio un'istanza)
		; la ritorno semplicemente.
               (T (cdr  (car (cdr (cdr instance)))))
               
               )
         )
        ; lo slot che sto guardando adesso non è quello che cerco
	; ma mi è restato ancora qualcosa da esaminare
	; tolgo lo slot che ho già esaminato e continuo ricorsivamente
        (T (get-slot (cons 'ool-instance  
                         (cons (car (cdr instance)) (cdr (cdr (cdr instance))))
                         )
                     slot-name
                     )
           )
	; devo ricordarmi 'ool-instance altrimenti il tentativo successivo
	; va in errore perchè non riconosce l'istanza.
        )
  )
;
; Utilizzo forse-method nella prepara-slots per inserire i metodi nella
; forma corretta:
; (<nome-metodo> (method ((this e parametri)...corpo del metodo...)))
; Sarà possibile invocare il metodo scrivendo:
; (<method-name> <istanza> <parametri>) 
; potrebbero non esserci parametri (il this è aggiunto dal programma).
;
(defun forse-method (slotm)
  (cond ((and (listp (cdr slotm))		; se lo slot che gli passo
              (equalp 'method (cadr slotm)))	; ha le caratteristiche di un 
						; metodo
         (append (list (car slotm)		; lo scrivo nella forma scritta
                       'method)			; sopra usando anche la 
                 (list (process-method		; process-method
                        (car slotm)
                        (cdr (cdr slotm)))
                       )
                 )
         )
        
        (T slotm)	; se lo slot non è un metodo allora lo ritorno 
			; senza farci niente
        )
  )
;
; process-method scrive il codice necessario all'utilizzo del metodo.
; Utilizzo setf e fdefinition per associare method-name alla funzione anonima
; che costruisco con lambda.
; Questa funzione avrà come parametri sicuramente 'this' (che sarà l'istanza
; su cui chiamo il metodo) e degli altri argomenti.
; Uso aplly per applicare il metodo (funzione) che si chiama method-name 
; (per le istruzioni precedenti setf e fdefinition) all' istanza 'this' 
; e agli args.
;
(defun process-method (method-name method-spec)
  (setf (fdefinition method-name)
    (lambda (this &rest args)
      (apply (get-slot this method-name)
             (append (list this) args)
             )
      )
    )
  
  (eval (rewrite-method-code method-name method-spec))
  )
;
; rewrite-method-code prende come parametri il nome del metodo e una lista
; method-spec. Inserisce this come primo argomento.
;
(defun rewrite-method-code (method-name method-spec)
  (cond ((not (symbolp method-name))                ; nome del metodo deve
         (error "ERRORE: method-name non valido"))  ; essere valido

        ((functionp (car method-spec))  ; funzione già definita.
         (car method-spec))
    
        (T
         (append (list 'lambda
                       (cond ((not (null (car method-spec)))
			; correggi-args per evitare duplicati anche 
			; negli argomenti.
                              (correggi-args
                               ; sotto-condizione
                               ; per verificare la
                               ; presenza del this
                               (cond ((and (listp (car method-spec))
                                           (not (equalp 
                                             'this (car (car method-spec)))))

                                   (append '(this) (car method-spec)))
                                 ; se non c'è lo inserisco io.
                                 (T (car method-spec))
                                 )
                               ))
                    
                         (T (list 'this))
                         
                         )
                       )
                 (cdr method-spec)
                 )
         )
        )
  )
;
; Nella rewrite-method-code uso questa funzione per evitare di avere 
; ripetizioni. Se non ci sono la lista di output è come quella di input.
; 
(defun correggi-args (l)
  (cond ((null l) nil)
        ; uso la ricorsione come al solito.
        ((listp l)
         (cond ((not (member (car l) (cdr l)))
             
                (cond ((symbolp (car l))
                 
                       (cons (car l)
                             (correggi-args (cdr l))))
               
                  (T (error "ERRORE: arg non valido"))
                  ))
           
           (T (error "ERRORE: argomenti ripetuti"))
           )
         )
        ; meglio accertarsi che slot-args siano corretti.
        (T (error "ERRORE: slot-args non accettabili"))
        
        )
  )
;
; end of file.