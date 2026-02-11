import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Controllers
  final _modelController = TextEditingController();
  final _anController = TextEditingController();
  final _kmController = TextEditingController();
  final _pretController = TextEditingController();
  final _descriereController = TextEditingController();
  // Dropdown values
  String? _marcaSelectata;
  String? _combustibilSelectat;
  String? _cutieSelectata;
  bool _isLoading = false;

  // Liste pentru dropdowns
  final List<String> _marci = [
    "Audi", "BMW", "Chevrolet", "Citroen", "Dacia", "Fiat", "Ford", "Honda",
    "Hyundai", "Kia", "Mazda", "Mercedes-Benz", "Mitsubishi", "Nissan",
    "Opel", "Peugeot", "Renault", "Seat", "Skoda", "Subaru", "Suzuki",
    "Toyota", "Volkswagen", "Volvo"
  ];
  final List<String> _combustibili = ['Benzină', 'Motorină', 'Electric', 'Hybrid-Benzină', 'Hybrid-Motorină', 'GPL', 'GNC', 'Hidrogen'];
  final List<String> _cutii = ['Manuală', 'Automată'];

  // Stocare imagini
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  XFile? _videoFile;

  String? _validateOptionalNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    if (int.tryParse(value) == null) return 'Introduceți un număr valid.';
    return null;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _anController.dispose();
    _kmController.dispose();
    _pretController.dispose();
    _descriereController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles);
        });
      }
    } catch (e) {
      _showSnackBar("Eroare la selectarea imaginilor: $e");
    }
  }
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 45),  
      );
      if(pickedFile == null) return;
      
      setState(() { _isLoading = true; });
      _showSnackBar("Se optimizează videoclipul pentru încărcare... Vă rugăm așteptați.");

      final MediaInfo? info = await VideoCompress.compressVideo(
        pickedFile.path,
        quality: VideoQuality.DefaultQuality, 
        deleteOrigin: false,
        includeAudio: true,
      );
      if (info != null && info.file != null) {
        final double sizeInMb = info.file!.lengthSync() / (1024 * 1024);

        if (sizeInMb > 20) {
          _showSnackBar("Videoclipul este prea mare chiar și după compresie (${sizeInMb.toStringAsFixed(1)} MB). Încearcă un clip mai scurt.");
          
          await VideoCompress.deleteAllCache();
        } else {
          setState(() {
            _videoFile = XFile(info.file!.path);
          });
          _showSnackBar("Video optimizat: ${sizeInMb.toStringAsFixed(1)} MB");
        }
      }
    } catch (e) {
      _showSnackBar("Eroare la selectarea videoclipului: $e");
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<String> _uploadFile(XFile image) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User negăsit");

    final ref = _storage.ref().child('listings').child(user.uid).child('${DateTime.now().toIso8601String()}-${image.name}');
    UploadTask uploadTask = ref.putFile(File(image.path));
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  List<String> _generateKeywords(List<String> inputs) {
    List<String> keywords = [];
    for (var input in inputs) {
      String text = input.toLowerCase().trim();
      if (text.isNotEmpty) {
        keywords.add(text); 
        if (inputs.length > 1 && keywords.length < 5) { 
           if (inputs.indexOf(input) == 0 && inputs[1].isNotEmpty) {
             keywords.add('${inputs[0].toLowerCase().trim()} ${inputs[1].toLowerCase().trim()}');
           }
        }
      }
    }
    return keywords.toSet().toList();
  }
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnackBar("Adaugă cel puțin o imagine.");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar("Eroare: Utilizator neautentificat.");
        setState(() { _isLoading = false; });
        return;
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception("Documentul utilizatorului nu a fost găsit.");
      }
      final userData = userDoc.data()!;

      List<String> imageUrls = [];
      for (var image in _images) {
        String url = await _uploadFile(image);
        imageUrls.add(url);
      }
      //upload video
      String? videoUrl;
      if (_videoFile != null) {
        videoUrl = await _uploadFile(_videoFile!); 
      }

      final String marca = _marcaSelectata!;
      final String model = _modelController.text.trim();
      final String an = _anController.text.trim();

      List<String> keywords = _generateKeywords([
          marca,
          model,
          an,
          _combustibilSelectat!,
          _cutieSelectata!
      ]);

      await _firestore.collection('listings').add({
        'ownerId': user.uid,
        'ownerNume': userData['nume'],
        'ownerPrenume': userData['prenume'],
        'ownerTelefon': userData['telefon'],
        'ownerJudet': userData['judet'],
        'marca': _marcaSelectata,
        'model': _modelController.text.trim(),
        'anFabricatie': int.tryParse(_anController.text.trim()),
        'kilometri': int.tryParse(_kmController.text.trim()),
        'combustibil': _combustibilSelectat,
        'cutie': _cutieSelectata,
        'pret': int.tryParse(_pretController.text.trim()),
        'descriere': _descriereController.text.trim(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'videoUrl':videoUrl,
        'searchKeywords': keywords, 
      });

      _showSnackBar("Anunț publicat cu succes!");
      if(mounted) Navigator.pop(context);

    } catch (e) {
      _showSnackBar("A apărut o eroare: $e");
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adaugă Anunț Nou')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdown(_marci, 'Marcă', _marcaSelectata, (val) => setState(() => _marcaSelectata = val)),
              _buildTextFormField(_modelController, 'Model', validator: _validateNotEmpty, maxLength: 50),
              _buildTextFormField(_anController, 'An Fabricație', keyboardType: TextInputType.number, validator: _validateNumber, maxLength: 4),
              _buildTextFormField(_kmController, 'Kilometri', keyboardType: TextInputType.number, validator: _validateNumber, maxLength: 9),
              _buildTextFormField(_pretController, 'Preț (€) (Lăsați gol pentru "Contactați vânzătorul")', keyboardType: TextInputType.number, validator: _validateOptionalNumber, maxLength: 10),
              _buildDropdown(_combustibili, 'Combustibil', _combustibilSelectat, (val) => setState(() => _combustibilSelectat = val)),
              _buildDropdown(_cutii, 'Cutie de viteze', _cutieSelectata, (val) => setState(() => _cutieSelectata = val)),
              _buildTextFormField(_descriereController, 'Descriere', keyboardType: TextInputType.multiline, maxLines: 4, maxLength: 1500),
              const SizedBox(height: 20),
              
              // Secțiune Imagini
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Adaugă Imagini'),
                onPressed: _pickImages,
              ),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(File(_images[index].path), width: 100, height: 100, fit: BoxFit.cover),
                      );
                    },
                  ),
                ),
              OutlinedButton.icon(
              icon: const Icon(Icons.videocam),
              label: Text(_videoFile == null ? 'Adaugă Video' : 'Video Selectat (Modifică)'),
              onPressed: _pickVideo,
              ),
              if (_videoFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("✅ Videoclip pregătit pentru încărcare", style: TextStyle(color: Colors.green)),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  textStyle: const TextStyle(fontSize: 18, color: Colors.white)
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Publică Anunțul', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      
    );
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) return 'Acest câmp este obligatoriu.';
    return null;
  }
  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Acest câmp este obligatoriu.';
    if (int.tryParse(value) == null) return 'Introduceți un număr valid.';
    return null;
  }

  Widget _buildTextFormField(TextEditingController controller, String label, 
  {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, int maxLines = 1, int maxLength = 90}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Selectați o opțiune' : null,
      ),
    );
  }
}