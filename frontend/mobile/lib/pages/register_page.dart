import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _restaurantController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final restaurantName = _restaurantController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty ||
        restaurantName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context
          .read<AuthProvider>()
          .register(name, email, password, restaurantName);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _restaurantController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool isPassword = false,
    bool isError = false,
    String? errorText,
    ValueChanged<String>? onSubmitted,
  }) {
    const primaryColor = Color(0xFFFF8A00);
    const textColor = Color(0xFF14171F);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: isError ? const Color(0xFFFEF2F2) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isError ? Colors.red : primaryColor),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF9CA3AF),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
          keyboardType: keyboardType,
          obscureText: isPassword && _obscurePassword,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
        ),
        if (isError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF8A00);
    const textColor = Color(0xFF14171F);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3E6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.restaurant_menu,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LaukAI',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Main Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create your account',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the future of restaurant management',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      controller: _nameController,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      label: 'Restaurant Name',
                      hintText: 'Enter restaurant name',
                      controller: _restaurantController,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      isError: _error != null && _error!.toLowerCase().contains('email'),
                      errorText: _error,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      label: 'Password',
                      hintText: 'Create a password',
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      label: 'Confirm Password',
                      hintText: 'Confirm your password',
                      controller: _confirmController,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                    ),
                    
                    if (_error != null && !_error!.toLowerCase().contains('email')) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Login',
                            style: GoogleFonts.outfit(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Terms of Service',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Help Center',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
