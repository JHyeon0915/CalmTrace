from datetime import datetime, date, timezone
from app.database import get_database
from app.services.streak_service import StreakService

DEFAULT_GOALS = [
    {"goal_type": "breathing", "title": "Practice Breathing", "description": "Complete a guided breathing session"},
    {"goal_type": "stress_check", "title": "Check Stress Levels", "description": "Review your current stress level"},
]


class GoalsService:
    def __init__(self):
        self.db = get_database()
        self.streak_service = StreakService()
    
    async def get_daily_goals(self, user_id: str, target_date: date = None) -> dict:
        if target_date is None:
            target_date = datetime.now(timezone.utc).date()
        
        date_str = target_date.isoformat()
        goals_doc = await self.db.daily_goals.find_one({"user_id": user_id, "date": date_str})
        
        if not goals_doc:
            goals = [
                {
                    "id": f"{goal['goal_type']}_{date_str}",
                    "goal_type": goal["goal_type"],
                    "title": goal["title"],
                    "description": goal["description"],
                    "is_completed": False,
                    "completed_at": None,
                }
                for goal in DEFAULT_GOALS
            ]
            
            goals_doc = {
                "user_id": user_id,
                "date": date_str,
                "goals": goals,
                "created_at": datetime.now(timezone.utc),
            }
            await self.db.daily_goals.insert_one(goals_doc)
        
        goals = goals_doc.get("goals", [])
        completed_count = sum(1 for g in goals if g.get("is_completed", False))
        
        return {
            "date": date_str,
            "goals": goals,
            "completed_count": completed_count,
            "total_count": len(goals),
        }
    
    async def complete_goal(self, user_id: str, goal_type: str) -> dict:
        today = datetime.utcnow()
        today_date = today.date()
        date_str = today_date.isoformat()
        
        daily_goals = await self.get_daily_goals(user_id, today_date)
        goals = daily_goals["goals"]
        
        goal_found = False
        already_completed = False
        
        for goal in goals:
            if goal["goal_type"] == goal_type:
                goal_found = True
                if goal["is_completed"]:
                    already_completed = True
                else:
                    goal["is_completed"] = True
                    goal["completed_at"] = today.isoformat()
                break
        
        if not goal_found:
            raise ValueError(f"Goal type '{goal_type}' not found")
        
        await self.db.daily_goals.update_one(
            {"user_id": user_id, "date": date_str},
            {"$set": {"goals": goals, "updated_at": today}}
        )
        
        completed_count = sum(1 for g in goals if g.get("is_completed", False))
        total_count = len(goals)
        
        streak_data = None
        streak_updated = False
        
        if not already_completed:
            streak_result = await self.streak_service.complete_goal(user_id)
            streak_updated = True
            streak_data = {
                "streakCount": streak_result["streak_count"],
                "isNewStreak": streak_result["is_new_streak"],
                "shouldCelebrate": streak_result["should_celebrate"],
                "message": streak_result["message"],
                "milestoneReached": streak_result.get("milestone_reached"),
            }
        
        return {
            "success": True,
            "goal_type": goal_type,
            "completed_at": today,
            "daily_progress": completed_count,
            "total_goals": total_count,
            "streak_updated": streak_updated,
            "streak_data": streak_data,
        }
    
    async def reset_daily_goals(self, user_id: str, target_date: date = None) -> bool:
        if target_date is None:
            target_date = datetime.utcnow().date()
        date_str = target_date.isoformat()
        await self.db.daily_goals.delete_one({"user_id": user_id, "date": date_str})
        return True


def get_goals_service() -> GoalsService:
    return GoalsService()
