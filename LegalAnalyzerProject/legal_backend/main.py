from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any
import uvicorn
import logging
from datetime import datetime

from models.indian_legal_analyzer import IndianLegalAnalyzer
from utils.document_processor import IndianDocumentProcessor

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Indian Legal Contract Analyzer API",
    description="AI-powered legal document analysis using InLegalBERT",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

document_processor = IndianDocumentProcessor()
legal_analyzer = IndianLegalAnalyzer()

class AnalysisRequest(BaseModel):
    text: str
    question: Optional[str] = None

class AnalysisResponse(BaseModel):
    status: str
    data: Dict[str, Any]
    metadata: Dict[str, Any]
    message: Optional[str] = None

@app.get("/")
async def root():
    return {"message": "Indian Legal Contract Analyzer API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "legal-analyzer"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_contract(file: UploadFile = File(...)):
    try:
        start_time = datetime.now()
        
        allowed_types = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain']
        if file.content_type not in allowed_types:
            raise HTTPException(status_code=400, detail="Unsupported file type")
        
        content = await file.read()
        if len(content) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
        
        if file.content_type == 'application/pdf':
            text = document_processor.extract_text_from_pdf(content)
        elif file.content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            text = document_processor.extract_text_from_docx(content)
        else:
            text = document_processor.extract_text_from_txt(content)
        
        if not text or len(text.strip()) < 50:
            raise HTTPException(status_code=400, detail="Document too short for analysis")
        
        text = document_processor.preprocess_text(text)
        clauses = document_processor.segment_into_clauses(text)
        
        analysis_result = legal_analyzer.comprehensive_analysis(text, clauses)
        
        processing_time = (datetime.now() - start_time).total_seconds()
        metadata = {
            "file_type": file.content_type,
            "text_length": len(text),
            "clauses_identified": len(clauses),
            "processing_time_seconds": round(processing_time, 2),
            "timestamp": datetime.now().isoformat()
        }
        
        response_data = {
            "summary": {
                "message": f"Analysis completed. Found {len(clauses)} clauses with {len(analysis_result['provisions_by_category'])} categories.",
                "total_clauses": len(clauses),
                "categories_identified": len(analysis_result['provisions_by_category']),
                "risk_level": analysis_result["risk_assessment"]["risk_level"]
            },
            "clauses": analysis_result["provisions_by_category"],
            "compliance": analysis_result["compliance_analysis"],
            "risk": analysis_result["risk_assessment"],
            "document_stats": {
                "total_words": len(text.split()),
                "total_clauses": len(clauses),
                "risk_level": analysis_result["risk_assessment"]["risk_level"]
            }
        }
        
        return AnalysisResponse(
            status="success",
            data=response_data,
            metadata=metadata,
            message="Document analyzed successfully"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.post("/analyze-text", response_model=AnalysisResponse)
async def analyze_text(request: AnalysisRequest):
    try:
        if not request.text.strip() or len(request.text.strip()) < 50:
            raise HTTPException(status_code=400, detail="Text too short for analysis")
        
        start_time = datetime.now()
        
        text = document_processor.preprocess_text(request.text)
        clauses = document_processor.segment_into_clauses(text)
        analysis_result = legal_analyzer.comprehensive_analysis(text, clauses)
        
        processing_time = (datetime.now() - start_time).total_seconds()
        metadata = {
            "text_length": len(text),
            "clauses_identified": len(clauses),
            "processing_time_seconds": round(processing_time, 2),
            "timestamp": datetime.now().isoformat()
        }
        
        response_data = {
            "summary": {
                "message": f"Analysis completed. Found {len(clauses)} clauses.",
                "total_clauses": len(clauses),
                "categories_identified": len(analysis_result['provisions_by_category']),
                "risk_level": analysis_result["risk_assessment"]["risk_level"]
            },
            "clauses": analysis_result["provisions_by_category"],
            "compliance": analysis_result["compliance_analysis"],
            "risk": analysis_result["risk_assessment"],
            "document_stats": {
                "total_words": len(text.split()),
                "total_clauses": len(clauses),
                "risk_level": analysis_result["risk_assessment"]["risk_level"]
            }
        }
        
        return AnalysisResponse(
            status="success",
            data=response_data,
            metadata=metadata,
            message="Text analyzed successfully"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.post("/ask", response_model=AnalysisResponse)
async def ask_question(request: AnalysisRequest):
    try:
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Document text is required")
        
        if not request.question or not request.question.strip():
            raise HTTPException(status_code=400, detail="Question is required")
        
        answer_result = legal_analyzer.answer_legal_question(request.question, request.text)
        
        metadata = {
            "question_answered": True,
            "answer_confidence": answer_result["confidence"],
            "timestamp": datetime.now().isoformat()
        }
        
        return AnalysisResponse(
            status="success",
            data={
                "question": request.question,
                "answer": answer_result["answer"],
                "confidence": answer_result["confidence"]
            },
            metadata=metadata,
            message="Question answered successfully"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Question answering failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)