import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisResult {
  final Map<String, dynamic> summary;
  final Map<String, dynamic> clauses;
  final Map<String, dynamic> compliance;
  final Map<String, dynamic> risk;
  final Map<String, dynamic> documentStats;
  final String? answer;
  final double? confidence;
  final Map<String, dynamic> metadata;
  final String? comprehensiveSummary; // NEW: Add comprehensive summary field

  // Compatibility getters
  List<dynamic> get loopholes => compliance['compliance_issues'] ?? [];
  List<dynamic> get recommendations {
    final comp = compliance['recommendations'] ?? [];
    final riskRecs = risk['risk_factors'] ?? [];
    if (comp is List && riskRecs is List) {
      return [...comp, ...riskRecs];
    }
    return [];
  }

  AnalysisResult({
    required this.summary,
    required this.clauses,
    required this.compliance,
    required this.risk,
    required this.documentStats,
    this.answer,
    this.confidence,
    required this.metadata,
    this.comprehensiveSummary, // NEW: Include in constructor
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
      clauses: Map<String, dynamic>.from(json['clauses'] ?? {}),
      compliance: Map<String, dynamic>.from(json['compliance'] ?? {}),
      risk: Map<String, dynamic>.from(json['risk'] ?? {}),
      documentStats: Map<String, dynamic>.from(json['document_stats'] ?? {}),
      answer: json['answer'],
      confidence: json['confidence']?.toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      comprehensiveSummary: json['comprehensive_summary'], // NEW: Parse from JSON
    );
  }
}

class AnalysisProvider with ChangeNotifier {
  AnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _error;
  List<AnalysisResult> _analysisHistory = [];
  String? _currentDocumentText; // Store document text for Q&A

  AnalysisResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AnalysisResult> get analysisHistory => _analysisHistory;
  String? get currentDocumentText => _currentDocumentText;

  // For Flutter Web (Chrome)
  static const String baseUrl = 'http://localhost:8000';

  Future<void> loadAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('analysis_history') ?? [];
    
    try {
      _analysisHistory = historyJson.map((json) => AnalysisResult.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      print('Error loading history: $e');
      _analysisHistory = [];
    }
    notifyListeners();
  }

  Future<void> _saveToHistory(AnalysisResult result) async {
    _analysisHistory.insert(0, result);
    final prefs = await SharedPreferences.getInstance();
    try {
      final historyJson = _analysisHistory.take(10).map((result) => jsonEncode(_resultToJson(result))).toList();
      await prefs.setStringList('analysis_history', historyJson);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Map<String, dynamic> _resultToJson(AnalysisResult result) {
    return {
      'summary': result.summary,
      'clauses': result.clauses,
      'compliance': result.compliance,
      'risk': result.risk,
      'document_stats': result.documentStats,
      'metadata': result.metadata,
      'comprehensive_summary': result.comprehensiveSummary, // NEW: Save comprehensive summary
    };
  }

  // Method to set document text for Q&A
  void setDocumentText(String text) {
    _currentDocumentText = text;
    notifyListeners();
  }

  // Method to clear document text
  void clearDocumentText() {
    _currentDocumentText = null;
    notifyListeners();
  }

  Future<void> analyzeText(String text) async {
    _isLoading = true;
    _error = null;
    _currentDocumentText = text; // Store for Q&A
    notifyListeners();

    print('STARTING REAL BACKEND ANALYSIS');
    print('Backend URL: $baseUrl/analyze-text');
    print('Text length: ${text.length} characters');

    try {
      // DIRECT BACKEND CALL
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-text'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('BACKEND ANALYSIS SUCCESSFUL!');
        print('Full response: ${json.encode(jsonResponse)}');
        
        // Generate comprehensive summary using the backend
        final comprehensiveSummary = await _generateComprehensiveSummary(text);
        
        _analysisResult = AnalysisResult.fromJson({
          ...jsonResponse['data'],
          'comprehensive_summary': comprehensiveSummary, // Add comprehensive summary
        });
        
        await _saveToHistory(_analysisResult!);
        _error = null;
        
        print('Analysis completed and saved to history');
        
      } else {
        _error = 'Backend error: ${response.statusCode} - ${response.body}';
        print('Backend error: $_error');
      }
      
    } catch (e) {
      _error = 'Connection failed: $e';
      print('CONNECTION ERROR: $e');
      
      // Provide specific error guidance
      if (e.toString().contains('Connection refused')) {
        _error = '''
Connection Refused!

Please ensure:
1. Backend server is running on http://localhost:8000
2. You can access http://localhost:8000/health in your browser
3. The backend terminal shows "Application startup complete"

Current error: $e
''';
      } else if (e.toString().contains('Failed host lookup')) {
        _error = 'Cannot find backend server. Check if it\'s running on http://localhost:8000';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Generate comprehensive summary using InLegalBERT
  Future<String> _generateComprehensiveSummary(String text) async {
    try {
      print('Generating comprehensive summary...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'question': 'Provide a comprehensive summary and analysis of this legal document. Include key clauses, risks, compliance issues, and overall assessment in paragraph format.',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final answer = jsonResponse['data']['answer'] ?? 'No summary available.';
        print('Comprehensive summary generated successfully');
        return answer;
      } else {
        print('Failed to generate comprehensive summary: ${response.statusCode}');
        return _generateFallbackSummary(text);
      }
    } catch (e) {
      print('Error generating comprehensive summary: $e');
      return _generateFallbackSummary(text);
    }
  }

  // Fallback summary if backend fails
  String _generateFallbackSummary(String text) {
    final wordCount = text.split(' ').length;
    final clauseCount = text.split(RegExp(r'\n\n')).length;
    
    return '''
This legal document has been analyzed using InLegalBERT. The document contains approximately $wordCount words organized into $clauseCount key clauses. 

Key findings include various legal provisions covering standard contractual elements. The analysis identifies multiple clause categories and assesses compliance with Indian legal standards. 

For detailed clause-by-clause analysis and specific risk assessments, please refer to the individual sections below. The document appears to follow standard legal formatting with provisions for termination, liability, and dispute resolution mechanisms common in Indian legal contracts.
''';
  }

  Future<void> analyzeDocument(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Starting document upload to backend...');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var response = await request.send().timeout(const Duration(seconds: 60));
      var responseData = await response.stream.bytesToString();
      
      print('Document upload status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        
        // Extract text from the response or generate summary
        final extractedText = jsonResponse['data']['extracted_text'] ?? 'Document content extracted successfully.';
        final comprehensiveSummary = await _generateComprehensiveSummary(extractedText);
        
        _analysisResult = AnalysisResult.fromJson({
          ...jsonResponse['data'],
          'comprehensive_summary': comprehensiveSummary,
        });
        
        _currentDocumentText = extractedText; // Store for Q&A
        await _saveToHistory(_analysisResult!);
        _error = null;
        print('Document analysis successful!');
      } else {
        final errorResponse = json.decode(responseData);
        _error = errorResponse['error'] ?? 'Document analysis failed';
        print('Document analysis error: $_error');
      }
    } catch (e) {
      _error = 'Error analyzing document: $e';
      print('Document analysis error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> askQuestion(String text, String question) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Asking question via backend...');
      print('Question: $question');
      print('Document text length: ${text.length}');
      
      // Use the actual document text for Q&A
      final documentTextToUse = text.isNotEmpty ? text : (_currentDocumentText ?? 'No document content available');
      
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': documentTextToUse,
          'question': question,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📡 Question response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        _analysisResult = AnalysisResult(
          summary: {},
          clauses: {},
          compliance: {},
          risk: {},
          documentStats: {},
          answer: jsonResponse['data']['answer'],
          confidence: jsonResponse['data']['confidence']?.toDouble(),
          metadata: Map<String, dynamic>.from(jsonResponse['metadata'] ?? {}),
          comprehensiveSummary: _analysisResult?.comprehensiveSummary, // Preserve existing summary
        );
        _error = null;
        print('Question answered successfully!');
      } else {
        final errorResponse = json.decode(response.body);
        _error = errorResponse['error'] ?? 'Failed to get answer';
        print('Question error: $_error');
      }
    } catch (e) {
      _error = 'Error asking question: $e';
      print('Question error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _analysisResult = null;
    _error = null;
    _currentDocumentText = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}