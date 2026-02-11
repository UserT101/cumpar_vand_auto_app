import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  void _shareApp(BuildContext context) {
    const String message =
        "Descoperă aplicația *Cumpar Auto* 🚗!\n"
        "Caută mașina dorită rapid și sigur aici:\n"
        "https://cumpar-masini.ro/";

    SharePlus.instance.share(
      ShareParams(
      text: message,
      subject: "Recomandare aplicație - Cumpar Auto",
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color.fromRGBO(48, 48, 48, 1),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Ink(
            decoration: const ShapeDecoration(
              color: Colors.blueAccent, // bright circular background
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 28),
              onPressed: () => _shareApp(context),
              tooltip: "Share app", // shows on long press
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
