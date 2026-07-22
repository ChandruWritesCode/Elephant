import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/pages/settings%20pages/appearance.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openServerConfigDialog() {
    final hostController = TextEditingController(text: Env.host);
    final portController = TextEditingController(text: Env.port);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          scrollable: true,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.8),
          title: Row(
            children: [
              Icon(Icons.dns, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                "Server Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your decentralized peer node coordinates:",
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Host",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: hostController,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  hintText: Env.defaultHost,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Port",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  hintText: Env.defaultPort,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                await Env.updateConfig(Env.defaultHost, Env.defaultPort);

                navigator.pop();
                setState(() {});
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Reset connection to elephant.commandlinecoding.in",
                    ),
                  ),
                );
              },
              child: Text(
                "Reset Default",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              onPressed: () async {
                final newHost = hostController.text.trim();
                final newPort = portController.text.trim();

                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                await Env.updateConfig(newHost, newPort);

                navigator.pop();
                setState(() {});
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text("Target base set to: ${Env.httpBaseUrl}"),
                  ),
                );
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthState>();
      if (_tabController.index == 0) {
        auth.handleLogin(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        auth.handleRegister(
          _usernameController.text.trim(),
          _displayNameController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    }
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: colorScheme.onSurface, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  top: -150,
                  left: -150,
                  child:
                      Container(
                            width: 500,
                            height: 500,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.45),
                                  colorScheme.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .move(
                            duration: 6.seconds,
                            curve: Curves.easeInOutSine,
                            end: const Offset(300, 250),
                          )
                          .scale(
                            duration: 4.seconds,
                            curve: Curves.easeInOutSine,
                            end: const Offset(1.4, 1.4),
                          ),
                ),
                Positioned(
                  bottom: -200,
                  right: -100,
                  child:
                      Container(
                            width: 600,
                            height: 600,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.tertiary.withValues(alpha: 0.35),
                                  colorScheme.tertiary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .move(
                            duration: 8.seconds,
                            curve: Curves.easeInOutSine,
                            end: const Offset(-400, -300),
                          )
                          .scale(
                            duration: 6.seconds,
                            curve: Curves.easeInOutSine,
                            end: const Offset(1.2, 0.8),
                          ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  left: MediaQuery.of(context).size.width * 0.1,
                  child:
                      Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.secondary.withValues(alpha: 0.30),
                                  colorScheme.secondary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .moveX(
                            duration: 7.seconds,
                            curve: Curves.easeInOutSine,
                            end: MediaQuery.of(context).size.width * 0.5,
                          )
                          .moveY(
                            duration: 9.seconds,
                            curve: Curves.easeInOutSine,
                            end: 300,
                          )
                          .scale(
                            duration: 5.seconds,
                            curve: Curves.easeInOutSine,
                            end: const Offset(1.6, 1.6),
                          ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.surface.withValues(alpha: 0.25),
                              theme.colorScheme.surface.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.20,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 40,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_rounded,
                                    color: Color(0xFF0052CC),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Elephant',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Column(
                                key: ValueKey<int>(_tabController.index),
                                children: [
                                  Text(
                                    _tabController.index == 0
                                        ? 'Welcome Back'
                                        : 'Create Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _tabController.index == 0
                                        ? 'Access your secure workspace'
                                        : 'Join the peer mesh platform',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      curve: Curves.fastOutSlowIn,
                                      alignment: _tabController.index == 0
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: FractionallySizedBox(
                                        widthFactor: 0.5,
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.2),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.5),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => setState(
                                              () => _tabController.index = 0,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _tabController.index == 0
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                      : theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => setState(
                                              () => _tabController.index = 1,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Register',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _tabController.index == 1
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                      : theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
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
                              const SizedBox(height: 24),
                              if (authState.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  child: Text(
                                    authState.errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              Text(
                                "Username",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                textInputAction: TextInputAction.next,
                                controller: _usernameController,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  hintText: "username",
                                  hintStyle: TextStyle(color: theme.hintColor),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                    ? 'Required field'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.fastLinearToSlowEaseIn,
                                child: _tabController.index == 1
                                    ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                "Display Name",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                textInputAction:
                                                    TextInputAction.next,
                                                controller:
                                                    _displayNameController,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: colorScheme
                                                              .primary,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 12,
                                                      ),
                                                  hintText: "John Doe",
                                                  hintStyle: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).hintColor,
                                                  ),
                                                  filled: true,
                                                  fillColor: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                validator: (val) =>
                                                    (val == null ||
                                                        val.trim().isEmpty)
                                                    ? 'Required field'
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          )
                                          .animate()
                                          .fade(duration: 400.ms, delay: 150.ms)
                                          .slideX(begin: -0.05)
                                    : const SizedBox.shrink(),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Password",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  if (_tabController.index == 0)
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: Color(0xFF0052CC),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                obscureText: true,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  hintText: "••••••••",
                                  hintStyle: TextStyle(color: theme.hintColor),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().length < 6)
                                    ? 'Must be at least 6 characters'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: authState.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _tabController.index == 0
                                            ? 'Sign In'
                                            : 'Sign Up',
                                        key: ValueKey<int>(
                                          _tabController.index,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      "or sign in with",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  _buildSocialButton(
                                    label: "Google",
                                    icon: Icons.g_mobiledata,
                                    onPressed: authState.isLoading
                                        ? () {}
                                        : () => context
                                              .read<AuthState>()
                                              .handleOAuthLogin("google"),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildSocialButton(
                                    label: "GitHub",
                                    icon: Icons.code,
                                    onPressed: authState.isLoading
                                        ? () {}
                                        : () => context
                                              .read<AuthState>()
                                              .handleOAuthLogin("github"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiaryContainer,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "End-to-end encrypted session",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _openServerConfigDialog,
                                  icon: Icon(
                                    Icons.dns_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  label: Text(
                                    "Connected to: ${Env.host}:${Env.port} ⚙️",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutExpo),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: RepaintBoundary(
              child:
                  ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.20,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: const EdgeInsets.all(12),
                              icon: Icon(
                                Icons.color_lens_outlined,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppearanceSettings(),
                                  ),
                                );
                              },
                              tooltip: 'Appearance Settings',
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fade(delay: 400.ms, duration: 500.ms)
                      .scale(curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }
}
