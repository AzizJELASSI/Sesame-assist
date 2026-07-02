import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/profile.dart';
import '../../../core/supabase_client.dart';

final allAgentsProvider = FutureProvider<List<Profile>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('role', 'agent')
      .order('full_name');

  return (response as List).map((json) => Profile.fromJson(json)).toList();
});
