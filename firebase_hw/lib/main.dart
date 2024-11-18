import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to MessageApp',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();

  void login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text('Login')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('Don’t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  void register() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'role': 'user',
        'registrationDateTime': DateTime.now(),
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _firstName, decoration: InputDecoration(labelText: 'First Name')),
            TextField(controller: _lastName, decoration: InputDecoration(labelText: 'Last Name')),
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final boards = [
    {'name': 'General', 'icon': Icons.chat},
    {'name': 'Announcements', 'icon': Icons.announcement},
    {'name': 'Help', 'icon': Icons.help},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Message Boards')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Message Boards'),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final board = boards[index];
          return ListTile(
            leading: Icon(board['icon'] as IconData?),
            title: Text(board['name'] as String),
            onTap: () => Navigator.pushNamed(context, '/chat', arguments: board['name']),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _dobController;

  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _dobController = TextEditingController();
    
    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
      _fetchUserData();
    }
  }

  void _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _firstName.text = data['firstName'];
        _lastName.text = data['lastName'];
        _dobController.text = data['dob'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching user data')));
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _updateProfile() async {
    if (_userId != null) {
      try {
        await _firestore.collection('users').doc(_userId).update({
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'dob': _dobController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile')));
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _firstName,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastName,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _dobController,
              decoration: InputDecoration(labelText: 'Date of Birth (Optional)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _dobController;
  late TextEditingController _email;
  late TextEditingController _newPasswordController;

  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _dobController = TextEditingController();
    _email = TextEditingController();
    _newPasswordController = TextEditingController();

    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
      _fetchUserData();
    }
  }

  void _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _firstName.text = data['firstName'] ?? '';
        _lastName.text = data['lastName'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _email.text = _auth.currentUser?.email ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching user data')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateProfile() async {
    if (_userId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firestore.collection('users').doc(_userId).update({
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'dob': _dobController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile')));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeEmail() async {
    if (_email.text.isNotEmpty) {
      try {
        await _auth.currentUser?.updateEmail(_email.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating email')));
      }
    }
  }

  void _changePassword() async {
    if (_newPasswordController.text.isNotEmpty) {
      try {
        await _auth.currentUser?.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating password')));
      }
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); 
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dobController.dispose();
    _email.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstName,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastName,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _dobController,
              decoration: InputDecoration(labelText: 'Date of Birth'),
            ),
            TextField(
              controller: _email,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changeEmail,
              child: Text('Change Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Change Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final boardName = ModalRoute.of(context)!.settings.arguments as String;
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final messageController = TextEditingController();

    void sendMessage() {
      firestore.collection('messages').add({
        'board': boardName,
        'message': messageController.text,
        'username': auth.currentUser!.email,
        'datetime': DateTime.now(),
      });
      messageController.clear();
    }

    return Scaffold(
      appBar: AppBar(title: Text(boardName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('messages')
                  .where('board', isEqualTo: boardName)
                  .orderBy('datetime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet. Be the first to send one!'));
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ListTile(
                      title: Text(msg['username']),
                      subtitle: Text(msg['message']),
                      trailing: Text(
                        msg['datetime'].toDate().toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: messageController, decoration: InputDecoration(hintText: 'Enter message')),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}