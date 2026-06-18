import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Integration card data model.
class _Integration {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> scopes;
  bool connected;

  _Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.scopes,
    this.connected = false,
  });
}

/// Integrations settings page — toggle Google connectors (Gmail, Calendar, Drive).
class IntegrationsPage extends StatefulWidget {
  const IntegrationsPage({super.key});

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  final List<_Integration> _integrations = [
    _Integration(
      id: 'gmail',
      name: 'Gmail',
      description:
          'Draft and send emails on your behalf. The agent can compose professional replies, follow-ups, and status updates grounded in your task data.',
      icon: Icons.mail_outline,
      color: const Color(0xFFEA4335),
      scopes: ['gmail.send', 'gmail.compose', 'gmail.readonly'],
    ),
    _Integration(
      id: 'calendar',
      name: 'Google Calendar',
      description:
          'Create and manage calendar events. The agent can schedule meetings, set reminders, and block focus time based on your task deadlines.',
      icon: Icons.calendar_today_outlined,
      color: const Color(0xFF4285F4),
      scopes: ['calendar.events', 'calendar.readonly'],
    ),
    _Integration(
      id: 'drive',
      name: 'Google Drive',
      description:
          'Read and organize files in Drive. The agent can find documents, create folders, and attach references to tasks.',
      icon: Icons.folder_outlined,
      color: const Color(0xFF0F9D58),
      scopes: ['drive.readonly', 'drive.file'],
    ),
  ];

  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Integrations'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Text(
                  'Connect your tools',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enable integrations so the Activities agent can execute tasks on your behalf.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Integration cards
                ..._integrations.map(_buildIntegrationCard),

                const SizedBox(height: 32),

                // Security note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Your data is secure',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'OAuth tokens are encrypted at rest. The agent only accesses what it needs for each task. You can revoke access at any time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIntegrationCard(_Integration integration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: integration.connected
              ? integration.color.withAlpha(120)
              : AppTheme.borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon bubble
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: integration.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    integration.icon,
                    color: integration.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integration.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (integration.connected)
                        Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Toggle switch
                Switch.adaptive(
                  value: integration.connected,
                  activeTrackColor: integration.color,
                  onChanged: (val) => _toggleIntegration(integration, val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              integration.description,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),

            // Scopes
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: integration.scopes.map((scope) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scope,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleIntegration(_Integration integration, bool enable) async {
    if (enable) {
      // TODO: Launch Google OAuth flow via agent-service
      // For now, show a placeholder dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Connect ${integration.name}?'),
          content: Text(
            'This will redirect you to Google to authorize ${integration.name} access.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: integration.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Connect'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => integration.connected = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${integration.name} connected'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } else {
      // Disconnect
      setState(() => integration.connected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${integration.name} disconnected'),
          backgroundColor: AppTheme.surfaceBackground,
        ),
      );
    }
  }
}
