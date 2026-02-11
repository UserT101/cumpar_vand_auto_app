import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/widgets/listing_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum FilterMode { myListings, savedListings }

class FilteredListingsScreen extends StatefulWidget {
  final FilterMode mode;

  const FilteredListingsScreen({super.key, required this.mode});

  @override
  State<FilteredListingsScreen> createState() => _FilteredListingsScreenState();
}

class _FilteredListingsScreenState extends State<FilteredListingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late Future<List<QueryDocumentSnapshot>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchListings();
  }

  void _refreshListing() {
    setState(() {
      _listingsFuture = _fetchListings();
    });
  }

  Future<List<QueryDocumentSnapshot>> _fetchListings() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    if (widget.mode == FilterMode.myListings) {
      final snapshot = await _firestore
          .collection('listings')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      List<QueryDocumentSnapshot> docs = snapshot.docs;

      docs.sort((a, b) {
        var aData = a.data() as Map<String, dynamic>;
        var bData = b.data() as Map<String, dynamic>;

        Timestamp aTime = aData['createdAt'] ?? Timestamp(0, 0);
        Timestamp bTime = bData['createdAt'] ?? Timestamp(0, 0);

        return bTime.compareTo(aTime);
      });

      return docs;
    } else {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || !userDoc.data()!.containsKey('savedListingIds')) {
        return [];
      }

      final List<dynamic> savedIds = userDoc.data()!['savedListingIds'];
      if (savedIds.isEmpty) {
        return [];
      }

      final snapshot = await _firestore
          .collection('listings')
          .where(FieldPath.documentId, whereIn: savedIds)
          .get();

      return snapshot.docs;
    }
  }

  Future<void> _deleteListing(String docId) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmare Ștergere'),
            content: const Text('Ești sigur că vrei să ștergi acest anunț?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anulează'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Șterge', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) {
      return;
    }
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _firestore.collection('listings').doc(docId).delete();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anunț șters cu succes.')),
      );
      _refreshListing();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la ștergerea anunțului: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.mode == FilterMode.myListings
        ? 'Anunțurile Mele'
        : 'Anunțuri Salvate';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color.fromRGBO(48, 48, 48, 1),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('A apărut o eroare: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(widget.mode == FilterMode.myListings
                    ? 'Nu ai niciun anunț publicat.'
                    : 'Nu ai niciun anunț salvat.'));
          }

          final listings = snapshot.data!;

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listingDoc = listings[index];
              Widget listCard = ListingCard(listing: listingDoc);

              if (widget.mode == FilterMode.myListings) {
                // Aici folosim Stack pentru a suprapune butonul peste card
                return Stack(
                  alignment: Alignment.topRight, // Aliniere generală
                  children: [
                    // 1. Cardul Anunțului (dedesubt)
                    listCard,
                    
                    // 2. Butonul de Ștergere (deasupra)
                    Positioned(
                      top: 15, // Distanță de sus
                      right: 15, // Distanță din dreapta
                      child: Material(
                        elevation: 5, // Umbră ca să se vadă bine
                        shape: const CircleBorder(),
                        color: Colors.white, // Fundal alb la buton
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _deleteListing(listingDoc.id),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0), // Mărimea zonei de click
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return listCard;
            },
          );
        },
      ),
    );
  }
}