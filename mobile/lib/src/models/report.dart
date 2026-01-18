import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'report.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Report {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String? userId;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  @JsonKey(name: 'gps_accuracy')
  final double gpsAccuracy;

  @HiveField(6)
  @JsonKey(name: 'captured_at')
  final String capturedAt; // ISO 8601 format

  @HiveField(7)
  @JsonKey(name: 'photo_urls')
  final List<String>? photoUrls;

  @HiveField(8)
  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @HiveField(9)
  final String? description;

  @HiveField(10)
  final bool anonymous;

  @HiveField(11)
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @HiveField(12)
  @JsonKey(name: 'case_id')
  final String? caseId;

  @HiveField(13)
  final String? status;

  @HiveField(14)
  @JsonKey(name: 'is_synced')
  final bool isSynced;

  @HiveField(15)
  @JsonKey(name: 'local_id')
  final String? localId; // For local queue
  
  @HiveField(16)
  @JsonKey(name: 'video_urls')
  final List<String>? videoUrls;

  @HiveField(17)
  @JsonKey(name: 'retry_count')
  final int retryCount;

  @HiveField(18)
  @JsonKey(name: 'last_attempt_at')
  final int? lastAttemptAt; // epoch millis

  @HiveField(19)
  @JsonKey(name: 'failed')
  final bool failed;

  Report({
    this.id,
    this.userId,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
    required this.capturedAt,
    this.photoUrls,
    this.videoUrl,
    this.description,
    this.anonymous = false,
    this.createdAt,
    this.caseId,
    this.status = 'submitted',
    this.isSynced = false,
    this.localId,
    this.videoUrls,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.failed = false,
  });

  factory Report.fromJson(Map<String, dynamic> json) =>
      _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);

  // Copy with method for creating modified copies
  Report copyWith({
    String? id,
    String? userId,
    String? category,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    String? capturedAt,
    List<String>? photoUrls,
    String? videoUrl,
    String? description,
    bool? anonymous,
    String? createdAt,
    String? caseId,
    String? status,
    bool? isSynced,
    String? localId,
    List<String>? videoUrls,
    int? retryCount,
    int? lastAttemptAt,
    bool? failed,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      capturedAt: capturedAt ?? this.capturedAt,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      description: description ?? this.description,
      anonymous: anonymous ?? this.anonymous,
      createdAt: createdAt ?? this.createdAt,
      caseId: caseId ?? this.caseId,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      videoUrls: videoUrls ?? this.videoUrls,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      failed: failed ?? this.failed,
    );
  }
}
