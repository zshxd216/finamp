import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../components/QueueRestoreScreen/queue_restore_tile.dart';
import '../models/finamp_models.dart';

class QueueRestoreScreen extends StatelessWidget {
  const QueueRestoreScreen({super.key});

  static const routeName = "/queues";

  @override
  Widget build(BuildContext context) {
    final queueService = GetIt.instance<QueueService>();
    final queuesBoxOld = Hive.box<FinampOldStorableQueueInfo>("Queues");
    final queuesBoxNew = Hive.box<FinampStorableQueueInfo>("QueuesNew");
    var queueMapOld = queuesBoxOld.toMap();
    var queueMapNew = queuesBoxNew.toMap();

    queueMapOld.remove("latest");
    queueMapNew.remove("latest");
    for (var entry in queueMapOld.entries) {
      if (queueMapNew.containsKey(entry.key)) {
        queueMapOld.remove(entry.key);
      }
    }
    var queueListOld = queueMapOld.values.toList();
    var queueListNew = queueMapNew.values.toList();
    var combinedQueueList = [...queueListOld.map((e) => (null, e)), ...queueListNew.map((e) => (e, null))];
    combinedQueueList.sort((x, y) {
      var xCreation = x.$1?.creation ?? x.$2!.creation;
      var yCreation = y.$1?.creation ?? y.$2!.creation;
      return yCreation - xCreation;
    });

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.queuesScreen)),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 30.0, bottom: 45.0),
        itemCount: combinedQueueList.length,
        itemBuilder: (context, index) {
          final newQueueInfo = combinedQueueList.elementAt(index).$1;
          final oldQueueInfo = combinedQueueList.elementAt(index).$2;
          return QueueRestoreTile(
            key: ValueKey(
              combinedQueueList.elementAt(index).$1?.creation ?? combinedQueueList.elementAt(index).$2!.creation,
            ),
            info: newQueueInfo,
            oldInfo: oldQueueInfo,
          );
        },
      ),
    );
  }
}
