import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://grlrrdaarzczjnqdeahh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdybHJyZGFhcnpjempucWRlYWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NTc1NTUsImV4cCI6MjA4OTIzMzU1NX0.a0M0rzjsEDaJv2MHk73NCBJgFCETjpMHtioSuqv53v8',
  );

  runApp(const IctuCommunityApp());
}
