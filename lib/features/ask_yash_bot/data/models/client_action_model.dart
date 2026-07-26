enum ClientActionType {
  openPdfPicker,
  openSpecificPdf,
  openStudyTimer,
  startStudySession,
  stopStudySession,
  openAnalytics,
  openAchievements,
  openGymTracker,
  openBookmarkPage,
  openProfile,
  openSettings,
  generatePdfExport,
  shareFile,
  downloadReport,
  navigateToScreen,
  scrollToSection,
  openSubject,
  openChapter,
  createBookmark,
  deleteBookmark,
  startRevisionSession,
  generateQuiz,
  generateNotes,
}

class ClientActionModel {
  const ClientActionModel({
    required this.actionType,
    this.target,
    this.parameters,
    this.confirmationMessage,
  });

  final ClientActionType actionType;
  final String? target;
  final Map<String, dynamic>? parameters;
  final String? confirmationMessage;

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'target': target,
      'parameters': parameters,
      'confirmationMessage': confirmationMessage,
    };
  }

  factory ClientActionModel.fromJson(Map<String, dynamic> json) {
    return ClientActionModel(
      actionType: ClientActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => ClientActionType.navigateToScreen,
      ),
      target: json['target'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      confirmationMessage: json['confirmationMessage'] as String?,
    );
  }
}
