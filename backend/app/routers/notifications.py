from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional

from app.auth import get_current_user
from app.services.notification_service import NotificationService
from app.schemas.notification import (
    NotificationPreferences,
    NotificationPreferencesUpdate,
    NotificationPreferencesResponse,
    DeviceRegistration,
    DeviceResponse,
    SendNotificationRequest,
    QuietHours
)

router = APIRouter()


def get_notification_service() -> NotificationService:
    return NotificationService()


# ==================== Preferences ====================

@router.get("/preferences", response_model=NotificationPreferencesResponse)
async def get_notification_preferences(
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Get current user's notification preferences"""
    return await service.get_preferences(current_user["uid"])


@router.put("/preferences", response_model=NotificationPreferencesResponse)
async def update_notification_preferences(
    updates: NotificationPreferencesUpdate,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Update notification preferences"""
    update_dict = updates.model_dump(exclude_none=True)
    
    # Convert QuietHours model to dict if present
    if "quiet_hours" in update_dict and update_dict["quiet_hours"] is not None:
        update_dict["quiet_hours"] = update_dict["quiet_hours"]
    
    return await service.update_preferences(current_user["uid"], update_dict)


@router.put("/preferences/quiet-hours", response_model=NotificationPreferencesResponse)
async def update_quiet_hours(
    quiet_hours: QuietHours,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Update just the quiet hours settings"""
    return await service.update_preferences(
        current_user["uid"], 
        {"quiet_hours": quiet_hours.model_dump()}
    )


@router.post("/preferences/toggle")
async def toggle_notifications(
    enabled: bool,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Quick toggle to enable/disable all notifications"""
    prefs = await service.update_preferences(
        current_user["uid"],
        {"enabled": enabled}
    )
    return {"enabled": prefs["enabled"]}


# ==================== Device Management ====================

@router.post("/devices/register", response_model=DeviceResponse)
async def register_device(
    registration: DeviceRegistration,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Register a device for push notifications"""
    return await service.register_device(
        user_id=current_user["uid"],
        platform=registration.platform,
        fcm_token=registration.fcm_token
    )


@router.delete("/devices/{device_id}")
async def unregister_device(
    device_id: str,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Unregister a device"""
    success = await service.unregister_device(current_user["uid"], device_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    return {"status": "unregistered", "device_id": device_id}


@router.get("/devices")
async def list_devices(
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """List all registered devices for current user"""
    devices = await service.get_user_devices(current_user["uid"])
    return {"devices": devices, "count": len(devices)}


# ==================== Notification History ====================

@router.get("/history")
async def get_notification_history(
    limit: int = 20,
    offset: int = 0,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Get notification history"""
    notifications = await service.get_notification_history(
        current_user["uid"],
        limit=limit,
        offset=offset
    )
    return {"notifications": notifications, "count": len(notifications)}


@router.post("/history/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Mark a notification as read"""
    success = await service.mark_notification_read(
        current_user["uid"],
        notification_id
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    return {"status": "read", "notification_id": notification_id}


# ==================== Send Notification (Internal/Test) ====================

@router.post("/send-test")
async def send_test_notification(
    request: SendNotificationRequest,
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Send a test notification to yourself"""
    result = await service.send_notification(
        user_id=current_user["uid"],
        notification_type=request.type,
        title=request.title,
        body=request.body,
        data=request.data
    )
    return result


# ==================== Check Status ====================

@router.get("/can-notify")
async def check_can_notify(
    notification_type: str = "daily_reminder",
    current_user: dict = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service)
):
    """Check if a notification can be sent right now"""
    can_send, reason = await service.can_send_notification(
        current_user["uid"],
        notification_type
    )
    
    prefs = await service.get_preferences(current_user["uid"])
    is_quiet = service.is_quiet_hours(prefs.get("quiet_hours", {}))
    
    return {
        "can_notify": can_send,
        "reason": reason,
        "is_quiet_hours": is_quiet,
        "notifications_enabled": prefs.get("enabled", True),
        "type_enabled": prefs.get(f"{notification_type}s", True)
    }