import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'models/scheduling_models.dart';
import 'services/scheduling_service.dart';
import 'providers/scheduling_provider.dart';
import 'pages/staff_scheduling_page.dart';
import 'pages/my_appointments_page.dart';
import 'pages/service_selection_page.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'pages/app_intro_page.dart';
import 'widgets/mobile_app_shell.dart';

class _SalonMark extends StatelessWidget {
  final double size;
  final bool showName;

  const _SalonMark({this.size = 30, this.showName = true});

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/favicon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(Icons.spa_rounded, color: AppColors.primary, size: size * 0.62),
          );
        },
      ),
    );

    if (!showName) return logo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 10),
        Text(
          'SALON',
          style: AppTypography.brand.copyWith(
            fontSize: size * 0.78,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}

class _SalonHeaderTitle extends StatelessWidget {
  const _SalonHeaderTitle();

  @override
  Widget build(BuildContext context) => const _SalonMark(size: 30);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SalonApp());
}

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon Booking',
      theme: buildSalonTheme(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ChangeNotifierProvider<ServiceSelectionProvider>(
          create: (_) => ServiceSelectionProvider(allSalonServices),
          child: MobileAppShell(child: child!),
        );
      },
      home: const AppIntroPage(nextPage: AuthWrapper()),
    );
  }
}

// One combined catalog, each service tagged with the correct category.
// Put this near the top of main.dart, outside any class.
final List<SalonService> allSalonServices = [
  // --- Haircut ---
  SalonService(id: 'haircut_layered_cut', name: 'Layered Cut', durationMinutes: 45, price: 800, imageUrl: 'assets/images/haircuts/layered-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_bob_cut', name: 'Bob Cut', durationMinutes: 40, price: 700, imageUrl: 'assets/images/haircuts/bob-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_curtain_bangs', name: 'Curtain Bangs', durationMinutes: 35, price: 700, imageUrl: 'assets/images/haircuts/curtain-bangs.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_feather_cut', name: 'Feather Cut', durationMinutes: 45, price: 850, imageUrl: 'assets/images/haircuts/feather-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_wolf_cut', name: 'Wolf Cut', durationMinutes: 50, price: 1000, imageUrl: 'assets/images/haircuts/wolf-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_fade_cut', name: 'Fade Cut', durationMinutes: 35, price: 450, imageUrl: 'assets/images/haircuts/fade-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_undercut', name: 'Undercut', durationMinutes: 30, price: 400, imageUrl: 'assets/images/haircuts/undercut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_crew_cut', name: 'Crew Cut', durationMinutes: 25, price: 350, imageUrl: 'assets/images/haircuts/crew-cut.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_pompadour', name: 'Pompadour', durationMinutes: 40, price: 500, imageUrl: 'assets/images/haircuts/pompadour.jpg', category: 'Haircut'),
  SalonService(id: 'haircut_taper_cut', name: 'Taper Cut', durationMinutes: 30, price: 400, imageUrl: 'assets/images/haircuts/taper-cut.jpg', category: 'Haircut'),

  // --- Hair Treatment ---
  SalonService(id: 'treat_keratin', name: 'Keratin Treatment', durationMinutes: 120, price: 2000, imageUrl: 'assets/images/treatments/keratin-treatment.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_brazilian', name: 'Brazilian Blowout', durationMinutes: 150, price: 2500, imageUrl: 'assets/images/treatments/brazilian-blowout.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_rebonding', name: 'Hair Rebonding', durationMinutes: 180, price: 2800, imageUrl: 'assets/images/treatments/hair-rebonding.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_spa', name: 'Hair Spa / Deep Conditioning', durationMinutes: 60, price: 700, imageUrl: 'assets/images/treatments/hair-spa.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_hot_oil', name: 'Hot Oil Treatment', durationMinutes: 45, price: 500, imageUrl: 'assets/images/treatments/hot-oil-treatment.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_botox', name: 'Hair Botox / Bond Repair', durationMinutes: 120, price: 2200, imageUrl: 'assets/images/treatments/hair-botox.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_scalp', name: 'Scalp Detox / Scalp Treatment', durationMinutes: 45, price: 600, imageUrl: 'assets/images/treatments/scalp-detox.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_olaplex', name: 'Olaplex / Smartbond Treatment', durationMinutes: 90, price: 1800, imageUrl: 'assets/images/treatments/smart-bond.jpg', category: 'Hair Treatment'),
  SalonService(id: 'treat_color_protect', name: 'Color Protect Treatment', durationMinutes: 60, price: 1000, imageUrl: 'assets/images/treatments/color-protect.jpg', category: 'Hair Treatment'),

  // --- Hair Color ---
  SalonService(id: 'color_ash_brown', name: 'Ash Brown', durationMinutes: 90, price: 2000, imageUrl: 'assets/images/colors/ash-brown.jpg', category: 'Hair Color'),
  SalonService(id: 'color_balayage', name: 'Balayage', durationMinutes: 150, price: 2500, imageUrl: 'assets/images/colors/balayage.jpg', category: 'Hair Color'),
  SalonService(id: 'color_ombre', name: 'Ombre', durationMinutes: 120, price: 2200, imageUrl: 'assets/images/colors/ombre.jpg', category: 'Hair Color'),
  SalonService(id: 'color_blonde', name: 'Blonde', durationMinutes: 120, price: 2000, imageUrl: 'assets/images/colors/blonde.jpg', category: 'Hair Color'),
  SalonService(id: 'color_rose_gold', name: 'Rose Gold', durationMinutes: 120, price: 2400, imageUrl: 'assets/images/colors/rose-gold.jpg', category: 'Hair Color'),
  SalonService(id: 'color_burgundy', name: 'Burgundy', durationMinutes: 90, price: 1800, imageUrl: 'assets/images/colors/burgundy.jpg', category: 'Hair Color'),
  SalonService(id: 'color_jet_black', name: 'Jet Black', durationMinutes: 60, price: 1200, imageUrl: 'assets/images/colors/jet-black.jpg', category: 'Hair Color'),
  SalonService(id: 'color_silver', name: 'Silver', durationMinutes: 120, price: 2400, imageUrl: 'assets/images/colors/silver.jpg', category: 'Hair Color'),
  SalonService(id: 'color_violet', name: 'Violet', durationMinutes: 120, price: 2200, imageUrl: 'assets/images/colors/violet.jpg', category: 'Hair Color'),
];

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const MainPage();
        }
        
        return const HomePage();
      },
    );
  }
}

class CheckoutManager {
  static final CheckoutManager _instance = CheckoutManager._internal();
  factory CheckoutManager() => _instance;
  CheckoutManager._internal();

  final List<Map<String, String>> _selectedServices = [];
  
  List<Map<String, String>> get selectedServices => List.unmodifiable(_selectedServices);
  
  bool hasService(String serviceName) {
    return _selectedServices.any((s) => s['name'] == serviceName);
  }
  
  bool hasCategoryService(String category) {
    return _selectedServices.any((s) => s['category'] == category);
  }
  
  String? getServiceFromCategory(String category) {
    try {
      return _selectedServices.firstWhere((s) => s['category'] == category)['name'];
    } catch (e) {
      return null;
    }
  }
  
  void addService(Map<String, String> service) {
    _selectedServices.add(service);
  }
  
  void removeService(int index) {
    _selectedServices.removeAt(index);
  }
  
  void clear() {
    _selectedServices.clear();
  }
  
  int get count => _selectedServices.length;
}



// -----------------------------------------------------------------------------
// Restored authentication and authenticated navigation pages.
// These classes are intentionally kept in main.dart to preserve the existing
// application routing while the newer UI is housed in dedicated page files.
// -----------------------------------------------------------------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String? selectedGender;
  final AuthService _authService = AuthService();
  
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController(); // ✅ NEW
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // ✅ NEW
  
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? error = await _authService.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      gender: selectedGender,
      contact: contactController.text.trim(),
      address: '',
    );

    if (!mounted) return;
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFD3CBBB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Created!',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account has been created successfully. Please log in to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFD3CBBB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text(
                  'Sign Up Failed',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              error,
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B6F47)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Create your account to book salon services',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'First Name',
                        controller: firstNameController,
                        icon: Icons.person_outline,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        'Last Name',
                        controller: lastNameController,
                        icon: Icons.person_outline,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                _buildGenderDropdown(),
                const SizedBox(height: 12),
                
                _buildTextField(
                  'Email Address',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                
                _buildTextField(
                  'Phone Number',
                  controller: contactController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _validateContact,
                ),
                const SizedBox(height: 12),
                
                _buildTextField(
                  'Password',
                  controller: passwordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF8B6F47),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                
                // ✅ NEW - Confirm Password Field
                _buildTextField(
                  'Confirm Password',
                  controller: confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF8B6F47),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B0000),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF8B6F47), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B0000), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF8B6F47), size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B0000), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B6F47)),
      items: const [
        DropdownMenuItem(
          value: 'Male',
          child: Text('Male', style: TextStyle(fontSize: 15)),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text('Female', style: TextStyle(fontSize: 15)),
        ),
        DropdownMenuItem(
          value: 'Other',
          child: Text('Other', style: TextStyle(fontSize: 15)),
        ),
        DropdownMenuItem(
          value: 'Prefer not to say',
          child: Text('Prefer not to say', style: TextStyle(fontSize: 15)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose(); // ✅ NEW
    super.dispose();
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _obscurePassword = true;

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    bool hasEmailError = email.isEmpty;
    bool hasPasswordError = password.isEmpty;

    setState(() {
      _emailError = hasEmailError;
      _passwordError = hasPasswordError;
    });

    if (hasEmailError || hasPasswordError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? error = await _authService.signIn(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Login Failed'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
        toolbarHeight: 88,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const _SalonMark(size: 44),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: AppTypography.buildTextTheme().headlineLarge?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: AppTypography.buildTextTheme().bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (_emailError && value.isNotEmpty) {
                      setState(() => _emailError = false);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: _emailError ? Colors.red : const Color(0xFF8B6F47),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: _emailError ? 'Email is required' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    if (_passwordError && value.isNotEmpty) {
                      setState(() => _passwordError = false);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: _passwordError ? Colors.red : const Color(0xFF8B6F47),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: _passwordError ? 'Password is required' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF8B6F47),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF8B6F47),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      disabledBackgroundColor: const Color(0xFF8B0000).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create New Account',
                      style: TextStyle(
                        color: Color(0xFF8B6F47),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _emailError = false;

  void _resetPassword() async {
    final email = emailController.text.trim();

    setState(() {
      _emailError = email.isEmpty;
    });

    if (_emailError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? error = await _authService.resetPassword(email: email);

    if (!mounted) return;
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFD3CBBB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Email Sent!',
              style: TextStyle(
                color: Color(0xFF8B0000),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Password reset link has been sent to your email. Please check your inbox.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFD3CBBB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Error',
              style: TextStyle(
                color: Color(0xFF8B0000),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              error,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B6F47)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Color(0xFF8B6F47),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFFD3CBBB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Color(0xFF8B0000),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _emailError
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (_emailError && value.isNotEmpty) {
                          setState(() {
                            _emailError = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: _emailError ? Colors.red : const Color(0xFF8B6F47),
                          fontSize: 14,
                        ),
                        border: const OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Send Reset Link',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  
  String _userName = 'User';
  String _userEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    final currentUser = _authService.currentUser;
    if (!mounted) return;
    
    setState(() {
      if (userData != null) {
        _userName = '${userData['firstName'] ?? ''}'.trim();
        if (_userName.isEmpty) _userName = 'User';
      }
      _userEmail = currentUser?.email ?? 'user@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        titleSpacing: 20,
        title: const _SalonMark(size: 38),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.selectedBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (MediaQuery.sizeOf(context).width >= 520)
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        width: 280,
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B0000),
                      Color(0xFFB22222),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildDrawerItem(
                        context: context,
                        title: 'My Appointments',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyAppointmentsPage()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        title: 'Profile Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        title: 'Staff Schedules',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StaffSchedulesViewPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                    _buildDrawerItem(
                      context: context,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: () {
                        _showLogoutConfirmation(context);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              ServiceCard(
                title: 'Haircut',
                imageUrl: 'assets/images/cards/haircut-card.jpg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HaircutServicesPage()),
                ),
              ),
              const SizedBox(height: 10),
              ServiceCard(
                title: 'Hair Treatment',
                imageUrl: 'assets/images/cards/treatment-card.jpg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HairServicesPage()),
                ),
              ),
              const SizedBox(height: 10),
              ServiceCard(
                title: 'Hair Color',
                imageUrl: 'assets/images/cards/color-card.jpg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HairColorPage()),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red[700] : Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                const Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext); // Close dialog
                            Navigator.pop(context); // Close drawer
                            await AuthService().signOut();
                            CheckoutManager().clear();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const HomePage()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class HaircutServicesPage extends StatelessWidget {
  const HaircutServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceSelectionPage(
      categoryTitle: 'Haircut',
      onContinue: (context, selected, totalDuration, totalPrice) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => SchedulingProvider(),
              child: StaffSchedulingPage(
                totalDurationMinutes: totalDuration,
                onScheduleConfirmed: (staffId, startTime) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        totalAmount: totalPrice.toInt(),
                        services: selected.map((s) => {
                          'name': s.name,
                          'duration': s.formattedDuration,
                          'price': s.price.toInt().toString(),
                          'category': s.category,
                        }).toList(),
                        scheduledStaffId: staffId,
                        scheduledStartTime: startTime,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class HairServicesPage extends StatelessWidget {
  const HairServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceSelectionPage(
      categoryTitle: 'Hair Treatment',
      onContinue: (context, selected, totalDuration, totalPrice) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => SchedulingProvider(),
              child: StaffSchedulingPage(
                totalDurationMinutes: totalDuration,
                onScheduleConfirmed: (staffId, startTime) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        totalAmount: totalPrice.toInt(),
                        services: selected.map((s) => {
                          'name': s.name,
                          'duration': s.formattedDuration,
                          'price': s.price.toInt().toString(),
                          'category': s.category,
                        }).toList(),
                        scheduledStaffId: staffId,
                        scheduledStartTime: startTime,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class HairColorPage extends StatelessWidget {
  const HairColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceSelectionPage(
      categoryTitle: 'Hair Color',
      onContinue: (context, selected, totalDuration, totalPrice) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => SchedulingProvider(),
              child: StaffSchedulingPage(
                totalDurationMinutes: totalDuration,
                onScheduleConfirmed: (staffId, startTime) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        totalAmount: totalPrice.toInt(),
                        services: selected.map((s) => {
                          'name': s.name,
                          'duration': s.formattedDuration,
                          'price': s.price.toInt().toString(),
                          'category': s.category,
                        }).toList(),
                        scheduledStaffId: staffId,
                        scheduledStartTime: startTime,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _openGuestService(String title, String category, IconData icon) {
    final services = allSalonServices
        .where((service) => service.category == category)
        .map((service) => <String, String>{
              'name': service.name,
              'duration': service.formattedDuration,
              'price': service.formattedPrice,
              'imageUrl': service.imageUrl,
              'category': service.category,
            })
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuestServicePage(
          title: title,
          services: services,
          iconData: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        titleSpacing: 20,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const _SalonMark(size: 38),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Log in'),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'BEAUTY • CARE • CONFIDENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your next great\nlook starts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.06,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Explore our signature services and book a time that works for you.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 170,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Text(
                'Explore services',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.45),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ModernServiceCard(
                  title: 'Haircut',
                  subtitle: 'Cuts, trims & styling',
                  imageUrl: 'assets/images/cards/haircut-card.jpg',
                  onTap: () => _openGuestService('Haircut', 'Haircut', Icons.content_cut_rounded),
                ),
                SizedBox(height: 14),
                ModernServiceCard(
                  title: 'Hair Treatment',
                  subtitle: 'Repair, nourish & restore',
                  imageUrl: 'assets/images/cards/treatment-card.jpg',
                  onTap: () => _openGuestService('Hair Treatment', 'Hair Treatment', Icons.spa_rounded),
                ),
                SizedBox(height: 14),
                ModernServiceCard(
                  title: 'Hair Color',
                  subtitle: 'Color, tone & transform',
                  imageUrl: 'assets/images/cards/color-card.jpg',
                  onTap: () => _openGuestService('Hair Color', 'Hair Color', Icons.palette_outlined),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernServiceCard(
      title: title,
      subtitle: 'Discover your next signature look',
      imageUrl: imageUrl,
      onTap: onTap,
    );
  }
}

class ModernServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const ModernServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: 188,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.asset(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: AppColors.surfaceAlt),
                  )
                else
                  const ColoredBox(color: AppColors.surfaceAlt),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primaryDark.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.buildTextTheme().headlineSmall?.copyWith(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuestServicePage extends StatelessWidget {
  final String title;
  final List<Map<String, String>> services;
  final IconData iconData;

  const GuestServicePage({
    super.key,
    required this.title,
    required this.services,
    required this.iconData,
  });

  void _showLoginDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: AppColors.selectedBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ready to book your look?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Create an account or log in to reserve a service, choose your stylist, and manage your appointments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Log in to book'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Create an account'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 4 : width >= 720 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(iconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title • ${services.length} options',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Tap any service to view details and book.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = services[index];
                  final image = service['imageUrl'];
                  final price = service['price'] ?? '';
                  final duration = service['duration'] ?? '';

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _showLoginDialog(context),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.055),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      image ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFEAD7DA), Color(0xFFF7F0F1)],
                                          ),
                                        ),
                                        child: Icon(iconData, color: AppColors.primary, size: 34),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.38),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          service['category'] ?? title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service['name'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            duration,
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Text(
                                          price,
                                          style: const TextStyle(fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: services.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width < 420 ? 0.77 : 0.82,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>> services;
  final String? scheduledStaffId;
  final DateTime? scheduledStartTime;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.services,
    this.scheduledStaffId,
    this.scheduledStartTime,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with SingleTickerProviderStateMixin {
  String selectedPayment = 'Cash';
  final BookingService _bookingService = BookingService();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getStaffName(String staffId) {
    for (final staff in StaffMember.defaults) {
      if (staff.id == staffId) return staff.name;
    }
    return 'Staff';
  }

  void _processPayment() async {
    if (_isProcessing || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    String? error;

    if (widget.scheduledStaffId != null && widget.scheduledStartTime != null) {
      error = await _bookingService.createBookingWithSchedule(
        services: widget.services.map((s) => {
          'name': s['name']?.toString() ?? '',
          'duration': s['duration']?.toString() ?? '',
          'price': s['price']?.toString() ?? '',
          'category': s['category']?.toString() ?? '',
        }).toList(),
        totalAmount: widget.totalAmount,
        paymentMethod: selectedPayment,
        staffId: widget.scheduledStaffId!,
        scheduledStartTime: widget.scheduledStartTime!,
      );
    } else {
      error = await _bookingService.createBookingWithoutSchedule(
        services: widget.services.map((s) => {
          'name': s['name']?.toString() ?? '',
          'duration': s['duration']?.toString() ?? '',
          'price': s['price']?.toString() ?? '',
          'category': s['category']?.toString() ?? '',
        }).toList(),
        totalAmount: widget.totalAmount,
        paymentMethod: selectedPayment,
      );
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (error != null) {
      _showErrorDialog('Booking Failed', error);
      return;
    }

    _showSuccessDialog();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    _animationController.forward(from: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final appointment = widget.scheduledStartTime;
        final staffName = widget.scheduledStaffId == null
            ? null
            : _getStaffName(widget.scheduledStaffId!);

        return FadeTransition(
          opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(color: Color(0xFFE8F7EE), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: AppColors.success, size: 38),
                    ),
                    const SizedBox(height: 14),
                    const Text('You’re all set', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Your appointment has been successfully booked.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('₱${widget.totalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                            ],
                          ),
                          if (appointment != null) ...[
                            const SizedBox(height: 10),
                            _successRow(Icons.calendar_today_rounded, DateFormat('EEE, MMM d').format(appointment)),
                            const SizedBox(height: 7),
                            _successRow(Icons.schedule_rounded, TimeOfDay.fromDateTime(appointment).format(context)),
                            if (staffName != null) ...[
                              const SizedBox(height: 7),
                              _successRow(Icons.person_rounded, staffName),
                            ],
                          ],
                          const SizedBox(height: 7),
                          _successRow(selectedPayment == 'Cash' ? Icons.payments_rounded : Icons.account_balance_wallet_rounded, 'Paid via $selectedPayment'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<ServiceSelectionProvider>().clearSelection();
                          CheckoutManager().clear();
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const MainPage()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _successRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Checkout'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, -6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Secure checkout • Review everything before confirming.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
                  Text('₱${widget.totalAmount}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isProcessing
                        ? const Row(key: ValueKey('processing'), mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white)), SizedBox(width: 10), Text('Confirming booking…')])
                        : Row(key: const ValueKey('confirm'), mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_rounded), const SizedBox(width: 8), Text('Confirm payment')]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _buildCheckoutIntro(),
            const SizedBox(height: 16),
            _buildOrderSummary(),
            if (widget.scheduledStartTime != null) ...[
              const SizedBox(height: 14),
              _buildScheduleInfo(),
            ],
            const SizedBox(height: 20),
            const Text('Payment method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 5),
            const Text('Choose how you would like to pay at checkout.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildPaymentOption('Cash', Icons.payments_rounded, 'Pay at the salon counter'),
            const SizedBox(height: 10),
            _buildPaymentOption('GCash', Icons.account_balance_wallet_rounded, 'Pay using the GCash mobile app'),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutIntro() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Almost there', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Make it official.', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Text(
                '₱${widget.totalAmount}',
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _checkoutStep('01', 'Review', active: true),
              Expanded(child: Container(height: 1, color: Colors.white24)),
              _checkoutStep('02', 'Payment', active: true),
              Expanded(child: Container(height: 1, color: Colors.white24)),
              _checkoutStep('03', 'Done'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkoutStep(String number, String label, {bool active = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: active ? AppColors.primary : Colors.white54,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.selectedBackground, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order summary', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('Services included in this booking', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))])), Text('${widget.services.length} item${widget.services.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary))]),
          const SizedBox(height: 14),
          ...widget.services.map((service) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.selectedBackground, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(service['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${service['category'] ?? ''} • ${service['duration'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))])), const SizedBox(width: 8), Text('₱${service['price']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary))]),
              )),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), Text('₱${widget.totalAmount}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary))]),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    final date = widget.scheduledStartTime!;
    final staffName = widget.scheduledStaffId == null ? null : _getStaffName(widget.scheduledStaffId!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFF8F2), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.success.withValues(alpha: 0.20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20)), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Appointment confirmed', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.success)), SizedBox(height: 2), Text('Your selected schedule is reserved for checkout.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))]))]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [_schedulePill(Icons.calendar_today_rounded, DateFormat('EEE, MMM d').format(date)), _schedulePill(Icons.schedule_rounded, TimeOfDay.fromDateTime(date).format(context)), if (staffName != null) _schedulePill(Icons.person_rounded, staffName)]),
      ]),
    );
  }

  Widget _schedulePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: AppColors.success), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary))]),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, String description) {
    final isSelected = selectedPayment == method;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isProcessing ? null : () => setState(() => selectedPayment = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selectedBackground : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.6 : 1),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5))]
                : null,
          ),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(method, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: isSelected ? AppColors.primary : AppColors.textPrimary)), const SizedBox(height: 3), Text(description, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))])),
            AnimatedContainer(duration: const Duration(milliseconds: 180), width: 24, height: 24, decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.6)), child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null),
          ]),
        ),
      ),
    );
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AuthService _authService = AuthService();
  
  String firstName = '';
  String lastName = '';
  String userEmail = '';
  String contact = '';
  String? gender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final userData = await _authService.getUserData();
    final currentUser = _authService.currentUser;

    if (userData != null && mounted) {
      setState(() {
        firstName = userData['firstName'] ?? '';
        lastName = userData['lastName'] ?? '';
        contact = userData['contact'] ?? '';
        gender = userData['gender'];
        userEmail = currentUser?.email ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  _buildSectionCard(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'Update your name and gender',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            firstName: firstName,
                            lastName: lastName,
                            gender: gender,
                            onSaved: _loadUserData,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  _buildSectionCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  _buildSectionCard(
                    icon: Icons.contact_mail_outlined,
                    title: 'Personal Details',
                    subtitle: 'Manage contact and email',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPersonalDetailsPage(
                            email: userEmail,
                            contact: contact,
                            onSaved: _loadUserData,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Keep your profile updated to ensure smooth bookings and communications.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String? gender;
  final VoidCallback onSaved;

  const EditProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.onSaved,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  String? selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);
    selectedGender = widget.gender;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'gender': selectedGender,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        widget.onSaved();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your name and gender information',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),

              _buildTextField(
                'First Name',
                controller: firstNameController,
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                'Last Name',
                controller: lastNameController,
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
              ),
              const SizedBox(height: 15),

              _buildGenderDropdown(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8B6F47), size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF8B6F47), size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B6F47)),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(fontSize: 15))),
        DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(fontSize: 15))),
        DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(fontSize: 15))),
        DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say', style: TextStyle(fontSize: 15))),
      ],
      onChanged: (value) {
        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChanging = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPasswordController.text.trim());

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Password changed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else {
        errorMessage = e.message ?? 'An error occurred';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChanging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new one',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),

              _buildPasswordField(
                'Current Password',
                controller: currentPasswordController,
                obscureText: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              _buildPasswordField(
                'New Password',
                controller: newPasswordController,
                obscureText: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 6) return 'Must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildPasswordField(
                'Confirm New Password',
                controller: confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value != newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isChanging ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isChanging
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your new password is at least 6 characters long and contains a mix of letters and numbers for better security.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label, {
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8B6F47), size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF8B6F47),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

class EditPersonalDetailsPage extends StatefulWidget {
  final String email;
  final String contact;
  final VoidCallback onSaved;

  const EditPersonalDetailsPage({
    super.key,
    required this.email,
    required this.contact,
    required this.onSaved,
  });

  @override
  State<EditPersonalDetailsPage> createState() => _EditPersonalDetailsPageState();
}

class _EditPersonalDetailsPageState extends State<EditPersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController contactController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    contactController = TextEditingController(text: widget.contact);
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Contact is optional
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'contact': contactController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        widget.onSaved();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Contact updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Details',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your contact details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF8B6F47),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email cannot be changed as it\'s linked to your account',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                validator: _validateContact,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF8B6F47), size: 22),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  helperText: 'Enter 10-11 digit phone number',
                  helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_android, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep your phone number updated to receive important notifications about your appointments.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    contactController.dispose();
    super.dispose();
  }
}

class StaffSchedulesViewPage extends StatefulWidget {
  const StaffSchedulesViewPage({super.key});

  @override
  State<StaffSchedulesViewPage> createState() => _StaffSchedulesViewPageState();
}

class _StaffSchedulesViewPageState extends State<StaffSchedulesViewPage> {
  final SchedulingService _schedulingService = SchedulingService();
  DateTime _selectedDate = DateTime.now();
  Map<String, List<ScheduleBlock>> _staffSchedules = {};
  bool _isLoading = true;

  final Map<String, IconData> _staffIcons = {
    'staff_1': Icons.content_cut_rounded,
    'staff_2': Icons.spa_rounded,
    'staff_3': Icons.auto_awesome_rounded,
  };

  final Map<String, Color> _staffColors = {
    'staff_1': const Color(0xFF9B5DE5),
    'staff_2': const Color(0xFF3A86FF),
    'staff_3': const Color(0xFF2A9D8F),
  };

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final schedules = <String, List<ScheduleBlock>>{};
    for (final staffMember in _schedulingService.staff) {
      final staffId = staffMember.id;
      schedules[staffId] = await _schedulingService.getStaffSchedule(staffId, _selectedDate);
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() {
      _staffSchedules = schedules;
      _isLoading = false;
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSchedules();
  }

  String _getNextAvailableTime(String staffId) {
    final blocks = _staffSchedules[staffId] ?? [];
    final now = DateTime.now();
    
    if (_selectedDate.day == now.day && 
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year &&
        now.hour >= 20) {
      return 'Available tomorrow at 9:00 AM';
    }

    for (var block in blocks) {
      if (block.isAvailable) {
        final time = TimeOfDay.fromDateTime(block.startTime);
        return 'Next available: ${time.format(context)}';
      }
    }

    return 'No slots available today';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Staff Schedules',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                IconButton.filledTonal(tooltip: 'Previous day', onPressed: () => _changeDate(-1), icon: const Icon(Icons.chevron_left_rounded)),
                const SizedBox(width: 8),
                Expanded(child: Column(children: [Text(DateFormat('EEEE').format(_selectedDate), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)), const SizedBox(height: 2), Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                IconButton.filledTonal(tooltip: 'Next day', onPressed: () => _changeDate(1), icon: const Icon(Icons.chevron_right_rounded)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Wrap(spacing: 8, runSpacing: 8, children: [_buildLegendItem(const Color(0xFFE8F7EE), AppColors.success, 'Available'), _buildLegendItem(const Color(0xFFFCE8EC), AppColors.danger, 'Occupied'), _buildLegendItem(const Color(0xFFF1EEEC), AppColors.textSecondary, 'Closed')]),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _schedulingService.staff.length,
                    itemBuilder: (context, index) {
                      final staffMember = _schedulingService.staff[index];
                      final staffId = staffMember.id;
                      final staffName = staffMember.name;
                      final blocks = _staffSchedules[staffId] ?? [];
                      
                      return _buildStaffCard(staffId, staffName, blocks);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))]),
    );
  }

  Widget _buildStaffCard(String staffId, String staffName, List<ScheduleBlock> blocks) {
    final staffColor = _staffColors[staffId] ?? AppColors.primary;
    final staffIcon = _staffIcons[staffId] ?? Icons.person_rounded;
    final availableCount = blocks.where((b) => b.isAvailable).length;
    final occupiedCount = blocks.where((b) => b.isDuringBusinessHours && !b.isAvailable).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [staffColor.withValues(alpha: 0.16), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: staffColor, borderRadius: BorderRadius.circular(16)), child: Icon(staffIcon, color: Colors.white, size: 23)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(staffName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(_getNextAvailableTime(staffId), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_miniMetric('$availableCount', 'free', AppColors.success), const SizedBox(height: 4), _miniMetric('$occupiedCount', 'occupied', AppColors.danger)]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
          child: LayoutBuilder(builder: (context, constraints) {
            final count = constraints.maxWidth >= 650 ? 5 : constraints.maxWidth >= 480 ? 4 : constraints.maxWidth >= 340 ? 3 : 2;
            return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6), itemCount: blocks.length, itemBuilder: (context, index) => _buildTimeSlot(blocks[index]));
          }),
        ),
      ]),
    );
  }

  Widget _miniMetric(String value, String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Text('$value $label', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color)));
  }

  Widget _buildTimeSlot(ScheduleBlock block) {
    late final Color background;
    late final Color foreground;
    late final String label;

    if (!block.isDuringBusinessHours) {
      background = const Color(0xFFF1EEEC);
      foreground = AppColors.textSecondary;
      label = 'Closed';
    } else if (block.isAvailable) {
      background = const Color(0xFFE8F7EE);
      foreground = AppColors.success;
      label = 'Available';
    } else {
      background = const Color(0xFFFCE8EC);
      foreground = AppColors.danger;
      label = 'Occupied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13), border: Border.all(color: foreground.withValues(alpha: 0.14))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(TimeOfDay.fromDateTime(block.startTime).format(context), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: foreground, letterSpacing: 0.3))),
      ]),
    );
  }
}
