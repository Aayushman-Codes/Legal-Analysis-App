import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.analysisHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No analysis history',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.analysisHistory.length,
            itemBuilder: (context, index) {
              final analysis = provider.analysisHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: _buildRiskIcon(analysis.summary['risk_level']),
                  title: Text('Contract Analysis ${index + 1}'),
                  subtitle: Text('${analysis.summary['total_clauses']} clauses • ${analysis.summary['categories_identified']} categories'),
                  trailing: Text(
                    analysis.summary['risk_level'],
                    style: TextStyle(
                      color: _getRiskColor(analysis.summary['risk_level']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    _showAnalysisDetails(context, analysis);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRiskIcon(String riskLevel) {
    IconData icon;
    Color color;
    
    switch (riskLevel) {
      case 'HIGH':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'MEDIUM':
        icon = Icons.info;
        color = Colors.orange;
        break;
      case 'LOW':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color);
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAnalysisDetails(BuildContext context, dynamic analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Risk Level: ${analysis.summary['risk_level']}'),
              Text('Total Clauses: ${analysis.summary['total_clauses']}'),
              Text('Categories: ${analysis.summary['categories_identified']}'),
              const SizedBox(height: 16),
              const Text(
                'Key Findings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...analysis.summary['key_findings'].map<Widget>((finding) => Text('• $finding')).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}