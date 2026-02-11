import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers pentru câmpuri
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numeController = TextEditingController();
  final TextEditingController _prenumeController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();

  // Variabilă pentru stocarea județului selectat
  String? _selectedJudet;
  bool _consentGiven = false;
  bool _isLoading = false;

  // MODIFICARE: Lista județelor
  final List<String> judeteRomania = [
    'Alba', 'Arad', 'Argeș', 'Bacău', 'Bihor', 'Bistrița-Năsăud', 'Botoșani',
    'Brașov', 'Brăila', 'București', 'Buzău', 'Caraș-Severin', 'Călărași',
    'Cluj', 'Constanța', 'Covasna', 'Dâmbovița', 'Dolj', 'Galați',
    'Giurgiu', 'Gorj', 'Harghita', 'Hunedoara', 'Ialomița', 'Iași',
    'Ilfov', 'Maramureș', 'Mehedinți', 'Mureș', 'Neamț', 'Olt',
    'Prahova', 'Satu Mare', 'Sălaj', 'Sibiu', 'Suceava', 'Teleorman',
    'Timiș', 'Tulcea', 'Vaslui', 'Vâlcea', 'Vrancea'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _numeController.dispose();
    _prenumeController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_consentGiven) {
      _showSnackBar("Trebuie să vă dați consimțământul pentru a continua.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(
            "${_prenumeController.text.trim()} ${_numeController.text.trim()}");

        await _firestore.collection('users').doc(user.uid).set({
          'nume': _numeController.text.trim(),
          'prenume': _prenumeController.text.trim(),
          'email': _emailController.text.trim(),
          'telefon': _telefonController.text.trim(),
          'judet': _selectedJudet, 
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar("Cont creat cu succes!");

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Crearea contului a eșuat.";
      if (e.code == 'weak-password') {
        message = 'Parola este prea slabă.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Deja există un cont cu această adresă de email.';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("A apărut o eroare: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creare Cont Nou'),
        backgroundColor: const Color.fromRGBO(48, 48, 48, 1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                          _numeController, 'Nume', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextFormField(_prenumeController, 'Prenume',
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                          _emailController, 'Email', Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                          _passwordController, 'Parolă', Icons.lock_outline,
                          obscureText: true),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                          _telefonController, 'Telefon', Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedJudet,
                        isExpanded: true, 
                        decoration: InputDecoration(
                          labelText: 'Județ',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: judeteRomania.map((String judet) {
                          return DropdownMenuItem<String>(
                            value: judet,
                            child: Text(judet),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedJudet = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selectați un județ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildConsentCheckbox(),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Creează Cont',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Introduceți $label";
        }
        if (label == 'Email' && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return "Introduceți un email valid";
        }
        if (label == 'Parolă' && value.length < 6) {
          return "Parola trebuie să aibă minim 6 caractere";
        }
        return null;
      },
    );
  }
  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://docs.google.com/document/d/1vGtiUDU2U-q1_Uujx1elwhT3rkKS87F5ZIpiySF0QwY/edit?tab=t.0');
    if (!await launchUrl(url)) {
      throw Exception('Nu s-a putut deschide link-ul $url');
    }
  }
  Widget _buildConsentCheckbox() {
    return FormField<bool>(
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _consentGiven,
                  onChanged: (value) {
                    setState(() {
                      _consentGiven = value ?? false;
                      state.didChange(value);
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 13), // Stilul general (negru)
                      children: [
                        const TextSpan(
                          text: "Sunt de acord cu ",
                        ),
                        TextSpan(
                          text: "Termenii și Condițiile și Politica de Confidențialitate.",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor, // Culoarea albastră/principală
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline, // Subliniat ca un link
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchPrivacyPolicy(); // Deschide link-ul când se apasă
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  state.errorText ?? "",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
      validator: (value) {
        if (!_consentGiven) {
          return 'Trebuie să bifați consimțământul';
        }
        return null;
      },
    );
  }
}