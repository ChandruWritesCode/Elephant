import 'package:elephant_frontend/players/intro_animation.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Spacer(flex: 4),
            Container(
              clipBehavior: .hardEdge,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: IntroAnimation(),
            ),
            Spacer(),
            const Text(
              'Welcome to Elephant',
              style: TextStyle(fontSize: 25, fontWeight: .bold),
            ),
            const SizedBox(height: 10),
            const Text('Privacy that fits in your pocket.'),
            Spacer(flex: 1),
            Container(
              margin: .symmetric(horizontal: 20),
              child: FilledButton(
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 40),
                  ),
                ),
                onPressed: () {},
                child: Text('Get Started'),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              child: Text(
                'Already have an account? Sign in',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}
