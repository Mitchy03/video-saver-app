import 'package:flutter_test/flutter_test.dart';
import 'package:video_saver_app/services/video_extractor.dart';

void main() {
  final extractor = VideoExtractor();

  test('detects supported platforms from url', () {
    expect(extractor.detectPlatform('https://x.com/user/status/1'),
        VideoPlatform.twitter);
    expect(extractor.detectPlatform('https://youtu.be/abc1234'),
        VideoPlatform.youtube);
    expect(extractor.detectPlatform('https://youtube.com/shorts/xyz789'),
        VideoPlatform.youtubeShorts);
    expect(extractor.detectPlatform('https://instagram.com/p/abc123'),
        VideoPlatform.instagram);
  });

  test('enforces ownership gate', () async {
    expect(
      () => extractor.extract(
        'https://x.com/user/status/1',
        isPremium: false,
        ownContent: false,
      ),
      throwsA(isA<OwnershipException>()),
    );
  });
}
