enum VideoPlatform { twitter, youtube, youtubeShorts, instagram, unknown }

class VideoExtractor {
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

  String iconLabel(VideoPlatform platform) {
    return {
          VideoPlatform.twitter: 'X',
          VideoPlatform.youtube: 'YouTube',
          VideoPlatform.youtubeShorts: 'Shorts',
          VideoPlatform.instagram: 'Instagram',
        }[platform] ??
        'Unknown';
  }

  bool isValidUrl(String url) {
    return detectPlatform(url) != VideoPlatform.unknown;
  }
}
