from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timezone
from typing import Optional

from app.auth import get_current_user
from app.database import get_database
from app.schemas.ai_coach import (
    AIChatRequest,
    AIChatResponse,
    AICoachStatusResponse,
    QuickResponse,
)
from app.services.ai_coach_service import get_ai_coach_service, ChatMessage

router = APIRouter()


@router.get("/status", response_model=AICoachStatusResponse)
async def get_coach_status(
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI coach availability and initial greeting.
    """
    service = get_ai_coach_service()
    user_name = current_user.get("name", "").split()[0] if current_user.get("name") else None
    
    return AICoachStatusResponse(
        available=service.is_available,
        model="gemini-1.5-flash",
        greeting=service.get_greeting(user_name),
        quick_responses=[
            QuickResponse(**qr) for qr in service.get_quick_responses()
        ],
    )


@router.post("/chat", response_model=AIChatResponse)
async def chat_with_coach(
    request: AIChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Send a message to the AI stress coach.
    """
    service = get_ai_coach_service()
    
    if not service.is_available:
        raise HTTPException(
            status_code=503,
            detail="AI Coach is temporarily unavailable. Please try again later."
        )
    
    # Build conversation history
    history = None
    if request.conversation_history:
        history = [
            ChatMessage(role=msg.role, content=msg.content)
            for msg in request.conversation_history[-20:]  # Limit history
        ]
    
    # Build user context
    user_context = {}
    if request.stress_level is not None:
        user_context["stress_level"] = request.stress_level
    
    # Get current time of day for context
    hour = datetime.now().hour
    if 5 <= hour < 12:
        user_context["time_of_day"] = "morning"
    elif 12 <= hour < 17:
        user_context["time_of_day"] = "afternoon"
    elif 17 <= hour < 21:
        user_context["time_of_day"] = "evening"
    else:
        user_context["time_of_day"] = "night"
    
    # Get AI response
    result = await service.chat(
        user_message=request.message,
        conversation_history=history,
        user_context=user_context if user_context else None,
    )
    
    # Store conversation in database (optional, for analytics)
    db = get_database()
    await db.ai_coach_conversations.insert_one({
        "user_id": current_user["uid"],
        "user_message": request.message,
        "ai_response": result.get("response"),
        "success": result["success"],
        "model": result.get("model"),
        "stress_level": request.stress_level,
        "timestamp": datetime.now(timezone.utc),
    })
    
    return AIChatResponse(
        success=result["success"],
        response=result.get("response", "I'm having trouble responding. Please try again."),
        error=result.get("error"),
        model=result.get("model"),
        timestamp=datetime.now(timezone.utc),
    )


@router.get("/history")
async def get_chat_history(
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
):
    """
    Get recent chat history with AI coach.
    """
    db = get_database()
    
    cursor = db.ai_coach_conversations.find(
        {"user_id": current_user["uid"]}
    ).sort("timestamp", -1).limit(limit)
    
    history = []
    async for doc in cursor:
        history.append({
            "user_message": doc["user_message"],
            "ai_response": doc["ai_response"],
            "timestamp": doc["timestamp"].isoformat(),
        })
    
    return {"history": list(reversed(history))}