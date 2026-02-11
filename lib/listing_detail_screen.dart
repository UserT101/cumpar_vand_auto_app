// lib/listing_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/car_listings_screen.dart';
import 'package:cumpar_auto/contact.dart';
import 'package:cumpar_auto/home_screen.dart';
import 'package:cumpar_auto/profile.dart';
import 'package:cumpar_auto/widgets/custom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

// --- Widget pentru Video Player ---
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator()));
  }
}

// --- Ecranul Principal de Detalii ---
class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isSaved = false;
  bool _isLoadingSave = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    _user = _auth.currentUser;
    if (_user == null) {
      setState(() {
        _isLoadingSave = false;
      });
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('savedListingIds')) {
        final List<dynamic> savedIds = userDoc.data()!['savedListingIds'];
        if (mounted) {
          setState(() {
            _isSaved = savedIds.contains(widget.listingId);
            _isLoadingSave = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoadingSave = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingSave = false; });
    }
  }

  Future<void> _toggleSave() async {
    _user = _auth.currentUser;
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Trebuie să fii autentificat pentru a salva un anunț.')),
      );
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()));
      return;
    }

    setState(() {
      _isLoadingSave = true;
    });

    final userRef = _firestore.collection('users').doc(_user!.uid);
    try {
      if (_isSaved) {
        await userRef.update({
          'savedListingIds': FieldValue.arrayRemove([widget.listingId])
        });
        if (mounted) _showSnackBar("Anunț șters din favorite.");
      } else {
        await userRef.set({
          'savedListingIds': FieldValue.arrayUnion([widget.listingId])
        }, SetOptions(merge: true));
        if (mounted) _showSnackBar("Anunț salvat la favorite.");
      }

      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
          _isLoadingSave = false;
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar("Eroare la salvare: $e");
      if (mounted) setState(() { _isLoadingSave = false; });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Nu se poate apela $phoneNumber';
    }
  }

  void _onTabTapped(BuildContext context, int index) {
    if (index == 1) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const CarListingsScreen();
        break;
      case 2:
        page = const ContactScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  Future<void> _showReportDialog() async {
    return showDialog(
      context :context,
      builder: (BuildContext context) {
        return AlertDialog(
          title :const Text('Raportează Anunț'),
          content :const Text('Ești sigur că dorești să raportezi acest anunț? Echipa noastră va revizui raportul.'),
          actions :[
            TextButton(
              child :const Text('Anulează'),
              onPressed :() {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child :const Text("Raportează", style: TextStyle(color: Colors.red)),
              onPressed :() async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance.collection('reports').add({
                  'listingId': widget.listingId,
                  'reportedAt': FieldValue.serverTimestamp(),
                });
                if(mounted){
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anunț raportat. Vă mulțumim!')),
                  );
                }
              }
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalii Anunț'),
        backgroundColor: const Color.fromRGBO(48, 48, 48, 1),
        foregroundColor: Colors.white,
        actions: [
          if (_user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isLoadingSave
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)))
                  : IconButton(
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleSave,
                      tooltip: _isSaved
                          ? 'Șterge de la favorite'
                          : 'Salvează la favorite',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 28),
                    tooltip: 'Raportează Anunț',
                    onPressed: _showReportDialog,
                  ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Anunțul nu a fost găsit.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> images = data['imageUrls'] ?? [];
          final String? videoUrl = data['videoUrl'];
          final String? descriere = data['descriere'];
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  Hero(
                    tag: 'listingImage${widget.listingId}',
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 250.0,
                        autoPlay: true,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: images.length > 1,
                      ),
                      // MODIFICAT PENTRU CLICK & FULL SCREEN
                      items: images.asMap().entries.map((entry) {
                        int index = entry.key;
                        String imageUrl = entry.value;

                        return Builder(
                          builder: (BuildContext context) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenGallery(
                                      images: images,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                if (videoUrl != null && videoUrl.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Prezentare Video',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  VideoPlayerWidget(videoUrl: videoUrl),
                  const Divider(),
                ],
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['marca']} ${data['model']}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['pret'] != null
                            ? '${data['pret']} €'
                            : 'Contactează vânzătorul',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            // Logică culoare: Albastru pt preț, Roșu pt contact
                            color: data['pret'] != null
                                ? Colors.blueAccent
                                : Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildDetailRow(Icons.calendar_today, 'Anul',
                          data['anFabricatie'].toString()),
                      _buildDetailRow(
                          Icons.speed, 'Kilometri', '${data['kilometri']} km'),
                      _buildDetailRow(Icons.local_gas_station, 'Combustibil',
                          data['combustibil']),
                      _buildDetailRow(
                          Icons.settings, 'Cutie de viteze', data['cutie']),
                      const SizedBox(height: 24),
                      if (descriere != null && descriere.isNotEmpty) ...[
                        const Text(
                          'Descriere',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descriere,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                      ],
                      const Text(
                        'Informații Vânzător',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildDetailRow(Icons.person, 'Nume',
                          '${data['ownerNume']} ${data['ownerPrenume']}'),
                      _buildDetailRow(
                          Icons.location_city, 'Județ', data['ownerJudet']),
                      _buildDetailRow(
                          Icons.phone, 'Telefon', data['ownerTelefon']),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _launchDialer(data['ownerTelefon']),
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text('Sună Vânzătorul',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 1,
        onTabTapped: (index) => _onTabTapped(context, index),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          );
        },
      ),
    );
  }
}