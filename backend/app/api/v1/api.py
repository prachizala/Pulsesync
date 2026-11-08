from fastapi import APIRouter
from app.api.v1.endpoints import auth, health, incidents

api_router = APIRouter()

api_router.include_router(health.router, tags=["Health"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(incidents.router, prefix="/incidents", tags=["Incidents"])
