import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/network_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class LocalNetworkAddressSelector extends ConsumerStatefulWidget {
  const LocalNetworkAddressSelector({super.key});

  // Externally callable hook to force committing pending edits before actions (e.g., test connection)
  static Future<void> Function()? commitPendingEdits;

  @override
  ConsumerState<LocalNetworkAddressSelector> createState() => _LocalNetworkAddressSelector();
}

class _LocalNetworkAddressSelector extends ConsumerState<LocalNetworkAddressSelector> {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  String _lastCommittedValue = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
      if (!(_focusNode?.hasFocus ?? false)) {
        _commitIfChanged();
      }
    });
    LocalNetworkAddressSelector.commitPendingEdits = _commitIfChanged;
  }

  Future<void> _updateUrl(String url) async {
    if (url.isEmpty) return; // Ignore empty
    if (!url.startsWith('http')) {
      GlobalSnackbar.message((context) => AppLocalizations.of(context)!.missingSchemaError);
      return;
    }
    GetIt.instance<FinampUserHelper>().currentUser?.update(newLocalAddress: url);
    await changeTargetUrl();
  }

  Future<void> _commitIfChanged() async {
    final current = _controller?.text.trim() ?? '';
    if (current == _lastCommittedValue) return;
    _lastCommittedValue = current;
    await _updateUrl(current);
  }

  @override
  void dispose() {
    if (LocalNetworkAddressSelector.commitPendingEdits == _commitIfChanged) {
      LocalNetworkAddressSelector.commitPendingEdits = null;
    }
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FinampUser? user = ref.watch(FinampUserHelper.finampCurrentUserProvider).valueOrNull;
    String address = user?.localAddress ?? DefaultSettings.localNetworkAddress;
    bool featureEnabled = user?.preferLocalNetwork ?? DefaultSettings.preferLocalNetwork;

    _controller ??= TextEditingController(text: address);
    if (_lastCommittedValue.isEmpty) {
      _lastCommittedValue = address;
    }

    return ListTile(
      enabled: featureEnabled,
      title: Text(AppLocalizations.of(context)!.preferLocalNetworkTargetAddressLocalSettingTitle),
      subtitle: Text(AppLocalizations.of(context)!.preferLocalNetworkTargetAddressLocalSettingDescription),
      trailing: SizedBox(
        width: 200 * MediaQuery.textScaleFactorOf(context),
        child: TextField(
          enabled: featureEnabled,
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.url,
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
            _commitIfChanged();
          },
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
            _commitIfChanged();
          },
          onSubmitted: (_) => _commitIfChanged(),
        ),
      ),
    );
  }
}
