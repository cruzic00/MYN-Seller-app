import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/auth_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/main.dart';
import 'package:toast/toast.dart';

/// Seller sign-in.
///
/// The MYN online-shop API matches a seller on username or email plus password
/// (auth.controller.js login) and issues the JWT directly, so there is no phone
/// or OTP path here — that belonged to the legacy Laravel CMS.
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  /// Sampled from the artwork's own background, so the page and the bottom edge
  /// of the illustration meet with no visible seam.
  static const Color _pageYellow = Color(0xFFFDC82D);
  static const Color _inkOnYellow = Color(0xFF5A4300);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> onPressedLogin() async {
    if (_loading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _error("Enter your username or email");
      return;
    }
    if (password.isEmpty) {
      _error("Enter your password");
      return;
    }

    setState(() => _loading = true);
    try {
      final loginResponse =
          await AuthRepository().getLoginResponse(username, password);

      if (!mounted) return;

      if (loginResponse.result == false) {
        _error(loginResponse.message ?? "Could not sign you in");
        return;
      }

      ToastComponent.showDialog(loginResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      AuthHelper().setUserData(loginResponse);

      await access_token.load();
      if (!mounted) return;
      if (access_token.$!.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Main()),
            (route) => false);
      }
    } finally {
      // Guard the button for the whole round trip, so a slow network cannot be
      // turned into three login attempts by an impatient tap.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String message) {
    ToastComponent.showDialog(message,
        gravity: Toast.center, duration: Toast.lengthLong, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status-bar icons: the artwork sitting behind them is light yellow.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _pageYellow,
        body: SingleChildScrollView(
          // Everything scrolls together, so opening the keyboard slides the
          // artwork up rather than scrolling the card under a pinned image.
          //
          // No IntrinsicHeight/Spacer here: IntrinsicHeight asks the artwork for
          // its natural height (820px) rather than the height it actually
          // renders at under fitWidth, which pushed the wordmark a screen and a
          // half below the fold. An explicit height keeps the column honest.
          child: Column(
            children: [
              // Deliberately outside any SafeArea: the artwork runs under the
              // status bar, and its top strip is empty yellow anyway.
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 820 / 941,
                child: Image.asset("assets/login_myn.jpg", fit: BoxFit.cover),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildCard(),
                ),
              ),
              _buildFooter(),
              const SizedBox(height: 10),
              _buildWordmark(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(88, 62, 0, 0.24),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: MynPalette.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A short brand rule beside the heading, so the card has one
              // deliberate accent instead of being an undifferentiated slab.
              Container(
                width: 4,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: MyTheme.accent_color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back",
                      style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Sign in to manage your orders and stock.",
                      style: TextStyle(
                          color: MynPalette.muted,
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _label("Username or email"),
          const SizedBox(height: 7),
          TextField(
            controller: _usernameController,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            style: TextStyle(
                color: MynPalette.heading,
                fontSize: 14.5,
                fontWeight: FontWeight.w600),
            decoration: _fieldDecoration(
              hint: "you@yourshop.com",
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          _label("Password"),
          const SizedBox(height: 7),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onPressedLogin(),
            style: TextStyle(
                color: MynPalette.heading,
                fontSize: 14.5,
                fontWeight: FontWeight.w600),
            decoration: _fieldDecoration(
              hint: "Enter your password",
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: MynPalette.muted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 26),
          _buildSignInButton(),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return Opacity(
      opacity: _loading ? 0.75 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MyTheme.accent_color, MynPalette.accentDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MyTheme.accent_color.withValues(alpha: 0.34),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _loading ? null : onPressedLogin,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Sign in",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 19, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: MynPalette.heading,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: MynPalette.muted, fontSize: 14, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, color: MynPalette.muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: MynPalette.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: MyTheme.accent_color, width: 1.6),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent_rounded, color: _inkOnYellow, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              "Trouble signing in? Contact the MYN admin.",
              style: TextStyle(
                color: _inkOnYellow,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The logo asset is transparent, so it sits on the yellow directly
        // rather than needing a plate behind it.
        Image.asset("assets/app_logo.png", width: 78),
        const SizedBox(height: 2),
        Text(
          "Seller Partner App",
          style: TextStyle(
            color: _inkOnYellow.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
