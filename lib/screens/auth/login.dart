import 'package:flutter/material.dart';
import 'package:lapangin/screens/auth/register.dart';
import 'package:lapangin/screens/menu.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0062FF);

    return MaterialApp(
      title: 'Masuk',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light().copyWith(primary: primaryColor),
        fontFamily: 'Poppins',
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final request = context.read<CookieRequest>();

    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      final response = await request.login(
        "https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/auth/login/",
        {'username': username, 'password': password},
      );

      if (request.loggedIn) {
        String message = response['message'];
        String uname = response['username'];
        if (context.mounted) {
          // Navigasi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
          // Tampilkan SnackBar
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text("$message Selamat datang, $uname.")),
            );
        }
      } else {
        // Gagal login
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                'Gagal Masuk',
                style: TextStyle(fontFamily: "Poppins"),
              ),
              content: Text(
                response['message'] ?? 'Terjadi kesalahan saat mencoba masuk.',
                style: TextStyle(fontFamily: "Poppins"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontFamily: "Poppins"),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Handle kesalahan (misalnya, masalah jaringan)
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Kesalahan Jaringan',
              style: TextStyle(fontFamily: "Poppins"),
            ),
            content: Text(
              'Tidak dapat terhubung ke server. Silakan coba lagi. Error: $e',
              style: TextStyle(fontFamily: "Poppins"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(fontFamily: "Poppins"),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      // Pastikan status loading diatur ulang terlepas dari berhasil/gagal
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),

              // Title
              const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 36.0),

              // Input Username
              TextField(
                controller: _usernameController,
                // ... (styling) ...
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontFamily: "Poppins",
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFF0062FF),
                    fontFamily: "Poppins",
                  ),
                  hintStyle: TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontFamily: "Poppins",
                  ),
                  hintText: 'Masukkan username Anda',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFFE5E5E5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFE5E5f5),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF0062FF),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // Input Kata Sandi
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  labelStyle: TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontFamily: "Poppins",
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFF0062FF),
                    fontFamily: "Poppins",
                  ),
                  hintText: 'Masukkan kata sandi Anda',
                  hintStyle: TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontFamily: "Poppins",
                  ),
                  prefixIcon: const Icon(Icons.key, color: Color(0xFFE5E5E5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Color(0xFFE5E5E5),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFE5E5E5),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF0062FF),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36.0),

              // Tombol Masuk
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  elevation: 5,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
              ),
              const SizedBox(height: 36.0),

              // Pembatas "Atau"
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

              // Bagian Daftar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya Akun?',
                    style: TextStyle(fontSize: 16.0, fontFamily: "Poppins"),
                  ),
                  const SizedBox(width: 4.0),
                  GestureDetector(
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Daftar',
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
    );
  }
}
