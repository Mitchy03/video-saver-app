import 'package:twitter_api_v2/twitter_api_v2.dart' as twitter;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum VideoPlatform { twitter, youtube, youtubeShorts, instagram, unknown }

class QualityLabels {
  const QualityLabels({required this.lowQuality, required this.highQuality});

  final String lowQuality;
  final String highQuality;
}

class VideoExtractionResult {
  VideoExtractionResult({
    required this.platform,
    required this.title,
    required this.thumbnailUrl,
    required this.lowQualityUrl,
    required this.highQualityUrl,
    required this.qualityLabels,
  });

  final VideoPlatform platform;
  final String title;
  final String thumbnailUrl;
  final String lowQualityUrl;
  final String highQualityUrl;
  final QualityLabels qualityLabels;
}

class OwnershipException implements Exception {
  OwnershipException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class BaseExtractor {
  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  });
}

class TwitterVideoExtractor implements BaseExtractor {
  // ignore: unused_field
  final twitter.TwitterApi _client = twitter.TwitterApi(
    bearerToken: 'DUMMY_TOKEN_FOR_REVIEW_ONLY',
  );

  final _regex = RegExp(r'(?:x|twitter)\.com/.+?/status/([0-9]+)');

  @override
  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  }) async {
    if (!ownContent) {
      throw OwnershipException(
        'Graph API制限: 自分の投稿のみダウンロード可能です。',
      );
    }
    if (!_regex.hasMatch(url)) {
      throw FormatException('Invalid Twitter URL');
    }

    // Placeholder implementation; a real app would call twitter API here.
    final quality = isPremium ? '720p / 60fps' : '480p / 30fps';
    final highUrl = 'https://video-cdn.twitter.com/mock_${quality.replaceAll(' ', '')}.mp4';
    final lowUrl = 'https://video-cdn.twitter.com/mock_480p30.mp4';
    return VideoExtractionResult(
      platform: VideoPlatform.twitter,
      title: 'Sample X/Twitter clip',
      thumbnailUrl: 'https://img.example.com/twitter_thumb.jpg',
      lowQualityUrl: lowUrl,
      highQualityUrl: highUrl,
      qualityLabels: const QualityLabels(
        lowQuality: '480p / 30fps',
        highQuality: '720p / 60fps',
      ),
    );
  }
}

class YouTubeVideoExtractor implements BaseExtractor {
  // ignore: unused_field
  final YoutubeExplode _client = YoutubeExplode();
  final _regex = RegExp(r'(?:youtube\.com/watch\?v=|youtu.be/)([A-Za-z0-9_-]{6,})');

  @override
  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  }) async {
    if (!ownContent) {
      throw OwnershipException(
        'Graph API制限: 自分の投稿のみダウンロード可能です。',
      );
    }
    if (!_regex.hasMatch(url)) {
      throw FormatException('Invalid YouTube URL');
    }

    // Placeholder for real youtube_explode metadata lookup.
    final quality = isPremium ? '1080p' : '360p';
    return VideoExtractionResult(
      platform: VideoPlatform.youtube,
      title: 'Sample YouTube video',
      thumbnailUrl: 'https://img.example.com/youtube_thumb.jpg',
      lowQualityUrl: 'https://rr1---sn.mock.googlevideo.com/videoplayback_360.mp4',
      highQualityUrl: 'https://rr1---sn.mock.googlevideo.com/videoplayback_1080.mp4',
      qualityLabels: const QualityLabels(
        lowQuality: '360p',
        highQuality: '1080p+',
      ),
    );
  }
}

class YouTubeShortsExtractor implements BaseExtractor {
  final _regex = RegExp(r'youtube.com/shorts/([A-Za-z0-9_-]{6,})');

  @override
  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  }) async {
    if (!ownContent) {
      throw OwnershipException(
        'Graph API制限: 自分の投稿のみダウンロード可能です。',
      );
    }
    if (!_regex.hasMatch(url)) {
      throw FormatException('Invalid YouTube Shorts URL');
    }

    return VideoExtractionResult(
      platform: VideoPlatform.youtubeShorts,
      title: 'Sample Shorts clip',
      thumbnailUrl: 'https://img.example.com/youtube_shorts_thumb.jpg',
      lowQualityUrl: 'https://shorts.mock/480p.mp4',
      highQualityUrl: 'https://shorts.mock/720p.mp4',
      qualityLabels: const QualityLabels(
        lowQuality: '480p',
        highQuality: '720p',
      ),
    );
  }
}

class InstagramVideoExtractor implements BaseExtractor {
  final _regex = RegExp(r'instagram.com/(?:p|reel)/([A-Za-z0-9_-]{4,})');

  @override
  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  }) async {
    if (!ownContent) {
      throw OwnershipException(
        'Graph API制限: 自分の投稿のみダウンロード可能です。',
      );
    }
    if (!_regex.hasMatch(url)) {
      throw FormatException('Invalid Instagram URL');
    }

    return VideoExtractionResult(
      platform: VideoPlatform.instagram,
      title: 'Sample Instagram reel',
      thumbnailUrl: 'https://img.example.com/instagram_thumb.jpg',
      lowQualityUrl: 'https://instagram.mock/480p.mp4',
      highQualityUrl: 'https://instagram.mock/1080p.mp4',
      qualityLabels: const QualityLabels(
        lowQuality: '480p',
        highQuality: '1080p',
      ),
    );
  }
}

class VideoExtractor {
  VideoExtractor()
      : _twitter = TwitterVideoExtractor(),
        _youtube = YouTubeVideoExtractor(),
        _shorts = YouTubeShortsExtractor(),
        _instagram = InstagramVideoExtractor();

  final TwitterVideoExtractor _twitter;
  final YouTubeVideoExtractor _youtube;
  final YouTubeShortsExtractor _shorts;
  final InstagramVideoExtractor _instagram;

  VideoPlatform detectPlatform(String url) {
    if (url.contains('youtube.com/shorts/')) {
      return VideoPlatform.youtubeShorts;
    }
    if (url.contains('youtube.com/watch') || url.contains('youtu.be/')) {
      return VideoPlatform.youtube;
    }
    if (url.contains('twitter.com/') || url.contains('x.com/')) {
      return VideoPlatform.twitter;
    }
    if (url.contains('instagram.com/')) {
      return VideoPlatform.instagram;
    }
    return VideoPlatform.unknown;
  }

  Future<VideoExtractionResult> extract(
    String url, {
    required bool isPremium,
    required bool ownContent,
  }) async {
    final platform = detectPlatform(url);
    switch (platform) {
      case VideoPlatform.twitter:
        return _twitter.extract(url, isPremium: isPremium, ownContent: ownContent);
      case VideoPlatform.youtube:
        return _youtube.extract(url, isPremium: isPremium, ownContent: ownContent);
      case VideoPlatform.youtubeShorts:
        return _shorts.extract(url, isPremium: isPremium, ownContent: ownContent);
      case VideoPlatform.instagram:
        return _instagram.extract(url, isPremium: isPremium, ownContent: ownContent);
      case VideoPlatform.unknown:
        throw FormatException('Unsupported platform');
    }
  }

  String iconLabel(VideoPlatform platform) {
    return {
          VideoPlatform.twitter: 'X',
          VideoPlatform.youtube: 'YouTube',
          VideoPlatform.youtubeShorts: 'Shorts',
          VideoPlatform.instagram: 'Instagram',
        }[platform] ?? 'Unknown';
  }
}
