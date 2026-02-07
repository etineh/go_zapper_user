import 'package:flutter/foundation.dart';
import 'package:gozapper/domain/entities/credential.dart';
import 'package:gozapper/domain/repositories/credential_repository.dart';

enum CredentialStatus { initial, loading, loaded, error }

class CredentialProvider extends ChangeNotifier {
  final CredentialRepository credentialRepository;

  CredentialProvider({required this.credentialRepository});

  CredentialStatus _status = CredentialStatus.initial;
  List<Credential> _credentials = [];
  Credential? _activeCredential;
  String? _errorMessage;

  // Getters
  CredentialStatus get status => _status;
  List<Credential> get credentials => _credentials;
  Credential? get activeCredential => _activeCredential;
  String? get errorMessage => _errorMessage;
  bool get hasActiveCredential => _activeCredential != null;
  String? get activeApiKey => _activeCredential?.apiKey;

  // Fetch all credentials
  Future<void> fetchCredentials() async {
    _setStatus(CredentialStatus.loading);
    _clearError();

    final result = await credentialRepository.getCredentials();

    result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(CredentialStatus.error);
      },
      (credentials) {
        _credentials = credentials;
        _setStatus(CredentialStatus.loaded);
      },
    );
  }

  // Fetch active credential
  Future<bool> fetchActiveCredential() async {
    _setStatus(CredentialStatus.loading);
    _clearError();

    final result = await credentialRepository.getActiveCredential();

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(CredentialStatus.error);
        return false;
      },
      (credential) {
        _activeCredential = credential;
        _setStatus(CredentialStatus.loaded);
        return true;
      },
    );
  }

  // Create sandbox credential
  Future<bool> createSandboxCredential(String name) async {
    _setStatus(CredentialStatus.loading);
    _clearError();

    final result = await credentialRepository.createSandboxCredential(name);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(CredentialStatus.error);
        return false;
      },
      (credential) {
        _activeCredential = credential;
        // Add to credentials list if not already there
        if (!_credentials.any((c) => c.id == credential.id)) {
          _credentials.add(credential);
        }
        _setStatus(CredentialStatus.loaded);
        return true;
      },
    );
  }

  // Create production credential
  Future<bool> createProductionCredential(String name) async {
    _setStatus(CredentialStatus.loading);
    _clearError();

    final result = await credentialRepository.createProductionCredential(name);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(CredentialStatus.error);
        return false;
      },
      (credential) {
        _activeCredential = credential;
        // Add to credentials list if not already there
        if (!_credentials.any((c) => c.id == credential.id)) {
          _credentials.add(credential);
        }
        _setStatus(CredentialStatus.loaded);
        return true;
      },
    );
  }

  // Update credential status (enable/disable)
  Future<bool> updateCredentialStatus(String id, bool status) async {
    _clearError();

    final result =
        await credentialRepository.updateCredentialStatus(id, status);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (success) {
        // Update the credential in the list
        final index = _credentials.indexWhere((c) => c.id == id);
        if (index != -1) {
          _credentials[index] = Credential(
            id: _credentials[index].id,
            apiKey: _credentials[index].apiKey,
            environment: _credentials[index].environment,
            status: status,
            organizationId: _credentials[index].organizationId,
            createdAt: _credentials[index].createdAt,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      },
    );
  }

  // Helper methods
  void _setStatus(CredentialStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Clear all user-specific credential data on logout
  void clearUserData() {
    _credentials = [];
    _activeCredential = null;
    _status = CredentialStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
