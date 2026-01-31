"""
FastAPI routes for DRIVER hazard reporting and retrieval.

SAFETY CRITICAL:
- POST /hazards/report: Create hazard report (minimal data)
- GET /hazards/verified: Return ONLY VERIFIED hazards
- NEVER expose unverified hazards to drivers

All responses use HazardResponse schema (no status, no internal details).
"""

from fastapi import APIRouter, Depends, BackgroundTasks, status
from sqlalchemy.orm import Session
from datetime import datetime

from backend.models import Hazard, HazardStatus
from backend.schemas import HazardReportRequest, HazardResponse
from backend.db import get_db

router = APIRouter(prefix="/hazards", tags=["driver"])


@router.post("/report", response_model=dict, status_code=status.HTTP_201_CREATED)
def report_hazard(
    report: HazardReportRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Driver reports a hazard.
    
    SAFETY RULES:
    1. Create hazard with status = PENDING_AUTHORITY (awaiting verification)
    2. Return minimal confirmation to driver
    3. Async: Send verification request to authorities
    
    Frontend should:
    - Only submit when driver taps "Report Hazard"
    - Not block on result (async operation)
    - Show confirmation: "Report sent to safety team"
    
    Args:
        report: Driver's hazard report (type, lat, long, observed_at)
        background_tasks: FastAPI background task runner
        db: Database session
    
    Returns:
        Confirmation with hazard ID (for reference only)
    """
    
    # Create hazard record with initial status
    hazard = Hazard(
        hazard_type=report.hazard_type,
        latitude=report.latitude,
        longitude=report.longitude,
        observed_at=report.observed_at,
        status=HazardStatus.PENDING_AUTHORITY
    )
    
    db.add(hazard)
    db.commit()
    db.refresh(hazard)
    
    # ASYNC: Send verification requests to authorities
    # This happens asynchronously so driver gets response immediately
    background_tasks.add_task(
        notify_authorities_of_hazard,
        hazard_id=str(hazard.id),
        hazard_type=str(hazard.hazard_type.value),
        latitude=report.latitude,
        longitude=report.longitude
    )
    
    # Return minimal confirmation (no internal details)
    return {
        "status": "received",
        "message": "Hazard report sent to safety team",
        "hazard_id": str(hazard.id),
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/verified", response_model=list[HazardResponse])
def get_verified_hazards_for_driver(
    db: Session = Depends(get_db),
    limit: int = 100
):
    """
    Get all VERIFIED hazards for driver display on map.
    
    SAFETY CRITICAL:
    - Only return hazards with status == VERIFIED
    - Do NOT expose internal status, verification details, or authority info
    - Drivers see only what's safe to display
    
    Response uses HazardResponse schema (minimal, safe fields only).
    
    Args:
        db: Database session
        limit: Max hazards to return (default 100)
    
    Returns:
        List of VERIFIED hazards with only: id, type, lat, long, created_at
    """
    hazards = db.query(Hazard).filter(
        Hazard.status == HazardStatus.VERIFIED
    ).order_by(Hazard.created_at.desc()).limit(limit).all()
    
    # Return ORM objects directly - Pydantic handles conversion
    return hazards


# ============================================================================
# BACKGROUND TASK: Notify authorities
# ============================================================================

def notify_authorities_of_hazard(
    hazard_id: str,
    hazard_type: str,
    latitude: float,
    longitude: float
) -> None:
    """
    ASYNC background task: Send verification requests to relevant authorities.
    
    This task:
    1. Finds relevant authorities by jurisdiction
    2. Sends verification email with token
    3. Updates hazard status via authority portal
    
    Note: This runs asynchronously after driver gets response.
    """
    # Placeholder for authority notification logic
    # Implementation in authority_service
    pass

