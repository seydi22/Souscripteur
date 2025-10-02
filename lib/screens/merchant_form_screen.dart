import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../services/image_service.dart';
import '../locator.dart';

// Définition des couleurs et des styles de la charte
const Color kPrimaryColor = Color(0xFFF36E21);
const Color kAccentColor = Color(0xFF0056A6);
const Color kBackgroundColor = Color(0xFFFAFAFA); // Equivalent à Colors.grey[100]

final ButtonStyle kPrimaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryColor,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  minimumSize: const Size.fromHeight(50),
);

final ButtonStyle kAccentButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kAccentColor,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  minimumSize: const Size.fromHeight(50),
);

final BoxDecoration kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      spreadRadius: 1,
      blurRadius: 7,
      offset: const Offset(0, 3),
    ),
  ],
);

const BorderRadius kDefaultBorderRadius = BorderRadius.all(Radius.circular(8));

class MerchantFormScreen extends StatefulWidget {
  @override
  _MerchantFormScreenState createState() => _MerchantFormScreenState();
}

class _MerchantFormScreenState extends State<MerchantFormScreen> {
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  bool _isSubmitting = false;
  int _currentStep = 0;

  // Contrôleurs
  final _nomController = TextEditingController();
  final _secteurController = TextEditingController();
  final _typeCommerceController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contactController = TextEditingController();
  final _nifController = TextEditingController();
  final _rcController = TextEditingController();
  final _nomGerantController = TextEditingController();
  final _prenomGerantController = TextEditingController();
  final _communeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _nomOperateurController = TextEditingController();
  final _prenomOperateurController = TextEditingController();
  final _nniOperateurController = TextEditingController();
  final _telephoneOperateurController = TextEditingController();

  // Variables pour les listes déroulantes
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedIdType; // 'cni', 'passeport'

  // Gestion des fichiers
  XFile? _photoEnseigne;
  XFile? _cniRecto;
  XFile? _cniVerso;
  XFile? _photoPasseport;

  // Données pour les listes déroulantes de la Mauritanie
  Map<String, List<String>> mauritaniaRegionsAndCities = {};
  bool _isLoadingRegions = true;

  final ImageService _imageService = locator<ImageService>();

  @override
  void initState() {
    super.initState();
    _fetchRegionsAndCities();
    _nifController.text = '00000001';
    _rcController.text = '001/002';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _secteurController.dispose();
    _typeCommerceController.dispose();
    _adresseController.dispose();
    _contactController.dispose();
    _nifController.dispose();
    _rcController.dispose();
    _nomGerantController.dispose();
    _prenomGerantController.dispose();
    _communeController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    _nomOperateurController.dispose();
    _prenomOperateurController.dispose();
    _nniOperateurController.dispose();
    _telephoneOperateurController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegionsAndCities() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      mauritaniaRegionsAndCities = {
        'Adrar': ['Atar', 'Chinguetti', 'Ouadane', 'Aoujeft'],
        'Assaba': ['Kiffa', 'Guerou', 'Kankossa', 'Barkewol ', 'Boumdeid'],
        'Brakna': ['Aleg', 'Boghe', 'Magta-Lahjar', 'Bababé', 'MBagne'],
        'Dakhlet Nouadhibou': ['Nouadhibou'],
        'Gorgol': ['Kaedi', 'M\'bout', 'Maghama', 'Lexeiba', 'Monguel'],
        'Guidimaka': ['Sélibabi', 'Ould Yengé', 'Ghabou', 'Wompou'],
        'Hodh Ech Chargui': ['Néma', 'Timbedra', 'Amourj', 'Bassikounou', 'Djiguenni', 'Oualata'],
        'Hodh El Gharbi': ['Aïoun el-Atrouss', 'Kobenni', 'Tintane', 'Tamchekett'],
        'Inchiri': ['Akjoujt'],
        'Nouakchott-Nord': ['Dar Naim', 'Teyarett', 'Toujounine'],
        'Nouakchott-Ouest': ['Tevragh Zeïna', 'Sebkha', 'Ksar'],
        'Nouakchott-Sud': ['Arafat', 'El Mina', 'Riyadh'],
        'Tagant': ['Tidjikdja', 'Tichitt', 'Moudjeria'],
        'Tiris Zemmour': ['Zouerate', 'F\'Derick', 'Bir Moghreïn'],
        'Trarza': ['Rosso', 'Boutilimit', 'Mederdra', 'R\\Kiz', 'Keur Macène', 'Ouad Naga'],
      };
      _isLoadingRegions = false;
    });
  }

  Future<void> _showImageSourceSelection(String type) async {
    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: kAccentColor),
              title: const Text('Galerie de photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kAccentColor),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (pickedSource != null) {
      _pickImage(type, pickedSource);
    }
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    final processedImage = await _imageService.pickAndProcessImage(source: source);
    if (processedImage != null) {
      setState(() {
        if (type == 'photoEnseigne') {
          _photoEnseigne = processedImage;
        } else if (type == 'cniRecto') {
          _cniRecto = processedImage;
        } else if (type == 'cniVerso') {
          _cniVerso = processedImage;
        } else if (type == 'photoPasseport') {
          _photoPasseport = processedImage;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    bool allFormsValid = true;
    for (var formKey in _formKeys) {
      if (!formKey.currentState!.validate()) {
        allFormsValid = false;
      }
    }

    if (allFormsValid) {
      if (_isMissingFiles()) {
        _showErrorDialog('Veuillez téléverser tous les documents requis.');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Agent non authentifié.')),
        );
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final uri = Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/merchants/register');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'x-auth-token': '$token'});

      request.fields['nom'] = _nomController.text;
      request.fields['secteur'] = _secteurController.text;
      request.fields['typeCommerce'] = _typeCommerceController.text;
      request.fields['adresse'] = _adresseController.text;
      request.fields['contact'] = '00222${_contactController.text}';
      request.fields['nif'] = _nifController.text;
      request.fields['rc'] = _rcController.text;
      request.fields['region'] = _selectedRegion!;
      request.fields['ville'] = _selectedCity!;
      request.fields['commune'] = _communeController.text;
      request.fields['nomGerant'] = _nomGerantController.text;
      request.fields['prenomGerant'] = _prenomGerantController.text;
      request.fields['typePiece'] = _selectedIdType!;
      request.fields['longitude'] = _longitudeController.text;
      request.fields['latitude'] = _latitudeController.text;
      request.fields['nomOperateur'] = _nomOperateurController.text;
      request.fields['prenomOperateur'] = _prenomOperateurController.text;
      request.fields['nniOperateur'] = _nniOperateurController.text;
      request.fields['telephoneOperateur'] = '00222${_telephoneOperateurController.text}';

      if (_photoEnseigne != null) {
        request.files.add(http.MultipartFile.fromBytes('photoEnseigne', await _photoEnseigne!.readAsBytes(), filename: _photoEnseigne!.name));
      }
      if (_selectedIdType == 'cni' && _cniRecto != null && _cniVerso != null) {
        request.files.add(http.MultipartFile.fromBytes('pieceIdentiteRecto', await _cniRecto!.readAsBytes(), filename: _cniRecto!.name));
        request.files.add(http.MultipartFile.fromBytes('pieceIdentiteVerso', await _cniVerso!.readAsBytes(), filename: _cniVerso!.name));
      } else if (_selectedIdType == 'passeport' && _photoPasseport != null) {
        request.files.add(http.MultipartFile.fromBytes('photoPasseport', await _photoPasseport!.readAsBytes(), filename: _photoPasseport!.name));
      }

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          _showSuccessDialog();
        } else {
          final msg = () {
            try {
              return json.decode(responseBody)['msg'] ?? 'Erreur inconnue';
            } catch (_) {
              return responseBody;
            }
          }();
          _showErrorDialog('Échec de l enrôlement : $msg');
        }
      } catch (e) {
        _showErrorDialog('Erreur de connexion au serveur: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  bool _isMissingFiles() {
    if (_photoEnseigne == null) return true;
    if (_selectedIdType == 'cni' && (_cniRecto == null || _cniVerso == null)) return true;
    if (_selectedIdType == 'passeport' && _photoPasseport == null) return true;
    if (_selectedIdType == null) return true;
    return false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Succès !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAccentColor),
              ),
              const SizedBox(height: 10),
              const Text(
                'Le marchand a été enrôlé avec succès et est maintenant en attente de validation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: kPrimaryButtonStyle,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/agent-dashboard');
                },
                child: const Text('Retour au tableau de bord'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      setState(() => _isSubmitting = true);
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      _showErrorDialog('Erreur de géolocalisation: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Les services de localisation sont désactivés. Veuillez les activer.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('L\'accès à la localisation est refusé.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog('L\'accès à la localisation est refusé de manière permanente. Impossible de demander la permission.');
      return false;
    }
    return true;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile? file, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          if (file != null)
            kIsWeb
                ? Image.network(file.path, height: 50, width: 50, fit: BoxFit.cover)
                : Image.file(File(file.path), height: 50, width: 50, fit: BoxFit.cover),
          const SizedBox(width: 8),
          Expanded(
            child: Text(file != null ? file.name : 'Aucun fichier pour: $label'),
          ),
        ],
      ),
    );
  }

  List<Step> _getSteps() {
    return <Step>[
      Step(
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        title: const Text('Commerce'),
        content: Form(key: _formKeys[0], child: _buildStep1_BusinessInfo()),
      ),
      Step(
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        title: const Text('Gérant'),
        content: Form(key: _formKeys[1], child: _buildStep2_ManagerInfo()),
      ),
      Step(
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        title: const Text('Adresse'),
        content: Form(key: _formKeys[2], child: _buildStep3_AddressInfo()),
      ),
      Step(
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 3,
        title: const Text('Opérateur'),
        content: Form(key: _formKeys[3], child: _buildStep4_OperatorInfo()),
      ),
      Step(
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 4,
        title: const Text('Documents'),
        content: Form(key: _formKeys[4], child: _buildStep5_Documents()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Enrôlement du marchand'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          final isLastStep = _currentStep == _getSteps().length - 1;
          if (_formKeys[_currentStep].currentState!.validate()) {
            if (isLastStep) {
              _submitForm();
            } else {
              setState(() {
                _currentStep += 1;
              });
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: _getSteps(),
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == _getSteps().length - 1;
          return Container(
            margin: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: <Widget>[
                if (_currentStep != 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Précédent'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: kPrimaryButtonStyle,
                    child: Text(isLastStep ? 'Soumettre' : 'Suivant'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1_BusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations sur l\'activité commerciale  معلومات عن النشاط التجاري'),
        TextFormField(
          controller: _nomController,
          decoration: InputDecoration(
            labelText: 'Nom de l\'enseigne commerciale اسم العلامة التجارية',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom de l\'enseigne';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _secteurController,
          decoration: InputDecoration(
            labelText: 'Secteur d\'activité   نوع النشاط',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le secteur d\'activité';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _typeCommerceController,
          decoration: InputDecoration(
            labelText: 'Nature de l\'activité commerciale  طبيعة النشاط التجاري',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer la nature de l\'activité';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2_ManagerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations du gérant et fiscales  معلومات عن المدير والبيانات الضريبية'),
        TextFormField(
          controller: _nomGerantController,
          decoration: InputDecoration(
            labelText: 'Nom du gérant  اسم  ممثل القانوني',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom du gérant';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prenomGerantController,
          decoration: InputDecoration(
            labelText: 'Prénom du gérant   لقب ممثل القانوني ',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le prénom du gérant';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nifController,
          decoration: InputDecoration(
            labelText: 'NIF رقم السجل الضريبي ',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          maxLength: 10,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le NIF';
            }
            if (!(value.length == 8 || value.length == 10)) {
              return 'Le NIF doit contenir exactement 8 ou 10 chiffres.';
            }
            if (RegExp(r'^(0+|1+)$').hasMatch(value)) {
              return 'Le NIF ne peut pas être composé uniquement de zéros ou de uns.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rcController,
          decoration: InputDecoration(
            labelText: 'RC (Registre de Commerce  رقم السجل التجاري)',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le RC';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep3_AddressInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Adresse et Localisation  العنوان والموقع'),
        _isLoadingRegions
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Région  الولاية',
                  border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
                ),
                items: mauritaniaRegionsAndCities.keys.map((String region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRegion = newValue;
                    _selectedCity = null;
                  });
                },
                validator: (value) => value == null ? 'Sélectionnez une région' : null,
              ),
        const SizedBox(height: 16),
        _isLoadingRegions
            ? const SizedBox.shrink()
            : DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'Ville  المدينة',
                  border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
                ),
                items: _selectedRegion != null
                    ? mauritaniaRegionsAndCities[_selectedRegion]!.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                    : [],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
                validator: (value) => value == null ? 'Sélectionnez une ville' : null,
              ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _communeController,
          decoration: InputDecoration(
            labelText: 'Commune  البلدية',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer la commune';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _adresseController,
          decoration: InputDecoration(
            labelText: 'Adresse العنوان',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer l\'adresse';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text('Coordonnées GPS  الإحداثيات الجغرافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentColor)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _getCurrentPosition,
          icon: const Icon(Icons.my_location),
          label: const Text('Obtenir les coordonnées GPS'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: kAccentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(
                  labelText: 'Longitude خط الطول',
                  border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
                ),
                readOnly: true,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(
                  labelText: 'Latitude  خط العرض',
                  border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
                ),
                readOnly: true,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone  رقم الهاتف',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          maxLength: 8,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le numéro de téléphone';
            }
            if (value.length < 8 || !RegExp(r'^[423]\d{7,}').hasMatch(value)) {
              return 'Le numéro doit avoir au moins 8 chiffres et commencer par 4, 2 ou 3.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep4_OperatorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations de l\'opérateur  معلومات عن المشغّل'),
        TextFormField(
          controller: _nomOperateurController,
          decoration: InputDecoration(
            labelText: 'Nom de l\'opérateur اسم  المشغّل',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Nom de l\'opérateur requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prenomOperateurController,
          decoration: InputDecoration(
            labelText: 'Prénom de l\'opérateur لقب المشغّل',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Prénom de l\'opérateur requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nniOperateurController,
          decoration: InputDecoration(
            labelText: 'NNI de l\'opérateur  رقم وثيقة الهوية',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          maxLength: 10,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return 'NNI requis';
            if (v.length != 10) return 'Le NNI doit avoir 10 chiffres.';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telephoneOperateurController,
          decoration: InputDecoration(
            labelText: 'Téléphone de l\'opérateur  هاتف المشغّل',
            border: OutlineInputBorder(borderRadius: kDefaultBorderRadius),
          ),
          maxLength: 8,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Téléphone requis';
            if (value.length < 8 || !RegExp(r'^[423]\d{7,}').hasMatch(value)) {
              return 'Le numéro doit avoir au moins 8 chiffres et commencer par 4, 2 ou 3.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep5_Documents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Documents à téléverser  وثيقة للتحميل'),
        const Text('Pièce d\'identité du représentant légal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAccentColor)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('CNI رقم وثيقة الهوية/ Carte de séjour  بطاقة إقامة'),
                value: 'cni',
                groupValue: _selectedIdType,
                onChanged: (value) {
                  setState(() {
                    _selectedIdType = value;
                  });
                },
                activeColor: kAccentColor,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Passeport  جواز السفر'),
                value: 'passeport',
                groupValue: _selectedIdType,
                onChanged: (value) {
                  setState(() {
                    _selectedIdType = value;
                  });
                },
                activeColor: kAccentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedIdType == 'cni') ...[
          ElevatedButton.icon(
            onPressed: () => _showImageSourceSelection('cniRecto'),
            icon: const Icon(Icons.upload_file),
            label: const Text('CNI Recto  بطاقة التعريف الوطنية (الجهة الأمامية)'),
            style: kAccentButtonStyle,
          ),
          _buildImagePreview(_cniRecto, 'CNI Recto'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showImageSourceSelection('cniVerso'),
            icon: const Icon(Icons.upload_file),
            label: const Text('CNI Verso بطاقة التعريف الوطنية (الجهة الخلفية)'),
            style: kAccentButtonStyle,
          ),
          _buildImagePreview(_cniVerso, 'CNI Verso'),
          const SizedBox(height: 8),
        ],
        if (_selectedIdType == 'passeport') ...[
          ElevatedButton.icon(
            onPressed: () => _showImageSourceSelection('photoPasseport'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Passeport جواز السفر'),
            style: kAccentButtonStyle,
          ),
          _buildImagePreview(_photoPasseport, 'Passeport'),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showImageSourceSelection('photoEnseigne'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Téléverser Photo Enseigne  صورة اللافتة'),
          style: kAccentButtonStyle,
        ),
        _buildImagePreview(_photoEnseigne, 'Photo Enseigne'),
        if (_selectedIdType == null)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Veuillez sélectionner un type de pièce d\'identité.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}