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

  ValueNotifier<bool> carModeNotifier = ValueNotifier<bool>(false);

  void init() {
    _detectCarMode();
    carModeNotifier.value = _isCarMode;
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

  void toggleCarMode(bool enable) {
    _isCarMode = enable;
    FinampSettingsHelper.setEnableCarMode(enable);
    carModeNotifier.value = enable;
  }

  // 获取适合车机模式的字体大小
  double getCarModeFontSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.2; // 车机模式下字体增大20%
    }
    return defaultSize;
  }

  // 获取适合车机模式的图标大小
  double getCarModeIconSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.3; // 车机模式下图标增大30%
    }
    return defaultSize;
  }

  // 获取适合车机模式的按钮大小
  double getCarModeButtonSize(double defaultSize) {
    if (_isCarMode) {
      return defaultSize * 1.4; // 车机模式下按钮增大40%
    }
    return defaultSize;
  }

  // 获取适合车机模式的间距
  double getCarModeSpacing(double defaultSpacing) {
    if (_isCarMode) {
      return defaultSpacing * 1.2; // 车机模式下间距增大20%
    }
    return defaultSpacing;
  }
}

// 注册到GetIt
try {
  GetIt.instance.registerSingleton(CarModeHelper());
} catch (e) {
  // 已注册
}
