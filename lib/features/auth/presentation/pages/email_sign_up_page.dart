import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class EmailSignUpPage extends StatefulWidget {
  const EmailSignUpPage({super.key});

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool receivePromos = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                        'Sign Up with E-mail',
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
                      _AuthTextField(
                        controller: firstNameController,
                        label: 'FIRST NAME',
                        hint: 'Enter your first name',
                        inputSize: inputSize,
                        labelSize: labelSize,
                        scale: scale,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                      ),
                      SizedBox(height: 14 * scale),
                      _AuthTextField(
                        controller: lastNameController,
                        label: 'LAST NAME',
                        hint: 'Enter your last name',
                        inputSize: inputSize,
                        labelSize: labelSize,
                        scale: scale,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 14 * scale),
                      _AuthTextField(
                        controller: emailController,
                        label: 'EMAIL',
                        hint: 'Enter email address',
                        inputSize: inputSize,
                        labelSize: labelSize,
                        scale: scale,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 14 * scale),
                      _AuthTextField(
                        controller: passwordController,
                        label: 'PASSWORD',
                        hint: 'Enter your password',
                        inputSize: inputSize,
                        labelSize: labelSize,
                        scale: scale,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 14 * scale),
                      _AuthTextField(
                        controller: confirmPasswordController,
                        label: 'CONFIRM PASSWORD',
                        hint: 'Re-enter your password',
                        inputSize: inputSize,
                        labelSize: labelSize,
                        scale: scale,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 16 * scale),
                      Row(
                        children: [
                          SizedBox(
                            width: 22 * scale,
                            height: 22 * scale,
                            child: Checkbox(
                              value: receivePromos,
                              onChanged: (value) {
                                setState(() {
                                  receivePromos = value ?? false;
                                });
                              },
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3 * scale),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Text(
                              'I\'d like to receive promotional emails.',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTight ? 34 * scale : 48 * scale),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Already have account? ',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF595959),
                                    fontSize: helperSize,
                                  ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign In',
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
                          child: const Text('Create an account'),
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.inputSize,
    required this.labelSize,
    required this.scale,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final double inputSize;
  final double labelSize;
  final double scale;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: labelSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: TextStyle(color: Colors.black, fontSize: inputSize),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF8F8F8F),
              fontSize: inputSize,
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCFCFCF)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            contentPadding: EdgeInsets.only(top: 8 * scale, bottom: 8 * scale),
          ),
        ),
      ],
    );
  }
}
