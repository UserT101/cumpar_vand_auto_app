import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/widgets/custom_appbar.dart';
import 'package:cumpar_auto/widgets/custom_navbar.dart';
import 'package:cumpar_auto/widgets/listing_card.dart';
import 'package:flutter/material.dart';

import 'package:cumpar_auto/add_listing_screen.dart';
import 'package:cumpar_auto/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarListingsScreen extends StatefulWidget {
  const CarListingsScreen({super.key});

  @override
  State<CarListingsScreen> createState() => _CarListingsScreenState();
}

class _FilterValues {
  String? marca;
  String? model;
  String? cutie;
  String? combustibil; 
  int? anMin;
  int? anMax;
  int? kmMax;
  int? pretMin;
  int? pretMax;

  _FilterValues({
    this.marca,
    this.model,
    this.cutie,
    this.combustibil, 
    this.anMin,
    this.anMax,
    this.kmMax,
    this.pretMin,
    this.pretMax,
  });

  bool get hasFilters {
    return marca != null ||
        (model != null && model!.isNotEmpty) ||
        cutie != null ||
        combustibil != null || 
        anMin != null ||
        anMax != null ||
        kmMax != null ||
        pretMin != null ||
        pretMax != null;
  }
}

class _CarListingsScreenState extends State<CarListingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  int _currentIndex = 1;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  _FilterValues _filters = _FilterValues();

  final List<String> _marci = ["Abarth", "Acura", "Alfa Romeo", "Aston Martin", "Audi", 
  "Bentley", "BMW", "Bugatti", "Buick", "BYD", "Cadillac", "Chevrolet", "Chrysler", "Citroen", 
  "Cupra", "Dacia", "Daewoo", "Daihatsu", "Dodge", "DS Automobiles", "Ferrari", "Fiat", "Ford", "Geely", 
  "GMC", "Honda", "Hummer", "Hyundai", "Infiniti", "Isuzu", "Iveco", "Jaguar", "Jeep", "KGM (SsangYong)", 
  "Kia", "Lada", "Lamborghini", "Lancia", "Land Rover", "Lexus", "Lincoln", "Lotus", "Maserati", "Maybach", 
  "Mazda", "McLaren", "Mercedes-Benz", "MG", "Mini", "Mitsubishi", "Nissan", "Opel", "Peugeot", "Polestar", 
  "Pontiac", "Porsche", "Renault", "Rolls-Royce", "Rover", "Saab", "Seat", "Skoda", "Smart", "Subaru", "Suzuki", 
  "Tesla", "Toyota", "Volkswagen", "Volvo"];
  final List<String> _cutii = ['Manuală', 'Automată'];
  final List<String> _combustibili = ['Benzină', 'Motorină', 'Electric', 'Hybrid-Benzină', 'Hybrid-Motorină', 'GPL', 'GNC', 'Hidrogen'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _checkAuthAndNavigate() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Trebuie să fii autentificat pentru a adăuga un anunț.')),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const AddListingScreen()));
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    Query query = _firestore.collection('listings');

    if (_filters.marca != null) {
      query = query.where('marca', isEqualTo: _filters.marca);
    }
    if (_filters.cutie != null) {
      query = query.where('cutie', isEqualTo: _filters.cutie);
    }
    if (_filters.combustibil != null) {
      query = query.where('combustibil', isEqualTo: _filters.combustibil);
    }
    
    if (_searchQuery.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: _searchQuery.toLowerCase());
    } 
    else if (_filters.marca == null && _filters.cutie == null && _filters.combustibil == null) {
       query = query.orderBy('createdAt', descending: true);
    }
    
    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _applyClientSideFilters(
      List<QueryDocumentSnapshot> docs) {
        
    if (_filters.model == null &&
        _filters.anMin == null &&
        _filters.anMax == null &&
        _filters.kmMax == null &&
        _filters.pretMin == null &&
        _filters.pretMax == null) {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Verificare Model
      if (_filters.model != null && _filters.model!.isNotEmpty) {
        final model = data['model'] as String? ?? '';
        if (!model.toLowerCase().contains(_filters.model!.toLowerCase())) {
          return false;
        }
      }

      // Verificare An
      final an = data['anFabricatie'] as int? ?? 0;
      if (_filters.anMin != null && an < _filters.anMin!) return false;
      if (_filters.anMax != null && an > _filters.anMax!) return false;

      // Verificare Kilometri
      final km = data['kilometri'] as int? ?? 0;
      if (_filters.kmMax != null && km > _filters.kmMax!) return false;

      // Verificare Preț
      final pret = data['pret'] as int?;
      if(pret != null) {
        if (_filters.pretMin != null && pret < _filters.pretMin!) return false;
        if (_filters.pretMax != null && pret > _filters.pretMax!) return false;
      }
      return true;
    }).toList();
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _FilterSheetContent(
          marci: _marci,
          cutii: _cutii,
          combustibili: _combustibili, 
          initialFilters: _filters,
          
          onApply: (newFilters) {
            setState(() {
              _filters = newFilters;
            });
            Navigator.pop(context);
          },
          onReset: () {
            setState(() {
              _filters = _FilterValues();
              _searchController.clear();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Anunțuri Auto'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Caută (ex: Dacia, Logan, 2019...)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showFilterSheet,
                  icon: Icon(
                    _filters.hasFilters ? Icons.filter_alt : Icons.filter_alt_off_outlined,
                    color: _filters.hasFilters ? Theme.of(context).primaryColor : Colors.grey[600],
                    size: 30,
                  ),
                  tooltip: 'Filtre Avansate',
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(_searchQuery.isEmpty && !_filters.hasFilters
                          ? 'Nu există niciun anunț.'
                          : 'Niciun rezultat găsit pentru filtrele selectate.'));
                }

                final serverDocs = snapshot.data!.docs;
                final clientDocs = _applyClientSideFilters(serverDocs); 

                if (clientDocs.isEmpty) {
                   return const Center(child: Text('Niciun rezultat găsit pentru filtrele selectate.'));
                }

                return ListView.builder(
                  itemCount: clientDocs.length,
                  itemBuilder: (context, index) {
                    final listing = clientDocs[index];
                    return ListingCard(listing: listing);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkAuthAndNavigate,
        backgroundColor: Colors.blueAccent,
        tooltip: 'Adaugă anunț nou',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar:
          CustomNavBar(currentIndex: _currentIndex, onTabTapped: _onTabTapped),
    );
  }
}

class _FilterSheetContent extends StatefulWidget {
  final List<String> marci;
  final List<String> cutii;
  final List<String> combustibili;
  final _FilterValues initialFilters;
  final Function(_FilterValues) onApply;
  final VoidCallback onReset;

  const _FilterSheetContent({
    required this.marci,
    required this.cutii,
    required this.combustibili, 
    required this.initialFilters,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late TextEditingController _modelController;
  late TextEditingController _anMinController;
  late TextEditingController _anMaxController;
  late TextEditingController _kmMaxController;
  late TextEditingController _pretMinController;
  late TextEditingController _pretMaxController;

  String? _tempMarca;
  String? _tempCutie;
  String? _tempCombustibil; 

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _modelController = TextEditingController(text: filters.model);
    _anMinController = TextEditingController(text: filters.anMin?.toString() ?? '');
    _anMaxController = TextEditingController(text: filters.anMax?.toString() ?? '');
    _kmMaxController = TextEditingController(text: filters.kmMax?.toString() ?? '');
    _pretMinController = TextEditingController(text: filters.pretMin?.toString() ?? '');
    _pretMaxController = TextEditingController(text: filters.pretMax?.toString() ?? '');

    _tempMarca = filters.marca;
    _tempCutie = filters.cutie;
    _tempCombustibil = filters.combustibil; 
  }

  @override
  void dispose() {
    _modelController.dispose();
    _anMinController.dispose();
    _anMaxController.dispose();
    _kmMaxController.dispose();
    _pretMinController.dispose();
    _pretMaxController.dispose();
    super.dispose();
  }

  void _handleApply() {
    final newFilters = _FilterValues(
      marca: _tempMarca,
      cutie: _tempCutie,
      combustibil: _tempCombustibil, 
      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      anMin: int.tryParse(_anMinController.text),
      anMax: int.tryParse(_anMaxController.text),
      kmMax: int.tryParse(_kmMaxController.text),
      pretMin: int.tryParse(_pretMinController.text),
      pretMax: int.tryParse(_pretMaxController.text),
    );
    
    widget.onApply(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtre Avansate',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),
            
            DropdownButtonFormField<String>(
              initialValue: _tempMarca,
              hint: const Text('Orice Marcă'),
              items: widget.marci.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                setState(() => _tempMarca = val);
              },
              decoration: const InputDecoration(labelText: 'Marcă'),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model (ex: A4)'),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _tempCombustibil,
              hint: const Text('Orice Combustibil'),
              items: widget.combustibili.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() => _tempCombustibil = val);
              },
              decoration: const InputDecoration(labelText: 'Combustibil'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _tempCutie,
              hint: const Text('Orice Tip de Cutie'),
              items: widget.cutii.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() => _tempCutie = val);
              },
              decoration: const InputDecoration(labelText: 'Cutie de viteze'),
            ),
            const SizedBox(height: 16),

            // An
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _anMinController,
                    decoration: const InputDecoration(labelText: 'An minim'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _anMaxController,
                    decoration: const InputDecoration(labelText: 'An maxim'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kilometri
            TextField(
              controller: _kmMaxController,
              decoration: const InputDecoration(labelText: 'Kilometri maximi'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Pret
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pretMinController,
                    decoration: const InputDecoration(labelText: 'Preț minim (€)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _pretMaxController,
                    decoration: const InputDecoration(labelText: 'Preț maxim (€)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Butoane Acțiune
            ElevatedButton(
              onPressed: _handleApply,
              child: const Text('Aplică Filtrele'),
            ),
            OutlinedButton(
              onPressed: widget.onReset,
              child: const Text('Resetează Toate Filtrele'),
            ),
          ],
        ),
      ),
    );
  }
}