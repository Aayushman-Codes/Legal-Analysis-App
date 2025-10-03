import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import 'analysis_screen.dart';
import 'history_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Legal Contract Analyzer',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered analysis for Indian legal documents',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureCard(
              context,
              icon: Icons.upload_file,
              title: 'Upload Document',
              subtitle: 'Analyze PDF, DOCX, or text files',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen())),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.text_fields,
              title: 'Paste Text',
              subtitle: 'Analyze contract text directly',
              onTap: () => _showTextInputDialog(context),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'Analysis History',
              subtitle: 'View previous analyses',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            const Spacer(),
            _buildQuickStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final history = Provider.of<AnalysisProvider>(context).analysisHistory;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Total Analyses', history.length.toString()),
                _buildStatItem(context, 'Today', history.length.toString()),
                _buildStatItem(context, 'High Risk', history.where((r) => r.summary['risk_level'] == 'HIGH').length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showTextInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Contract Text'),
        content: const TextField(
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Paste your contract text here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen()));
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }
}