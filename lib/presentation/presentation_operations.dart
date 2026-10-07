import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/data_management/data_management_cubit.dart';

/// Tracks the initiating data owners across retained presentation trees.
/// The original owner still handles its picker/share/restore effects once.
class PresentationOperations extends ChangeNotifier {
  final Map<DataManagementCubit, StreamSubscription<DataManagementState>>
  _owners = {};
  bool _disposed = false;
  static PresentationOperations? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OperationsScope>()?.notifier;
  static PresentationOperations of(BuildContext context) =>
      maybeOf(context) ??
      (throw FlutterError(
        'PresentationOperationHost is required above style selection.',
      ));
  bool get blocksSelection => _owners.keys.any(
    (owner) =>
        !owner.isClosed && (owner.state.busy || owner.state.refreshRequired),
  );
  void attach(DataManagementCubit owner) {
    _owners.putIfAbsent(
      owner,
      () => owner.stream.listen((_) {
        if (!_disposed) notifyListeners();
      }),
    );
    _notifyAfterFrame();
  }

  void detach(DataManagementCubit owner) {
    _owners.remove(owner)?.cancel();
    _notifyAfterFrame();
  }

  void _notifyAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _owners.values) {
      subscription.cancel();
    }
    _owners.clear();
    super.dispose();
  }
}

/// Optional in standalone screen fixtures; installed above all production routes.
class DataOperationScope extends StatefulWidget {
  const DataOperationScope({super.key, required this.child});
  final Widget child;
  @override
  State<DataOperationScope> createState() => _DataOperationScopeState();
}

class _DataOperationScopeState extends State<DataOperationScope> {
  PresentationOperations? _operations;
  DataManagementCubit? _owner;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = PresentationOperations.maybeOf(context);
    if (operations == null) return;
    final owner = context.read<DataManagementCubit>();
    if (identical(operations, _operations) && identical(owner, _owner)) return;
    if (_owner != null) _operations?.detach(_owner!);
    _operations = operations;
    _owner = owner;
    operations.attach(owner);
  }

  @override
  void dispose() {
    if (_owner != null) _operations?.detach(_owner!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Owns the tracker for the lifetime of the application Navigator.
class PresentationOperationHost extends StatefulWidget {
  const PresentationOperationHost({super.key, required this.child});
  final Widget child;
  @override
  State<PresentationOperationHost> createState() =>
      _PresentationOperationHostState();
}

class _PresentationOperationHostState extends State<PresentationOperationHost> {
  final _operations = PresentationOperations();
  @override
  void dispose() {
    _operations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _OperationsScope(notifier: _operations, child: widget.child);
}

class _OperationsScope extends InheritedNotifier<PresentationOperations> {
  const _OperationsScope({required super.notifier, required super.child});
}
