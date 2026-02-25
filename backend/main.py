from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.database import init_db, close_db
from app.routers import auth, streak, goals, notifications, stress


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    await init_db()
    yield
    # Shutdown
    await close_db()


app = FastAPI(
    title="Stress Management API",
    description="Backend API for stress management therapy app",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/v1/auth", tags=["Authentication"])
app.include_router(streak.router, prefix="/v1/streak", tags=["Streak"])
app.include_router(goals.router, prefix="/v1/goals", tags=["Goals"])
app.include_router(notifications.router, prefix="/v1/notifications", tags=["Notifications"])
app.include_router(stress.router, prefix="/v1/stress", tags=["Stress Prediction"])


@app.get("/")
async def root():
    return {"message": "Stress Management API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000)