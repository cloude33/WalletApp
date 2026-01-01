import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  drive.DriveApi? _driveApi;

  Future<bool> isAuthenticated() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<void> signIn() async {
    try {
      _driveApi = null;

      // 1. Try silent sign-in first
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
      }

      // 2. Check if we have a user and can get a client
      if (_googleSignIn.currentUser != null) {
        try {
          final httpClient = await _googleSignIn.authenticatedClient();
          if (httpClient != null) {
            _driveApi = drive.DriveApi(httpClient);
            debugPrint('✅ Google Drive silent sign-in successful');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Silent sign-in client error: $e');
        }
      }

      // 3. Force explicit sign out to clear state if silent failed
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Sign out error (ignorable): $e');
      }

      // 4. Explicit sign-in
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
          _driveApi = drive.DriveApi(httpClient);
          debugPrint(
            '✅ Google Drive explicit sign-in successful: ${account.email}',
          );
        } else {
          throw Exception(
            'Google Sign-In succeeded but failed to obtain authenticated HTTP client. Please try again.',
          );
        }
      } else {
        throw Exception('Google Sign-In canceled by user.');
      }
    } catch (e) {
      debugPrint('❌ Google Drive Sign In Error: $e');
      _driveApi = null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
  }

  Future<drive.File?> uploadBackup(
    File file,
    String fileName, {
    String? description,
    Map<String, String>? properties,
  }) async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final uploadMedia = drive.Media(file.openRead(), await file.length());

      final driveFile = drive.File()
        ..name = fileName
        ..description = description
        ..parents = ['appDataFolder'];

      if (properties != null) {
        driveFile.properties = properties;
      }

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: uploadMedia,
      );

      debugPrint('Drive Upload Success: ${result.id}');
      return result;
    } catch (e) {
      debugPrint('Drive Upload Error: $e');
      rethrow; // Rethrow to show actual error
    }
  }

  Future<List<drive.File>> listBackups() async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final fileList = await _driveApi!.files.list(
        q: "name contains 'money_backup_' and 'appDataFolder' in parents and trashed = false",
        $fields: "files(id, name, createdTime, size, description, properties)",
        orderBy: "createdTime desc",
        spaces: 'appDataFolder',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Drive List Error: $e');
      rethrow;
    }
  }

  Future<File?> downloadBackup(String fileId, String savePath) async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      final media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final file = File(savePath);
      final sink = file.openWrite();

      await media.stream.pipe(sink);
      await sink.close();

      return file;
    } catch (e) {
      debugPrint('Drive Download Error: $e');
      rethrow;
    }
  }

  Future<void> deleteBackup(String fileId) async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Google Drive API not initialized');

    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('Drive Delete Success: $fileId');
    } catch (e) {
      debugPrint('Drive Delete Error: $e');
      rethrow;
    }
  }
}
