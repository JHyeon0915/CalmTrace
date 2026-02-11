from datetime import datetime, date, timezone
from typing import List
from app.database import get_database
from app.services.streak_service import StreakService

# All available goals with their metadata
AVAILABLE_GOALS = {
    "breathing": {
        "title": "Practice Breathing",
        "description": "Complete a breathing exercise",
    },
    "stress_check": {
        "title": "Check Stress Levels",
        "description": "Monitor your stress biomarkers",
    },
    "therapy": {
        "title": "Try a Therapy Technique",
        "description": "Use mindfulness or grounding",
    },
    "games": {
        "title": "Play a Relaxing Game",
        "description": "Unwind with a calm activity",
    },
    "chat": {
        "title": "Chat with AI Coach",
        "description": "Reflect on your feelings",
    },
}

# Default goals for new users
DEFAULT_GOAL_TYPES = ["breathing", "stress_check"]


class GoalsService:
    def __init__(self):
        self.db = get_database()
        self.streak_service = StreakService()
    
    def _create_goal_from_type(self, goal_type: str, date_str: str, existing_goal: dict = None) -> dict:
        """Create a goal dict from a goal type."""
        goal_info = AVAILABLE_GOALS.get(goal_type, {
            "title": goal_type.replace("_", " ").title(),
            "description": "",
        })
        
        return {
            "id": f"{goal_type}_{date_str}",
            "goal_type": goal_type,
            "title": goal_info["title"],
            "description": goal_info["description"],
            "is_completed": existing_goal.get("is_completed", False) if existing_goal else False,
            "completed_at": existing_goal.get("completed_at") if existing_goal else None,
        }
    
    async def get_daily_goals(self, user_id: str, target_date: date = None) -> dict:
        """Get user's goals for a specific date."""
        if target_date is None:
            target_date = datetime.now(timezone.utc).date()
        
        date_str = target_date.isoformat()
        goals_doc = await self.db.daily_goals.find_one({
            "user_id": user_id,
            "date": date_str,
        })
        
        if not goals_doc:
            # Create default goals for today
            goals = [
                self._create_goal_from_type(goal_type, date_str)
                for goal_type in DEFAULT_GOAL_TYPES
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
    
    async def set_daily_goals(self, user_id: str, goal_types: List[str]) -> dict:
        """Set/update user's daily goals."""
        today = datetime.now(timezone.utc)
        today_date = today.date()
        date_str = today_date.isoformat()
        
        # Get existing goals to preserve completion status
        existing_doc = await self.db.daily_goals.find_one({
            "user_id": user_id,
            "date": date_str,
        })
        
        # Build a map of existing goals by type
        existing_goals_map = {}
        if existing_doc:
            for g in existing_doc.get("goals", []):
                existing_goals_map[g["goal_type"]] = g
        
        # Create new goals list, preserving completion status for unchanged goals
        goals = []
        for goal_type in goal_types:
            existing_goal = existing_goals_map.get(goal_type)
            goals.append(self._create_goal_from_type(goal_type, date_str, existing_goal))
        
        # Upsert the goals document
        await self.db.daily_goals.update_one(
            {"user_id": user_id, "date": date_str},
            {
                "$set": {
                    "goals": goals,
                    "updated_at": today,
                },
                "$setOnInsert": {
                    "user_id": user_id,
                    "date": date_str,
                    "created_at": today,
                }
            },
            upsert=True
        )
        
        completed_count = sum(1 for g in goals if g.get("is_completed", False))
        
        return {
            "date": date_str,
            "goals": goals,
            "completed_count": completed_count,
            "total_count": len(goals),
        }
    
    async def complete_goal(self, user_id: str, goal_type: str) -> dict:
        """Mark a goal as completed and update streak."""
        today = datetime.now(timezone.utc)
        today_date = today.date()
        date_str = today_date.isoformat()
        
        # Get daily goals
        daily_goals = await self.get_daily_goals(user_id, today_date)
        goals = daily_goals["goals"]
        
        # Find and update the goal
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
            raise ValueError(f"Goal type '{goal_type}' not found in today's goals")
        
        # Update in database
        await self.db.daily_goals.update_one(
            {"user_id": user_id, "date": date_str},
            {"$set": {"goals": goals, "updated_at": today}}
        )
        
        # Calculate completion stats
        completed_count = sum(1 for g in goals if g.get("is_completed", False))
        total_count = len(goals)
        
        # Update streak if this is a new completion
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
        """Reset goals for a specific date (for testing)."""
        if target_date is None:
            target_date = datetime.now(timezone.utc).date()
        
        date_str = target_date.isoformat()
        await self.db.daily_goals.delete_one({
            "user_id": user_id,
            "date": date_str,
        })
        return True


def get_goals_service() -> GoalsService:
    return GoalsService()