# app/schemas/stress.py

from pydantic import BaseModel, Field
from typing import Optional, Dict, List
from datetime import datetime


class EEGData(BaseModel):
    """Raw EEG data from EMOTIV headset."""
    channels: Dict[str, List[float]] = Field(
        ...,
        description="EEG channel data. Keys are channel names (AF3, F7, etc.), values are signal arrays.",
        example={
            "AF3": [1.2, 1.3, 1.4, 1.5],
            "F7": [0.8, 0.9, 1.0, 1.1],
        }
    )
    sampling_rate: int = Field(
        default=128,
        description="Sampling rate in Hz (EMOTIV default: 128)"
    )


class EmotivMetrics(BaseModel):
    """Performance metrics from EMOTIV headset."""
    engagement: Optional[float] = Field(None, ge=0, le=1)
    excitement: Optional[float] = Field(None, ge=0, le=1)
    stress: Optional[float] = Field(None, ge=0, le=1)
    relaxation: Optional[float] = Field(None, ge=0, le=1)
    interest: Optional[float] = Field(None, ge=0, le=1)
    focus: Optional[float] = Field(None, ge=0, le=1)


class HealthData(BaseModel):
    """Health data from smartwatch (Garmin via HealthKit/Health Connect)."""
    hrv_values: Optional[List[float]] = Field(
        None,
        description="Heart Rate Variability (SDNN) values in milliseconds"
    )
    rr_values: Optional[List[float]] = Field(
        None,
        description="Respiratory rate values in breaths per minute"
    )
    hr_values: Optional[List[float]] = Field(
        None,
        description="Heart rate values in BPM"
    )


class StressPredictionRequest(BaseModel):
    """Request body for stress prediction."""
    eeg_data: Optional[EEGData] = Field(
        None,
        description="Raw EEG data from EMOTIV headset"
    )
    health_data: Optional[HealthData] = Field(
        None,
        description="Health data from smartwatch"
    )
    emotiv_metrics: Optional[EmotivMetrics] = Field(
        None,
        description="Direct performance metrics from EMOTIV (fallback)"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "health_data": {
                    "hrv_values": [45.2, 48.1, 42.3, 50.5, 47.8],
                    "rr_values": [14.5, 15.2, 14.8, 15.0, 14.7],
                    "hr_values": [72, 75, 71, 73, 74]
                }
            }
        }


class DataSourceStatus(BaseModel):
    """Status of each data source used in prediction."""
    eeg: bool = False
    hrv: bool = False
    rr: bool = False
    hr: bool = False


class FeatureContribution(BaseModel):
    """Feature contribution for explainability."""
    hrv: Optional[float] = Field(None, description="HRV contribution percentage")
    rr: Optional[float] = Field(None, description="Respiratory rate contribution percentage")
    hr: Optional[float] = Field(None, description="Heart rate contribution percentage")
    eeg: Optional[float] = Field(None, description="EEG contribution percentage")


class StressPredictionResponse(BaseModel):
    """Response from stress prediction endpoint."""
    stress_level: int = Field(
        ...,
        ge=0,
        le=100,
        description="Stress level on 0-100 scale. 0-40: Low, 41-70: Medium, 71-100: High"
    )
    stress_class: str = Field(
        ...,
        description="Classification: 'normal' or 'stress'"
    )
    stress_label: str = Field(
        ...,
        description="Human-readable label: 'Low Stress', 'Medium Stress', or 'High Stress'"
    )
    confidence: float = Field(
        ...,
        ge=0,
        le=100,
        description="Prediction confidence percentage"
    )
    model_used: str = Field(
        ...,
        description="Model used for prediction: 'fusion', 'eeg_only', 'ecg_only', or 'emotiv_metrics'"
    )
    data_sources: DataSourceStatus
    timestamp: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "stress_level": 35,
                "stress_class": "normal",
                "stress_label": "Low Stress",
                "confidence": 92.5,
                "model_used": "fusion",
                "data_sources": {
                    "eeg": True,
                    "hrv": True,
                    "rr": True,
                    "hr": True
                },
                "timestamp": "2026-02-21T12:00:00Z"
            }
        }


class ExplainabilityResponse(BaseModel):
    """Response with feature contributions for explainability."""
    stress_level: int
    stress_label: str
    confidence: float
    contributions: FeatureContribution
    descriptions: Dict[str, str] = Field(
        ...,
        description="Human-readable descriptions of each factor's contribution"
    )
    timestamp: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "stress_level": 35,
                "stress_label": "Low Stress",
                "confidence": 92.5,
                "contributions": {
                    "hrv": 45.0,
                    "rr": 30.0,
                    "eeg": 25.0
                },
                "descriptions": {
                    "hrv": "Low variability detected, suggesting sympathetic nervous system activation.",
                    "rr": "Slightly elevated breathing rate observed.",
                    "eeg": "Beta wave dominance indicating active thinking or focus."
                },
                "timestamp": "2026-02-21T12:00:00Z"
            }
        }


class StressHistoryEntry(BaseModel):
    """Single entry in stress history."""
    stress_level: int
    stress_label: str
    confidence: float
    model_used: str
    timestamp: datetime


class StressHistoryResponse(BaseModel):
    """Response with stress history for trend analysis."""
    entries: List[StressHistoryEntry]
    average_stress: float
    trend: str = Field(
        ...,
        description="Trend: 'improving', 'stable', or 'worsening'"
    )
    period_days: int


class ModelStatusResponse(BaseModel):
    """Response with model status information."""
    models_loaded: bool
    available_models: List[str]
    fusion_model_accuracy: float = Field(default=94.0)
    eeg_model_accuracy: float = Field(default=50.0)
    ecg_model_accuracy: float = Field(default=70.0)