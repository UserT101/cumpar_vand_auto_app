import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/filtered_listing_screen.dart';
import 'package:cumpar_auto/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cumpar_auto/widgets/custom_navbar.dart';
import 'package:cumpar_auto/signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  bool _isLoading = false; // Loading state

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
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Vă rugăm să introduceți emailul și parola.");
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Autentificare eșuată.";
      if (e.code == 'user-not-found') {
        message = "Nu există un cont cu acest email. Încercați să vă înregistrați.";
      } else if (e.code == 'wrong-password') {
        message = "Parolă incorectă.";
      } else if (e.code == 'invalid-credential') {
        message = "Date incorecte (email sau parolă).";
      } else if (e.code == 'too-many-requests') {
        message = "Prea multe încercări. Încercați mai târziu.";
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Eroare: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
        _passwordController.clear();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User a dat cancel
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autentificare Firebase
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
        } else {
          
          if (mounted) {
            _showMissingDetailsDialog(user);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Eroare Firebase: ${e.message}");
    } catch (e) {
      _showSnackBar("A apărut o eroare: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://docs.google.com/document/d/1vGtiUDU2U-q1_Uujx1elwhT3rkKS87F5ZIpiySF0QwY/edit?tab=t.0');
    if (!await launchUrl(url)) {
      throw Exception('Nu s-a putut deschide link-ul $url');
    }
  }
  void _showMissingDetailsDialog(User user) {
    final phoneController = TextEditingController();
    String? selectedJudet;
    final formKey = GlobalKey<FormState>();
    bool isSavingDialog = false; 
    bool isAgreed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text("Finalizare Profil"),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            "Pentru a continua, avem nevoie de câteva detalii suplimentare."),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Număr de Telefon",
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 10) {
                              return "Introduceți un număr valid.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          initialValue: selectedJudet,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Județ',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          items: judeteRomania.map((String judet) {
                            return DropdownMenuItem<String>(
                              value: judet,
                              child: Text(judet),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              selectedJudet = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Selectați un județ' : null,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14, 
                              ),
                              children: [
                                const TextSpan(
                                  text: "Sunt de acord cu ",
                                ),
                                TextSpan(
                                  text: "termenii și condițiile si cu preluarea datelor personale.",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline, 
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _launchPrivacyPolicy(); 
                                    },
                                ),
                              ],
                            ),
                          ),
                          value: isAgreed,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              isAgreed = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (!isSavingDialog)
                    TextButton(
                      child: const Text("Anulează",
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await user.delete();
                        } catch(e) {
                          await _auth.signOut();
                        }
                        await _googleSignIn.signOut();
                        
                      },
                    ),
                  
                  ElevatedButton(
                    onPressed: (isSavingDialog || !isAgreed)
                        ? null 
                        : () async {
                            if (formKey.currentState!.validate()) {
                              setStateDialog(() {
                                isSavingDialog = true; 
                              });
                              
                              await _createUserInFirestore(user, phoneController.text.trim(), selectedJudet!);
                              
                              if (context.mounted) {
                                Navigator.of(context).pop(); 
                              }
                            }
                          },
                    child: isSavingDialog 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text("Salvați"), 
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createUserInFirestore(
      User user, String phone, String judet) async {
    
    String fullName = user.displayName ?? "Utilizator Google";
    List<String> nameParts = fullName.split(" ");
    String prenume = nameParts.isNotEmpty ? nameParts.first : "";
    String nume = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    await _firestore.collection('users').doc(user.uid).set({
      'nume': nume,
      'prenume': prenume,
      'email': user.email,
      'telefon': phone,
      'judet': judet,
      'createdAt': FieldValue.serverTimestamp(),
      'savedListingIds': [],
    });

    _showSnackBar("Cont creat cu succes!");
  }

  Future<void> _handleForgotPassword() async {
    String email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showSnackBar('Introduceti adresa de email pentru resetare');
      return;
    }
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if(!emailValid) {
      _showSnackBar('Adresa de email nu este validă');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar("Email de resetare trimis, verificati si folderul spam");
    } on FirebaseAuthException catch (e) {
      String message = "Eroare la trimiterea emailului de resetare.";
      if (e.code == 'user-not-found') {
        message = "Nu există un cont cu acest email.";
      }
      else if(e.code == 'invalid-email') {
        message = "Adresa de email invalida";
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Eroare: $e");
    }
  }
  void _handleLogout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _showSnackBar("Deconectat cu succes.");
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ești sigur?'),
          content: const Text(
              'Această acțiune este permanentă. Toate anunțurile și datele contului vor fi șterse definitiv.'),
          actions: [
            TextButton(
              child: const Text('Anulează', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ȘTERGE', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = user.uid;

      final listingsQuery = await _firestore
          .collection('listings')
          .where('ownerId', isEqualTo: uid)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in listingsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _firestore.collection('users').doc(uid).delete();
      await user.delete();

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnackBar("Contul a fost șters cu succes.");
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnackBar("Eroare: $e");
    }
  }

  Widget _buildProfileDetails(BuildContext context, User user) {
    final String displayName = user.displayName ?? "Utilizator";
    final String displayEmail = user.email ?? "Email indisponibil";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                displayEmail,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildProfileTile(
                  Icons.directions_car_outlined, 'Anunțurile mele', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const FilteredListingsScreen(mode: FilterMode.myListings),
                    ));
              }),
              _buildProfileTile(Icons.bookmark_border, 'Anunțuri salvate', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilteredListingsScreen(
                          mode: FilterMode.savedListings),
                    ));
              }),
              _buildProfileTile(
                Icons.delete_forever_outlined,
                'Șterge Cont',
                _confirmDeleteAccount,
                color: Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Deconectare', style: TextStyle(fontSize: 18)),
          onPressed: _handleLogout,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  ListTile _buildProfileTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    final tileColor = color ?? Theme.of(context).primaryColor;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: color),
      onTap: onTap,
    );
  }

  Widget _buildAuthForm(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Se autentifică..."),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          "Bine ați venit! Conectați-vă aici.",
          style: TextStyle(fontSize: 16.0, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32.0),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Parolă',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword, 
            child: const Text(
              "Ai uitat parola?",
              style: TextStyle(color: Colors.blueAccent,
              fontWeight: FontWeight.w600))
          ),
        ),
        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Login',
              style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
        const SizedBox(height: 16.0),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10), child: Text("SAU")),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16.0),
        
        ElevatedButton.icon(
          onPressed: _handleGoogleSignIn,
          icon: Image.asset(
            'assets/google_logo.png',
            height: 24.0,
            width: 24.0,
          ),
          label: const Text('Conectare cu Google',
              style: TextStyle(color: Colors.black87)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
          child: Text('Creați-vă cont',
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).primaryColor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        return Scaffold(
          appBar: CustomAppBar(title: isLoggedIn ? 'Profil' : 'Autentificare'),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: isLoggedIn
                      ? _buildProfileDetails(context, user)
                      : _buildAuthForm(context)),
          bottomNavigationBar: CustomNavBar(
              currentIndex: _currentIndex, onTabTapped: _onTabTapped),
        );
      },
    );
  }
}