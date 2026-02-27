from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ChatMessageInput(BaseModel):
    """Single message in conversation history."""
    role: str = Field(..., description="'user' or 'assistant'")
    content: str


class AIChatRequest(BaseModel):
    """Request body for AI coach chat."""
    message: str = Field(..., min_length=1, max_length=2000)
    conversation_history: Optional[List[ChatMessageInput]] = Field(
        default=None,
        description="Previous messages in conversation (max 20)"
    )
    stress_level: Optional[int] = Field(
        default=None,
        ge=0,
        le=100,
        description="Current stress level for context"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "I'm feeling really anxious about my presentation tomorrow",
                "conversation_history": [
                    {"role": "assistant", "content": "Hello! How are you feeling today?"},
                    {"role": "user", "content": "Not great, I'm stressed"}
                ],
                "stress_level": 65
            }
        }


class AIChatResponse(BaseModel):
    """Response from AI coach."""
    success: bool
    response: str
    error: Optional[str] = None
    model: Optional[str] = None
    timestamp: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "response": "I hear you - presentation anxiety is really common. Let's work through this together. What specifically about the presentation is worrying you most?",
                "model": "gemini-1.5-flash",
                "timestamp": "2026-02-21T12:00:00Z"
            }
        }


class QuickResponse(BaseModel):
    """Quick response option."""
    id: str
    label: str
    message: str


class AICoachStatusResponse(BaseModel):
    """Status of AI coach service."""
    available: bool
    model: str = "gemini-1.5-flash"
    greeting: str
    quick_responses: List[QuickResponse]