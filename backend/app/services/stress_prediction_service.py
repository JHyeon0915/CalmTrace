# app/services/stress_prediction_service.py

import os
import numpy as np
import joblib
from typing import Optional, Dict, List, Tuple
from datetime import datetime, timezone
from pathlib import Path

# TensorFlow import with GPU memory management
import tensorflow as tf

# Limit GPU memory growth to avoid OOM errors
gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(f"GPU config error: {e}")

from tensorflow.keras.models import load_model


class StressPredictionService:
    """
    Service for stress level prediction using DCNN-LSTM fusion model.
    
    Model expects:
    - EEG features: 513 dimensions
    - ECG features: 72 dimensions (derived from HRV/RR)
    - Total fusion features: 585 dimensions
    
    Output:
    - Binary classification: 0 = Normal, 1 = Stress
    - Confidence score (0-100%)
    """
    
    # Feature dimensions from the trained model
    EEG_FEATURE_DIM = 513
    ECG_FEATURE_DIM = 72
    FUSION_FEATURE_DIM = 585  # EEG + ECG
    
    # EEG channel names (14 channels for EMOTIV)
    EEG_CHANNELS = ['AF3', 'F7', 'F3', 'FC5', 'T7', 'P7', 'O1', 'O2', 
                    'P8', 'T8', 'FC6', 'F4', 'F8', 'AF4']
    
    # EEG frequency bands
    EEG_BANDS = {
        'delta': (0.5, 4),
        'theta': (4, 8),
        'alpha': (8, 13),
        'beta': (13, 30),
        'gamma': (30, 45)
    }
    

    def __init__(self, models_dir: str = None):
        # Try multiple possible paths
        if models_dir:
            self.models_dir = Path(models_dir)
        else:
            # Try relative to current working directory
            possible_paths = [
                Path("models"),
                Path("app/models"),
                Path("../models"),
                Path(__file__).parent.parent.parent / "models",  # Project root/models
            ]

            self.models_dir = Path("models")  # Default
            for path in possible_paths:
                if path.exists():
                    self.models_dir = path
                    break
                
        print(f"🧠 [StressPrediction] Models directory: {self.models_dir.absolute()}")

        self.fusion_model = None
        self.fusion_scaler = None
        self.eeg_model = None
        self.eeg_scaler = None
        self.ecg_model = None
        self.ecg_scaler = None
        self._loaded = False
        
    def load_models(self) -> bool:
        """Load all ML models and scalers."""
        try:
            print("🧠 [StressPrediction] Loading models...")
            
            # Load Fusion model (primary - best accuracy)
            fusion_model_path = self.models_dir / "fusion_model.keras"
            fusion_scaler_path = self.models_dir / "fusion_scaler.pkl"
            
            if fusion_model_path.exists() and fusion_scaler_path.exists():
                self.fusion_model = load_model(str(fusion_model_path))
                self.fusion_scaler = joblib.load(str(fusion_scaler_path))
                print(f"✓ Fusion model loaded: {fusion_model_path}")
            else:
                print(f"⚠️ Fusion model not found at {fusion_model_path}")
            
            # Load EEG model (fallback when no ECG data)
            eeg_model_path = self.models_dir / "eeg_model.keras"
            eeg_scaler_path = self.models_dir / "eeg_scaler.pkl"
            
            if eeg_model_path.exists() and eeg_scaler_path.exists():
                self.eeg_model = load_model(str(eeg_model_path))
                self.eeg_scaler = joblib.load(str(eeg_scaler_path))
                print(f"✓ EEG model loaded: {eeg_model_path}")
            
            # Load ECG model (fallback when no EEG data)
            ecg_model_path = self.models_dir / "ecg_model.keras"
            ecg_scaler_path = self.models_dir / "ecg_scaler.pkl"
            
            if ecg_model_path.exists() and ecg_scaler_path.exists():
                self.ecg_model = load_model(str(ecg_model_path))
                self.ecg_scaler = joblib.load(str(ecg_scaler_path))
                print(f"✓ ECG model loaded: {ecg_model_path}")
            
            self._loaded = self.fusion_model is not None
            print(f"🧠 [StressPrediction] Models loaded: {self._loaded}")
            return self._loaded
            
        except Exception as e:
            print(f"❌ [StressPrediction] Error loading models: {e}")
            return False
    
    @property
    def is_loaded(self) -> bool:
        return self._loaded
    
    # ==================== Feature Extraction ====================
    
    def extract_eeg_features(self, eeg_data: Dict[str, List[float]], 
                             sampling_rate: int = 128) -> np.ndarray:
        """
        Extract features from raw EEG data.
        
        Args:
            eeg_data: Dict with channel names as keys and raw signal values as lists
                      e.g., {'AF3': [1.2, 1.3, ...], 'F7': [...], ...}
            sampling_rate: EEG sampling rate in Hz (EMOTIV default: 128)
        
        Returns:
            Feature vector of shape (513,)
        """
        features = []
        
        for channel in self.EEG_CHANNELS:
            if channel not in eeg_data or len(eeg_data[channel]) == 0:
                # Pad with zeros if channel missing
                features.extend([0.0] * 37)  # 37 features per channel
                continue
            
            signal_data = np.array(eeg_data[channel])
            
            # Time-domain features
            features.append(np.mean(signal_data))
            features.append(np.std(signal_data))
            features.append(np.min(signal_data))
            features.append(np.max(signal_data))
            features.append(np.median(signal_data))
            
            # Statistical features
            from scipy.stats import skew, kurtosis
            features.append(skew(signal_data) if len(signal_data) > 2 else 0)
            features.append(kurtosis(signal_data) if len(signal_data) > 3 else 0)
            
            # Frequency-domain features (band powers)
            if len(signal_data) >= sampling_rate:
                from scipy import signal as sig
                freqs, psd = sig.welch(signal_data, fs=sampling_rate, nperseg=min(256, len(signal_data)))
                
                for band_name, (low, high) in self.EEG_BANDS.items():
                    idx = np.logical_and(freqs >= low, freqs <= high)
                    band_power = np.trapz(psd[idx], freqs[idx]) if np.any(idx) else 0
                    features.append(band_power)
            else:
                features.extend([0.0] * 5)  # 5 bands
            
            # Wavelet features
            try:
                import pywt
                coeffs = pywt.wavedec(signal_data, 'db4', level=4)
                for coeff in coeffs:
                    features.append(np.mean(np.abs(coeff)))
                    features.append(np.std(coeff))
                    features.append(np.sum(coeff ** 2))  # Energy
                # Pad if needed (5 levels * 3 features = 15)
                while len(features) % 37 != 0:
                    features.append(0.0)
            except:
                features.extend([0.0] * 15)
        
        # Ensure we have exactly 513 features
        features = np.array(features[:self.EEG_FEATURE_DIM])
        if len(features) < self.EEG_FEATURE_DIM:
            features = np.pad(features, (0, self.EEG_FEATURE_DIM - len(features)))
        
        return features
    
    def extract_ecg_features(self, hrv_values: List[float], 
                             rr_values: List[float],
                             hr_values: Optional[List[float]] = None) -> np.ndarray:
        """
        Extract features from HRV/RR/HR data (from smartwatch).
        
        Args:
            hrv_values: List of HRV (SDNN) values in milliseconds
            rr_values: List of respiratory rate values in breaths/min
            hr_values: Optional list of heart rate values in BPM
        
        Returns:
            Feature vector of shape (72,)
        """
        features = []
        
        # HRV features (24 features)
        if hrv_values and len(hrv_values) > 0:
            hrv = np.array(hrv_values)
            features.extend([
                np.mean(hrv), np.std(hrv), np.min(hrv), np.max(hrv),
                np.median(hrv), np.percentile(hrv, 25), np.percentile(hrv, 75),
                np.ptp(hrv),  # Peak-to-peak
            ])
            # Time-domain HRV metrics
            if len(hrv) > 1:
                diff_hrv = np.diff(hrv)
                features.extend([
                    np.sqrt(np.mean(diff_hrv ** 2)),  # RMSSD
                    np.mean(np.abs(diff_hrv)),  # Mean absolute difference
                    np.std(diff_hrv),
                    len(diff_hrv[np.abs(diff_hrv) > 50]) / len(diff_hrv) if len(diff_hrv) > 0 else 0,  # pNN50
                ])
            else:
                features.extend([0.0] * 4)
            features.extend([0.0] * 12)  # Padding to 24
        else:
            features.extend([0.0] * 24)
        
        # RR features (24 features)
        if rr_values and len(rr_values) > 0:
            rr = np.array(rr_values)
            features.extend([
                np.mean(rr), np.std(rr), np.min(rr), np.max(rr),
                np.median(rr), np.percentile(rr, 25), np.percentile(rr, 75),
                np.ptp(rr),
            ])
            if len(rr) > 1:
                diff_rr = np.diff(rr)
                features.extend([
                    np.sqrt(np.mean(diff_rr ** 2)),
                    np.mean(np.abs(diff_rr)),
                    np.std(diff_rr),
                    np.var(diff_rr),
                ])
            else:
                features.extend([0.0] * 4)
            features.extend([0.0] * 12)  # Padding to 24
        else:
            features.extend([0.0] * 24)
        
        # HR features (24 features)
        if hr_values and len(hr_values) > 0:
            hr = np.array(hr_values)
            features.extend([
                np.mean(hr), np.std(hr), np.min(hr), np.max(hr),
                np.median(hr), np.percentile(hr, 25), np.percentile(hr, 75),
                np.ptp(hr),
            ])
            if len(hr) > 1:
                diff_hr = np.diff(hr)
                features.extend([
                    np.sqrt(np.mean(diff_hr ** 2)),
                    np.mean(np.abs(diff_hr)),
                    np.std(diff_hr),
                    np.var(diff_hr),
                ])
            else:
                features.extend([0.0] * 4)
            features.extend([0.0] * 12)  # Padding to 24
        else:
            features.extend([0.0] * 24)
        
        # Ensure we have exactly 72 features
        features = np.array(features[:self.ECG_FEATURE_DIM])
        if len(features) < self.ECG_FEATURE_DIM:
            features = np.pad(features, (0, self.ECG_FEATURE_DIM - len(features)))
        
        return features
    
    # ==================== Prediction ====================
    
    def predict_stress(
        self,
        eeg_data: Optional[Dict[str, List[float]]] = None,
        hrv_values: Optional[List[float]] = None,
        rr_values: Optional[List[float]] = None,
        hr_values: Optional[List[float]] = None,
        emotiv_metrics: Optional[Dict[str, float]] = None,
    ) -> Dict:
        """
        Predict stress level from available sensor data.
        
        Uses fusion model when both EEG and ECG/HRV data available,
        otherwise falls back to single-modality model.
        
        Args:
            eeg_data: Raw EEG data from EMOTIV headset
            hrv_values: HRV values from smartwatch
            rr_values: Respiratory rate values from smartwatch
            hr_values: Heart rate values from smartwatch
            emotiv_metrics: Direct metrics from EMOTIV (stress, relaxation, etc.)
        
        Returns:
            Dict with prediction results
        """
        if not self._loaded:
            return {
                "error": "Models not loaded",
                "stress_level": None,
                "confidence": None,
            }
        
        has_eeg = eeg_data is not None and len(eeg_data) > 0
        has_ecg = (hrv_values and len(hrv_values) > 0) or (rr_values and len(rr_values) > 0)
        
        try:
            # Determine which model to use
            if has_eeg and has_ecg and self.fusion_model is not None:
                return self._predict_fusion(eeg_data, hrv_values, rr_values, hr_values)
            elif has_eeg and self.eeg_model is not None:
                return self._predict_eeg_only(eeg_data)
            elif has_ecg and self.ecg_model is not None:
                return self._predict_ecg_only(hrv_values, rr_values, hr_values)
            elif emotiv_metrics is not None:
                # Use EMOTIV's built-in stress metric if available
                return self._predict_from_emotiv_metrics(emotiv_metrics)
            else:
                return {
                    "error": "No valid sensor data provided",
                    "stress_level": None,
                    "confidence": None,
                }
                
        except Exception as e:
            print(f"❌ [StressPrediction] Prediction error: {e}")
            return {
                "error": str(e),
                "stress_level": None,
                "confidence": None,
            }
    
    def _predict_fusion(
        self,
        eeg_data: Dict[str, List[float]],
        hrv_values: List[float],
        rr_values: List[float],
        hr_values: Optional[List[float]],
    ) -> Dict:
        """Predict using fusion model (EEG + ECG)."""
        # Extract features
        eeg_features = self.extract_eeg_features(eeg_data)
        ecg_features = self.extract_ecg_features(hrv_values, rr_values, hr_values)
        
        # Concatenate features
        fusion_features = np.concatenate([eeg_features, ecg_features])
        
        # Scale features
        fusion_scaled = self.fusion_scaler.transform(fusion_features.reshape(1, -1))
        
        # Reshape for DCNN-LSTM: (batch, timesteps, features) -> (1, 585, 1)
        fusion_input = fusion_scaled.reshape(1, -1, 1)
        
        # Predict
        prediction = self.fusion_model.predict(fusion_input, verbose=0)
        predicted_class = int(np.argmax(prediction[0]))
        confidence = float(prediction[0][predicted_class]) * 100
        
        # Calculate stress level (0-100 scale)
        # Use probability of stress class as stress level
        stress_probability = float(prediction[0][1]) * 100
        
        return {
            "stress_level": int(stress_probability),
            "stress_class": "stress" if predicted_class == 1 else "normal",
            "confidence": round(confidence, 1),
            "model_used": "fusion",
            "prediction_raw": prediction[0].tolist(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data_sources": {
                "eeg": True,
                "hrv": True,
                "rr": True,
                "hr": hr_values is not None,
            }
        }
    
    def _predict_eeg_only(self, eeg_data: Dict[str, List[float]]) -> Dict:
        """Predict using EEG-only model."""
        eeg_features = self.extract_eeg_features(eeg_data)
        eeg_scaled = self.eeg_scaler.transform(eeg_features.reshape(1, -1))
        eeg_input = eeg_scaled.reshape(1, -1, 1)
        
        prediction = self.eeg_model.predict(eeg_input, verbose=0)
        predicted_class = int(np.argmax(prediction[0]))
        confidence = float(prediction[0][predicted_class]) * 100
        stress_probability = float(prediction[0][1]) * 100
        
        return {
            "stress_level": int(stress_probability),
            "stress_class": "stress" if predicted_class == 1 else "normal",
            "confidence": round(confidence, 1),
            "model_used": "eeg_only",
            "prediction_raw": prediction[0].tolist(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data_sources": {"eeg": True, "hrv": False, "rr": False, "hr": False}
        }
    
    def _predict_ecg_only(
        self,
        hrv_values: List[float],
        rr_values: List[float],
        hr_values: Optional[List[float]],
    ) -> Dict:
        """Predict using ECG-only model (HRV/RR/HR)."""
        ecg_features = self.extract_ecg_features(hrv_values, rr_values, hr_values)
        ecg_scaled = self.ecg_scaler.transform(ecg_features.reshape(1, -1))
        ecg_input = ecg_scaled.reshape(1, -1, 1)
        
        prediction = self.ecg_model.predict(ecg_input, verbose=0)
        predicted_class = int(np.argmax(prediction[0]))
        confidence = float(prediction[0][predicted_class]) * 100
        stress_probability = float(prediction[0][1]) * 100
        
        return {
            "stress_level": int(stress_probability),
            "stress_class": "stress" if predicted_class == 1 else "normal",
            "confidence": round(confidence, 1),
            "model_used": "ecg_only",
            "prediction_raw": prediction[0].tolist(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data_sources": {
                "eeg": False,
                "hrv": hrv_values is not None and len(hrv_values) > 0,
                "rr": rr_values is not None and len(rr_values) > 0,
                "hr": hr_values is not None and len(hr_values) > 0,
            }
        }
    
    def _predict_from_emotiv_metrics(self, emotiv_metrics: Dict[str, float]) -> Dict:
        """
        Use EMOTIV's built-in performance metrics as fallback.
        Maps EMOTIV's stress metric (0-1) to our stress level (0-100).
        """
        stress = emotiv_metrics.get('stress', 0.5)
        relaxation = emotiv_metrics.get('relaxation', 0.5)
        
        # Combine stress and inverse relaxation
        stress_level = (stress * 0.7 + (1 - relaxation) * 0.3) * 100
        
        return {
            "stress_level": int(stress_level),
            "stress_class": "stress" if stress_level > 50 else "normal",
            "confidence": 70.0,  # Lower confidence for EMOTIV metrics
            "model_used": "emotiv_metrics",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "emotiv_metrics": emotiv_metrics,
            "data_sources": {"eeg": False, "hrv": False, "rr": False, "hr": False}
        }
    
    # ==================== SHAP Explainability ====================
    
    def get_feature_contributions(
        self,
        eeg_data: Optional[Dict[str, List[float]]] = None,
        hrv_values: Optional[List[float]] = None,
        rr_values: Optional[List[float]] = None,
        hr_values: Optional[List[float]] = None,
    ) -> Dict:
        """
        Get simplified feature contributions for explainability.
        
        Returns contribution percentages for HRV, RR, and EEG.
        """
        contributions = {}
        
        # Calculate relative contributions based on feature variance
        has_hrv = hrv_values and len(hrv_values) > 1
        has_rr = rr_values and len(rr_values) > 1
        has_hr = hr_values and len(hr_values) > 1
        has_eeg = eeg_data and len(eeg_data) > 0
        
        total_weight = 0
        weights = {}
        
        if has_hrv:
            hrv_var = np.var(hrv_values) if len(hrv_values) > 1 else 0
            weights['hrv'] = 1 + hrv_var / 100  # Normalize
            total_weight += weights['hrv']
        
        if has_rr:
            rr_var = np.var(rr_values) if len(rr_values) > 1 else 0
            weights['rr'] = 0.8 + rr_var / 10
            total_weight += weights['rr']
        
        if has_hr:
            hr_var = np.var(hr_values) if len(hr_values) > 1 else 0
            weights['hr'] = 0.5 + hr_var / 50
            total_weight += weights['hr']
        
        if has_eeg:
            # EEG typically has higher contribution in fusion model
            weights['eeg'] = 1.5
            total_weight += weights['eeg']
        
        # Normalize to percentages
        if total_weight > 0:
            for key in weights:
                contributions[key] = round((weights[key] / total_weight) * 100, 1)
        
        # Generate descriptions
        descriptions = {}
        if has_hrv:
            hrv_mean = np.mean(hrv_values)
            if hrv_mean < 30:
                descriptions['hrv'] = "Low variability detected, suggesting sympathetic nervous system activation."
            elif hrv_mean > 60:
                descriptions['hrv'] = "Good variability indicating parasympathetic dominance."
            else:
                descriptions['hrv'] = "Moderate heart rate variability observed."
        
        if has_rr:
            rr_mean = np.mean(rr_values)
            if rr_mean > 18:
                descriptions['rr'] = "Elevated breathing rate observed."
            elif rr_mean < 12:
                descriptions['rr'] = "Slow, relaxed breathing pattern."
            else:
                descriptions['rr'] = "Normal respiratory rate."
        
        if has_eeg:
            descriptions['eeg'] = "EEG patterns analyzed for stress markers."
        
        return {
            "contributions": contributions,
            "descriptions": descriptions,
        }


# Global service instance
_prediction_service: Optional[StressPredictionService] = None


def get_prediction_service() -> StressPredictionService:
    """Get or create the global prediction service instance."""
    global _prediction_service
    if _prediction_service is None:
        _prediction_service = StressPredictionService()
        _prediction_service.load_models()
    return _prediction_service