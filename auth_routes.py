"""
Authentication routes for authority portal.

SAFETY CRITICAL:
- JWT-based authentication
- Password hashing with bcrypt
- Token expiration
- Role-based access control
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from backend.db import get_db
from backend.auth import authenticate_authority, create_authority_token
from backend.schemas import AuthorityLoginRequest, AuthorityLoginResponse, AuthorityResponse

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/login", response_model=AuthorityLoginResponse)
def login_authority(
    request: AuthorityLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Authenticate authority and return JWT token.
    
    Args:
        request: Login credentials (email, password)
        db: Database session
    
    Returns:
        JWT token and authority details
    
    Raises:
        HTTPException: If authentication fails
    """
    
    authority = authenticate_authority(request.email, request.password, db)
    
    if not authority:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create JWT token
    access_token = create_authority_token(authority)
    
    # Extract values from ORM object (avoid Column type issues)
    authority_name = getattr(authority, 'name', None)
    authority_created_at = getattr(authority, 'created_at', datetime.utcnow())
    
    return AuthorityLoginResponse(
        access_token=access_token,
        token_type="bearer",
        authority=AuthorityResponse(
            id=str(authority.id),
            email=str(authority.email),
            jurisdiction=str(authority.jurisdiction),
            name=authority_name,
            created_at=authority_created_at
        )
    )