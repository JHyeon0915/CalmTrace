from datetime import datetime, timezone
from app.database import get_database

CELEBRATION_MILESTONES = {1, 3, 7, 14, 30, 60, 90, 180, 365}


class StreakService:
    def __init__(self):
        self.db = get_database()
    
    async def ensure_user_exists(self, user_id: str) -> None:
        """Create streak record for user if it doesn't exist."""
        existing = await self.db.streaks.find_one({"user_id": user_id})
        if not existing:
            await self.db.streaks.insert_one({
                "user_id": user_id,
                "streak_count": 0,
                "last_completion_date": None,
                "last_celebration_date": None,
                "longest_streak": 0,
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc),
            })
    
    async def get_streak(self, user_id: str) -> dict:
        """Get user's current streak data."""
        streak_doc = await self.db.streaks.find_one({"user_id": user_id})
        
        if not streak_doc:
            return {
                "user_id": user_id,
                "streak_count": 0,
                "last_completion_date": None,
                "last_celebration_date": None,
                "longest_streak": 0,
            }
        return streak_doc
    
    async def check_and_update_streak(self, user_id: str) -> int:
        """Check if streak is valid, reset if broken. Returns current streak."""
        streak_doc = await self.get_streak(user_id)
        
        if streak_doc["streak_count"] == 0:
            return 0
        
        last_date = streak_doc.get("last_completion_date")
        if not last_date:
            return 0
        
        today = datetime.utcnow().date()
        last_completion_date = last_date.date() if isinstance(last_date, datetime) else last_date
        days_since = (today - last_completion_date).days
        
        # Streak broken if more than 1 day passed
        if days_since > 1:
            await self.db.streaks.update_one(
                {"user_id": user_id},
                {"$set": {"streak_count": 0, "updated_at": datetime.utcnow()}}
            )
            return 0
        
        return streak_doc["streak_count"]
    
    async def complete_goal(self, user_id: str) -> dict:
        """Record goal completion and update streak."""
        today = datetime.now(timezone.utc)
        today_date = today.date()
        
        streak_doc = await self.get_streak(user_id)
        current_streak = streak_doc.get("streak_count", 0)
        last_date = streak_doc.get("last_completion_date")
        longest_streak = streak_doc.get("longest_streak", 0)
        
        new_streak = current_streak
        is_new_streak = False
        should_celebrate = False
        
        if last_date is None:
            # First ever completion
            new_streak = 1
            is_new_streak = True
            should_celebrate = True
        else:
            last_completion_date = last_date.date() if isinstance(last_date, datetime) else last_date
            days_since = (today_date - last_completion_date).days
            
            if days_since == 0:
                # Already completed today - no change
                pass
            elif days_since == 1:
                # Consecutive day - increment
                new_streak = current_streak + 1
                should_celebrate = new_streak in CELEBRATION_MILESTONES or new_streak % 30 == 0
            else:
                # Streak broken - restart
                new_streak = 1
                is_new_streak = True
                should_celebrate = True
        
        # Update longest streak
        if new_streak > longest_streak:
            longest_streak = new_streak
        
        # Save to database
        await self.db.streaks.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "user_id": user_id,
                    "streak_count": new_streak,
                    "last_completion_date": today,
                    "longest_streak": longest_streak,
                    "updated_at": today,
                },
                "$setOnInsert": {"created_at": today}
            },
            upsert=True
        )
        
        message = self._get_streak_message(new_streak, is_new_streak)
        
        return {
            "streak_count": new_streak,
            "is_new_streak": is_new_streak,
            "should_celebrate": should_celebrate,
            "message": message,
            "milestone_reached": new_streak if should_celebrate else None,
        }
    
    async def has_seen_today_celebration(self, user_id: str) -> bool:
        """Check if user has seen today's celebration."""
        streak_doc = await self.get_streak(user_id)
        last_celebration = streak_doc.get("last_celebration_date")
        
        if not last_celebration:
            return False
        
        today = datetime.now(timezone.utc).date()
        celebration_date = last_celebration.date() if isinstance(last_celebration, datetime) else last_celebration
        return celebration_date == today
    
    async def mark_celebration_seen(self, user_id: str) -> bool:
        """Mark that user has seen today's celebration."""
        await self.db.streaks.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "last_celebration_date": datetime.utcnow(),
                    "updated_at": datetime.utcnow(),
                }
            },
            upsert=True
        )
        return True
    
    async def reset_streak(self, user_id: str) -> bool:
        """Reset user's streak to 0."""
        await self.db.streaks.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "streak_count": 0,
                    "last_completion_date": None,
                    "last_celebration_date": None,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
            upsert=True
        )
        return True
    
    def _get_streak_message(self, streak_count: int, is_new: bool) -> str:
        """Generate celebration message."""
        if is_new and streak_count == 1:
            return "Streak Started! 🎉 You've completed your first day of goals. Keep it up!"
        
        messages = {
            1: "1 Day Streak! 🔥 Great start!",
            3: "3 Day Streak! 🔥 You're building a great habit!",
            7: "One Week Strong! ⭐ A full week of self-care!",
            14: "Two Weeks! 🎊 Your dedication is inspiring!",
            30: "30 Days! 🏆 A full month of wellness!",
            60: "60 Days! 💪 Two months strong!",
            90: "90 Days! 🌟 Three months of consistency!",
        }
        
        return messages.get(streak_count, f"{streak_count} Day Streak! 🔥 You're making great progress!")


def get_streak_service() -> StreakService:
    return StreakService()
