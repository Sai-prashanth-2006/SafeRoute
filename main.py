"""
SafeRoute Backend - Main FastAPI Application

SAFETY CRITICAL SYSTEM:
- Driver hazard reporting (minimal input validation)
- Authority verification portal (JWT-protected)
- VERIFIED hazards only visible to drivers
- Full audit logging for accountability

Architecture:
- Driver endpoints: Public, minimal data exposure
- Authority endpoints: JWT-protected, full context
- Database: PostgreSQL with SQLAlchemy ORM
- Authentication: JWT tokens for authorities only
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from backend.db import engine, Base
from backend.hazards_routes import router as hazards_router
from backend.authority_routes import router as authority_router
from backend.auth_routes import router as auth_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown events.
    
    On startup:
    - Create all database tables
    - Initialize database connection
    
    On shutdown:
    - Close database connections
    """
    # Startup: Create tables
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created")
    
    yield
    
    # Shutdown: Cleanup
    print("🔒 Shutting down SafeRoute backend")


# Initialize FastAPI app
app = FastAPI(
    title="SafeRoute API",
    description="Safety-critical hazard reporting and verification system",
    version="1.0.0",
    lifespan=lifespan
)

# CORS Configuration
# WARNING: In production, restrict origins to your frontend domain only
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Change to ["https://saferoute.example.com"] in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(hazards_router)      # Driver endpoints: /hazards/*
app.include_router(authority_router)    # Authority endpoints: /authority/*
app.include_router(auth_router)         # Auth endpoints: /auth/*


@app.get("/")
def read_root():
    """
    Root endpoint - health check.
    """
    return {
        "status": "operational",
        "service": "SafeRoute API",
        "version": "1.0.0",
        "endpoints": {
            "driver": "/hazards",
            "authority": "/authority",
            "auth": "/auth",
            "docs": "/docs"
        }
    }


@app.get("/health")
def health_check():
    """
    Health check endpoint for monitoring.
    """
    return {
        "status": "healthy",
        "database": "connected"
    }


if __name__ == "__main__":
    import uvicorn
    
    # Run development server
    uvicorn.run(
        "backend.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,  # Auto-reload on code changes (dev only)
        log_level="info"
    )