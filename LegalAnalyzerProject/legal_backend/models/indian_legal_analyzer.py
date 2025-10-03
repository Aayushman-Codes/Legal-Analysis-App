import requests
import json
import re
import logging
from typing import List, Dict, Any
from datetime import datetime
from config import HF_API_URL, HF_TOKEN, LEGAL_MODELS, INDIAN_CLAUSE_CATEGORIES

logger = logging.getLogger(__name__)

class IndianLegalAnalyzer:
    def __init__(self):
        self.headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        self.session = requests.Session()
    
    def classify_legal_provision(self, text: str) -> Dict[str, Any]:
        try:
            # Skip very short texts
            if len(text.strip()) < 10:
                return {
                    "category": "other",
                    "confidence": 0.0,
                    "original_label": "too_short"
                }
                
            payload = {"inputs": text}
            
            response = self.session.post(
                f"{HF_API_URL}{LEGAL_MODELS['classification']}",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                return self._process_classification_result(result, text)
            else:
                logger.warning(f"Classification API returned {response.status_code}, using rule-based fallback")
                return self._rule_based_classification(text)
                
        except Exception as e:
            logger.error(f"Classification error: {e}")
            return self._rule_based_classification(text)

    def _process_classification_result(self, result: Any, text: str) -> Dict[str, Any]:
        try:
            if isinstance(result, list):
                top_result = result[0]
                label = top_result.get('label', 'unknown')
                score = top_result.get('score', 0.0)
                
                indian_category = self._map_to_indian_category(label, text)
                
                return {
                    "category": indian_category,
                    "confidence": score,
                    "original_label": label
                }
            else:
                return self._rule_based_classification(text)
                
        except Exception as e:
            logger.error(f"Error processing classification result: {e}")
            return self._rule_based_classification(text)

    def _map_to_indian_category(self, label: str, text: str) -> str:
        label_lower = label.lower()
        text_lower = text.lower()
        
        category_mapping = {
            'confidential': 'confidentiality',
            'terminat': 'termination',
            'liability': 'liability',
            'indemnif': 'indemnification',
            'intellectual': 'intellectual_property',
            'governing': 'governing_law',
            'payment': 'payment_terms',
            'warrant': 'warranties',
            'limitation': 'limitation_of_liability',
            'dispute': 'dispute_resolution',
            'jurisdiction': 'jurisdiction',
            'force': 'force_majeure',
            'compete': 'non_compete',
            'severability': 'severability',
            'assignment': 'assignment'
        }
        
        for key, category in category_mapping.items():
            if key in label_lower:
                return category
        
        # Indian-specific checks
        if any(term in text_lower for term in ['stamp duty', 'stamp act']):
            return 'other'
        elif any(term in text_lower for term in ['arbitration', 'arbitral tribunal']):
            return 'dispute_resolution'
        elif any(term in text_lower for term in ['notice', 'notify', 'communication']):
            return 'other'
        
        return 'other'

    def _rule_based_classification(self, text: str) -> Dict[str, Any]:
        text_lower = text.lower()
        
        # Define patterns for all categories we can detect
        patterns = {
            'confidentiality': [
                r'\b(?:confidential|non.?disclosure|proprietary information|trade secret)\b',
                r'\b(?:not disclose|maintain secrecy)\b'
            ],
            'termination': [
                r'\b(?:terminat|expir|cancell|end of|valid until)\b',
                r'\b(?:duration|term of|early termination)\b'
            ],
            'liability': [
                r'\b(?:liability|liable|responsible|obligation)\b',
                r'\b(?:damages|compensation|accountable)\b'
            ],
            'indemnification': [
                r'\b(?:indemnif|hold harmless|make good)\b',
                r'\b(?:reimburse|compensate for loss)\b'
            ],
            'intellectual_property': [
                r'\b(?:intellectual property|copyright|patent|trademark)\b',
                r'\b(?:ip rights|proprietary rights)\b'
            ],
            'governing_law': [
                r'\b(?:governing law|applicable law)\b',
                r'\b(?:laws of india|indian law)\b'
            ],
            'payment_terms': [
                r'\b(?:payment|fee|compensation|consideration|price)\b',
                r'\b(?:within \d+ days|upon delivery|invoice)\b'
            ],
            'warranties': [
                r'\b(?:warrant|guarantee|representation)\b',
                r'\b(?:assurance|certify)\b'
            ],
            'limitation_of_liability': [
                r'\b(?:limitation of liability|cap on damages)\b',
                r'\b(?:maximum liability|limited to)\b'
            ],
            'dispute_resolution': [
                r'\b(?:dispute|arbitration|mediation|conciliation)\b',
                r'\b(?:arbitral tribunal|arbitrator)\b'
            ],
            'jurisdiction': [
                r'\b(?:jurisdiction|courts of|competent court)\b',
                r'\b(?:territorial jurisdiction)\b'
            ],
            'force_majeure': [
                r'\b(?:force majeure|act of god|unforeseen circumstances)\b',
                r'\b(?:natural calamity)\b'
            ],
            'non_compete': [
                r'\b(?:non.?compete|non.?competition)\b',
                r'\b(?:restrictive covenant)\b'
            ],
            'severability': [
                r'\b(?:severability|severable)\b',
                r'\b(?:if any provision)\b'
            ],
            'assignment': [
                r'\b(?:assignment|assign)\b',
                r'\b(?:transfer rights)\b'
            ]
        }
        
        # Initialize all categories with zero score
        category_scores = {}
        for category in INDIAN_CLAUSE_CATEGORIES:
            category_scores[category] = 0
        
        # Score based on pattern matches
        for category, pattern_list in patterns.items():
            for pattern in pattern_list:
                try:
                    matches = re.findall(pattern, text_lower, re.IGNORECASE)
                    category_scores[category] += len(matches) * 2
                except Exception as e:
                    logger.warning(f"Pattern error for {category}: {pattern} - {e}")
                    continue
        
        # Boost scores for Indian legal specific terms
        if 'indian contract act' in text_lower:
            category_scores['governing_law'] += 3
        
        if any(court in text_lower for court in ['delhi', 'mumbai', 'chennai', 'kolkata', 'bangalore', 'hyderabad']):
            category_scores['jurisdiction'] += 3
        
        if 'stamp duty' in text_lower or 'stamp act' in text_lower:
            category_scores['other'] += 2
        
        # Find the best category
        best_category = 'other'
        best_score = 0
        
        for category, score in category_scores.items():
            if score > best_score:
                best_score = score
                best_category = category
        
        # Calculate confidence (normalize score)
        confidence = min(best_score / 10.0, 1.0) if best_score > 0 else 0.0
        
        return {
            "category": best_category,
            "confidence": confidence,
            "original_label": "rule_based"
        }

    def analyze_contract_compliance(self, text: str) -> Dict[str, Any]:
        compliance_issues = []
        text_lower = text.lower()
        
        # Indian Contract Act compliance
        if 'consideration' not in text_lower and 'payment' not in text_lower and 'price' not in text_lower:
            compliance_issues.append({
                "law": "Indian Contract Act, 1872",
                "issue": "Consideration not clearly specified",
                "severity": "HIGH"
            })
        
        # Jurisdiction compliance
        if not any(court in text_lower for court in ['delhi', 'mumbai', 'chennai', 'kolkata', 'bangalore', 'india', 'indian']):
            compliance_issues.append({
                "law": "Code of Civil Procedure, 1908",
                "issue": "Jurisdiction not specified for Indian courts",
                "severity": "HIGH"
            })
        
        # Companies Act compliance for corporate agreements
        if any(term in text_lower for term in ['company', 'private limited', 'ltd', 'pvt']):
            if 'board resolution' not in text_lower and 'authorized signatory' not in text_lower:
                compliance_issues.append({
                    "law": "Companies Act, 2013",
                    "issue": "Corporate authorization not specified",
                    "severity": "MEDIUM"
                })
        
        return {
            "compliance_issues": compliance_issues,
            "overall_compliance": "COMPLIANT" if not compliance_issues else "NON-COMPLIANT"
        }

    def assess_contract_risk(self, text: str) -> Dict[str, Any]:
        risk_factors = []
        risk_score = 0
        text_lower = text.lower()
        
        # High risk indicators
        if 'unlimited liability' in text_lower:
            risk_factors.append("Unlimited liability clause - high risk")
            risk_score += 3
        
        if not any(resolution in text_lower for resolution in ['arbitration', 'mediation', 'court', 'jurisdiction']):
            risk_factors.append("No dispute resolution mechanism - high risk")
            risk_score += 3
        
        if 'foreign law' in text_lower and 'india' not in text_lower:
            risk_factors.append("Foreign governing law without Indian jurisdiction - high risk")
            risk_score += 3
        
        # Medium risk indicators
        if 'as soon as possible' in text_lower or 'reasonable time' in text_lower:
            risk_factors.append("Vague timeframes - medium risk")
            risk_score += 2
        
        if 'penalty' in text_lower and 'liquidated damages' not in text_lower:
            risk_factors.append("Penalty clauses without liquidated damages - medium risk")
            risk_score += 2
        
        # Low risk indicators
        if 'confidential' not in text_lower and 'proprietary' not in text_lower:
            risk_factors.append("No confidentiality provisions - low risk")
            risk_score += 1
        
        # Determine risk level
        if risk_score >= 6:
            risk_level = "HIGH"
        elif risk_score >= 3:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"
        
        return {
            "risk_level": risk_level,
            "risk_score": risk_score,
            "risk_factors": risk_factors
        }

    def answer_legal_question(self, question: str, context: str) -> Dict[str, Any]:
        try:
            prompt = f"Context: {context[:1000]}\nQuestion: {question}\nAnswer:"
            
            payload = {
                "inputs": prompt,
                "parameters": {"max_length": 500}
            }
            
            response = self.session.post(
                f"{HF_API_URL}{LEGAL_MODELS['qa']}",
                headers=self.headers,
                json=payload,
                timeout=45
            )
            
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, list) and len(result) > 0:
                    answer = result[0].get('generated_text', '').strip()
                    return {
                        "answer": answer,
                        "confidence": 0.8,
                        "source": "inlegalbert"
                    }
            
            return self._fallback_legal_answer(question)
            
        except Exception as e:
            logger.error(f"Question answering error: {e}")
            return self._fallback_legal_answer(question)

    def _fallback_legal_answer(self, question: str) -> Dict[str, Any]:
        question_lower = question.lower()
        
        if any(term in question_lower for term in ['termination', 'end contract']):
            answer = "Under Indian Contract Act, termination rights must be clearly specified with proper notice periods. Check for termination clauses specifying conditions, notice periods, and consequences."
        elif any(term in question_lower for term in ['payment', 'consideration']):
            answer = "Consideration is essential for contract validity under Indian Contract Act Section 25. Payment terms should include amounts, due dates, payment methods, and consequences of late payment."
        elif any(term in question_lower for term in ['liability', 'damages']):
            answer = "Liability clauses are governed by Sections 73-74 of Indian Contract Act. Look for limitations of liability, caps on damages, indemnification provisions, and exclusion of consequential damages."
        elif any(term in question_lower for term in ['jurisdiction', 'court']):
            answer = "Jurisdiction clauses should specify Indian courts for enforceability. Common choices are courts in Delhi, Mumbai, Chennai, Kolkata, or Bangalore under Indian legal framework."
        elif any(term in question_lower for term in ['arbitration', 'dispute']):
            answer = "Arbitration clauses must comply with Arbitration and Conciliation Act, 1996. They should specify seat of arbitration (usually Indian city), governing rules, and appointment of arbitrators."
        elif any(term in question_lower for term in ['confidential', 'nda']):
            answer = "Confidentiality clauses protect proprietary information. They should define confidential information, obligations of parties, exceptions, and duration of confidentiality obligations."
        else:
            answer = "Based on Indian legal principles, ensure contract compliance with Indian Contract Act, proper jurisdiction clauses, clear dispute resolution mechanisms, and adequate protection of parties' rights."
        
        return {
            "answer": answer,
            "confidence": 0.7,
            "source": "fallback_knowledge"
        }

    def comprehensive_analysis(self, text: str, clauses: List[Dict]) -> Dict[str, Any]:
        classified_clauses = []
        for clause in clauses:
            classification = self.classify_legal_provision(clause["text"])
            classified_clauses.append({**clause, **classification})
        
        provisions_by_category = {}
        for clause in classified_clauses:
            category = clause["category"]
            if category not in provisions_by_category:
                provisions_by_category[category] = []
            provisions_by_category[category].append(clause)
        
        compliance_analysis = self.analyze_contract_compliance(text)
        risk_assessment = self.assess_contract_risk(text)
        
        return {
            "provisions_analysis": classified_clauses,
            "provisions_by_category": provisions_by_category,
            "compliance_analysis": compliance_analysis,
            "risk_assessment": risk_assessment
        }