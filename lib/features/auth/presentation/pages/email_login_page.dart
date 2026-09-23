import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'email_sign_up_page.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final emailController = TextEditingController(text: 'test@gmail.com');
  final passwordController = TextEditingController(text: 'test123');
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final scale = (screenSize.shortestSide / 390).clamp(0.82, 1.0);
    final isTight = screenSize.height < 760;
    final horizontalPadding = 20.0 * scale;
    final backButtonSize = 44.0 * scale;
    final titleSize = 22.0 * scale;
    final inputSize = 16.0 * scale;
    final labelSize = 11.0 * scale;
    final helperSize = 14.0 * scale;
    final forgotSize = 13.0 * scale;
    final buttonHeight = 46.0 * scale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFAFA),
      body: MediaQuery(
        data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isTight ? 10 * scale : 14 * scale,
                  horizontalPadding,
                  isTight ? 10 * scale : 12 * scale,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: backButtonSize,
                      height: backButtonSize,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white.withValues(alpha: 0.72),
                          side: const BorderSide(color: Color(0xFFE4E4E4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14 * scale),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 23 * scale,
                        ),
                      ),
                    ),
                    SizedBox(width: 14 * scale),
                    Expanded(
                      child: Text(
                        'Continue with E-mail',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.black,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE4E4E4)),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isTight ? 18 * scale : 22 * scale,
                    horizontalPadding,
                    18 * scale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('E-MAIL', fontSize: labelSize),
                      TextField(
                        controller: emailController,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: inputSize,
                          fontWeight: FontWeight.w400,
                        ),
                        strutStyle: StrutStyle(
                          fontSize: inputSize,
                          height: 1.05,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          suffixIcon: IconButton(
                            onPressed: emailController.clear,
                            visualDensity: VisualDensity.compact,
                            icon: CircleAvatar(
                              radius: 10 * scale,
                              backgroundColor: const Color(0xFFE0E0E0),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.black,
                                size: 14 * scale,
                              ),
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.8,
                            ),
                          ),
                          contentPadding: EdgeInsets.only(
                            top: 8 * scale,
                            bottom: 8 * scale,
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isTight ? 14 * scale : 16 * scale),
                      _FieldLabel('PASSWORD', fontSize: labelSize),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _enterApp(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: inputSize,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Enter your password',
                          errorText: errorText,
                          hintStyle: TextStyle(
                            color: const Color(0xFF9B9B9B),
                            fontSize: inputSize,
                            fontWeight: FontWeight.w400,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFCFCFCF)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          contentPadding: EdgeInsets.only(
                            top: 8 * scale,
                            bottom: 8 * scale,
                          ),
                        ),
                      ),
                      SizedBox(height: isTight ? 10 * scale : 12 * scale),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: TextStyle(fontSize: forgotSize),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                      SizedBox(height: isTight ? 28 * scale : 38 * scale),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF595959),
                                    fontSize: helperSize,
                                  ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmailSignUpPage(),
                                ),
                              ),
                              child: Text(
                                'Sign up',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF24A848),
                                      fontSize: helperSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isTight ? 18 * scale : 22 * scale),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: FilledButton(
                          onPressed: _enterApp,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGold,
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            textStyle: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enterApp() {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (email != 'test@gmail.com' || password != 'test123') {
      setState(() {
        errorText = 'Use demo credentials: test@gmail.com / test123';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}
