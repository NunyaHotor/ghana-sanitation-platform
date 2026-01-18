// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportAdapter extends TypeAdapter<Report> {
  @override
  final int typeId = 0;

  @override
  Report read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Report(
      id: fields[0] as String?,
      userId: fields[1] as String?,
      category: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      gpsAccuracy: fields[5] as double,
      capturedAt: fields[6] as String,
      photoUrls: (fields[7] as List?)?.cast<String>(),
      videoUrl: fields[8] as String?,
      description: fields[9] as String?,
      anonymous: fields[10] as bool,
      createdAt: fields[11] as String?,
      caseId: fields[12] as String?,
      status: fields[13] as String?,
      isSynced: fields[14] as bool,
      localId: fields[15] as String?,
      videoUrls: (fields[16] as List?)?.cast<String>(),
      retryCount: fields[17] as int,
      lastAttemptAt: fields[18] as int?,
      failed: fields[19] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Report obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.gpsAccuracy)
      ..writeByte(6)
      ..write(obj.capturedAt)
      ..writeByte(7)
      ..write(obj.photoUrls)
      ..writeByte(8)
      ..write(obj.videoUrl)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.anonymous)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.caseId)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.isSynced)
      ..writeByte(15)
      ..write(obj.localId)
      ..writeByte(16)
      ..write(obj.videoUrls)
      ..writeByte(17)
      ..write(obj.retryCount)
      ..writeByte(18)
      ..write(obj.lastAttemptAt)
      ..writeByte(19)
      ..write(obj.failed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      gpsAccuracy: (json['gps_accuracy'] as num).toDouble(),
      capturedAt: json['captured_at'] as String,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      videoUrl: json['video_url'] as String?,
      description: json['description'] as String?,
      anonymous: json['anonymous'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      caseId: json['case_id'] as String?,
      status: json['status'] as String? ?? 'submitted',
      isSynced: json['is_synced'] as bool? ?? false,
      localId: json['local_id'] as String?,
      videoUrls: (json['video_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      lastAttemptAt: (json['last_attempt_at'] as num?)?.toInt(),
      failed: json['failed'] as bool? ?? false,
    );

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'category': instance.category,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'gps_accuracy': instance.gpsAccuracy,
      'captured_at': instance.capturedAt,
      'photo_urls': instance.photoUrls,
      'video_url': instance.videoUrl,
      'description': instance.description,
      'anonymous': instance.anonymous,
      'created_at': instance.createdAt,
      'case_id': instance.caseId,
      'status': instance.status,
      'is_synced': instance.isSynced,
      'local_id': instance.localId,
      'video_urls': instance.videoUrls,
      'retry_count': instance.retryCount,
      'last_attempt_at': instance.lastAttemptAt,
      'failed': instance.failed,
    };
