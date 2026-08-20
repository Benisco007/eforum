import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Upload avatar ─────────────────────────────────────────────────────────
    Future<String?> uploadAvatar(String uid, File file) async {
        try {
            final ext  = file.path.split('.').last.toLowerCase();
            final path = '$uid.$ext';

            // Supprimer l'ancien fichier s'il existe
            try {
            await _supabase.storage.from('avatars').remove([path]);
            } catch (_) {}

            // Uploader le nouveau
            await _supabase.storage
                .from('avatars')
                .upload(path, file, fileOptions: const FileOptions(upsert: true));

            final url = _supabase.storage.from('avatars').getPublicUrl(path).trim();
            print('Supabase public URL: $url');
            return url;
        } catch (e) {
            print('Supabase upload error: $e');
            return null;
        }
        }
  // ─── Upload image post ─────────────────────────────────────────────────────

  Future<String?> uploadPostImage(String postId, File file) async {
    try {
      final path = '$postId.jpg';
      await _supabase.storage
          .from('posts')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _supabase.storage.from('posts').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // ─── Upload logo clan ──────────────────────────────────────────────────────

  Future<String?> uploadClanLogo(String clanId, File file) async {
    try {
      final ext  = file.path.split('.').last.toLowerCase();
      final path = 'clans/$clanId/logo.$ext';

      await _supabase.storage
          .from('clans')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _supabase.storage.from('clans').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // ─── Upload bannière clan ──────────────────────────────────────────────────

  Future<String?> uploadClanBanner(String clanId, File file) async {
    try {
      final ext  = file.path.split('.').last.toLowerCase();
      final path = 'clans/$clanId/banner.$ext';

      await _supabase.storage
          .from('clans')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _supabase.storage.from('clans').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // ─── Supprimer un fichier ──────────────────────────────────────────────────

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (_) {}
  }
}