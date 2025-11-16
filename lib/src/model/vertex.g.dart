// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vertex.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VertexImpl _$VertexImplFromJson(Map<String, dynamic> json) => VertexImpl(
      id: (json['id'] as num?)?.toInt(),
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toSet(),
      properties: json['properties'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VertexImplToJson(VertexImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labels': instance.labels.toList(),
      'properties': instance.properties,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
