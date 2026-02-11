import 'package:flutter/material.dart';
import 'package:cumpar_auto/car_listings_screen.dart';
import '../contact.dart';
import '../home_screen.dart';
import '../profile.dart'; // import your profile page

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color.fromRGBO(48, 48, 48, 1),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
      onTap: (index) {
        if (index == 0) {
          if (currentIndex == 0) return; 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (index == 1) {
          if (currentIndex == 1) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CarListingsScreen()),
          );
        } else if (index == 2) {
          if (currentIndex == 2) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ContactScreen()),
          );
        } else if (index == 3) {
          if (currentIndex == 3) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Acasă',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_filled_outlined),
          label: 'Anunțuri',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contact_mail),
          label: 'Contact',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
