import 'package:ase_capstone/components/textfield.dart';
import 'package:ase_capstone/models/theme_notifier.dart';
import 'package:ase_capstone/utils/firebase_operations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ase_capstone/utils/utils.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final Function? toggleTheme;
  final bool? isDarkMode;

  const SettingsPage({
    super.key,
    this.toggleTheme,
    this.isDarkMode,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final FirestoreService firestoreService = FirestoreService();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser!;
  late bool isDarkMode;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    isDarkMode = Provider.of<ThemeNotifier>(context, listen: false).isDarkMode;
    _loadNotificationSettings();
  }

  // function to change dark mode (true/false)
  void toggleDarkMode(bool value) {
    Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(value);
    setState(() {
      isDarkMode = value;
    });
  }

  void _changeUserPassword() async {
    try {
      // reauthenticate user to change password (will throw error if password is incorrect)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPasswordController.text,
      );

      // reauthenticate user
      await user!.reauthenticateWithCredential(credential);

      // check to ensure password and confirm password match
      if ((confirmPasswordController.text == newPasswordController.text) &&
          (confirmPasswordController.text.isNotEmpty &&
              newPasswordController.text.isNotEmpty)) {
        // update password
        await user!.updatePassword(newPasswordController.text);

        // send message to user that password has been changed
        _errorMessage = 'Password changed successfully';
      } else {
        // send error to user that passwords do not match
        _errorMessage = 'Passwords do not match';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        // send error to user that password is incorrect
        _errorMessage = 'Invalid credentials';
      } else if (e.code == 'weak-password') {
        // send error to user that password is too weak
        _errorMessage = 'That password is too weak please try again.';
      } else {
        // send error to user that an unknown error occurred
        _errorMessage = 'An unknown error occurred';
      }
    }

    // display error/success message to user
    setState(() {
      Utils.displayMessage(context: context, message: _errorMessage);
    });
  }

  void changePasswordDialog() {
    // clear text fields
    oldPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    // Show dialog to change password
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                MyTextField(
                  controller: oldPasswordController,
                  hintText: 'Enter your old password',
                  obscureText: true,
                ),
                SizedBox(height: 10),
                MyTextField(
                  controller: newPasswordController,
                  hintText: 'Enter your new password',
                  obscureText: true,
                ),
                SizedBox(height: 10),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm your new password',
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () {
                _changeUserPassword();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void changeUserIcon() {}

  bool notifyAll = true;
  bool notifyClassStart = true;
  bool notifyEvents = true;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _loadNotificationSettings() async {
    final data = await FirestoreService().getUser(userId: user!.uid);
    if (data.containsKey('notifications')) {
      final notif = data['notifications'];
      setState(() {
        notifyAll = notif['all'] ?? true;
        notifyClassStart = notif['classStart'] ?? true;
        notifyEvents = notif['event'] ?? true;
      });
    }
  }

  void manageNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveToFirestore() async {
              await FirestoreService().updateUserField(
                userId: user!.uid,
                field: 'notifications',
                value: {
                  'all': notifyAll,
                  'classStart': notifyClassStart,
                  'event': notifyEvents,
                },
              );
            }

            return AlertDialog(
              title: Text('Notification Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Enable All Notifications'),
                    value: notifyAll,
                    onChanged: (value) async {
                      setModalState(() {
                        notifyAll = value;
                        if (!notifyAll) {
                          notifyClassStart = false;
                          notifyEvents = false;
                        }
                      });
                      await saveToFirestore();
                    },
                  ),
                  SwitchListTile(
                    title: Text('Class Start Times'),
                    value: notifyClassStart,
                    onChanged: notifyAll
                        ? (value) async {
                            setModalState(() {
                              notifyClassStart = value;
                            });
                            await saveToFirestore();
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Event Times'),
                    value: notifyEvents,
                    onChanged: notifyAll
                        ? (value) async {
                            setModalState(() {
                              notifyEvents = value;
                            });
                            await saveToFirestore();
                          }
                        : null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('General'),
      ),
      body: Padding(
        padding: MediaQuery.of(context).size.width > 600
            ? EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 500
                    ? MediaQuery.of(context).size.width * .3
                    : 20,
              )
            : EdgeInsets.all(8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SwitchListTile(
              title: Text('Dark Mode'),
              value: isDarkMode,
              onChanged: toggleDarkMode,
              secondary: Icon(Icons.dark_mode),
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: changePasswordDialog,
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              onTap: manageNotifications,
            ),
            ListTile(
              leading: Icon(Icons.palette),
              title: Text('Change Theme'),
              onTap: () {
                Navigator.of(context).pushNamed('/theme-selection');
              },
            ),
          ],
        ),
      ),
    );
  }
}
