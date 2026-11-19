import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({
    super.key,
    required this.config,
    required this.api,
    required this.locationService,
  });

  final AppConfig config;
  final RebsApi api;
  final ConfigurableLocationService locationService;

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _currentScenario = 'loading...';
  bool _isLoadingScenario = false;
  String _selectedLocationPreset = 'office';

  static const _scenarios = [
    'success',
    'slow',
    'timeout',
    'accept_then_timeout',
    'server_error',
    'duplicate_conflict',
    'leave_rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  Future<void> _loadScenario() async {
    setState(() => _isLoadingScenario = true);
    final res = await widget.api.getScenario();
    if (mounted) {
      setState(() {
        _isLoadingScenario = false;
        _currentScenario = res is Success<String> ? res.value : 'offline / unreachable';
      });
    }
  }

  Future<void> _setScenario(String mode) async {
    setState(() => _isLoadingScenario = true);
    final res = await widget.api.setScenario(mode);
    if (mounted) {
      setState(() {
        _isLoadingScenario = false;
        if (res is Success<String>) {
          _currentScenario = res.value;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched scenario to: $mode')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to switch scenario (server unreachable)')),
          );
        }
      });
    }
  }

  Future<void> _resetServer() async {
    setState(() => _isLoadingScenario = true);
    final res = await widget.api.resetServer();
    if (mounted) {
      setState(() => _isLoadingScenario = false);
      if (res is Success<void>) {
        _loadScenario();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock server state reset.')),
        );
      }
    }
  }

  void _onLocationPresetChanged(String preset) {
    setState(() {
      _selectedLocationPreset = preset;
      switch (preset) {
        case 'office':
          widget.locationService.simulatedLocation = ConfigurableLocationService.atOffice;
          break;
        case 'far':
          widget.locationService.simulatedLocation = ConfigurableLocationService.fiveHundredMetersAway;
          break;
        case 'unavailable':
          widget.locationService.simulatedLocation = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Testing Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'API Configuration'),
          Card(
            child: ListTile(
              title: const Text('API Base URL (Build Time)'),
              subtitle: Text(widget.config.apiBaseUrl, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Simulated Location (D18)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Simulated Location'),
                    subtitle: const Text('Overrides device GPS with test presets'),
                    value: widget.locationService.isSimulationEnabled,
                    onChanged: (enabled) {
                      setState(() {
                        widget.locationService.isSimulationEnabled = enabled;
                        if (enabled) {
                          _onLocationPresetChanged(_selectedLocationPreset);
                        }
                      });
                    },
                  ),
                  if (widget.locationService.isSimulationEnabled) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'office', label: Text('At Office')),
                        ButtonSegment(value: 'far', label: Text('500m Away')),
                        ButtonSegment(value: 'unavailable', label: Text('GPS Off')),
                      ],
                      selected: {_selectedLocationPreset},
                      onSelectionChanged: (set) => _onLocationPresetChanged(set.first),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLocationPreset == 'office'
                          ? 'Office coordinate: 9.9312, 76.2673 (< 200m)'
                          : _selectedLocationPreset == 'far'
                              ? 'Outside geofence: 9.9360, 76.2673 (~500m)'
                              : 'Simulates GPS error / unavailable location',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Mock Server Scenarios (D27)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active: $_currentScenario',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_isLoadingScenario)
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadScenario),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scenarios.map((s) {
                      final isSelected = s == _currentScenario;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        onSelected: (_) => _setScenario(s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoadingScenario ? null : _resetServer,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset Server State'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SyncBloc>().add(const SyncRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync requested.')),
              );
            },
            icon: const Icon(Icons.sync),
            label: const Text('Trigger Sync Now'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
