// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EdgeImpl _$EdgeImplFromJson(Map<String, dynamic> json) => EdgeImpl(
      fromVertexId: (json['fromVertexId'] as num).toInt(),
      toVertexId: (json['toVertexId'] as num).toInt(),
      labels: (json['labels'] as List<dynamic>).map((e) => e as String).toSet(),
      id: (json['id'] as num?)?.toInt(),
      properties: json['properties'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EdgeImplToJson(EdgeImpl instance) => <String, dynamic>{
      'id': instance.id,
      'labels': instance.labels.toList(),
      'properties': instance.properties,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'fromVertexId': instance.fromVertexId,
      'toVertexId': instance.toVertexId,
    };
