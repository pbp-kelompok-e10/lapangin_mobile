import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/screens/auth/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final screenHeight = MediaQuery.of(context).size.height;

    InputDecoration _getInputDecoration({
      required String labelText,
      required String hintText,
      required IconData prefixIcon,
      IconData? suffixIcon,
      VoidCallback? suffixOnPressed,
      bool isPassword = false,
      bool isVisible = false,
    }) {
      const Color primaryColor = Color(0xFF0062FF);
      const Color lightGrayColor = Color(0xFFE5E5E5);

      return InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: lightGrayColor,
          fontFamily: "Poppins",
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontFamily: "Poppins",
        ),
        hintStyle: const TextStyle(
          color: lightGrayColor,
          fontFamily: "Poppins",
        ),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: lightGrayColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: lightGrayColor,
                ),
                onPressed: suffixOnPressed,
              )
            : null,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: lightGrayColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.1),

                // DAFTAR
                const Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 36.0),

                // --- Input Nama Lengkap (Sesuai Gambar) ---
                TextFormField(
                  controller: _fullNameController,
                  decoration: _getInputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan Nama Lengkap',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap tidak boleh kosong!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),

                // --- Input Username ---
                TextFormField(
                  controller: _usernameController,
                  decoration: _getInputDecoration(
                    labelText: 'Buat Username',
                    hintText: 'Masukkan username Anda',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),

                // --- Input Kata Sandi ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _getInputDecoration(
                    labelText: 'Buat Kata Sandi',
                    hintText: 'Masukkan kata sandi Anda',
                    prefixIcon: Icons.key_outlined,
                    isPassword: true,
                    isVisible: _isPasswordVisible,
                    suffixOnPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong!';
                    } else if (value.length < 8) {
                      return 'Kata sandi minimal 8 karakter!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),

                // --- Input Konfirmasi Kata Sandi
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _getInputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    hintText: 'Konfirmasi kata sandi Anda',
                    prefixIcon: Icons.key_outlined,
                    isPassword: true,
                    isVisible: _isConfirmPasswordVisible,
                    suffixOnPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong!';
                    } else if (value != _passwordController.text) {
                      return 'Konfirmasi kata sandi tidak cocok!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36.0),
                // --- Tombol DAFTAR ---
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String username = _usernameController.text;
                      String password1 = _passwordController.text;
                      String password2 = _confirmPasswordController.text;

                      final response = await request.postJson(
                        "https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/auth/register/",
                        jsonEncode({
                          "username": username,
                          "password1": password1,
                          "password2": password2,
                        }),
                      );

                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Registrasi berhasil! Silahkan Masuk.',
                              ),
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response['message'] ?? 'Gagal mendaftar!',
                                style: const TextStyle(fontFamily: "Poppins"),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),
                const SizedBox(height: 36.0),

                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Atau',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 36.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya Akun?',
                      style: TextStyle(fontSize: 16.0, fontFamily: "Poppins"),
                    ),
                    const SizedBox(width: 4.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Masuk',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
