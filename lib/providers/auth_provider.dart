import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _googleInitialized = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String get userName => _user?['firstName'] ?? 'Utilisateur';

  Future<void> loadUser() async {
    try {
      final token = await _api.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      final res = await _api.get('/users/me');
      _user = res.data['data'];
      _isAuthenticated = true;
    } catch (_) {
      await _api.clearTokens();
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await _api.post('/auth/login', data: {
      'emailOrPhone': email,
      'password': password,
    });
    final data = res.data['data'];
    await _api.setTokens(
      data['accessToken'],
      data['refreshToken'],
    );
    _user = data['user'];
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String firstName, String lastName, String email, String password) async {
    final res = await _api.post('/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    final data = res.data['data'];
    await _api.setTokens(
      data['accessToken'],
      data['refreshToken'],
    );
    _user = data['user'];
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();

    final idToken = account.authentication.idToken ?? '';

    final res = await _api.post('/auth/social', data: {
      'provider': 'google',
      'token': idToken,
      'email': account.email,
      'firstName': account.displayName?.split(' ').first ?? '',
      'lastName': account.displayName?.split(' ').skip(1).join(' ') ?? '',
      'photoUrl': account.photoUrl ?? '',
    });

    final data = res.data['data'];
    await _api.setTokens(
      data['accessToken'],
      data['refreshToken'],
    );
    _user = data['user'];
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> loginWithApple() async {
    // Generate nonce for security
    final rawNonce = _generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Impossible de récupérer le token Apple');

    final res = await _api.post('/auth/social', data: {
      'provider': 'apple',
      'token': idToken,
      'email': credential.email ?? '',
      'firstName': credential.givenName ?? '',
      'lastName': credential.familyName ?? '',
      'nonce': rawNonce,
    });

    final data = res.data['data'];
    await _api.setTokens(
      data['accessToken'],
      data['refreshToken'],
    );
    _user = data['user'];
    _isAuthenticated = true;
    notifyListeners();
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> logout() async {
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
    await _api.clearTokens();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
