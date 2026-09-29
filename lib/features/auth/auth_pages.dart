import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.connected,
    this.startupIssue,
  });
  final AuthController auth;
  final bool connected;
  final String? startupIssue;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.connected ||
        widget.auth.busy ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.auth.signIn(_email.text, _password.text);
    if (widget.auth.user != null) TextInput.finishAutofillContext();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: widget.auth,
              builder: (context, _) => AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.sports_esports_rounded,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GAME TERMINAL',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your shop. Ready to play.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Staff sign in',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use your assigned Owner or Receptionist account.',
                      ),
                      const SizedBox(height: 24),
                      if (!widget.connected) ...[
                        _Notice(
                          message: widget.startupIssue ?? 'Staff sign-in is not connected yet. Your administrator will enable access when the test environment is ready.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _email,
                        enabled: widget.connected && !widget.auth.busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) =>
                            value == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value.trim())
                            ? 'Enter a valid email address.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: widget.connected && !widget.auth.busy,
                        obscureText: _obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null,
                      ),
                      if (widget.auth.message != null) ...[
                        const SizedBox(height: 16),
                        _Notice(message: widget.auth.message!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: widget.connected && !widget.auth.busy
                            ? _submit
                            : null,
                        child: Text(
                          widget.auth.busy ? 'Signing in…' : 'Sign in',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Accounts are created by the shop administrator.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    ),
  );
}

class AccessPage extends StatelessWidget {
  const AccessPage({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 56),
                const SizedBox(height: 24),
                Text(
                  auth.phase == AuthPhase.denied
                      ? 'No access assigned'
                      : 'Access unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  auth.message ?? 'Your staff access could not be verified.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.busy ? null : auth.retry,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: auth.busy ? null : auth.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.account_circle_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                auth.user?.email ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(auth.role?.label ?? ''),
              const SizedBox(height: 16),
              Text(
                auth.role?.canOperate == true
                    ? 'Receptionist · shop operations access'
                    : 'Owner · read-only access to shop operations',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: auth.busy
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text(
                      'You will need to sign in again to access the shop.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await auth.signOut();
              },
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ],
  );
}
