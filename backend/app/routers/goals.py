from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user
from app.services.goals_service import GoalsService, get_goals_service
from app.schemas.streak import (
    DailyGoalsResponse, GoalCompleteRequest, GoalCompleteResponse, 
    Goal, StreakUpdateResponse
)

router = APIRouter()


@router.get("/daily", response_model=DailyGoalsResponse)
async def get_daily_goals(
    current_user: dict = Depends(get_current_user),
    goals_service: GoalsService = Depends(get_goals_service),
):
    """Get today's goals"""
    user_id = current_user["uid"]
    result = await goals_service.get_daily_goals(user_id)
    
    goals = [
        Goal(
            id=g["id"],
            goalType=g["goal_type"],
            title=g["title"],
            description=g.get("description"),
            isCompleted=g.get("is_completed", False),
            completedAt=g.get("completed_at"),
        )
        for g in result["goals"]
    ]
    
    return DailyGoalsResponse(
        date=result["date"],
        goals=goals,
        completedCount=result["completed_count"],
        totalCount=result["total_count"],
    )


@router.post("/complete", response_model=GoalCompleteResponse)
async def complete_goal(
    request: GoalCompleteRequest,
    current_user: dict = Depends(get_current_user),
    goals_service: GoalsService = Depends(get_goals_service),
):
    """Complete a goal"""
    user_id = current_user["uid"]
    
    try:
        result = await goals_service.complete_goal(user_id, request.goalType.value)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    streak_data = None
    if result.get("streak_data"):
        sd = result["streak_data"]
        streak_data = StreakUpdateResponse(
            streakCount=sd["streakCount"],
            isNewStreak=sd["isNewStreak"],
            shouldCelebrate=sd["shouldCelebrate"],
            message=sd["message"],
            milestoneReached=sd.get("milestoneReached"),
        )
    
    return GoalCompleteResponse(
        success=result["success"],
        goalType=request.goalType,
        completedAt=result["completed_at"],
        dailyProgress=result["daily_progress"],
        totalGoals=result["total_goals"],
        streakUpdated=result["streak_updated"],
        streakData=streak_data,
    )


@router.post("/reset")
async def reset_daily_goals(
    current_user: dict = Depends(get_current_user),
    goals_service: GoalsService = Depends(get_goals_service),
):
    """Reset daily goals (for testing)"""
    user_id = current_user["uid"]
    await goals_service.reset_daily_goals(user_id)
    return {"success": True, "message": "Daily goals reset"}
