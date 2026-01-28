"""
FastAPI routes for GOVERNMENT AUTHORITY portal.

SAFETY CRITICAL:
- Only VERIFIED authorities can access these endpoints
- ALL actions are logged in AuditLog (accountability)
- Token-based authentication for email verification links
- Status transitions are controlled and audited

Endpoints:
- GET /authority/hazards: View hazards by status (PENDING_AUTHORITY, VERIFIED, RESOLVED)
- POST /authority/hazards/{id}/verify: Verify a hazard (mark as safe to display)
- POST /authority/hazards/{id}/reject: Reject a false report
- POST /authority/hazards/{id}/resolve: Mark hazard as resolved
- POST /authority/verify-token: Verify authority via email token
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
import uuid

from backend.models import (
    Hazard, 
    HazardStatus, 
    Authority, 
    AuthorityVerification,
    AuditLog
)
from backend.schemas import (
    AuthorityVerificationRequest,
    HazardDetailResponse,
    HazardWithAuditResponse
)
from backend.db import get_db
from backend.auth import get_current_authority

router = APIRouter(prefix="/authority", tags=["authority"])


# ============================================================================
# HAZARD MANAGEMENT ENDPOINTS
# ============================================================================

@router.get("/hazards", response_model=list[HazardDetailResponse])
def get_hazards_for_authority(
    status_filter: Optional[HazardStatus] = Query(None, description="Filter by status"),
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority),
    limit: int = 100
):
    """
    Get hazards for authority review.
    
    SAFETY RULES:
    - Only authorities can access this endpoint
    - Returns full hazard details (status, verification info, location)
    - Filter by status (PENDING_AUTHORITY, VERIFIED, RESOLVED)
    
    Args:
        status_filter: Optional status filter
        db: Database session
        authority: Current authenticated authority
        limit: Max hazards to return
    
    Returns:
        List of hazards with full details
    """
    
    query = db.query(Hazard)
    
    if status_filter is not None:
        query = query.filter(Hazard.status == status_filter.value)
    
    hazards = query.order_by(Hazard.created_at.desc()).limit(limit).all()
    
    # Return ORM objects directly - Pydantic handles conversion
    return hazards


@router.get("/hazards/{hazard_id}", response_model=HazardWithAuditResponse)
def get_hazard_detail_with_audit(
    hazard_id: str,
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority)
):
    """
    Get detailed hazard info with full audit history.
    
    SAFETY RULES:
    - Only authorities can access
    - Returns complete audit trail for accountability
    
    Args:
        hazard_id: UUID of hazard
        db: Database session
        authority: Current authenticated authority
    
    Returns:
        Hazard details with audit log
    """
    
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    
    if not hazard:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hazard {hazard_id} not found"
        )
    
    # Return ORM hazard directly - Pydantic will access hazard.audit_logs relationship
    return hazard


@router.post("/hazards/{hazard_id}/verify", response_model=HazardDetailResponse)
def verify_hazard(
    hazard_id: str,
    request: AuthorityVerificationRequest,
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority)
):
    """
    Verify a hazard as legitimate.
    
    SAFETY CRITICAL:
    - Changes status from PENDING_AUTHORITY → VERIFIED
    - VERIFIED hazards are displayed to drivers
    - Creates audit log entry
    - Only authorities can verify
    
    Args:
        hazard_id: UUID of hazard
        request: Verification request with notes
        db: Database session
        authority: Current authenticated authority
    
    Returns:
        Updated hazard details
    """
    
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    
    if hazard is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hazard {hazard_id} not found"
        )
    
    # Check current status - read the value from the ORM object
    current_status = str(hazard.status)
    if current_status != HazardStatus.PENDING_AUTHORITY.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hazard is in {current_status} status, cannot verify"
        )
    
    # Store old status for audit log
    old_status = current_status
    
    # Update hazard status using .value (database stores strings)
    hazard.status = HazardStatus.VERIFIED.value  # type: ignore
    hazard.verified_at = datetime.utcnow()
    
    # Create audit log
    audit_log = AuditLog(
        id=str(uuid.uuid4()),
        hazard_id=hazard.id,
        action="VERIFY",
        old_status=old_status,
        new_status=HazardStatus.VERIFIED.value,
        notes=request.notes or f"Verified by {authority.email}",
        timestamp=datetime.utcnow(),
        authority_id=authority.id
    )
    
    db.add(audit_log)
    db.commit()
    db.refresh(hazard)
    
    # Return ORM object directly - Pydantic handles conversion
    return hazard


@router.post("/hazards/{hazard_id}/reject", response_model=HazardDetailResponse)
def reject_hazard(
    hazard_id: str,
    request: AuthorityVerificationRequest,
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority)
):
    """
    Reject a hazard as false report.
    
    SAFETY CRITICAL:
    - Changes status from PENDING_AUTHORITY → RESOLVED
    - Rejected hazards are NOT displayed to drivers
    - Creates audit log entry with rejection reason
    - Only authorities can reject
    
    Args:
        hazard_id: UUID of hazard
        request: Rejection request with reason
        db: Database session
        authority: Current authenticated authority
    
    Returns:
        Updated hazard details
    """
    
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    
    if hazard is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hazard {hazard_id} not found"
        )
    
    # Check current status - read the value from the ORM object
    current_status = str(hazard.status)
    if current_status != HazardStatus.PENDING_AUTHORITY.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hazard is in {current_status} status, cannot reject"
        )
    
    # Store old status for audit log
    old_status = current_status
    
    # Update hazard status using .value (database stores strings)
    hazard.status = HazardStatus.RESOLVED.value  # type: ignore
    
    # Create audit log
    audit_log = AuditLog(
        id=str(uuid.uuid4()),
        hazard_id=hazard.id,
        action="REJECT",
        old_status=old_status,
        new_status=HazardStatus.RESOLVED.value,
        notes=request.notes or f"Rejected by {authority.email}",
        timestamp=datetime.utcnow(),
        authority_id=authority.id
    )
    
    db.add(audit_log)
    db.commit()
    db.refresh(hazard)
    
    # Return ORM object directly - Pydantic handles conversion
    return hazard


@router.post("/hazards/{hazard_id}/resolve", response_model=HazardDetailResponse)
def resolve_hazard(
    hazard_id: str,
    request: AuthorityVerificationRequest,
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority)
):
    """
    Mark a verified hazard as resolved.
    
    SAFETY CRITICAL:
    - Changes status from VERIFIED → RESOLVED
    - Resolved hazards are removed from driver map
    - Creates audit log entry
    - Only authorities can resolve
    
    Args:
        hazard_id: UUID of hazard
        request: Resolution request with notes
        db: Database session
        authority: Current authenticated authority
    
    Returns:
        Updated hazard details
    """
    
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    
    if hazard is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hazard {hazard_id} not found"
        )
    
    # Check current status - read the value from the ORM object
    current_status = str(hazard.status)
    if current_status != HazardStatus.VERIFIED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hazard is in {current_status} status, cannot resolve (must be VERIFIED)"
        )
    
    # Store old status for audit log
    old_status = current_status
    
    # Update hazard status using .value (database stores strings)
    hazard.status = HazardStatus.RESOLVED.value  # type: ignore
    
    # Create audit log
    audit_log = AuditLog(
        id=str(uuid.uuid4()),
        hazard_id=hazard.id,
        action="RESOLVE",
        old_status=old_status,
        new_status=HazardStatus.RESOLVED.value,
        notes=request.notes or f"Resolved by {authority.email}",
        timestamp=datetime.utcnow(),
        authority_id=authority.id
    )
    
    db.add(audit_log)
    db.commit()
    db.refresh(hazard)
    
    # Return ORM object directly - Pydantic handles conversion
    return hazard


# ============================================================================
# TOKEN VERIFICATION ENDPOINT
# ============================================================================

@router.post("/verify-token", response_model=dict)
def verify_authority_token(
    hazard_id: str,
    token: str,
    db: Session = Depends(get_db)
):
    """
    Verify authority via email token (one-time use).
    
    SAFETY CRITICAL:
    - Token is single-use only
    - Token must not be expired
    - Links authority to hazard verification session
    
    Flow:
    1. Authority clicks email link with token
    2. Frontend calls this endpoint
    3. Token is validated and marked as used
    4. Authority can now verify/reject the hazard
    
    Args:
        hazard_id: UUID of hazard
        token: Verification token from email
        db: Database session
    
    Returns:
        Success message with authority details
    """
    
    # Find verification record
    verification = db.query(AuthorityVerification).filter(
        AuthorityVerification.hazard_id == hazard_id,
        AuthorityVerification.token == token
    ).first()
    
    if verification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid verification token"
        )
    
    # Check if already used - read boolean value directly
    if verification.used is True:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token has already been used"
        )
    
    # Check if expired
    if datetime.utcnow() > verification.expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token has expired"
        )
    
    # Mark token as used
    verification.used = True
    verification.used_at = datetime.utcnow()
    
    db.commit()
    
    # Get authority details
    authority = db.query(Authority).filter(
        Authority.id == verification.authority_id
    ).first()
    
    if authority is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authority not found"
        )
    
    return {
        "status": "verified",
        "message": "Token verified successfully",
        "hazard_id": hazard_id,
        "authority": {
            "id": authority.id,
            "email": authority.email,
            "jurisdiction": authority.jurisdiction
        }
    }


# ============================================================================
# STATISTICS ENDPOINT
# ============================================================================

@router.get("/stats", response_model=dict)
def get_authority_stats(
    db: Session = Depends(get_db),
    authority: Authority = Depends(get_current_authority)
):
    """
    Get statistics for authority dashboard.
    
    Args:
        db: Database session
        authority: Current authenticated authority
    
    Returns:
        Statistics about hazards
    """
    
    pending = db.query(Hazard).filter(
        Hazard.status == HazardStatus.PENDING_AUTHORITY.value
    ).count()
    
    verified = db.query(Hazard).filter(
        Hazard.status == HazardStatus.VERIFIED.value
    ).count()
    
    resolved = db.query(Hazard).filter(
        Hazard.status == HazardStatus.RESOLVED.value
    ).count()
    
    return {
        "pending_authority": pending,
        "verified": verified,
        "resolved": resolved,
        "total": pending + verified + resolved
    }
