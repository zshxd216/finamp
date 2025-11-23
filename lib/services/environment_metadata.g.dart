// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package, strict_raw_type

// dart format off


part of 'environment_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinampDeviceInfoAdapter extends TypeAdapter<FinampDeviceInfo> {
  @override
  final typeId = 110;

  @override
  FinampDeviceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampDeviceInfo(
      deviceName: fields[0] as String,
      deviceModel: fields[1] as String,
      osVersion: fields[2] as String,
      platform: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinampDeviceInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.deviceName)
      ..writeByte(1)
      ..write(obj.deviceModel)
      ..writeByte(2)
      ..write(obj.osVersion)
      ..writeByte(3)
      ..write(obj.platform);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinampDeviceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinampAppInfoAdapter extends TypeAdapter<FinampAppInfo> {
  @override
  final typeId = 111;

  @override
  FinampAppInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampAppInfo(
      appName: fields[0] as String,
      packageName: fields[1] as String,
      source: fields[2] as String?,
      version: fields[3] as String,
      buildNumber: fields[4] as String,
      installTime: fields[5] as DateTime?,
      updateTime: fields[6] as DateTime?,
      versionHistory: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, FinampAppInfo obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.buildNumber)
      ..writeByte(5)
      ..write(obj.installTime)
      ..writeByte(6)
      ..write(obj.updateTime)
      ..writeByte(7)
      ..write(obj.versionHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinampAppInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinampServerInfoAdapter extends TypeAdapter<FinampServerInfo> {
  @override
  final typeId = 112;

  @override
  FinampServerInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampServerInfo(
      serverAddressType: fields[0] as String,
      serverPort: (fields[1] as num).toInt(),
      serverProtocol: fields[2] as String,
      serverVersion: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinampServerInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.serverAddressType)
      ..writeByte(1)
      ..write(obj.serverPort)
      ..writeByte(2)
      ..write(obj.serverProtocol)
      ..writeByte(3)
      ..write(obj.serverVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinampServerInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinampDeviceInfo _$FinampDeviceInfoFromJson(Map<String, dynamic> json) =>
    FinampDeviceInfo(
      deviceName: json['deviceName'] as String,
      deviceModel: json['deviceModel'] as String,
      osVersion: json['osVersion'] as String,
      platform: json['platform'] as String,
    );

Map<String, dynamic> _$FinampDeviceInfoToJson(FinampDeviceInfo instance) =>
    <String, dynamic>{
      'deviceName': instance.deviceName,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'platform': instance.platform,
    };

FinampAppInfo _$FinampAppInfoFromJson(Map<String, dynamic> json) =>
    FinampAppInfo(
      appName: json['appName'] as String,
      packageName: json['packageName'] as String,
      source: json['source'] as String?,
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as String,
      installTime: json['installTime'] == null
          ? null
          : DateTime.parse(json['installTime'] as String),
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      versionHistory: (json['versionHistory'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FinampAppInfoToJson(FinampAppInfo instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'packageName': instance.packageName,
      'source': instance.source,
      'version': instance.version,
      'buildNumber': instance.buildNumber,
      'installTime': instance.installTime?.toIso8601String(),
      'updateTime': instance.updateTime?.toIso8601String(),
      'versionHistory': instance.versionHistory,
    };

FinampServerInfo _$FinampServerInfoFromJson(Map<String, dynamic> json) =>
    FinampServerInfo(
      serverAddressType: json['serverAddressType'] as String,
      serverPort: (json['serverPort'] as num).toInt(),
      serverProtocol: json['serverProtocol'] as String,
      serverVersion: json['serverVersion'] as String,
    );

Map<String, dynamic> _$FinampServerInfoToJson(FinampServerInfo instance) =>
    <String, dynamic>{
      'serverAddressType': instance.serverAddressType,
      'serverPort': instance.serverPort,
      'serverProtocol': instance.serverProtocol,
      'serverVersion': instance.serverVersion,
    };

EnvironmentMetadata _$EnvironmentMetadataFromJson(Map<String, dynamic> json) =>
    EnvironmentMetadata(
      deviceInfo: FinampDeviceInfo.fromJson(
        json['deviceInfo'] as Map<String, dynamic>,
      ),
      appInfo: FinampAppInfo.fromJson(json['appInfo'] as Map<String, dynamic>),
      serverInfo: json['serverInfo'] == null
          ? null
          : FinampServerInfo.fromJson(
              json['serverInfo'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$EnvironmentMetadataToJson(
  EnvironmentMetadata instance,
) => <String, dynamic>{
  'deviceInfo': instance.deviceInfo,
  'appInfo': instance.appInfo,
  'serverInfo': instance.serverInfo,
};
