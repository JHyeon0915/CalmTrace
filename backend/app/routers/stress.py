# app/routers/stress.py

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from datetime import datetime, timezone, timedelta

from app.auth import get_current_user
from app.database import get_database
from app.schemas.stress import (
    StressPredictionRequest,
    StressPredictionResponse,
    ExplainabilityResponse,
    StressHistoryResponse,
    StressHistoryEntry,
    ModelStatusResponse,
    DataSourceStatus,
    FeatureContribution,
)
from app.services.stress_prediction_service import get_prediction_service, StressPredictionService

router = APIRouter()


def get_stress_label(level: int) -> str:
    """Convert stress level to human-readable label."""
    if level <= 40:
        return "Low Stress"
    elif level <= 70:
        return "Medium Stress"
    else:
        return "High Stress"


@router.get("/status", response_model=ModelStatusResponse)
async def get_model_status():
    """
    Get ML model status and availability.
    """
    service = get_prediction_service()
    
    available = []
    if service.fusion_model is not None:
        available.append("fusion")
    if service.eeg_model is not None:
        available.append("eeg_only")
    if service.ecg_model is not None:
        available.append("ecg_only")
    
    return ModelStatusResponse(
        models_loaded=service.is_loaded,
        available_models=available,
        fusion_model_accuracy=94.0,
        eeg_model_accuracy=50.0,
        ecg_model_accuracy=70.0,
    )


@router.post("/predict", response_model=StressPredictionResponse)
async def predict_stress(
    request: StressPredictionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Predict stress level from sensor data.
    
    Accepts:
    - EEG data from EMOTIV headset
    - Health data (HRV, RR, HR) from smartwatch
    - EMOTIV performance metrics (fallback)
    
    Returns stress level (0-100), classification, and confidence.
    """
    service = get_prediction_service()
    
    if not service.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="ML models not loaded. Please try again later."
        )
    
    # Extract data from request
    eeg_data = None
    if request.eeg_data:
        eeg_data = request.eeg_data.channels
    
    hrv_values = None
    rr_values = None
    hr_values = None
    if request.health_data:
        hrv_values = request.health_data.hrv_values
        rr_values = request.health_data.rr_values
        hr_values = request.health_data.hr_values
    
    emotiv_metrics = None
    if request.emotiv_metrics:
        emotiv_metrics = request.emotiv_metrics.model_dump()
    
    # Make prediction
    result = service.predict_stress(
        eeg_data=eeg_data,
        hrv_values=hrv_values,
        rr_values=rr_values,
        hr_values=hr_values,
        emotiv_metrics=emotiv_metrics,
    )
    
    if "error" in result and result.get("stress_level") is None:
        raise HTTPException(
            status_code=400,
            detail=result["error"]
        )
    
    # Store prediction in database
    db = get_database()
    await db.stress_predictions.insert_one({
        "user_id": current_user["uid"],
        "stress_level": result["stress_level"],
        "stress_class": result["stress_class"],
        "confidence": result["confidence"],
        "model_used": result["model_used"],
        "data_sources": result["data_sources"],
        "timestamp": datetime.now(timezone.utc),
    })
    
    return StressPredictionResponse(
        stress_level=result["stress_level"],
        stress_class=result["stress_class"],
        stress_label=get_stress_label(result["stress_level"]),
        confidence=result["confidence"],
        model_used=result["model_used"],
        data_sources=DataSourceStatus(**result["data_sources"]),
        timestamp=datetime.fromisoformat(result["timestamp"].replace("Z", "+00:00")),
    )


@router.post("/predict/explain", response_model=ExplainabilityResponse)
async def predict_with_explanation(
    request: StressPredictionRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Predict stress level with SHAP-style feature explanations.
    
    Returns prediction plus contribution percentages for each data source.
    """
    service = get_prediction_service()
    
    if not service.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="ML models not loaded. Please try again later."
        )
    
    # Extract data
    eeg_data = request.eeg_data.channels if request.eeg_data else None
    hrv_values = request.health_data.hrv_values if request.health_data else None
    rr_values = request.health_data.rr_values if request.health_data else None
    hr_values = request.health_data.hr_values if request.health_data else None
    emotiv_metrics = request.emotiv_metrics.model_dump() if request.emotiv_metrics else None
    
    # Make prediction
    result = service.predict_stress(
        eeg_data=eeg_data,
        hrv_values=hrv_values,
        rr_values=rr_values,
        hr_values=hr_values,
        emotiv_metrics=emotiv_metrics,
    )
    
    if "error" in result and result.get("stress_level") is None:
        raise HTTPException(status_code=400, detail=result["error"])
    
    # Get feature contributions
    contributions_result = service.get_feature_contributions(
        eeg_data=eeg_data,
        hrv_values=hrv_values,
        rr_values=rr_values,
        hr_values=hr_values,
    )
    
    return ExplainabilityResponse(
        stress_level=result["stress_level"],
        stress_label=get_stress_label(result["stress_level"]),
        confidence=result["confidence"],
        contributions=FeatureContribution(**contributions_result["contributions"]),
        descriptions=contributions_result["descriptions"],
        timestamp=datetime.now(timezone.utc),
    )


@router.get("/history", response_model=StressHistoryResponse)
async def get_stress_history(
    days: int = Query(default=7, ge=1, le=30, description="Number of days of history"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get stress prediction history for trend analysis.
    """
    db = get_database()
    
    start_date = datetime.now(timezone.utc) - timedelta(days=days)
    
    cursor = db.stress_predictions.find({
        "user_id": current_user["uid"],
        "timestamp": {"$gte": start_date}
    }).sort("timestamp", -1)
    
    entries = []
    total_stress = 0
    count = 0
    
    async for doc in cursor:
        entries.append(StressHistoryEntry(
            stress_level=doc["stress_level"],
            stress_label=get_stress_label(doc["stress_level"]),
            confidence=doc["confidence"],
            model_used=doc["model_used"],
            timestamp=doc["timestamp"],
        ))
        total_stress += doc["stress_level"]
        count += 1
    
    # Calculate average and trend
    avg_stress = total_stress / count if count > 0 else 50
    
    # Determine trend based on first vs last 3 entries
    trend = "stable"
    if len(entries) >= 6:
        recent_avg = sum(e.stress_level for e in entries[:3]) / 3
        older_avg = sum(e.stress_level for e in entries[-3:]) / 3
        
        if recent_avg < older_avg - 5:
            trend = "improving"
        elif recent_avg > older_avg + 5:
            trend = "worsening"
    
    return StressHistoryResponse(
        entries=entries,
        average_stress=round(avg_stress, 1),
        trend=trend,
        period_days=days,
    )


@router.get("/latest", response_model=StressPredictionResponse)
async def get_latest_prediction(
    current_user: dict = Depends(get_current_user),
):
    """
    Get the most recent stress prediction for the user.
    """
    db = get_database()
    
    doc = await db.stress_predictions.find_one(
        {"user_id": current_user["uid"]},
        sort=[("timestamp", -1)]
    )
    
    if not doc:
        raise HTTPException(
            status_code=404,
            detail="No stress predictions found. Please make a prediction first."
        )
    
    return StressPredictionResponse(
        stress_level=doc["stress_level"],
        stress_class=doc["stress_class"],
        stress_label=get_stress_label(doc["stress_level"]),
        confidence=doc["confidence"],
        model_used=doc["model_used"],
        data_sources=DataSourceStatus(**doc.get("data_sources", {})),
        timestamp=doc["timestamp"],
    )


@router.post("/mock-predict", response_model=StressPredictionResponse)
async def mock_predict_stress(
    stress_level: int = Query(default=35, ge=0, le=100),
    confidence: int = Query(default=92, ge=0, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a mock stress prediction for testing.
    Useful for frontend development without real sensor data.
    """
    stress_class = "stress" if stress_level > 50 else "normal"
    
    # Store in database
    db = get_database()
    await db.stress_predictions.insert_one({
        "user_id": current_user["uid"],
        "stress_level": stress_level,
        "stress_class": stress_class,
        "confidence": float(confidence),
        "model_used": "mock",
        "data_sources": {"eeg": False, "hrv": False, "rr": False, "hr": False},
        "timestamp": datetime.now(timezone.utc),
    })
    
    return StressPredictionResponse(
        stress_level=stress_level,
        stress_class=stress_class,
        stress_label=get_stress_label(stress_level),
        confidence=float(confidence),
        model_used="mock",
        data_sources=DataSourceStatus(),
        timestamp=datetime.now(timezone.utc),
    )