class CreateExperimentSurveyRequest {
  CreateExperimentSurveyRequest({
    required this.maintenancePlanId,
    required this.rating,
    required this.variant,
    this.action,
    this.userId,
    this.comment,
  });

  final int maintenancePlanId;
  final int rating;
  final String variant;
  final String? action;
  final int? userId;
  final String? comment;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maintenancePlanId': maintenancePlanId,
      'rating': rating,
      'variant': variant,
      if (action != null) 'action': action,
      if (userId != null) 'userId': userId,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment,
    };
  }
}
