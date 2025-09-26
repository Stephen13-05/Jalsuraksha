import 'package:flutter/material.dart';
import 'package:app/frontend/ashaworkers/signup.dart';
import 'package:app/frontend/Localclincs/Signup.dart';

class UserSelectionPage extends StatelessWidget {
  const UserSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 10),
              const Text('JalSuraksha', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A4B6B))),
              const SizedBox(height: 30),
              const Text('Welcome! 👋',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A4B6B))),
              const SizedBox(height: 10),
              const Text('Your Partner in Preventing diseases.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF5A7A8A))),
              const SizedBox(height: 40),
              _buildUserCard(
                context,
                icon: Icons.shield_outlined,
                title: 'Asha Workers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AshaWorkerSignUpPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildUserCard(
                context,
                icon: Icons.local_hospital_outlined,
                title: 'Local Clinics',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClinicSignUpPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildUserCard(
                context,
                icon: Icons.groups_outlined,
                title: 'NGOs',
                onTap: () {},
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text('Contact Support',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, {required IconData icon, required String title, String subtitle = '', required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A4B6B))),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF5A7A8A))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}