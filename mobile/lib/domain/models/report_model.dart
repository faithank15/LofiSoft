class ReportRequest {
  const ReportRequest({
    required this.announcementId,
    required this.reason,
    this.details,
  });
  final String announcementId;
  final String reason;
  final String? details;
  Map<String, dynamic> toJson() => {
    'reason': reason,
    if (details != null && details!.trim().isNotEmpty)
      'details': details!.trim(),
  };
  static const List<String> commonReasons = [
    'Annonce frauduleuse',
    'Prix suspect ou trompeur',
    'Photo non conforme',
    'Logement déjà loué',
    'Informations erronées',
    'Autre motif',
  ];
}
