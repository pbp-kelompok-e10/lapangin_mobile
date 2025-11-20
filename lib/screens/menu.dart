import 'package:flutter/material.dart';
import 'package:lapangin/screens/auth/login.dart';
import 'package:lapangin/screens/booking/booking_history_list.dart';
import 'package:lapangin/screens/venue/venue_list.dart';
import 'package:lapangin/widgets/utils/search_bar.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    DashboardPage(),
    VenuesPage(),
    SignOutPlaceholder(),
  ];

  void _onItemTapped(int index) async {
    if (index == 3) {
      await _handleSignOut(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final request = context.read<CookieRequest>();

    try {
      final response = await request.logout(
        "http://localhost:8000/auth/logout/",
      );
      String message = response["message"];

      if (!context.mounted) return;

      if (response['status']) {
        String uname = response["username"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$message Sampai jumpa, $uname.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Sign Out: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSearchBarAppBar(),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Venue'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Sign out'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,

        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center();
  }
}

class SignOutPlaceholder extends StatelessWidget {
  const SignOutPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Proses Sign Out...', style: TextStyle(fontSize: 24)),
    );
  }
}
