from pydantic import BaseModel, Field
from typing import Optional, Literal, Union
from datetime import datetime


class QuietHours(BaseModel):
    """Quiet hours configuration - no notifications during this time"""
    enabled: bool = True
    start: str = Field(default="22:00", pattern=r"^\d{2}:\d{2}$")  # HH:MM format
    end: str = Field(default="07:00", pattern=r"^\d{2}:\d{2}$")


class NotificationPreferences(BaseModel):
    """User notification preferences"""
    enabled: bool = True
    max_per_day: Union[int, Literal["unlimited"]] = "unlimited"
    quiet_hours: QuietHours = Field(default_factory=QuietHours)
    
    # Notification types toggles
    stress_alerts: bool = True  # Alert when high stress detected
    daily_reminders: bool = True  # Daily check-in reminders
    goal_reminders: bool = True  # Remind to complete daily goals
    streak_reminders: bool = True  # Remind to maintain streak


class NotificationPreferencesUpdate(BaseModel):
    """Update notification preferences - all fields optional"""
    enabled: Optional[bool] = None
    max_per_day: Optional[Union[int, Literal["unlimited"]]] = None
    quiet_hours: Optional[QuietHours] = None
    stress_alerts: Optional[bool] = None
    daily_reminders: Optional[bool] = None
    goal_reminders: Optional[bool] = None
    streak_reminders: Optional[bool] = None


class NotificationPreferencesResponse(NotificationPreferences):
    """Response model for notification preferences"""
    user_id: str
    updated_at: datetime


class DeviceRegistration(BaseModel):
    """Register device for push notifications"""
    platform: Literal["android", "ios", "web"]
    fcm_token: str


class DeviceResponse(BaseModel):
    """Response after device registration"""
    device_id: str
    platform: str
    status: str
    registered_at: datetime


class NotificationLog(BaseModel):
    """Log of sent notifications"""
    notification_id: str
    user_id: str
    type: str  # stress_alert, daily_reminder, goal_reminder, streak_reminder
    title: str
    body: str
    sent_at: datetime
    delivered: bool = False
    read: bool = False


class SendNotificationRequest(BaseModel):
    """Request to send a notification (internal/admin use)"""
    type: Literal["stress_alert", "daily_reminder", "goal_reminder", "streak_reminder"]
    title: str
    body: str
    data: Optional[dict] = None