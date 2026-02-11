from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from enum import Enum


class StreakResponse(BaseModel):
    userId: str
    streakCount: int
    lastCompletionDate: Optional[datetime] = None
    lastCelebrationDate: Optional[datetime] = None
    longestStreak: int = 0


class StreakUpdateResponse(BaseModel):
    streakCount: int
    isNewStreak: bool
    shouldCelebrate: bool
    message: str
    milestoneReached: Optional[int] = None


class CelebrationSeenResponse(BaseModel):
    success: bool
    hasSeenToday: bool


class GoalType(str, Enum):
    BREATHING = "breathing"
    STRESS_CHECK = "stress_check"
    MINDFULNESS = "mindfulness"
    COGNITIVE_REFRAMING = "cognitive_reframing"
    CUSTOM = "custom"


class Goal(BaseModel):
    id: str
    goalType: str
    title: str
    description: Optional[str] = None
    isCompleted: bool = False
    completedAt: Optional[str] = None


class DailyGoalsResponse(BaseModel):
    date: str
    goals: List[Goal]
    completedCount: int
    totalCount: int


class GoalCompleteRequest(BaseModel):
    goalType: GoalType


class SetGoalsRequest(BaseModel):
    goalTypes: List[str]


class GoalCompleteResponse(BaseModel):
    success: bool
    goalType: GoalType
    completedAt: datetime
    dailyProgress: int
    totalGoals: int
    streakUpdated: bool
    streakData: Optional[StreakUpdateResponse] = None