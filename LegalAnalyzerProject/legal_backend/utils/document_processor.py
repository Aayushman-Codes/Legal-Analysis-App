import PyPDF2
import docx
import io
import re
import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

class IndianDocumentProcessor:
    @staticmethod
    def extract_text_from_pdf(file_content: bytes) -> str:
        try:
            pdf_file = io.BytesIO(file_content)
            pdf_reader = PyPDF2.PdfReader(pdf_file)
            
            if pdf_reader.is_encrypted:
                try:
                    pdf_reader.decrypt('')
                except:
                    raise Exception("PDF is encrypted and cannot be read")
            
            text = ""
            for page in pdf_reader.pages:
                page_text = page.extract_text()
                if page_text.strip():
                    text += page_text + "\n"
            
            if not text.strip():
                raise Exception("No extractable text found in PDF")
                
            return text.strip()
        except Exception as e:
            logger.error(f"PDF extraction error: {str(e)}")
            raise Exception(f"Error reading PDF: {str(e)}")

    @staticmethod
    def extract_text_from_docx(file_content: bytes) -> str:
        try:
            doc_file = io.BytesIO(file_content)
            doc = docx.Document(doc_file)
            text = ""
            
            for paragraph in doc.paragraphs:
                if paragraph.text.strip():
                    text += paragraph.text + "\n"
            
            return text.strip()
        except Exception as e:
            logger.error(f"DOCX extraction error: {str(e)}")
            raise Exception(f"Error reading DOCX: {str(e)}")

    @staticmethod
    def extract_text_from_txt(file_content: bytes) -> str:
        try:
            return file_content.decode('utf-8').strip()
        except UnicodeDecodeError:
            try:
                return file_content.decode('latin-1').strip()
            except UnicodeDecodeError:
                raise Exception("Unable to decode text file")

    @staticmethod
    def segment_into_clauses(text: str) -> List[Dict[str, Any]]:
        clauses = []
        sentences = re.split(r'(?<=[.!?])\s+', text)
        
        current_clause = ""
        for sentence in sentences:
            if len(current_clause + sentence) < 500:
                current_clause += " " + sentence if current_clause else sentence
            else:
                if current_clause:
                    clauses.append({
                        "text": current_clause.strip(),
                        "word_count": len(current_clause.split()),
                        "id": f"clause_{len(clauses) + 1}"
                    })
                current_clause = sentence
        
        if current_clause:
            clauses.append({
                "text": current_clause.strip(),
                "word_count": len(current_clause.split()),
                "id": f"clause_{len(clauses) + 1}"
            })
        
        return [clause for clause in clauses if clause['word_count'] > 5]

    @staticmethod
    def preprocess_text(text: str) -> str:
        text = re.sub(r'\s+', ' ', text)
        return text.strip()