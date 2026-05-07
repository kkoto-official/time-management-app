import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    final account = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
