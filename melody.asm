.model small
.data
        ; ------- I/O -------
        podajPlik           db 'Podaj nazwe pliku z melodia (wraz z rozszerzeniem)', 13, 10, '$'
        bladNazwyPliku      db 'Nie znaleziono pliku o podanej nazwie! Upewnij sie, ze plik istnieje i ze podajesz prawidlowa nazwe', 13, 10, '$'
        bladOtwarciaPliku   db 'Pliku nie mozna otworzyc! Upewnij sie, ze wskazujesz poprawny plik i ze posiadasz odpowiednie uprawnienia', 13, 10, '$'
        bladZamknieciaPliku db 'Plik nie mogl zostac poprawnie zamkniety.', 13, 10, '$'
        bladOdczytuPliku    db 'Podczas odczytu pliku wystapil blad. Upewnij sie, ze wskazujesz poprawny plik i ze posiadasz odpowiednie uprawnienia', 13, 10, '$'
        
        nazwaPliku          db 13, ?, 13 dup(0)     ; Bufor przechowujący nazwę pliku podaną przez użytkownika (max 12 znaków)
        uchwytPliku         dw ?
        czytanyZnak         db ?
        buforOdczytu        db 1024 dup(0)          ; Bufor odczytu przechowujący wszystkie odczytane znaki
        
        ; ----- Melodia -----
        
        ; Komunikaty o błędach w kodzie RTTTL
        bladSkladniRTTTL    db 'Blad w skladni kodu RTTTL! Odtwarzanie przerwane.', 13, 10, '$'
        tytulZaDlugi        db 'Tytul podany w 1-wszym segmencie kodu RTTTL jest za dlugi! Maksymalna dlugosc to 10. Odtwarzanie przerwane.', 13, 10, '$'
        zlaDomDlugoscNuty   db 'Domyslna dlugosc nuty podana w 2-gim segmencie kodu RTTTL jest niepoprawna! Dozwolone wartosci to: 1, 2, 4, 8, 16, 32. Odtwarzanie przerwane.', 13, 10, '$'
        zlaDomyslnaOktawa   db 'Domyslna oktawa podana w 2-gim segmencie kodu RTTTL jest niepoprawna! Dozwolone wartosci to liczby calkowite z przedzialu 4-7. Odtwarzanie przerwane.', 13, 10, '$'
        zleDomyslneTempo    db 'Domyslne tempo podane w 2-gim segmencie kodu RTTTL jest niepoprawne! Dozwolone wartosci to liczby calkowite z przedzialu 1-900. Odtwarzanie przerwane.', 13, 10, '$'
        zlaDlugoscNuty      db 'Dlugosc nuty podana w 3-cim segmencie kodu RTTTL jest niepoprawna! Dozwolone wartosci to: 1, 2, 4, 8, 16, 32. Odtwarzanie przerwane.', 13, 10, '$'
        zlyTon              db 'Ton podany w 3-cim segmencie kodu RTTTL jest niepoprawny! Dozwolone wartosci to: a, a#, b, c, c#, d, d#, e, f, f#, g, g#. Odtwarzanie przerwane.', 13, 10, '$'
        zlaOktawa           db 'Oktawa podana w 3-gim segmencie kodu RTTTL jest niepoprawna! Dozwolone wartosci to liczby calkowite z przedzialu 4-7. Odtwarzanie przerwane.', 13, 10, '$'
        
        ; Częstotliwości dźwięków w 4 oktawie
        c                   equ 4561                ; 1 193 180 Hz (podstawowa częstotliwość PC Speakera) / 261,63 Hz (częstotliwość C4)
        cis                 equ 4305
        d                   equ 4063                
        dis                 equ 3835
        e                   equ 3620                ; W c-dur nie ma eis ani bis!
        f                   equ 3417
        fis                 equ 3225
        g                   equ 3044
        gis                 equ 2873
        a                   equ 2712
        ais                 equ 2560
        b                   equ 2416

        ; Długości poszczególnych nut
        calaNuta            equ 2                   ; *2, by bezproblemowo dodać kropkę do całej nuty
        polnuta             equ 4
        cwiercnuta          equ 8
        osemka              equ 16
        szesnastka          equ 32
        trzydziestkaDwojka  equ 64
        
        ; Parametry dekodowanego dźwięku
        ton                 dw ?
        dlugoscNuty         db ?
        oktawa              db ?
        tempo               dw ?
        
        ; 1-wszy segment kodu RTTTL
        coJestGrane         db 13, 10, 'Odtwarzam utwor: ', 34, '$'
        tytulUtworu         db 10 dup(0), '$'       ; Maks. dopuszczalna długość tytułu utworu w standardzie RTTTL to 10
        kontrolki           db 13, 10, 'Sterowanie programem:', 13, 10, '[ESC] - wyjscie', 13, 10, '[Space] - pauza', 13, 10, '[-] - zmniejszenie tempa o 5', 13, 10, '[+] - zwiekszenie tempa o 5', 13, 10, '$'
        domyslnaDlugoscNuty db 8                    ; Domyślne wartości w standardzie RTTTL (jeśli w pliku nie podano innych)
        domyslnaOktawa      db 6
        domyslneTempo       dw 120                  ; Maks. dopuszczalne tempo to 900
        
        kolorTla            db ?
         
.stack
        db 256 dup (?)
        
Kod	    segment
        assume cs:Kod
        org 100h
        
        
        

start:              ; Podstawowe czynności początkowe
        mov ax,@data
        mov ds,ax                   ; Ustawienie adresu początku segmentu danych na .data
        mov ax,@stack
        mov ss,ax                   ; Ustawienie adresu segmentu stosu na .stack



filePass:           ; Przekazanie pliku z melodią

        ; Poproszenie o podanie nazwy pliku
        mov ah,9                    ; Funkcja 9h przerwania 21h wyświetlająca ciąg znaków
        lea dx,podajPlik            ; Odczytanie adresu zmiennej przechowującej napis do wyświetlenia
        int 21h                     ; Wywołanie przerwania (wypisanie tekstu do konsoli)
        
        ; Wpisanie do konsoli nazwy pliku
        mov ah,0Ah                  ; Funkcja 0Ah przerwania 21 pobierająca od użytkownika znaki z klawiatury i zapisująca je w buforze o adresie DS:DX (tutaj: zmienna nazwaPliku)
        lea dx,nazwaPliku           ; Ustalenie zmiennej, w której będzie przechowywany input
        int 21h                     ; Wywołanie przerwania (odczyt znaków z klawiatury)
        
        call inputToString          ; Wywołanie funkcji przekształcającej podaną nazwę pliku w łańcuch znaków (by móc ją poprawnie przekazać jako plik do otwarcia)
        
        
       
fileOpen:           ; Otwarcie pliku
        lea dx,nazwaPliku[2]        ; Pobranie nazwy pliku do otwarcia
        mov al,0                    ; Parametr w AL wskazuje na tryb dostępu; 0 oznacza odczyt
        mov ah,3Dh                  ; Funkcja 3Dh przerwania 21 otwierająca plik
        int 21h
        jc fileOpenError            ; Jeśli nie udało się otworzyć pliku (CF=1), przejdź do odpowiedniej procedury

filePrepare:        ; Czynności przygotowujące do odczytu
        lea si,buforOdczytu         ; Ustawienie SI na adres bufora odczytu (przyda się podczas odczytu pliku)
        mov di,si
        add di,1024                 ; DI przechowuje koniec bufora
        mov uchwytPliku,ax          ; W przeciwnym razie skopiuj zawartość AX (uchwyt do otwartego pliku) do zmiennej uchwyt
        mov bx,uchwytPliku          ; Skopiowanie uchwytu do pliku do rejestru BX
        call resetFilePointer       ; Dla pewności resetujemy wskaźnik pliku na początek
        mov cx,1                    ; Zawartość CX określa, ile bajtów pliku ma być odczytane -- czytamy po jednym znaku
        lea dx,czytanyZnak          ; W DX należy umieścić adres zmiennej, w której będzie przechowywany odczytany znak

fileRead:           ; Czytanie z pliku
        mov ah,3Fh                  ; Funkcja 3Fh przerwania 21 czytająca plik o uchwycie przechowywanym w BX
        int 21h
        jc fileReadError            ; Jeśli wystąpił błąd odczytu, CF=1; zwróć komunikat o błędzie
        
        cmp ax,0                    ; AX ustawiany jest na 0 jeśli napotkano koniec pliku...
        je prepareToPlay            ; ...w takiej sytuacji przejdź do kolejnej części programu
        
        mov al,czytanyZnak          ; Skopiowanie do AL odczytanego znaku
        mov [si],al                 ; Wstaw znak do bufora 
        inc si                      ; Zwiększ wskaźnik o 1 (kolejny element bufora)
        cmp si,di                   ; Porównaj z końcem bufora
        jb fileRead                 ; Jeśli OK, odczytaj kolejny znak
        jmp fileReadError           ; Jeśli koniec bufora, zwróć błąd (by zapobiec przepełnieniu)        
    
    
fileOpenError:      ; Zwrócenie błędu w przypadku niepowodzenia otwarcia pliku
        cmp ax,2                    ; Zawartość rejestru AH zawiera kod błędu; 2 oznacza błędną nazwę pliku
        je fileNameError
        
        mov ah,9                    ; Zwrócenie ogólnego powiadomienia o błędzie, jeśli nazwa jest OK
        lea dx,bladOtwarciaPliku
        int 21h
        jmp filePass                ; Poproś jeszcze raz o plik
       
fileNameError:      ; Zwrócenie błędu w przypadku błędnej nazwy pliku
        mov ah,9
        lea dx,bladNazwyPliku
        int 21h
        jmp filePass                ; Poproś jeszcze raz o plik
        
fileReadError:      ; Zwrócenie błędu w przypadku niepowodzenia odczytania pliku
        mov ah,9
        lea dx,bladOdczytuPliku
        int 21h
        jmp filePass                ; Poproś jeszcze raz o plik
        
        

fileClose:          ; Zamknięcie pliku
        mov ah,3Eh                  ; Funkcja 3Eh przerwania 21 zamykająca plik o uchwycie przechowywanym w BX
        int 21h
        jnc prepareToPlay           ; Przejdź do dalszej części programu jeśli CF=0 (brak błędu)

fileCloseError:     ; Zwrócenie błędu w przypadku niepowodzenia zamknięcia pliku
        mov ah,9
        lea dx,bladZamknieciaPliku
        int 21h
        
        

prepareToPlay:
        lea si,buforOdczytu         ; Ustawienie SI na adres początku bufora przechowującego zawartość odczytanego pliku
        
displayTitle:       ; Pobranie i wyświetlenie nazwy utworu (1-wszy segment kodu RTTTL)
        lea di,tytulUtworu          ; Skopiuj adres bufora tytulUtworu do rejestru DI (tam umieszczony zostanie odczytany z pliku tytuł utworu)
        xor cl,cl                   ; Wyzerowanie licznika znaków w tytule
        
        getTitleChar:       ; Pętla iterująca po tytule odczytująca po kolei jego znaki
                mov al,[si]                 ; Skopiuj do AL znak spod adresu SI
                inc cl                      ; Licznik znaków ++
                
                cmp al,':'                  ; Znak ':' oznacza koniec segmentu RTTTL (koniec nazwy utworu)
                je printRest                ; Jeśli takowy zostanie zwrócony, dokończ wypisanie tytułu
                cmp cl,10                   ; Jeśli nie, sprawdź czy koniec bufora tytulUtworu
                ja titleError               ; Jeśli koniec bufora, długość tytułu > 10 -- niezgodne z RTTTL!
                
                mov [di],al                 ; Jeśli OK, wstaw znak do bufora tytulUtworu
                inc si                      ; Przejdź do kolejnego znaku
                inc di                      ; Ustaw wskaźnik na kolejny element w buforze
                jmp getTitleChar
                
        printRest:
                mov al,'$'
                mov [di],al                 ; Jeśli długość tytułu < 10, zakończ string po ostatnim znaku (żeby nie wypisywać niepotrzebnie spacji)
                mov ah,9
                lea dx,coJestGrane          ; 'Odtwarzam utwor: "'
                int 21h
                
                lea dx,tytulUtworu
                int 21h
                
                mov ah,2
                mov dl,34                   ; '"'
                int 21h
                mov dl,13                   ; CR
                int 21h
                mov dl,10                   ; LF
                int 21h
                
                mov ah,9
                lea dx,kontrolki
                int 21h
                
                jmp getDefaults
                
titleError:
        mov ah,9
        lea dx,tytulZaDlugi
        int 21h
        jmp exitToDos
                
                
                
rtttlSyntaxError:
        mov ah,9
        lea dx,bladSkladniRTTTL
        int 21h
        jmp exitToDos
        
getDefaults:        ; Pobranie i zastosowanie ustawień domyślnych (2-gi segment kodu RTTTL)
        inc si                      ; Przesunięcie wskaźnika do początku 2-go segmentu kodu RTTTL
        mov al,[si]                 ; Skopiuj do AL znak spod adresu SI
        cmp al,'d'
        je getDefaultDuration
        cmp al,'o'
        je getDefaultOctave
        cmp al,'b'
        je getDefaultTempo
        cmp al,':'                  ; Koniec 2-go segmentu (brak ustawień domyślnych)
        jne rtttlSyntaxError        ; Jeśli drugi segment nie jest pusty i nie zaczyna się od 'd', 'o' lub 'b' -- niezgodne z RTTTL!
        jmp playNote                ; Jeśli pusty, przejdź do 3-go segmentu
        
        
        
        getDefaultDuration:
                mov domyslnaDlugoscNuty,0   ; Wyzerowanie dom. długości nuty (ponieważ ustawianie polega na dodawaniu kolejnych cyfr)
                add si,2                    ; Przesuń wskaźnik o dwa miejsca dalej (pomiń 'd=')
                xor cl,cl                   ; Wyzerowanie licznika cyfr
                
                getDurationDigit:   ; Pętla iterująca po domyślnej długości nuty odczytująca po kolei jej cyfry
                        mov al,[si]
                        cmp al,','                  ; Znak ',' wskazuje na kolejne ustawienie
                        je getNextDefault
                        cmp al,':'                  ; Koniec 2-go segmentu (podano tylko domyślną długość nuty); zakładamy, że przed separatorem ':' nie może już być przecinka
                        jne setDurationDigit        ; Samo 'je setDefaults' byłoby niestety zbyt dalekim skokiem względnym
                        jmp setDefaults
                        
                        setDurationDigit:
                                inc cl
                                cmp cl,2                    ; Sprawdź, czy wartość ma więcej niż 2 cyfry
                                ja defaultDurationError     ; Jesli tak, zwróć błąd
                                cmp al,'0'                  ; Sprawdź, czy znak jest w ogóle cyfrą
                                jb defaultDurationError     ; Jeśli nie, zwróć błąd
                                cmp al,'9'
                                ja defaultDurationError
                                                            ; Jeśli OK
                                sub al,48                   ; Odczytany zostaje znak, więc należy go przekształcić w cyfrę (ASCII-48)
                                cmp cl,1
                                jna postDurationDigitShift  ; Jeśli 1-wsza cyfra, kontynuuj
                                
                                ; W przeciwnym wypadku (wartość wielocyfrowa) pomnóż obecną zawartość bufora przez 10 (np. dla 32: odczytaj 3, kontynuuj, dodaj 3, odczytaj 2, wykonaj 3*10, dodaj 2 ==> 32)
                                call durationDigitShift     ; Zamiast męczyć się z MUL, można użyć takiej "sztuczki":
                                
                                postDurationDigitShift:
                                        add domyslnaDlugoscNuty,al  ; Dodaj odczytaną cyfrę do bufora                                
                                        inc si                      ; Pobierz kolejną cyfrę
                                        jmp getDurationDigit
                                                
                getNextDefault:     ; Nie bierzemy już pod uwagę 'd', dlatego nie wracamy do getDefaults
                        inc si                      ; Przesunięcie wskaźnika na kolejny znak ustawienia
                        mov al,[si]
                        cmp al,'o'
                        je getDefaultOctave
                        cmp al,'b'
                        je getDefaultTempo
                        jmp rtttlSyntaxError
        
                        
                        
        getDefaultOctave:
                add si,2                    ; Pomiń "o="
                mov al,[si]
                
                cmp al,'4'                  ; Dopuszczalne oktawy w RTTTL to 4-7
                jb defaultOctaveError
                cmp al,'7'
                ja defaultOctaveError
                sub al,48                   ; ASCII -> "int"
                
                mov domyslnaOktawa,al       ; Wstaw odczytaną oktawę do bufora...
                inc si                      ; ...i przejdź do kolejnego ustawienia
                mov al,[si]
                cmp al,':'                  
                je setDefaults
                cmp al,','                  ; Jeśli nie ':', to "musi" być to przecinek...
                jne defaultOctaveError      ; ...a jak nie (np. wielocyfrowa oktawa) -- zwróć błąd
                
                inc si
                mov al,[si]
                cmp al,'b'                  ; Po przecinku już tylko może się znaleźć 'b'...
                je getDefaultTempo          ; ...jeśli tak, przejdź do ustawienia domyślnego tempa; jeśli nie, kontynuuj (zwróć błąd)
                
                
                
        getDefaultTempo:
                mov domyslneTempo,0
                add si,2                    ; Pomiń "b="
                xor cl,cl                   ; Wyzerowanie licznika cyfr
                xor ah,ah                   ; Wyzerowanie rejestru AH (by móc poprawnie ustawić domyślne tempo, które jest typu word, za pomocą AX)
                
                getTempoDigit:       ; Pętla iterująca po domyślnym tempie odczytująca po kolei jego cyfry
                    mov al,[si]                     ; Skopiuj znak (cyfrę tempa) do AL
                    cmp al,':'
                    je setDefaults
                    
                    setTempoDigit:
                            cmp al,'0'                      ; Sprawdź, czy znak jest w ogóle cyfrą
                            jb defaultTempoError            ; Jeśli nie, zwróć błąd
                            cmp al,'9'
                            ja defaultTempoError
                            sub al,48                       ; ASCII -> "int"
                            inc cl
                            cmp cl,3                        ; Sprawdź, czy wartość ma więcej niż 3 cyfry
                            ja defaultTempoError            ; Jeśli tak, zwróć błąd (maks. tempo to 900; więcej niż 3 cyfry skreśla na starcie podane tempo)

                            cmp cl,1                        ; To samo, co w setDurationDigit
                            jna postTempoDigitShift
                            
                            call tempoDigitShift
                            
                            postTempoDigitShift:
                                    add domyslneTempo,ax            ; Dodaj odczytaną cyfrę do bufora (AH=0, więc funkcjonalnie dodajemy samo AL)
                                    inc si          
                                    jmp getTempoDigit
                        
                        
                        
        defaultDurationError:
                mov ah,9
                lea dx,zlaDomDlugoscNuty
                int 21h
                jmp exitToDos
                
        defaultOctaveError:
                mov ah,9
                lea dx,zlaDomyslnaOktawa
                int 21h
                jmp exitToDos
        
        defaultTempoError:
                mov ah,9
                lea dx,zleDomyslneTempo
                int 21h
                jmp exitToDos



setDefaults:

        checkDefaultDuration:   ; Sprawdź, czy podana domyślna długość nuty jest dozwoloną wartością(1,2,4,8,16,32)
                cmp domyslnaDlugoscNuty,1
                je setDefaultDuration
                cmp domyslnaDlugoscNuty,2
                je setDefaultDuration
                cmp domyslnaDlugoscNuty,4
                je setDefaultDuration
                cmp domyslnaDlugoscNuty,8
                je setDefaultDuration
                cmp domyslnaDlugoscNuty,16
                je setDefaultDuration
                cmp domyslnaDlugoscNuty,32
                je setDefaultDuration
                jmp defaultDurationError
                
        setDefaultDuration:
                mov al,domyslnaDlugoscNuty
                shl al,1                       ; *2, by było zgodnie z długościami zdefiniowanymi w DS
                mov domyslnaDlugoscNuty,al
                
        setDefaultOctave:
                cmp domyslnaOktawa,6
                je checkDefaultTempo
                
                mov al,domyslnaOktawa
                mov oktawa,al
                
        checkDefaultTempo:      ; Sprawdź, czy podane domyślne tempo jest dozwoloną wartością (1-900)
                cmp domyslneTempo,120
                je playNote
                cmp domyslneTempo,1
                jb defaultTempoError
                cmp domyslneTempo,900
                ja defaultTempoError
                
        setDefaultTempo:
                mov ax,domyslneTempo
                mov tempo,ax
        

playNote:           ; Odtworzenie pojedynczej nuty. Ton w AX, długość w CX:DX
        mov al,0B6h                 ; Przesłanie wartości 0B6h...
        out 43h,al                  ; ...do portu 43h, czyli przygotowanie głośnika
        
        mov al,[si]
        cmp al,''                   ; Koniec pliku?
        jne enableSpeaker           ; Nie? Odtwórz nutę
        jmp exitToDos               ; Tak? Wyjdź z programu
        
        enableSpeaker:
                call decodeNote
                test ax,ax          ; Jeśli AX=0 (pauza)...
                je biosDelay        ; ...nie generuj dźwięku, tylko czekaj
                
                cli                         ; Wyłącznie przerwań na czas migracji danych
                out 42h,al                  ; Wysłanie do portu głośnika młodszego bajtu tonu
                mov al,ah                   ; Skopiowanie starszego bajtu tonu do AL, by móc go wysłać do portu głośnika
                out 42h,al
                sti
                
                in al,61h                   ; Pobranie stanu kontrolera klawiatury
                or al,3                     ; Ustawienie ostatnich dwóch bitów, odpowiedzialnych za dostęp do głośnika i możliwość przesłania do niego danych, na 1
                out 61h,al                  ; Zapisanie nowego stanu kontolera klawiatury ("włączenie głośnika")
                
                biosDelay:
                        mov ah,86h                  ; Funkcja 86h przerwania 15h -- "pauza" przez ilość mikrosekund podaną w CX:DX (funkcjonalnie odpowiada odtworzeniu nuty)
                        int 15h
                
                call changeColor            ; Zmień kolor tła
                call controls
                call disableSpeaker

                jmp playNote                ; Pobierz kolejną nutę

exitToDos:
		mov ah,4Ch	                ; Funkcja 4Ch przerwania 21h -- wyjście z programu
		int 21h



    ;FUNKCJE        
regset:             ; Wyzerowanie rejestrów
        xor ax,ax
        xor bx,bx
        xor cx,cx
        xor dx,dx
        ret
        
inputToString:      ; Funkcja "konwertująca" bufor na łańcuch znaków (podmiana znaku CR na $)
        lea si,nazwaPliku[1]        ; Adres bajtu przechowującego długość nazwy pliku
        mov cx,[si]                 ; Przeniesienie długości do cx (dla bezpieczeństwa)
        mov ch,0
        add si,cx                   ; Adres powiększony o długość nazwy...
        inc si                      ; ...+1 = adres ostatniego znaku (CR)
        mov al,'$'                 
        mov [si], al                ; Nadpisanie nowej linii (CR) znakiem $
        ret
        
resetFilePointer:   ; Funkcja resetująca wskaźnik na początek pliku
        mov ah,42h                  ; Funkcja 42h przerwania 21h ustawiająca pozycję wskaźnika
        xor cx,cx                   ; CX:DX przechowuje przesunięcie względem pozycji źródłowej. Nie chcemy przesunięcia, więc rejestry te są zerowane.
        xor dx,dx
        mov al,0                    ; AL przechowuje źródło przesunięcia; 0 oznacza początek pliku
        int 21h
        ret
        
durationDigitShift:
        mov bl,domyslnaDlugoscNuty  ; Tymczasowo przenieś obecną zawartość bufora do BL
        shl bl,1                    ; Pomnóż ją przez 2 (lewe przesunięcie binarne)
        shl domyslnaDlugoscNuty,3   ; Pomnóż sam bufor przez 2^3=8
        add domyslnaDlugoscNuty,bl  ; Dodaj obie wartości do siebie (równoważne pomnożeniu przez 10)
        ret
        
tempoDigitShift:
        mov bx,domyslneTempo
        shl bx,1
        shl domyslneTempo,3
        add domyslneTempo,bx
        ret
        
decodeNote:         ; Zdekodowanie nuty zapisanej w RTTTL
        ; Wczytanie ustawień domyślnych
        mov al,domyslnaOktawa
        mov oktawa,al
        mov al,domyslnaDlugoscNuty
        mov dlugoscNuty,al
        mov ax,domyslneTempo
        mov tempo,ax
        
        inc si                      ; Ustawienie wskaźnika na pierwszy znak kodu nuty
        mov al,[si]                 ; Skopiowanie znaku do AL
        cmp al,'a'                  ; Jeśli znak nie jest literą (a przynajmniej ma kod niższy kod ASCII niż małe litery)...
        jb decodeDuration           ; ...to oznacza, że *prawdopodobnie* mamy do czynienia z długością nuty
        jmp decodeTone              ; W przeciwnym razie przejdź do zdekodowania tonu
        
        decodeDuration:        
                ddFirstDigit:       ; Sprawdź pierwszą cyfrę długości nuty
                        cmp al,'1'          ; '1' może oznaczać 1 lub 16
                        je ddCheckSixteen
                        cmp al,'2'          ; '2' już tylko 2
                        je ddSetTwo
                        cmp al,'3'          ; itp...
                        je ddCheckThirtyTwo
                        cmp al,'4'
                        je ddSetFour
                        cmp al,'8'
                        je ddSetEight
                        jmp durationError   ; Wszystko inne jest niepoprawne
                        
                        ddSetTwo:
                                mov al,polNuta
                                mov dlugoscNuty,al
                                jmp ddCheckExtra

                        ddSetFour:
                                mov al,cwiercnuta
                                mov dlugoscNuty,al
                                jmp ddCheckExtra

                        ddSetEight:
                                mov al,osemka
                                mov dlugoscNuty,al
                                jmp ddCheckExtra
                        
                ddCheckSixteen:
                        inc si
                        mov al,[si]
                        cmp al,'6'
                        je ddSetSixteen
                        
                        ddSetOne:   ; Jeśli nie 16, to 1
                            mov al,calaNuta
                            mov dlugoscNuty,al
                            dec si                  ; Ważne, by przesunąć spowrotem wskaźnik, bo obecnie wskazuje na znak po '1'!
                            jmp ddCheckExtra
                            
                        ddSetSixteen:
                            mov al,szesnastka       ; Wstępnie ustaw długość na 16...
                            mov dlugoscNuty,al      
                            jmp ddCheckExtra        ; ...ale wykonaj jeszcze ddCheckExtra
                        
                ddCheckThirtyTwo:   ; To samo co wyżej
                        mov al,trzydziestkaDwojka
                        mov dlugoscNuty,al
                        inc si
                        mov al,[si]
                        cmp al,'2'
                        je ddCheckExtra
                        jmp durationError
                      
                ddCheckExtra:    ; Sprawdź, czy za poprawną wartością nie ma kolejnej cyfry (np. 80 -- 8 jest poprawne, 80 już nie)
                        inc si
                        mov al,[si]
                        cmp al,'a'
                        jnb decodeTone  ; Litera oznacza ton
                        jmp durationError
                        
                durationError:
                        mov ah,9
                        lea dx,zlaDlugoscNuty
                        int 21h
                        jmp exitToDos 
                        
                
        decodeTone:     ; SI jest już ustawione na pozycję tonu; procedura analogiczna do decodeDuration
                cmp al,'a'
                je dtCheckA
                cmp al,'b'
                je dtSetB           ; bis nie istnieje w c-dur (eis też)
                cmp al,'c'
                je dtCheckC
                cmp al,'d'
                je dtCheckD
                cmp al,'e'
                je dtSetE
                cmp al,'f'
                je dtCheckF         
                cmp al,'g'
                je dtCheckG
                cmp al,'p'          ; Pauza
                je dtSetPause
                jmp toneError       ; Podanie tonu jest obowiązkowe
                
                dtCheckA:
                        inc si
                        mov al,[si]
                        cmp al,'#'
                        je dtSetAis
                        
                        dtSetA:
                                mov bx,a            ; Tymczasowe wstawienie do rejestru BX, by zmniejszyć zajętość pamięci i umożliwić skoki warunkowe
                                dec si
                                jmp dtCheckExtra

                        dtSetAis:
                                mov bx,ais
                                jmp dtCheckExtra
                            
                dtSetB:
                        mov bx,b
                        jmp dtCheckExtra
                        
                dtCheckC:
                        inc si
                        mov al,[si]
                        cmp al,'#'
                        je dtSetCis
                        
                        dtSetC:
                                mov bx,c
                                dec si
                                jmp dtCheckExtra

                        dtSetCis:
                                mov bx,cis
                                jmp dtCheckExtra
                            
                dtCheckD:
                        inc si
                        mov al,[si]
                        cmp al,'#'
                        je dtSetDis
                        
                        dtSetD:
                                mov bx,d
                                dec si
                                jmp dtCheckExtra

                        dtSetDis:
                                mov bx,dis
                                jmp dtCheckExtra
                            
                dtSetE:
                        mov bx,e
                        jmp dtCheckExtra
                            
                dtCheckF:
                        inc si
                        mov al,[si]
                        cmp al,'#'
                        je dtSetFis
                        
                        dtSetF:
                                mov bx,f
                                dec si
                                jmp dtCheckExtra

                        dtSetFis:
                                mov bx,fis
                                jmp dtCheckExtra
                            
                dtCheckG:
                        inc si
                        mov al,[si]
                        cmp al,'#'
                        je dtSetGis
                        
                        dtSetG:
                                mov bx,g
                                dec si
                                jmp dtCheckExtra

                        dtSetGis:
                                mov bx,gis
                                jmp dtCheckExtra
                            
                dtSetPause:
                        mov bx,0                    ; Brak dźwięku
                        inc si
                        mov al,[si]
                        cmp al,'.'
                        je applyDot             
                        cmp al,','
                        je applyDuration
                        cmp al,''
                        je applyDuration
                        jmp toneError
                
                dtCheckExtra:    ; Sprawdź, czy za poprawną wartością nie ma kolejnego znaku
                        inc si
                        mov al,[si]
                        cmp al,','                  ; Jeśli ',' (nie podano oktawy ani kropki)...
                        je endDecoding              ; ...zakończ dekodowanie
                        cmp al,'.' 
                        je applyDot
                        cmp al,''
                        je endDecoding
                        cmp al,'9'                  ; Cyfra oznacza oktawę
                        ja toneError
                        jmp decodeOctave

                toneError:
                        mov ah,9
                        lea dx,zlyTon
                        int 21h
                        jmp exitToDos
            
                
        decodeOctave:
                cmp al,'7'                  ; Sprawdź, czy oktawa 4-7
                ja octaveError
                cmp al,'4'
                jb octaveError
                sub al,48                   ; ASCII->int
                mov oktawa,al               ; Ustaw oktawę
                        
                inc si
                mov al,[si]       
                cmp al,','                  ; Po oktawie może być już tylko przecinek...
                je endDecoding
                cmp al,''
                je endDecoding              ; ...lub koniec pliku
                jmp octaveError

        octaveError:
                mov ah,9
                lea dx,zlaOktawa
                int 21h
                jmp exitToDos
                        
        applyDot:       ; Kropka to nic innego jak wydłużenie dźwięku o połowę
                mov cl,dlugoscNuty          ; CL posłuży jako rejestr pomocniczy
                shr cl,2                    ; CL = dlugoscNuty / 2
                sub dlugoscNuty,cl          ; dlugoscNuty = dlugoscNuty + CL = 1,5 * dlugoscNuty (w kodzie operacja odwrotna, ponieważ dlugoscNuty to "waga"!)
                inc si
                mov al,[si]
                cmp al,','
                je endDecoding
                cmp al,''
                je endDecoding
                jmp decodeOctave
                
        endDecoding:
                call setBgColor             ; Ustaw kolor tła na podstawie tonu
                mov cl,oktawa               ; Odczytaj oktawę (ustawioną lub domyślną)
                sub cl,3                    ; Oktawa domyślnych dźwięków to 4; AL sygnalizuje ile oktaw w górę należy przejść
         
                applyOctave:    ; Nadanie oktawy
                        dec cl                      ; while(CL != 0)...
                        je applyDuration
                        shr bx,1                    ; ...podziel nr częstotliwości przez 2 (równoważne zwiększeniu oktawy o 1)
                        jmp applyOctave
                        
                applyDuration:  ; Ustawienie faktycznej długości nuty (F) (w mikrosekundach) na podstawie długości względnej (W) w DX, według wzoru: F = (30000/tempo) * (16000/W)
                        mov ton,bx                  ; Zacznijmy od zwolnienia rejestru BX...
                        
                        xor dx,dx
                        mov ax,30000
                        div tempo                   ; AX = DX:AX/tempo, reszta w DX
                        mov bx,ax                   ; BX = 30000/tempo
                        
                        xor ch,ch
                        xor dx,dx
                        mov cl,dlugoscNuty          ; Skopiuj względną długość do CL
                        mov ax,16000
                        div cx                      ; AX = 16000/W
                        
                        mul bx                      ; DX:AX = AX*BX
                        mov cx,dx                   ; Starsze słowo wyniku przenieś do CX...
                        mov dx,ax                   ; ...a młodsze do DX
                        
                 
                applyTone:      ; Nadanie tonu (skopiowanie ze zmiennej ton do AX)
                        mov ax,ton
                
ret

disableSpeaker:     ; Funkcja wyłączająca głośnik
        in al,61h
        and al,0FCh
        out 61h,al
        ret
        
controls:
        mov ah,1                ; Wykryj wciśnięty klawisz
        int 16h
        jz noKey                ; Jeśli nie wykryto, wyjdź z funkcji
        
        mov ah,0                ; Jeśli wykryto, odczytaj go
        int 16h
                
        checkPlus:  ; Zwiększenie tempa
                cmp al,'+'
                jne checkMinus
                cmp domyslneTempo,895       ; Jeśli tempo > 895, nie zwiększaj już tempa (max. to 900)
                ja noKey
                add domyslneTempo,5
                jmp noKey
                
        checkMinus:
                cmp al,'-'
                jne checkEsc
                cmp domyslneTempo,6         ; Jeśli tempo < 6, nie zmniejszaj już tempa (min. to 1)
                jb noKey
                sub domyslneTempo,5    
                
                jmp noKey
        
        checkEsc:
                cmp al,27                   ; Jeśli Escape
                jne checkPause
                call disableSpeaker
                jmp exitToDos               ; Wyjdź z programu
            
        checkPause:
                cmp al,32                   ; Jeśli spacja
                jne noKey
                
                call disableSpeaker
                
                mov ah,86h                  ; Pauza BIOS
                int 15h
                
                mov ah,0                    ; Wczytaj kolejny klawisz
                int 16h
                
        checkUnpause:
                cmp al,27
                je checkEsc
                cmp al,'+'
                je checkPlus
                cmp al,'-'
                je checkMinus
                cmp al,32
                jne checkUnpause            ; Pętla (cisza) dopóki się nie odpauzuje lub nie wyjdzie z programu
                
        noKey:
                ret
                
setBgColor:
        cmp bx,c
        je setBg00
        cmp bx,d
        je setBg01
        cmp bx,e
        je setBg02
        cmp bx,f
        je setBg03
        cmp bx,g
        je setBg04
        cmp bx,a
        je setBg05
        cmp bx,b
        je setBg06
        cmp bx,0
        je dontSetBgColor
        jmp setBg07
        
        setBg00:
                mov kolorTla,17h
                ret
        setBg01:
                mov kolorTla,20h
                ret
        setBg02:
                mov kolorTla,30h
                ret
        setBg03:
                mov kolorTla,40h
                ret
        setBg04:
                mov kolorTla,50h
                ret
        setBg05:
                mov kolorTla,60h
                ret
        setBg06:
                mov kolorTla,70h
                ret
        setBg07:
                mov kolorTla,07h
                ret
        dontSetBgColor:
                ret
                
changeColor:
        mov cx,2000             ; Rozmiar ekranu
        mov di,1                ; Offset (względny adres komórki ekranu)
        mov ax,0b800h           ; Adres bufora tekstu VGA
        mov es,ax               ; Skopiuj adres do ES...
        mov al,kolorTla         ; ...a do AL skopiuj kolor
        
        colorLoop:
                mov es:[di],al          ; Ustaw kolor bieżącej komórki ekranu
                add di,2                ; Przejdź do kolejnego atrybutu (2B)
                loop colorLoop
        
ret

Kod		ends

end		start		        ; informuje o koncu pliku