# Vânzări Cumpărări Auto 

Aplicația mobilă oficială pentru platforma [cumpar-masini.ro](https://cumpar-masini.ro).

Această aplicație Flutter permite utilizatorilor să vândă și să cumpere autoturisme rapid și sigur. Utilizatorii pot vinde mașina direct către dealerul nostru partener sau pot posta anunțuri gratuite pentru a găsi cumpărători.

## Funcționalități Cheie

### Pentru Vânzători
* **Vânzare Rapidă (Instant):** Formular dedicat pentru a trimite oferta direct către echipa `cumpar-masini.ro` pentru o evaluare imediată.
* **Postare Anunțuri:** Utilizatorii autentificați pot publica anunțuri detaliate (poze, descriere, preț, specificații tehnice).
* **Gestionare Anunțuri:** Posibilitatea de a edita sau șterge propriile anunțuri.

### Pentru Cumpărători
* **Filtrare Avansată:** Căutare rapidă după marcă, model, an, preț, combustibil și kilometraj.
* **Vizualizare Detaliată:** Galerie foto interactivă și specificații complete.
* **Contact Direct:** Butoane rapide pentru apelare telefonică, mesaj pe WhatsApp sau Email direct din aplicație.

### Tehnic & UX
* **Autentificare Sigură:** Sistem de Login/Înregistrare gestionat prin Firebase Auth.
* **Design Modern:** Interfață "Edge-to-Edge" optimizată pentru ultimele versiuni de Android (inclusiv Android 15).
* **Navigare Fluidă:** Experiență nativă pe Android și iOS.

## Tehnologii Folosite

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend & Database:** Google Firebase (Firestore, Authentication, Storage pentru imagini).
* **Platforme:** Android (Kotlin, minSdk 21, targetSdk 35) & iOS.
* **Arhitectură:** MVC / Provider (sau ce folosești tu pentru state management).
