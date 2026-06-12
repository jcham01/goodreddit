import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';
import 'package:goodreddit/features/update/presentation/bloc/update_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks for a newer GitHub release on launch (Android only) and offers the
/// update in a dialog. Renders [child] unconditionally — the check never
/// blocks the app.
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
            update.releaseNotes ??
                'A new version of GoodReddit is available.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (download == true && update.apkUrl != null) {
      await launchUrl(
        Uri.parse(update.apkUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
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
