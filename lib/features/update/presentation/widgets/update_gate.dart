import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';
import 'package:goodreddit/features/update/presentation/bloc/update_cubit.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks for a newer GitHub release on launch (Android only) and offers the
/// update in a dialog. The APK is downloaded in-app with a progress dialog,
/// then handed to the system installer. Renders [child] unconditionally — the
/// check never blocks the app.
class UpdateGate extends StatefulWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      context.read<UpdateCubit>().check();
    }
  }

  Future<void> _showUpdateDialog(AppUpdate update) async {
    final download = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update available — v${update.version}'),
        content: SingleChildScrollView(
          child: Text(
            update.releaseNotes ?? 'A new version of GoodReddit is available.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Install'),
          ),
        ],
      ),
    );
    if (download == true && update.apkUrl != null && mounted) {
      await _downloadInApp(update);
    }
  }

  Future<void> _downloadInApp(AppUpdate update) async {
    final progress = ValueNotifier<double?>(null);
    var dialogOpen = true;

    // Progress dialog — closed when the installer takes over or on error.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Downloading v${update.version}…'),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (_, value, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 12),
                Text(
                  value == null
                      ? 'Starting download…'
                      : '${(value * 100).round()} %',
                ),
              ],
            ),
          ),
        ),
      ).then((_) => dialogOpen = false),
    );

    void closeDialog() {
      if (dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      OtaUpdate()
          .execute(
            update.apkUrl!,
            destinationFilename: 'goodreddit-${update.version}.apk',
          )
          .listen(
            (event) {
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  final pct = int.tryParse(event.value ?? '');
                  if (pct != null) progress.value = pct / 100;
                case OtaStatus.INSTALLING:
                  // The system installer UI takes over from here.
                  closeDialog();
                default:
                  closeDialog();
                  _fallbackToBrowser(update, '${event.status} ${event.value ?? ''}');
              }
            },
            onError: (Object e) {
              closeDialog();
              _fallbackToBrowser(update, '$e');
            },
          );
    } catch (e) {
      closeDialog();
      await _fallbackToBrowser(update, '$e');
    }
  }

  /// Last resort when the in-app download fails: hand the APK URL to the
  /// browser so the user can still update.
  Future<void> _fallbackToBrowser(AppUpdate update, String reason) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('In-app update failed ($reason) — opening the browser.'),
      ),
    );
    await launchUrl(
      Uri.parse(update.apkUrl!),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateCubit, UpdateState>(
      listenWhen: (prev, curr) =>
          prev.status != UpdateStatus.available &&
          curr.status == UpdateStatus.available,
      listener: (context, state) => _showUpdateDialog(state.update!),
      child: widget.child,
    );
  }
}
