import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/finamp_models.dart';
import 'finamp_settings_helper.dart';

class CarModeHelper {
  static final CarModeHelper _instance = CarModeHelper._internal();
  factory CarModeHelper() => _instance;
  CarModeHelper._internal();

  bool _isCarMode = false;
  bool get isCarMode => _isCarMode;

  bool _enableFloatingLyrics = false;
  bool get enableFloatingLyrics => _enableFloatingLyrics;

  ValueNotifier<bool> carModeNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> floatingLyricsNotifier = ValueNotifier<bool>(false);

  void init() {
    _detectCarMode();
    _loadFloatingLyricsSetting();
    carModeNotifier.value = _isCarMode;
    floatingLyricsNotifier.value = _enableFloatingLyrics;
  }

  void _detectCarMode() {
    // 检测是否为车机环境
    // 1. 检查是否为Android平台
    if (Platform.isAndroid) {
      // 2. 检查屏幕尺寸和密度（车机通常有大屏幕）
      // 3. 检查是否连接到汽车蓝牙或其他汽车特定的硬件
      // 4. 检查用户设置
      _isCarMode = FinampSettingsHelper.finampSettings.enableCarMode;
    }
  }

  void _loadFloatingLyricsSetting() {
    _enableFloatingLyrics = FinampSettingsHelper.finampSettings.enableFloatingLyrics;
  }

  void toggleCarMode(bool enable) {
    _isCarMode = enable;
    FinampSettingsHelper.setEnableCarMode(enable);
    carModeNotifier.value = enable;
  }

  void toggleFloatingLyrics(bool enable) {
    _enableFloatingLyrics = enable;
    FinampSettingsHelper.setEnableFloatingLyrics(enable);
    floatingLyricsNotifier.value = enable;
  }

  // 获取适合车机模式的字体大小（适配1440*1920分辨率）
  double getCarModeFontSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.5; // 1440*1920分辨率下车机字体增大50%
    }
    return defaultSize;
  }

  // 获取适合车机模式的图标大小（适配1440*1920分辨率）
  double getCarModeIconSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.6; // 1440*1920分辨率下车机图标增大60%
    }
    return defaultSize;
  }

  // 获取适合车机模式的按钮大小（适配1440*1920分辨率）
  double getCarModeButtonSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.8; // 1440*1920分辨率下车机按钮增大80%
    }
    return defaultSize;
  }

  // 获取适合车机模式的间距（适配1440*1920分辨率）
  double getCarModeSpacing(double defaultSpacing) {
    if (_isCarMode) {
      return defaultSpacing * 1.5; // 1440*1920分辨率下车机间距增大50%
    }
    return defaultSpacing;
  }

  // 获取适合车机模式的布局比例
  double getCarModeLayoutRatio(double defaultRatio) {
    if (_isCarMode) {
      return defaultRatio * 1.2; // 1440*1920分辨率下车机布局比例调整
    }
    return defaultRatio;
  }

  // 获取车机模式下的安全边距
  EdgeInsets getCarModePadding() {
    if (_isCarMode) {
      return EdgeInsets.symmetric(horizontal: 40, vertical: 30);
    }
    return EdgeInsets.all(0);
  }
}

// 注册到GetIt
void registerCarModeHelper() {
  try {
    GetIt.instance.registerSingleton(CarModeHelper());
  } catch (e) {
    // 已注册
  }
}
