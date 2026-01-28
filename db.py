"""
Database configuration and session management.

V1: SQLite for simplicity
Future: PostgreSQL-compatible (no SQLite-specific features)

Provides:
- Database engine setup
- Session management (FastAPI dependency)
- Database initialization (create tables)
- Helper functions for common queries
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator
import os
from models import Base, Hazard, Authority, AuthorityVerification, AuditLog, HazardStatus

# Database URL - use SQLite for V1
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./hazard_app.db")

# Create engine with appropriate settings
if DATABASE_URL.startswith("sqlite"):
    # SQLite specific
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        echo=os.getenv("SQL_ECHO", "false").lower() == "true"
    )
else:
    # PostgreSQL / other databases
    engine = create_engine(
        DATABASE_URL,
        echo=os.getenv("SQL_ECHO", "false").lower() == "true"
    )

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db():
    """
    Initialize database by creating all tables.
    
    SAFETY: Call once on startup. Safe to call multiple times
    (SQLAlchemy only creates missing tables).
    """
    Base.metadata.create_all(bind=engine)


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency for database session.
    
    Usage:
        @app.get("/hazards")
        def list_hazards(db: Session = Depends(get_db)):
            ...
    
    Automatically closes session after request.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================================================
# HELPER FUNCTIONS FOR COMMON QUERIES
# ============================================================================

def get_verified_hazards(db: Session, limit: int = 100) -> list[Hazard]:
    """
    Get all VERIFIED hazards for driver consumption.
    
    SAFETY CRITICAL: Only return VERIFIED hazards to drivers.
    
    Args:
        db: Database session
        limit: Max number of hazards (for pagination)
    
    Returns:
        List of VERIFIED hazards, ordered newest first
    """
    return db.query(Hazard).filter(
        Hazard.status == HazardStatus.VERIFIED
    ).order_by(Hazard.created_at.desc()).limit(limit).all()


def get_hazard_by_id(db: Session, hazard_id: str) -> Hazard:
    """Get hazard by ID (with full details, authority-only)."""
    return db.query(Hazard).filter(Hazard.id == hazard_id).first()


def get_pending_hazards(db: Session) -> list[Hazard]:
    """Get all hazards awaiting authority verification."""
    return db.query(Hazard).filter(
        Hazard.status == HazardStatus.PENDING_AUTHORITY
    ).order_by(Hazard.created_at.asc()).all()


def get_authority_by_id(db: Session, authority_id: str) -> Authority:
    """Get authority by ID."""
    return db.query(Authority).filter(Authority.id == authority_id).first()


def get_authority_by_email(db: Session, email: str) -> Authority:
    """Get authority by email."""
    return db.query(Authority).filter(Authority.email == email).first()


def get_verification_by_token(db: Session, token: str) -> AuthorityVerification:
    """Get verification record by token (for email link validation)."""
    return db.query(AuthorityVerification).filter(
        AuthorityVerification.token == token
    ).first()


def get_verification_by_hazard_id(db: Session, hazard_id: str) -> AuthorityVerification:
    """Get verification record for a hazard."""
    return db.query(AuthorityVerification).filter(
        AuthorityVerification.hazard_id == hazard_id
    ).first()

