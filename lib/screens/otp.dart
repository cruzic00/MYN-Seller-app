import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/app_localizations.dart';
import 'package:myn_seller_app/custom/input_decorations.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/main.dart';

import '../helpers/auth_helper.dart';

class Otp extends StatefulWidget {
  Otp({this.verify_by = "phone", this.mobile, this.user_id, this.type});

  final String? verify_by, type, mobile;
  final int? user_id;

  @override
  _OtpState createState() => _OtpState();
}

class _OtpState extends State<Otp> with SingleTickerProviderStateMixin {
  TextEditingController _verificationCodeController = TextEditingController();
  AnimationController? _controller;
  Duration _duration = Duration(milliseconds: 500);

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller?.forward();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  onTapResend() async {
    var resendCodeResponse = await AuthRepository()
        .getResendCodeResponse(widget.user_id, widget.verify_by);

    if (resendCodeResponse.result == false) {
      ToastComponent.showDialog(resendCodeResponse.message,
          gravity: 0, duration: 1, isError: true);
    } else {
      ToastComponent.showDialog(resendCodeResponse.message,
          gravity: 0, duration: 1);
    }
  }

  onPressConfirm() async {
    var code = _verificationCodeController.text.toString();
    if (code.length < 6) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.otp_screen_verification_code_warning,
          gravity: 0,
          duration: 1,
          isError: true);
      return;
    }

    var confirmCodeResponse =
        await AuthRepository().getConfirmCodeResponse(widget.user_id, code);

    if (confirmCodeResponse.result == false) {
      ToastComponent.showDialog(confirmCodeResponse.message,
          gravity: 0, duration: 1, isError: true);
    } else {
      ToastComponent.showDialog(confirmCodeResponse.message,
          gravity: 0, duration: 1);

      var loginResponse = await AuthRepository()
          .getLoginResponseByID(widget.user_id.toString());

      print(loginResponse.user?.avatar_original);
      AuthHelper().setUserData(loginResponse);

      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => Main()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _screen_width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MyTheme.white, Color.fromARGB(255, 189, 248, 230)],
          ),
        ),
        child: buildBody(context),
      ),
    );
  }

  buildBody(context) {
    final _screen_width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Center(
          child: Container(
            constraints: BoxConstraints(minWidth: 400),
            width: _screen_width * (2 / 4),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      width: 250, child: Image.asset('assets/app_logo.png')),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "Phone Number",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: RichText(
                      text: TextSpan(
                          text: "We've sent an SMS with a verification code to",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(
                                text: " ${widget.mobile}",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Enter Verification Code",
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: TextField(
                      controller: _verificationCodeController,
                      autofocus: false,
                      keyboardType: TextInputType.number,
                      decoration: InputDecorations.buildInputDecoration_1(
                          hint_text: "Enter OTP"),
                    ),
                  ),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      height: 45,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: MyTheme.accent_color_2, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: MyTheme.accent_color,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                          ),
                        ),
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: onPressConfirm,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  InkWell(
                    onTap: onTapResend,
                    child: Text(
                      "Resend",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
