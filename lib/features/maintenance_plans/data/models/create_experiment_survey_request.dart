class CreateExperimentSurveyRequest {
  CreateExperimentSurveyRequest({
    required this.maintenancePlanId,
    required this.rating,
    required this.variant,
    this.action,
    this.userId,
    this.comment,
    this.durationSeconds,
    this.lastStep,
  });

  final int maintenancePlanId;
  final int rating;
  final String variant;
  final String? action;
  final int? userId;
  final String? comment;
  final int? durationSeconds;
  final String? lastStep;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maintenancePlanId': maintenancePlanId,
      'rating': rating,
      'variant': variant,
      if (action != null) 'action': action,
      if (userId != null) 'userId': userId,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (lastStep != null && lastStep!.trim().isNotEmpty) 'lastStep': lastStep,
    };
  }
}
