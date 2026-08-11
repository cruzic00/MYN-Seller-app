import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/input_decorations.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/profile_repositories.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

class ProfileEdit extends StatefulWidget {
  ProfileEdit({Key? key, this.show_back_button = false}) : super(key: key);

  final bool show_back_button;

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  ScrollController _mainScrollController = ScrollController();

  TextEditingController _nameController =
      TextEditingController(text: "${user_name.$}");
  TextEditingController _emailController =
      TextEditingController(text: "${user_email.$}");
  TextEditingController _phoneController =
      TextEditingController(text: "${user_phone.$}");

  final imagepicker = ImagePicker();

  //for image uploading
  File? _file;

  chooseAndUploadImage(context) async {
    Permission.photos.request();
    final XFile? pickedImage =
        await imagepicker.pickImage(source: ImageSource.gallery);
    // new File( await ImagePicker.pickImage(source: ImageSource.gallery));

    if (pickedImage == null) {
      ToastComponent.showDialog("No file is chosen",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }

    _file = File(pickedImage.path);
    String base64Image = base64Encode(_file!.readAsBytesSync());
    String fileName = _file!.path.split("/").last;

    var profileImageUpdateResponse =
        await ProfileRepository().getProfileImageUpdateResponse(
      base64Image,
      fileName,
    );

    if (profileImageUpdateResponse.result == false) {
      ToastComponent.showDialog(profileImageUpdateResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    } else {
      ToastComponent.showDialog(profileImageUpdateResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);

      avatar_original.$ = profileImageUpdateResponse.path;
      setState(() {});
    }
  }

  Future<void> _onPageRefresh() async {}

  onPressUpdate() async {
    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var phone = _phoneController.text.toString();

    if (name == "") {
      ToastComponent.showDialog("Enter your name",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }
    if (email == "") {
      ToastComponent.showDialog("Enter Email",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }
    if (phone == "") {
      ToastComponent.showDialog("Enter Phone",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }

    var profileUpdateResponse =
        await ProfileRepository().getProfileUpdateResponse(
      name,
      email,
      phone,
    );

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);

      user_name.$ = name;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(
          builder: (context) => IconButton(
                icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
                onPressed: () => Navigator.of(context).pop(),
              )),
      title: Text(
        "Account",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0.0,
      titleSpacing: 0,
      backgroundColor: Colors.white,
    );
  }

  buildBody(context) {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            "Please log in to see the profile",
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else {
      return RefreshIndicator(
        color: MyTheme.red,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        displacement: 10,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                buildTopSection(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    height: 24,
                  ),
                ),
                buildProfileForm(context)
              ]),
            )
          ],
        ),
      );
    }
  }

  buildTopSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Color.fromRGBO(112, 112, 112, .3), width: 2),
                  //shape: BoxShape.rectangle,
                ),
                child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.all(Radius.circular(100.0)),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: AppConfig.BASE_PATH +
                          "${avatar_original.$}", //"${avatar_original.$}",
                      fit: BoxFit.fill,
                    )),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    child: Icon(
                      Icons.edit,
                      color: MyTheme.font_grey,
                      size: 14,
                    ),
                    shape: CircleBorder(
                      side:
                          new BorderSide(color: MyTheme.light_grey, width: 1.0),
                    ),
                    color: MyTheme.light_grey,
                    onPressed: () {
                      chooseAndUploadImage(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  buildProfileForm(context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Basic Information",
                style: TextStyle(
                    color: MyTheme.grey_153,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "Name",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                height: 36,
                child: TextField(
                  controller: _nameController,
                  autofocus: false,
                  decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "John Doe"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "Email",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
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
                      controller: _emailController,
                      autofocus: false,
                      decoration: InputDecorations.buildInputDecoration_1(
                          hint_text: "Enter Email ID"),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "Phone Number",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                height: 36,
                child: TextField(
                  controller: _phoneController,
                  autofocus: false,
                  decoration: InputDecorations.buildInputDecoration_1(
                      hint_text: "Enter Phone Number"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    border: Border.all(color: MyTheme.textfield_grey, width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(8.0))),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)))),
                  child: Text(
                    "Update Profile",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    onPressUpdate();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
