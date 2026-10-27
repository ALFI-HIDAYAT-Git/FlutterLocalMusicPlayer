import 'package:flutter_test/flutter_test.dart';
import 'package:music_application/main.dart';
import 'package:music_application/models/track.dart';

void main() {
  testWidgets('startup errors are shown to the user', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(message: 'Izin audio diperlukan'),
    );

    expect(find.textContaining('Izin audio diperlukan'), findsOneWidget);
  });

  test('playlist data can be serialized for local storage', () {
    const playlist = MusicPlaylist(name: 'Santai', trackIds: ['12', '19']);

    expect(
      MusicPlaylist.fromJson(playlist.toJson()).trackIds,
      ['12', '19'],
    );
  });
}
