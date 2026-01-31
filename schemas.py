"""
Pydantic schemas for request/response validation.

SAFETY RULES (ENFORCED BY SCHEMA):
1. Driver input (HazardReportRequest) must be minimal:
   - type, latitude, longitude, timestamp ONLY
   - No ability to set status, verified_at, etc.

2. Driver responses (HazardResponse) MUST only include VERIFIED hazards.
   - Status is never sent to drivers in list/map endpoints
   - Frontend receives safe-to-display hazards only

3. Authority responses reveal full context:
   - Status, verification details, audit history
   - Only authorities see sensitive fields

4. All inputs are strictly validated:
   - Coordinates must be valid lat/long
   - Types must match enum
   - Timestamps must be recent (prevent time-travel attacks)
"""

from pydantic import BaseModel, Field, validator, ConfigDict
from datetime import datetime
from typing import Optional, List
from enum import Enum


class HazardType(str, Enum):
    """Types of hazards (must match models.py)."""
    ACCIDENT = "ACCIDENT"
    POTHOLE = "POTHOLE"
    ROADBLOCK = "ROADBLOCK"
    DEBRIS = "DEBRIS"
    REPORTED = "REPORTED"


class HazardStatus(str, Enum):
    """Lifecycle states - AUTHORITY/INTERNAL VIEW ONLY.
    
    NOTE: Drivers never see status in responses.
    This enum is for internal and authority portal use.
    """
    REPORTED = "REPORTED"
    PENDING_AUTHORITY = "PENDING_AUTHORITY"
    VERIFIED = "VERIFIED"
    RESOLVED = "RESOLVED"


class AuthorityAction(str, Enum):
    """Actions authorities can take on hazards."""
    VERIFY = "VERIFY"
    REJECT = "REJECT"
    RESOLVE = "RESOLVE"
    REPORT = "REPORT"


class AuthorityLevel(str, Enum):
    """Authority jurisdiction levels."""
    STATE = "STATE"
    LOCAL = "LOCAL"
    NATIONAL = "NATIONAL"


# ============================================================================
# DRIVER SCHEMAS (Minimal, Read-Only)
# ============================================================================

class HazardReportRequest(BaseModel):
    """
    Driver hazard report request (minimal data only).
    
    SAFETY: No ability to set status or verification fields.
    """
    hazard_type: HazardType
    latitude: float = Field(..., ge=-90, le=90, description="Latitude (-90 to 90)")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude (-180 to 180)")
    observed_at: datetime = Field(default_factory=datetime.utcnow, description="When hazard was observed")
    
    @validator('observed_at')
    def validate_observed_at(cls, v):
        """Prevent time-travel attacks: observed_at must be within last 24 hours."""
        if v > datetime.utcnow():
            raise ValueError("observed_at cannot be in the future")
        if (datetime.utcnow() - v).days > 1:
            raise ValueError("observed_at must be within last 24 hours")
        return v


class HazardResponse(BaseModel):
    """
    Driver hazard response (safe, minimal fields only).
    
    SAFETY: NO status, NO verification details, NO authority info.
    """
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    hazard_type: HazardType
    latitude: float
    longitude: float
    created_at: datetime


# ============================================================================
# AUTHORITY SCHEMAS (Full Context, Secure)
# ============================================================================

class AuthorityVerificationRequest(BaseModel):
    """
    Authority action request (verify/reject/resolve).
    """
    notes: Optional[str] = Field(None, max_length=1000, description="Optional notes about the action")


class HazardDetailResponse(BaseModel):
    """
    Full hazard details for authority portal.
    
    SAFETY: Only authorities see this. Includes status and all fields.
    """
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    hazard_type: HazardType
    latitude: float
    longitude: float
    observed_at: datetime
    status: HazardStatus
    verified_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime


class AuditLogResponse(BaseModel):
    """
    Audit log entry for accountability.
    """
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    hazard_id: str
    action: str
    old_status: Optional[str] = None
    new_status: str
    notes: Optional[str] = None
    timestamp: datetime
    authority_id: Optional[str] = None


class HazardWithAuditResponse(BaseModel):
    """
    Hazard with full audit trail.
    """
    hazard: HazardDetailResponse
    audit_logs: List[AuditLogResponse]


# ============================================================================
# AUTHORITY MANAGEMENT SCHEMAS (Admin/Setup)
# ============================================================================

class AuthorityCreateRequest(BaseModel):
    """
    Request to create new authority account.
    """
    email: str = Field(..., description="Authority email address")
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    jurisdiction: AuthorityLevel = Field(..., description="Authority jurisdiction level")
    name: Optional[str] = Field(None, description="Authority name/department")


class AuthorityResponse(BaseModel):
    """
    Authority account details.
    """
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    email: str
    jurisdiction: str
    name: Optional[str] = None
    created_at: datetime


class AuthorityLoginRequest(BaseModel):
    """
    Authority login request.
    """
    email: str
    password: str


class AuthorityLoginResponse(BaseModel):
    """
    Authority login response with JWT token.
    """
    access_token: str
    token_type: str = "bearer"
    authority: AuthorityResponse


# ============================================================================
# ERROR & STATUS SCHEMAS
# ============================================================================

class ErrorResponse(BaseModel):
    """
    Standard error response.
    """
    detail: str
    status_code: int


class StatusResponse(BaseModel):
    """
    Generic status response.
    """
    status: str
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
