
import 'package:cumpar_auto/widgets/custom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cumpar_auto/widgets/custom_appbar.dart';
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentIndex = 2; // indexul Contact

  final List<String> marci = [
    "Audi", "BMW", "Chevrolet", "Citroen", "Dacia", "Fiat", "Ford", "Honda",
    "Hyundai", "Kia", "Mazda", "Mercedes-Benz", "Mitsubishi", "Nissan",
    "Opel", "Peugeot", "Renault", "Seat", "Skoda", "Subaru", "Suzuki",
    "Toyota", "Volkswagen", "Volvo"
  ];

  final List<String> combustibili = ['benzina','motorina','electric','hybrid'];

  String? marcaSelectata;
  String? combustibilSelectat;
  final TextEditingController numeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController anController = TextEditingController();
  final TextEditingController descriereController = TextEditingController();
  final TextEditingController pretController = TextEditingController();


  @override
  void dispose() {
    numeController.dispose();
    emailController.dispose();
    modelController.dispose();
    anController.dispose();
    descriereController.dispose();
    pretController.dispose();
    super.dispose();
  }
  
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String message = '''
        Cerere cumpărare auto:
        Nume și Prenume: ${numeController.text}
        Email: ${emailController.text}
        Marca: ${marcaSelectata ?? ''}
        Model: ${modelController.text}
        An fabricație: ${anController.text}
        Combustibil: ${combustibilSelectat ?? ''}
        Preț cerut: ${pretController.text}€
        Descriere: ${descriereController.text}
        ''';
      String phoneNumber = "40733850800";

      final Uri whatsappUri = Uri.parse(
          "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");

      try {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        final Uri whatsappWebUri = Uri.parse(
            "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
        try {
          await launchUrl(
            whatsappWebUri,
            mode: LaunchMode.externalApplication, 
          );
        } catch (e) {
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nu se poate deschide WhatsApp")),
          );
        }
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Vinde Auto!'),
      body: Container(
        width: double.infinity,
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
                      // Nume și Prenume
                      TextFormField(
                        controller: numeController,
                        decoration: InputDecoration(
                          labelText: 'Nume și Prenume',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Introdu numele și prenumele"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Introdu email-ul";
                          }
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return "Introdu un email valid";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: marcaSelectata,
                        decoration: InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        items: marci.map((marca) {
                          return DropdownMenuItem(
                            value: marca,
                            child: Text(marca),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            marcaSelectata = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Selectează o marcă" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: modelController,
                        decoration: InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Introdu modelul"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: anController,
                        decoration: InputDecoration(
                          labelText: 'An fabricație',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Introdu anul fabricației";
                          }
                          if (int.tryParse(value) == null) {
                            return "Introdu un număr valid";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: combustibilSelectat,
                        decoration: InputDecoration(
                          labelText: 'Tip combustibil',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        items: combustibili.map((comb) {
                          return DropdownMenuItem(
                            value: comb,
                            child: Text(comb),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            combustibilSelectat = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Selectează tip combustibil" : null,
                      ),
                      const SizedBox(height:16),
                      TextFormField(
                        controller: pretController,
                        decoration: InputDecoration(
                          labelText:'Prețul cerut în euro',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          )
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Introdu prețul cerut";
                          }
                          if (int.tryParse(value) == null) {
                            return "Introdu un număr valid";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor:
                              const Color.fromRGBO(48, 48, 48, 1),
                        ),
                        child: const Text(
                          "Trimite cererea",
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
      bottomNavigationBar: CustomNavBar(currentIndex: _currentIndex, onTabTapped: _onTabTapped),
    );
  }
}
