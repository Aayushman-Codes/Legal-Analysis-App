import os
from dotenv import load_dotenv

load_dotenv()

HF_API_URL = "https://api-inference.huggingface.co/models/"
HF_TOKEN = os.getenv("HF_TOKEN", "insertyourhuggingfacetokenhere")

LEGAL_MODELS = {
    "classification": "law-ai/InLegalBERT",
    "qa": "law-ai/InLegalBERT",
}

INDIAN_CLAUSE_CATEGORIES = [
    "confidentiality", "termination", "liability", "indemnification",
    "intellectual_property", "governing_law", "payment_terms", "warranties",
    "limitation_of_liability", "dispute_resolution", "jurisdiction", 
    "force_majeure", "non_compete", "severability", "assignment"
]