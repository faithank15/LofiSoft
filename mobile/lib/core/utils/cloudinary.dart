/// Aide pour les images hébergées sur Cloudinary.
///
/// Principe : on stocke UNE image de bonne qualité sur Cloudinary, et on demande à Cloudinary
/// de la redimensionner selon l'endroit où on l'affiche (miniature, carte, plein écran).
/// Résultat : image nette sur le téléphone ET peu de données consommées.
///
/// Une URL Cloudinary ressemble à :
///   https://res.cloudinary.com/<cloud>/image/upload/v123/annonces/abc.jpg
/// On insère des options après `/upload/` :
///   .../upload/f_auto,q_auto,c_fill,w_800/v123/annonces/abc.jpg
abstract final class Cloudinary {
  /// Nom du « cloud » (voir le tableau de bord Cloudinary). Passé à la compilation :
  /// `--dart-define=CLOUDINARY_CLOUD_NAME=xxxx`. Sert seulement si l'API renvoie un public_id.
  static const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

  static const _marker = '/upload/';

  /// Renvoie l'URL optimisée pour afficher l'image à `width` pixels PHYSIQUES.
  /// - `f_auto` : le meilleur format pour l'appareil (WebP, AVIF...)
  /// - `q_auto` : qualité ajustée automatiquement
  /// - `c_fill,w_` : recadrage à la bonne largeur
  /// Une URL qui n'est pas Cloudinary est renvoyée telle quelle.
  static String optimize(String url, {required int width, int? height}) {
    final index = url.indexOf(_marker);
    if (!url.contains('res.cloudinary.com') || index < 0) return url;
    final options = [
      'f_auto',
      'q_auto',
      'c_fill',
      'w_$width',
      if (height != null) 'h_$height',
    ].join(',');
    final start = index + _marker.length;
    return '${url.substring(0, start)}$options/${url.substring(start)}';
  }

  /// Construit l'URL à partir d'un public_id (si l'API ne renvoie que celui-ci).
  static String fromPublicId(String publicId, {required int width}) =>
      'https://res.cloudinary.com/$cloudName/image/upload/f_auto,q_auto,c_fill,w_$width/$publicId';
}
