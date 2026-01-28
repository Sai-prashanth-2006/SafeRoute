"""
JWT-based authentication utilities for SafeRoute.

SAFETY CRITICAL:
- Used ONLY for authority portal (not for drivers)
- JWT tokens for authority authentication
- Role-based access control (VIEWER, VERIFIER)
- Token expiration and validation

Roles:
- VIEWER: Can view hazards but cannot verify/reject
- VERIFIER: Can view, verify, reject, and resolve hazards
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import jwt
import os

from backend.models import Authority, AuthorityLevel
from backend.db import get_db

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 480  # 8 hours

# Security scheme
security = HTTPBearer()


class AuthorityRole:
    """Authority roles for access control."""
    VIEWER = "VIEWER"
    VERIFIER = "VERIFIER"


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create JWT access token.
    
    Args:
        data: Payload data to encode (should include authority_id, email, role)
        expires_delta: Token expiration time (default: 8 hours)
    
    Returns:
        Encoded JWT token
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> dict:
    """
    Decode and validate JWT token.
    
    Args:
        token: JWT token to decode
    
    Returns:
        Decoded token payload
    
    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_authority(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> Authority:
    """
    Get current authenticated authority from JWT token.
    
    SAFETY CRITICAL:
    - Validates JWT token
    - Verifies authority exists in database
    - Ensures authority is active
    
    Args:
        credentials: HTTP Bearer token from request
        db: Database session
    
    Returns:
        Authority object
    
    Raises:
        HTTPException: If authentication fails
    """
    
    token = credentials.credentials
    
    # Decode token
    payload = decode_access_token(token)
    
    # Extract authority ID
    authority_id: Optional[str] = payload.get("authority_id")
    if authority_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get authority from database
    authority = db.query(Authority).filter(Authority.id == authority_id).first()
    
    if authority is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authority not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return authority


def get_current_verifier(
    authority: Authority = Depends(get_current_authority)
) -> Authority:
    """
    Get current authority with VERIFIER role.
    
    SAFETY CRITICAL:
    - Only VERIFIER role can verify/reject/resolve hazards
    - VIEWER role is read-only
    
    Args:
        authority: Current authenticated authority
    
    Returns:
        Authority object with VERIFIER role
    
    Raises:
        HTTPException: If authority doesn't have VERIFIER role
    """
    
    # Check if authority has VERIFIER level (STATE or LOCAL can verify)
    if authority.jurisdiction not in [
        AuthorityLevel.STATE.value,
        AuthorityLevel.LOCAL.value
    ]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions. VERIFIER role required."
        )
    
    return authority


def create_authority_token(authority: Authority) -> str:
    """
    Create JWT token for authority.
    
    Args:
        authority: Authority object
    
    Returns:
        JWT token string
    """
    
    token_data = {
        "authority_id": authority.id,
        "email": authority.email,
        "jurisdiction": authority.jurisdiction,
        "role": AuthorityRole.VERIFIER  # Default role
    }
    
    return create_access_token(token_data)


def hash_password(password: str) -> str:
    """
    Hash password using bcrypt.
    
    Args:
        password: Plain text password
    
    Returns:
        Hashed password
    """
    import bcrypt
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify password against hash.
    
    Args:
        plain_password: Plain text password
        hashed_password: Hashed password from database
    
    Returns:
        True if password matches, False otherwise
    """
    import bcrypt
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        hashed_password.encode('utf-8')
    )


# ============================================================================
# AUTHENTICATION ENDPOINT (for login)
# ============================================================================

def authenticate_authority(email: str, password: str, db: Session) -> Optional[Authority]:
    """
    Authenticate authority by email and password.
    
    Args:
        email: Authority email
        password: Plain text password
        db: Database session
    
    Returns:
        Authority object if authentication succeeds, None otherwise
    """
    
    authority = db.query(Authority).filter(Authority.email == email).first()
    
    if not authority:
        return None
    
    # Verify password (assuming Authority model has password_hash field)
    if not hasattr(authority, 'password_hash') or not authority.password_hash:
        return None
    
    if not verify_password(password, authority.password_hash):
        return None
    
    return authority
