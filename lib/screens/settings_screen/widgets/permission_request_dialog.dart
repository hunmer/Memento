import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/permission_controller.dart';

Future<bool> showPermissionRequestDialog({
  required BuildContext context,
  required PermissionController controller,
  bool barrierDismissible = false,
  bool showSkipButton = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder:
        (context) => PermissionRequestDialog(
          controller: controller,
          showSkipButton: showSkipButton,
        ),
  );

  return result ?? false;
}

class PermissionRequestDialog extends StatefulWidget {
  const PermissionRequestDialog({
    super.key,
    required this.controller,
    this.showSkipButton = true,
  });

  final PermissionController controller;
  final bool showSkipButton;

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  List<PermissionStateInfo> _permissionStates = [];
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final states = await widget.controller.loadPermissionStates();
      if (!mounted) return;

      if (states.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _permissionStates = states;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Failed to load permission states: $e');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestSingle(Permission permission) async {
    setState(() => _isRequesting = true);
    await widget.controller.requestPermission(permission);
    await _loadStates();
    setState(() => _isRequesting = false);
    _closeIfAllGranted();
  }

  Future<void> _handleRequestAll() async {
    setState(() => _isRequesting = true);
    await widget.controller.requestPermissions(
      _permissionStates.map((s) => s.requirement).toList(),
    );
    await _loadStates();
    setState(() => _isRequesting = false);
    _closeIfAllGranted();
  }

  void _closeIfAllGranted() {
    if (_permissionStates.isNotEmpty &&
        _permissionStates.every((state) => state.isGranted)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 480 ? 480.0 : width * 0.9;
    final listHeight = MediaQuery.of(context).size.height * 0.4;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'app_permissionsTitle'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'app_close'.tr,
                    onPressed:
                        _isRequesting
                            ? null
                            : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'app_permissionsDescription'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    itemCount: _permissionStates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final state = _permissionStates[index];
                      return _buildPermissionTile(state);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final allGranted =
        _permissionStates.isNotEmpty &&
        _permissionStates.every((state) => state.isGranted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: (_isRequesting || allGranted) ? null : _handleRequestAll,
          icon: const Icon(Icons.done_all),
          label: Text('app_permissionsGrantAll'.tr),
        ),
        if (widget.showSkipButton) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                _isRequesting ? null : () => Navigator.of(context).pop(false),
            child: Text('app_notNow'.tr),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionTile(PermissionStateInfo state) {
    final requirement = state.requirement;
    final status = state.status;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(requirement.icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.titleKey.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  requirement.descriptionKey.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildTrailing(status, requirement.permission),
        ],
      ),
    );
  }

  Widget _buildTrailing(PermissionStatus status, Permission permission) {
    if (status.isGranted) {
      return Chip(
        label: Text('app_permissionsGranted'.tr),
        avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
        backgroundColor: Colors.green.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.green),
      );
    }

    if (status.isPermanentlyDenied) {
      return TextButton(
        onPressed: _isRequesting ? null : openAppSettings,
        child: Text('app_permissionsOpenSettings'.tr),
      );
    }

    return ElevatedButton(
      onPressed: _isRequesting ? null : () => _handleRequestSingle(permission),
      child: Text('app_permissionsRequest'.tr),
    );
  }
}
