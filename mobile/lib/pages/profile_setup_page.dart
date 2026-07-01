import 'package:mobile/pages/home_page.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:mobile/providers/image_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileImageProvider>();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const Text(
                'Set up your profile',
                style: TextStyle(fontWeight: .bold, fontSize: 25),
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  'Add a photo and display name so your contacts can securely recognize you.',
                  style: TextStyle(fontWeight: .w400),
                  textAlign: .center,
                ),
              ),
              const SizedBox(height: 25),
              CircleAvatar(
                radius: 60,
                backgroundImage: profile.selectedImage != null
                    ? FileImage(profile.selectedImage!)
                    : null,
                child: profile.selectedImage == null
                    ? Icon(Icons.person)
                    : null,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: context.read<ProfileImageProvider>().pickImage,
                child: Text(
                  'Upload',
                  style: TextStyle(fontWeight: .w300, fontSize: 15),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: EdgeInsets.all(20),
                child: TextField(
                  decoration: InputDecoration(
                    hint: Text(
                      'e.g. Alex',
                      style: TextStyle(color: Colors.grey),
                    ),
                    label: Text('Display Name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                margin: .symmetric(horizontal: 20),
                child: FilledButton(
                  style: ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, 40),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                    context.read<BasicProviders>().logIn();
                  },
                  child: Row(
                    mainAxisAlignment: .center,
                    children: [Text('Finish'), Icon(Icons.arrow_forward)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
