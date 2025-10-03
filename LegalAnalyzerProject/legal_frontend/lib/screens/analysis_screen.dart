import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../providers/analysis_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalysisProvider>(context, listen: false).loadAnalysisHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Contract'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildTabButton('Upload File', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Analyze Text', 1),
                    const SizedBox(width: 8),
                    _buildTabButton('Q&A', 2),
                  ],
                ),
              ),
              
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildUploadTab(provider),
                    _buildTextInputTab(provider),
                    _buildQATab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedTab == index 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: _selectedTab == index
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () => setState(() => _selectedTab = index),
        child: Text(text),
      ),
    );
  }

  Widget _buildUploadTab(AnalysisProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.upload_file, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Legal Document',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supports PDF, DOCX, and text files',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _pickFile,
                    icon: const Icon(Icons.upload),
                    label: const Text('Choose File'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (provider.isLoading) _buildLoadingIndicator(),
          if (provider.error != null) _buildErrorWidget(provider.error!),
          if (provider.analysisResult != null) _buildResults(provider.analysisResult!, provider),
        ],
      ),
    );
  }

  Widget _buildTextInputTab(AnalysisProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Text input field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Contract Text',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Paste your contract text here...\n\nExample: This Agreement is made between Party A and Party B. The term of this agreement shall be one year. Confidential information shall not be disclosed to third parties.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _textController.text.trim().isEmpty || provider.isLoading
                  ? null
                  : () {
                      print('Analyze Text Button Pressed');
                      print('Text length: ${_textController.text.length}');
                      provider.setDocumentText(_textController.text.trim()); // Store for Q&A
                      provider.analyzeText(_textController.text.trim());
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _textController.text.trim().isEmpty || provider.isLoading
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
              child: provider.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing...'),
                      ],
                    )
                  : const Text(
                      'Analyze Text',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sample text button for quick testing
          if (_textController.text.isEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _textController.text = '''
This Agreement is made between Company ABC (hereinafter referred to as "Party A") and Service Provider XYZ (hereinafter referred to as "Party B").

TERM: This agreement shall be effective from January 1, 2024 and shall continue for a period of one year.

CONFIDENTIALITY: Both parties agree to maintain the confidentiality of all proprietary information shared during the term of this agreement. No confidential information shall be disclosed to third parties without written consent.

PAYMENT TERMS: Party B shall invoice Party A for services rendered. Payment shall be made within 30 days of receipt of invoice.

TERMINATION: Either party may terminate this agreement with 30 days written notice to the other party.

GOVERNING LAW: This agreement shall be governed by and construed in accordance with the laws of India.

JURISDICTION: The courts in Mumbai shall have exclusive jurisdiction over any disputes arising from this agreement.

ARBITRATION: Any dispute arising out of or in connection with this agreement shall be referred to arbitration in accordance with the Arbitration and Conciliation Act, 1996. The seat of arbitration shall be Delhi.

LIABILITY: Neither party shall be liable for any indirect, special, or consequential damages arising from this agreement.

INDEMNIFICATION: Party B agrees to indemnify and hold harmless Party A from any claims, damages, or losses arising from the services provided.
''';
                  setState(() {});
                },
                child: const Text('Load Sample Contract'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          
          // Status indicators
          if (provider.isLoading) _buildLoadingIndicator(),
          if (provider.error != null) _buildErrorWidget(provider.error!),
          if (provider.analysisResult != null) _buildResults(provider.analysisResult!, provider),
        ],
      ),
    );
  }

  Widget _buildQATab(AnalysisProvider provider) {
    final hasDocumentForQA = provider.currentDocumentText != null && provider.currentDocumentText!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Document status indicator
          Card(
            color: hasDocumentForQA ? Colors.green[50] : Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    hasDocumentForQA ? Icons.check_circle : Icons.info,
                    color: hasDocumentForQA ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDocumentForQA 
                              ? 'Document loaded for Q&A'
                              : 'No document loaded',
                          style: TextStyle(
                            color: hasDocumentForQA ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasDocumentForQA) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${provider.currentDocumentText!.length} characters available for analysis',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Question input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ask a Legal Question',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask questions about clauses, risks, compliance, or specific legal aspects of your document',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: hasDocumentForQA 
                          ? 'E.g., What are the termination clauses? What are the compliance risks? Explain the liability provisions...'
                          : 'Please load a document first to ask questions',
                      border: const OutlineInputBorder(),
                      enabled: hasDocumentForQA,
                    ),
                    onChanged: (value) {
                      setState(() {}); 
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Suggested questions when document is loaded
          if (hasDocumentForQA) ...[
            const Text(
              'Suggested Questions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestedQuestion('What are the key risk factors?'),
                _buildSuggestedQuestion('Explain the termination clauses'),
                _buildSuggestedQuestion('What compliance issues exist?'),
                _buildSuggestedQuestion('Summarize the liability provisions'),
                _buildSuggestedQuestion('Are there any jurisdiction issues?'),
                _buildSuggestedQuestion('What are the payment terms?'),
                _buildSuggestedQuestion('Explain the confidentiality clauses'),
                _buildSuggestedQuestion('What dispute resolution mechanisms are included?'),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !hasDocumentForQA || _questionController.text.trim().isEmpty || provider.isLoading
                  ? null
                  : () {
                      print('Ask Question Button Pressed');
                      print('Question: ${_questionController.text.trim()}');
                      print('Document available: ${provider.currentDocumentText != null}');
                      
                      // Use the actual stored document text
                      provider.askQuestion(
                        provider.currentDocumentText!,
                        _questionController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: !hasDocumentForQA || _questionController.text.trim().isEmpty || provider.isLoading
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
              child: provider.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing with InLegalBERT...'),
                      ],
                    )
                  : const Text(
                      'Ask Legal Question',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Status indicators
          if (provider.isLoading) _buildLoadingIndicator(),
          if (provider.error != null) _buildErrorWidget(provider.error!),
          if (provider.analysisResult?.answer != null) _buildAnswer(provider.analysisResult!),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestion(String question) {
    return ActionChip(
      label: Text(question),
      onPressed: () {
        _questionController.text = question;
        setState(() {});
      },
      backgroundColor: Colors.blue[50],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 2 ? 'Analyzing with InLegalBERT...' : 'Analyzing Document...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Processing legal clauses and compliance requirements',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Analysis Error',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Provider.of<AnalysisProvider>(context, listen: false).clearError();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!),
                ),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AnalysisResult result, AnalysisProvider provider) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Comprehensive Summary Card
            if (result.comprehensiveSummary != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'InLegalBERT Comprehensive Analysis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.comprehensiveSummary!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              _showInLegalBERTInfo(context);
                            },
                            child: Text(
                              'Powered by InLegalBERT',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Analysis Summary Card (Existing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Analysis Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed: () {
                            setState(() {
                              _selectedTab = 2; // Switch to Q&A tab
                            });
                          },
                          tooltip: 'Ask questions about this analysis',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRiskIndicator(result.risk['risk_level'] ?? 'MEDIUM'),
                    const SizedBox(height: 12),
                    _buildSummaryItem('Total Clauses', '${result.documentStats['total_clauses'] ?? 'N/A'}'),
                    _buildSummaryItem('Categories Identified', '${result.summary['categories_identified'] ?? 'N/A'}'),
                    _buildSummaryItem('Risk Level', result.risk['risk_level'] ?? 'N/A'),
                    _buildSummaryItem('Risk Score', '${result.risk['risk_score'] ?? 'N/A'}'),
                    _buildSummaryItem('Compliance Status', result.compliance['overall_compliance'] ?? 'N/A'),
                    _buildSummaryItem('Total Words', '${result.documentStats['total_words'] ?? 'N/A'}'),
                    if (result.metadata['processing_time_seconds'] != null)
                      _buildSummaryItem('Processing Time', '${result.metadata['processing_time_seconds']} seconds'),
                  ],
                ),
              ),
            ),
            
            // Clauses by Category
            if (result.clauses.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clauses by Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.clauses.entries.map((entry) => _buildCategorySection(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),
            ],
            
            // Compliance Issues
            if (result.compliance['compliance_issues'] != null && (result.compliance['compliance_issues'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Compliance Issues',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(result.compliance['compliance_issues'] as List).map((issue) => _buildComplianceIssue(issue)),
                    ],
                  ),
                ),
              ),
            ],
            
            // Risk Factors
            if (result.risk['risk_factors'] != null && (result.risk['risk_factors'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Risk Factors',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(result.risk['risk_factors'] as List).map((factor) => _buildRiskFactor(factor)),
                    ],
                  ),
                ),
              ),
            ],
            
            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 2;
                      });
                    },
                    icon: const Icon(Icons.question_answer),
                    label: const Text('Ask Questions'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.clearResults();
                      _textController.clear();
                      provider.clearDocumentText();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Analysis'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<dynamic> clauses) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(_getCategoryIcon(category), size: 20),
          const SizedBox(width: 8),
          Text(
            _formatCategoryName(category),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('${clauses.length}'),
            backgroundColor: Colors.blue[50],
            labelStyle: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      children: clauses.map<Widget>((clause) => ListTile(
        title: Text(
          clause['text']?.toString() ?? 'No text available',
          style: const TextStyle(fontSize: 12),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Confidence: ${((clause['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildComplianceIssue(dynamic issue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['issue']?.toString() ?? 'Unknown issue',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Law: ${issue['law']?.toString() ?? 'Unknown'} • Severity: ${issue['severity']?.toString() ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactor(dynamic factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, size: 16, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(factor.toString())),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAnswer(AnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'InLegalBERT Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.answer!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${((result.confidence ?? 0) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String riskLevel) {
    Color color;
    IconData icon;
    
    switch (riskLevel) {
      case 'HIGH':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'MEDIUM':
        color = Colors.orange;
        icon = Icons.info;
        break;
      case 'LOW':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${riskLevel} RISK',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _getRiskDescription(riskLevel),
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'HIGH':
        return 'Immediate attention required. Significant legal and compliance risks identified.';
      case 'MEDIUM':
        return 'Moderate risks present. Review recommended for important contracts.';
      case 'LOW':
        return 'Minimal risks identified. Standard legal provisions detected.';
      default:
        return 'Risk assessment completed.';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'confidentiality':
        return Icons.lock;
      case 'termination':
        return Icons.exit_to_app;
      case 'liability':
        return Icons.gavel;
      case 'indemnification':
        return Icons.security;
      case 'intellectual_property':
        return Icons.lightbulb;
      case 'governing_law':
        return Icons.balance;
      case 'payment_terms':
        return Icons.payment;
      case 'warranties':
        return Icons.assignment_turned_in;
      case 'limitation_of_liability':
        return Icons.speed;
      case 'dispute_resolution':
        return Icons.people;
      case 'jurisdiction':
        return Icons.location_on;
      case 'force_majeure':
        return Icons.flash_on;
      case 'non_compete':
        return Icons.block;
      case 'severability':
        return Icons.link_off;
      case 'assignment':
        return Icons.swap_horiz;
      default:
        return Icons.description;
    }
  }

  String _formatCategoryName(String category) {
    return category.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  // NEW: Show InLegalBERT information
  void _showInLegalBERTInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('InLegalBERT'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'InLegalBERT is a legal language model specifically trained on Indian legal documents.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'This analysis is powered by InLegalBERT to provide comprehensive legal document understanding and insights specific to Indian legal framework.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // You can add functionality to open the actual InLegalBERT website
              // For now, just close the dialog
              Navigator.pop(context);
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final provider = Provider.of<AnalysisProvider>(context, listen: false);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'doc'],
      );

      if (result != null && result.files.single.path != null) {
        await provider.analyzeDocument(File(result.files.single.path!));
      }
    } catch (e) {
      final provider = Provider.of<AnalysisProvider>(context, listen: false);
      provider.clearError();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _questionController.dispose();
    super.dispose();
  }
}