from fastapi import APIRouter, Depends
from app.auth import get_current_user
from app.services.streak_service import StreakService, get_streak_service
from app.schemas.streak import StreakResponse, StreakUpdateResponse, CelebrationSeenResponse

router = APIRouter()


@router.get("", response_model=StreakResponse)
async def get_streak(
    current_user: dict = Depends(get_current_user),
    streak_service: StreakService = Depends(get_streak_service),
):
    """Get current streak (validates and resets if broken)"""
    user_id = current_user["uid"]
    valid_streak = await streak_service.check_and_update_streak(user_id)
    streak_data = await streak_service.get_streak(user_id)
    
    return StreakResponse(
        userId=user_id,
        streakCount=valid_streak,
        lastCompletionDate=streak_data.get("last_completion_date"),
        lastCelebrationDate=streak_data.get("last_celebration_date"),
        longestStreak=streak_data.get("longest_streak", 0),
    )


@router.post("/complete", response_model=StreakUpdateResponse)
async def complete_and_update_streak(
    current_user: dict = Depends(get_current_user),
    streak_service: StreakService = Depends(get_streak_service),
):
    """Complete goal and update streak"""
    user_id = current_user["uid"]
    result = await streak_service.complete_goal(user_id)
    
    return StreakUpdateResponse(
        streakCount=result["streak_count"],
        isNewStreak=result["is_new_streak"],
        shouldCelebrate=result["should_celebrate"],
        message=result["message"],
        milestoneReached=result.get("milestone_reached"),
    )


@router.get("/celebration/seen", response_model=CelebrationSeenResponse)
async def check_celebration_seen(
    current_user: dict = Depends(get_current_user),
    streak_service: StreakService = Depends(get_streak_service),
):
    """Check if celebration was seen today"""
    user_id = current_user["uid"]
    has_seen = await streak_service.has_seen_today_celebration(user_id)
    return CelebrationSeenResponse(success=True, hasSeenToday=has_seen)


@router.post("/celebration/seen", response_model=CelebrationSeenResponse)
async def mark_celebration_seen(
    current_user: dict = Depends(get_current_user),
    streak_service: StreakService = Depends(get_streak_service),
):
    """Mark celebration as seen"""
    user_id = current_user["uid"]
    await streak_service.mark_celebration_seen(user_id)
    return CelebrationSeenResponse(success=True, hasSeenToday=True)


@router.post("/reset")
async def reset_streak(
    current_user: dict = Depends(get_current_user),
    streak_service: StreakService = Depends(get_streak_service),
):
    """Reset streak (for testing)"""
    user_id = current_user["uid"]
    await streak_service.reset_streak(user_id)
    return {"success": True, "message": "Streak reset to 0"}
