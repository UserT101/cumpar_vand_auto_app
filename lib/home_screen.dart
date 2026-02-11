import 'package:cumpar_auto/contact.dart';
import 'package:flutter/gestures.dart'; // Necesar pentru link-uri (TapGestureRecognizer)
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesar pentru a deschide browserul
import 'package:cumpar_auto/widgets/custom_navbar.dart';
import 'package:cumpar_auto/widgets/custom_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://cumpar-masini.ro');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Nu s-a putut deschide linkul $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultStyle = const TextStyle(fontSize: 14, color: Colors.black, height: 1.5);
    final TextStyle linkStyle = const TextStyle(
      fontSize: 14,
      color: Colors.blueAccent,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );

    return Scaffold(
      appBar: CustomAppBar(title: 'Vânzări Cumpărări Auto'),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/carimg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Vânzări Cumpărări Auto",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 6,
                                  color: Colors.black45,
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Anunțuri auto, vinde rapid mașina sau cumpară o mașină ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.car_rental, 
                      title: "Vinde Mașina Rapid",
        
                      descriptionWidget: RichText(
                        text: TextSpan(
                          
                          style: defaultStyle,
                          children: [
                            const TextSpan(
                                text:
                                    "Vânzări Cumpărări Auto este aplicația simplă și rapidă unde poți să vinzi sau să cumperi mașini fără bătăi de cap. Îți poți vinde autoturismul direct către dealerul nostru de încredere, cu care colaborăm prin "),
                            TextSpan(
                              text: "cumpar-masini.ro",
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()..onTap = _launchURL,
                            ),
                            const TextSpan(
                                text:
                                    ", sau poți posta gratuit anunțul tău și să găsești rapid cumpărători. Totul ușor, sigur și 100% online."),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureCard(
                      icon: Icons.verified_user, 
                      title: "Postezi Gratis",
                      descriptionWidget: Text(
                        "Vinde-ți mașina direct de pe telefon, în doar câteva minute! Postezi anunțul rapid, simplu și gratuit, fără drumuri, fără acte complicate și fără stres. Completezi detaliile, apeși publică și ajungi instant la mii de cumpărători. Totul 100% online, direct din aplicație. Mai ușor de atât nu se poate!",
                        style: defaultStyle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureCard(
                      icon: Icons.handshake, 
                      title: "Vânzări Cumpărări Auto by cumpar-masini.ro",
                      descriptionWidget: RichText(
                        text: TextSpan(
                          style: defaultStyle,
                          children: [
                            const TextSpan(
                                text:
                                    "Vânzări Cumpărări Auto este locul unde dorințele tale prind roți. Totul este simplu, frumos și gratuit – postezi anunțul și vezi imediat cât de ușor poate fi. Ai două căi: poți să vinzi direct prin aplicație, sau să alegi scurtătura și să vinzi prin dealerul nostru de încredere, cu care colaborăm prin "),
                            TextSpan(
                              text: "Cumpăr-Mașini.ro",
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()..onTap = _launchURL,
                            ),
                            const TextSpan(
                                text:
                                    ". Alegerea e a ta, iar fiecare clic te apropie de mașina visurilor tale."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Trimite cererea ta acum",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
          currentIndex: _currentIndex, onTabTapped: _onTabTapped),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Widget descriptionWidget, 
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  descriptionWidget,
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}