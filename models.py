"""
FIX AND ALIGN the Pydantic schemas with the corrected data models.

CRITICAL ALIGNMENT RULES:

1. HazardStatus MUST match models EXACTLY:
   PENDING_AUTHORITY → VERIFIED → RESOLVED

   ❌ Do NOT include REPORTED in schemas.

2. Driver input must be MINIMAL and SAFE:
   - hazard_type
   - latitude
   - longitude
   - OPTIONAL: observed_at (timestamp of observation)

   ❌ Drivers must NEVER set status, authority, verification flags, or audit data.

3. Driver responses MUST:
   - Include ONLY VERIFIED hazards
   - Omit internal status and verification details
   - Be safe to display directly on Google Maps

4. Authority schemas MAY expose:
   - Full lifecycle status
   - Verification details
   - Audit history

5. Actions must use Enums, NOT free-text strings.

SCHEMAS TO IMPLEMENT / FIX:

DRIVER SCHEMAS:
- HazardReportRequest
  - hazard_type (Enum)
  - latitude (validated -90 to 90)
  - longitude (validated -180 to 180)
  - observed_at (optional datetime; NOT used for lifecycle logic)

- HazardResponse
  - id
  - hazard_type
  - latitude
  - longitude
  - created_at

AUTHORITY SCHEMAS:
- AuthorityAction (Enum: VERIFY, REJECT, RESOLVE)

- AuthorityVerificationRequest
  - action (AuthorityAction enum)
  - reason (optional, required only for REJECT)

- HazardDetailResponse
  - id
  - hazard_type
  - latitude
  - longitude
  - status
  - created_at
  - updated_at
  - resolved_at
  - is_verified
  - verified_at

- AuditLogResponse
  - id
  - hazard_id
  - action
  - old_status
  - new_status
  - notes
  - timestamp
  - authority_id

IMPORTANT:
- Remove REPORTED from all enums.
- Replace string-based actions with Enums.
- Avoid presentation-only fields like "verification_status".
- Keep schemas role-specific and explicit.

Goal:
Produce schemas that strictly enforce safety, align perfectly with models,
and prevent frontend misuse by design.
"""


from enum import Enum
from datetime import datetime, timedelta
from sqlalchemy import Column, Integer, String, Float, DateTime, Enum as SQLEnum, ForeignKey, Boolean, Text, UniqueConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid

Base = declarative_base()


class HazardType(str, Enum):
    """Types of hazards drivers can report."""
    ACCIDENT = "ACCIDENT"
    POTHOLE = "POTHOLE"
    ROADBLOCK = "ROADBLOCK"


class HazardStatus(str, Enum):
    """
    Hazard lifecycle states.
    
    REPORTED: Initial state - hazard just reported by driver
    PENDING_AUTHORITY: Authority notified, awaiting verification
    VERIFIED: Authority verified - NOW VISIBLE TO DRIVERS
    RESOLVED: Authority marked as resolved/no longer a hazard
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


class AuthorityLevel(str, Enum):
    """Geographic jurisdiction levels for authorities."""
    LOCAL = "LOCAL"  # City/Town level
    STATE = "STATE"  # State level
    NATIONAL = "NATIONAL"  # Federal level


class Hazard(Base):
    """
    Core hazard record with strict lifecycle enforcement.
    
    SAFETY CRITICAL: Status field is the single source of truth for visibility.
    Only VERIFIED hazards should ever be returned to drivers.
    """
    __tablename__ = "hazards"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Minimal driver-reported data (as required)
    hazard_type = Column(SQLEnum(HazardType), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    
    # Optional: when driver observed the hazard (NOT used for lifecycle logic)
    observed_at = Column(DateTime, nullable=True)
    
    # Lifecycle state - CRITICAL FOR SAFETY
    status = Column(SQLEnum(HazardStatus), nullable=False, default=HazardStatus.REPORTED)
    
    # Audit timestamps
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    
    # Relationships
    audit_logs = relationship("AuditLog", back_populates="hazard", cascade="all, delete-orphan")
    verification = relationship("AuthorityVerification", back_populates="hazard", uselist=False, cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Hazard id={self.id} type={self.hazard_type} status={self.status}>"


class Authority(Base):
    """
    Government agencies authorized to verify hazards.
    
    SECURITY: Authorities authenticate via JWT after verifying email.
    """
    __tablename__ = "authorities"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Organization info
    name = Column(String(255), nullable=False, unique=True)
    email = Column(String(255), nullable=False, unique=True)
    phone = Column(String(20), nullable=True)
    
    # Jurisdiction
    level = Column(SQLEnum(AuthorityLevel), nullable=False)
    jurisdiction = Column(String(255), nullable=False)  # e.g., "New Hampshire", "Manchester, NH", "I-93 North"
    
    # Access control
    is_active = Column(Boolean, default=True, nullable=False)
    jwt_secret = Column(String(255), nullable=False)  # Per-authority secret for JWT signing
    
    # Audit
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    verifications = relationship("AuthorityVerification", back_populates="authority", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="authority")
    
    def __repr__(self):
        return f"<Authority id={self.id} name={self.name} level={self.level}>"


class AuthorityVerification(Base):
    """
    Tracks verification tokens and approval flow.
    
    SECURITY: Email-based verification + secure token expiry.
    Authorities must click email link OR log into portal to verify hazards.
    """
    __tablename__ = "authority_verifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Foreign keys
    hazard_id = Column(String(36), ForeignKey("hazards.id"), nullable=False, unique=True)
    authority_id = Column(String(36), ForeignKey("authorities.id"), nullable=False)
    
    # Verification token (for email link)
    token = Column(String(255), nullable=False, unique=True)
    token_expires_at = Column(DateTime, nullable=False)  # Typically 48 hours
    
    # Verification result
    is_verified = Column(Boolean, default=False, nullable=False)
    verified_at = Column(DateTime, nullable=True)
    rejection_reason = Column(Text, nullable=True)  # If authority rejects
    
    # Timestamps
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    hazard = relationship("Hazard", back_populates="verification")
    authority = relationship("Authority", back_populates="verifications")
    
    def is_token_expired(self) -> bool:
        """Check if verification token is past expiry."""
        return bool(datetime.utcnow() > self.token_expires_at)
    
    def __repr__(self):
        return f"<AuthorityVerification hazard={self.hazard_id} authority={self.authority_id} verified={self.is_verified}>"


class AuditLog(Base):
    """
    Complete audit trail of all hazard state changes.
    
    SAFETY CRITICAL: Every state change must be logged with:
    - What changed (action)
    - Who made the change (authority or system)
    - When (timestamp)
    - Why (reason/notes)
    
    Used for accountability and debugging safety issues.
    """
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Foreign keys
    hazard_id = Column(String(36), ForeignKey("hazards.id"), nullable=False)
    authority_id = Column(String(36), ForeignKey("authorities.id"), nullable=True)  # NULL if system action
    
    # What happened
    action = Column(String(50), nullable=False)  # REPORT, ASSIGN_AUTHORITY, VERIFY, REJECT, RESOLVE
    old_status = Column(SQLEnum(HazardStatus), nullable=True)
    new_status = Column(SQLEnum(HazardStatus), nullable=True)
    
    # Context
    notes = Column(Text, nullable=True)
    timestamp = Column(DateTime, nullable=False, default=datetime.utcnow)
    
    # Relationships
    hazard = relationship("Hazard", back_populates="audit_logs")
    authority = relationship("Authority", back_populates="audit_logs")
    
    def __repr__(self):
        return f"<AuditLog hazard={self.hazard_id} action={self.action} at={self.timestamp}>"


class User(Base):
    """
    Users of the system (drivers, authorities, admins).
    
    Note: V1 keeps this simple. Drivers use anonymous ID from app.
    Authorities authenticate via email-based flow.
    """
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # User identification
    email = Column(String(255), unique=True, nullable=True)  # NULL for anonymous drivers
    user_type = Column(String(50), nullable=False)  # "driver", "authority", "admin"
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Audit
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<User id={self.id} type={self.user_type} email={self.email}>"
