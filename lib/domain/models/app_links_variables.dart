/// URLs publicadas en el backend (`versions/variables`), sin deploy de la app.
class AppLinksVariables {
  /// Página oficial en Facebook (no depende de `url_web` del backend).
  static const String facebookPageUrl =
      'https://www.facebook.com/profile.php?id=61573279525305';

  final String? urlTwitter;
  final String? urlWeb;

  const AppLinksVariables({this.urlTwitter, this.urlWeb});

  factory AppLinksVariables.fromJson(Map<String, dynamic> json) {
    return AppLinksVariables(
      urlTwitter: json['url_twitter'] as String?,
      urlWeb: json['url_web'] as String?,
    );
  }

  bool get hasTwitter =>
      urlTwitter != null && urlTwitter!.trim().isNotEmpty;

  bool get hasWeb => urlWeb != null && urlWeb!.trim().isNotEmpty;

  bool get hasAny => hasTwitter || hasWeb;
}
