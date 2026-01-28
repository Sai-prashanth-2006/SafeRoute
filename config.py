"""
Configuration management for SafeRoute backend.

Loads environment variables and provides typed configuration objects.
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    """
    
    # Database
    database_url: str = "postgresql://postgres:postgres@localhost:5432/saferoute"
    
    # JWT Authentication
    jwt_secret_key: str = "dev-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 480
    
    # Email (for authority notifications)
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: Optional[str] = None
    smtp_password: Optional[str] = None
    smtp_from: str = "noreply@saferoute.com"
    
    # Frontend
    frontend_url: str = "http://localhost:3000"
    
    # Environment
    environment: str = "development"
    debug: bool = True
    
    # Authority verification
    verification_token_expiry_hours: int = 48
    
    class Config:
        env_file = ".env"
        case_sensitive = False


# Global settings instance
settings = Settings()