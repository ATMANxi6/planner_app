import 'package:flutter/material.dart';
import '../widgets/continuous_timeline_view.dart';

/// Fullscreen time block calendar view with Google Calendar-style continuous timeline
class TimeBlockFullscreen extends StatelessWidget {
  final DateTime? initialDate;

  const TimeBlockFullscreen({
    super.key,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Block Calendar'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
      ),
      body: ContinuousTimelineView(
        initialDate: initialDate ?? DateTime.now(),
      ),
    );
  }
}
