import 'package:myn_seller_app/addon_config.dart';
import 'package:myn_seller_app/custom/input_decorations.dart';
import 'package:myn_seller_app/custom/intl_phone_input.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/auth_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:toast/toast.dart';

import 'otp.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "phone"; //phone or email
  String initialCountry = 'US';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'IN', dialCode: "+91");
  String? _phone = "";

  //controllers
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    if (is_logged_in.$ == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  onPressedLogin() async {
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showDialog("Enter email",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    } else if (_login_by == 'phone' && _phone == "") {
      ToastComponent.showDialog("Enter phone number",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    } else if (password == "") {
      ToastComponent.showDialog("Enter password",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }

    var loginResponse =
        await AuthRepository().getLoginResponse(_phone, password);

    if (loginResponse.result == false) {
      ToastComponent.showDialog(loginResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    } else {
      //print('dd');
      ToastComponent.showDialog(loginResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      AuthHelper().setUserData(loginResponse);

      // final FirebaseMessaging _fcm = FirebaseMessaging.instance;

      // await _fcm.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );

      // String? fcmToken = await _fcm.getToken();

      // if (fcmToken != null) {
      //   print("--fcm token--");
      //   print(fcmToken);
      //   await ProfileRepository().getDeviceTokenUpdateLoginResponse(
      //       loginResponse.user!.id.toString(), fcmToken);
      // }

      access_token.load().whenComplete(() {
        if (access_token.$!.isNotEmpty) {
          print("redirecting to opt screen");
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Otp(
              mobile: _phone,
              verify_by: "phone",
              user_id: loginResponse.user!.id,
              type: "login",
            );
          }));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
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
    final _screen_width = MediaQuery.of(context).size.width * (1);
    return Stack(
      children: [
        Center(
          child: Container(
            constraints: BoxConstraints(minWidth: 400),
            width: _screen_width * (2 / 4),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 0.0,
                    ),
                    child: Text(
                      "Login to ",
                      style: TextStyle(
                          color: MyTheme.dark_grey,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Container(
                        width: 255, child: Image.asset("assets/app_logo.png")),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 20.0,
                    ),
                    child: Text(
                      "The Seller",
                      style: TextStyle(
                          color: MyTheme.dark_grey,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    width: _screen_width * (3 / 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            "Name",
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 36,
                                child: TextField(
                                  controller: _passwordController,
                                  autofocus: false,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  style: TextStyle(color: MyTheme.dark_grey),
                                  decoration:
                                      InputDecorations.buildInputDecoration_1(
                                          hint_text: "Enter Seller Name"),
                                ),
                              ),
                              /*GestureDetector(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return PasswordForget();
                                    }));
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                    color: MyTheme.golden,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline),
                              ),
                            )*/
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            _login_by == "email" ? "Email" : "Phone",
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_login_by == "email")
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: 36,
                                  child: TextField(
                                    style: TextStyle(color: MyTheme.dark_grey),
                                    controller: _emailController,
                                    autofocus: false,
                                    decoration:
                                        InputDecorations.buildInputDecoration_1(
                                            hint_text: "johndoe@example.com"),
                                  ),
                                ),
                                AddonConfig.otp_addon_installed
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _login_by = "phone";
                                          });
                                        },
                                        child: Text(
                                          "or, Login with a phone number",
                                          style: TextStyle(
                                              color: MyTheme.yellow,
                                              fontStyle: FontStyle.italic,
                                              decoration:
                                                  TextDecoration.underline),
                                        ),
                                      )
                                    : Container()
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: 36,
                                  child: CustomInternationalPhoneNumberInput(
                                    onInputChanged: (PhoneNumber number) {
                                      print(number.phoneNumber);
                                      setState(() {
                                        _phone = number.phoneNumber;
                                      });
                                    },
                                    onInputValidated: (bool value) {
                                      print('on input validation ${value}');
                                    },
                                    selectorConfig: SelectorConfig(
                                      selectorType:
                                          PhoneInputSelectorType.DIALOG,
                                    ),
                                    ignoreBlank: false,
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle:
                                        TextStyle(color: MyTheme.font_grey),
                                    textStyle:
                                        TextStyle(color: MyTheme.dark_grey),
                                    initialValue: phoneCode,
                                    textFieldController: _phoneNumberController,
                                    formatInput: true,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            signed: true, decimal: true),
                                    inputDecoration: InputDecorations
                                        .buildInputDecoration_phone(
                                            hint_text: "01710 333 558"),
                                    onSaved: (PhoneNumber number) {
                                      print('On Saved: $number');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: MyTheme.textfield_grey, width: 1),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(12.0))),
                            child: MaterialButton(
                              minWidth: MediaQuery.of(context).size.width,
                              //height: 50,
                              color: MyTheme.accent_color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12.0))),
                              child: Text(
                                "LOGIN",
                                style: TextStyle(
                                    color: MyTheme.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                onPressedLogin();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                    ),
                    child: Text(
                      "If you are finding any problem while logging in ",
                      style: TextStyle(fontSize: 14, color: MyTheme.dark_grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                    ),
                    child: Text(
                      "please contact the admin",
                      style: TextStyle(fontSize: 14, color: MyTheme.dark_grey),
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
