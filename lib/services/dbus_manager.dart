import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:finamp/color_schemes.g.dart';
import 'package:finamp/extensions/string.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:logging/logging.dart';

final _logger = Logger("dBus");

bool shouldUseDBus() {
  return Platform.isLinux;
}

class _ChangeAccentColorService extends DBusObject {
  _ChangeAccentColorService() : super(DBusObjectPath('/com/unicornsonlsd/Finamp'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface == 'com.unicornsonlsd.Finamp' && call.name == 'updateAccentColor') {
      await fetchSystemPalette();
      return DBusMethodSuccessResponse([DBusBoolean(true)]);
    }
    else if (call.interface == 'com.unicornsonlsd.Finamp' && call.name == 'setAccentColor') {
      final text = call.values[0].asString();
      _logger.fine("request to set Accent color to $text");
      final color = text.toColorOrNull();

      if (color == null) return DBusMethodErrorResponse.failed("Invalid color");

      FinampSetters.setAccentColor(color);
      return DBusMethodSuccessResponse([DBusBoolean(true)]);
    }
    _logger.info("Received message but couldn't handle it");
    return super.handleMethodCall(call);
  }
}


Future<void> initDBus() async {
  if (!shouldUseDBus()) return;
  _logger.info("Device is allowed to use dBus");

  final client = DBusClient.session();

  try {
    await client.requestName('com.unicornsonlsd.FinampSettings');
    await client.registerObject(_ChangeAccentColorService());
  } catch (e) {
    _logger.warning("Failed to register object: $e");
    await client.close();
  }

  _logger.info("init finished");
}
