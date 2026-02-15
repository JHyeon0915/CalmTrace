from datetime import datetime, time, timezone
from typing import Optional
from bson import ObjectId
import firebase_admin.messaging as fcm

from app.database import get_database


class NotificationService:
    """Service for managing notifications and preferences"""
    
    def __init__(self):
        self.db = get_database()
    
    # ==================== Preferences ====================
    
    async def get_preferences(self, user_id: str) -> dict:
        """Get user's notification preferences"""
        prefs = await self.db.notification_preferences.find_one({"user_id": user_id})
        
        if not prefs:
            # Return defaults if no preferences set
            return self._get_default_preferences(user_id)
        
        return self._format_preferences(prefs)
    
    async def update_preferences(self, user_id: str, updates: dict) -> dict:
        """Update user's notification preferences"""
        now = datetime.now(timezone.utc)
        
        # Get existing preferences or create defaults
        existing = await self.db.notification_preferences.find_one({"user_id": user_id})
        
        if existing:
            # Merge updates with existing
            update_data = {"updated_at": now}
            
            for key, value in updates.items():
                if key == "max_per_day":
                    update_data[key] = value if value != None else None    # allow null
                    print(update_data[key])
                elif value is not None:
                    if key == "quiet_hours" and isinstance(value, dict):
                        # Merge quiet hours
                        existing_qh = existing.get("quiet_hours", {})
                        existing_qh.update(value)
                        update_data["quiet_hours"] = existing_qh
                    else:
                        update_data[key] = value
            
            await self.db.notification_preferences.update_one(
                {"user_id": user_id},
                {"$set": update_data}
            )
        else:
            # Create new preferences with defaults + updates
            prefs_data = self._get_default_preferences_dict()
            prefs_data["user_id"] = user_id
            prefs_data["created_at"] = now
            prefs_data["updated_at"] = now
            
            for key, value in updates.items():
                if value is not None:
                    if key == "quiet_hours" and isinstance(value, dict):
                        prefs_data["quiet_hours"].update(value)
                    else:
                        prefs_data[key] = value
            
            await self.db.notification_preferences.insert_one(prefs_data)
        
        return await self.get_preferences(user_id)
    
    def _get_default_preferences_dict(self) -> dict:
        """Get default preferences as dict"""
        return {
            "enabled": True,
            "max_per_day": "unlimited",
            "quiet_hours": {
                "enabled": True,
                "start": "22:00",
                "end": "07:00"
            },
            "stress_alerts": True,
            "daily_reminders": True,
            "goal_reminders": True,
            "streak_reminders": True
        }
    
    def _get_default_preferences(self, user_id: str) -> dict:
        """Get default preferences for a user"""
        defaults = self._get_default_preferences_dict()
        defaults["user_id"] = user_id
        defaults["updated_at"] = datetime.now(timezone.utc)
        return defaults
    
    def _format_preferences(self, prefs: dict) -> dict:
        """Format preferences for response"""
        return {
            "user_id": prefs["user_id"],
            "enabled": prefs.get("enabled", True),
            "max_per_day": prefs.get("max_per_day", "unlimited"),
            "quiet_hours": prefs.get("quiet_hours", {
                "enabled": True,
                "start": "22:00",
                "end": "07:00"
            }),
            "stress_alerts": prefs.get("stress_alerts", True),
            "daily_reminders": prefs.get("daily_reminders", True),
            "goal_reminders": prefs.get("goal_reminders", True),
            "streak_reminders": prefs.get("streak_reminders", True),
            "updated_at": prefs.get("updated_at", datetime.now(timezone.utc))
        }
    
    # ==================== Device Management ====================
    
    async def register_device(self, user_id: str, platform: str, fcm_token: str) -> dict:
        """Register a device for push notifications"""
        now = datetime.now(timezone.utc)
        
        # Check if device token already exists for this user
        existing = await self.db.devices.find_one({
            "user_id": user_id,
            "fcm_token": fcm_token
        })
        
        if existing:
            # Update last seen
            await self.db.devices.update_one(
                {"_id": existing["_id"]},
                {"$set": {"last_seen": now}}
            )
            return {
                "device_id": str(existing["_id"]),
                "platform": platform,
                "status": "already_registered",
                "registered_at": existing["registered_at"]
            }
        
        # Register new device
        device_data = {
            "user_id": user_id,
            "platform": platform,
            "fcm_token": fcm_token,
            "registered_at": now,
            "last_seen": now,
            "active": True
        }
        
        result = await self.db.devices.insert_one(device_data)
        
        return {
            "device_id": str(result.inserted_id),
            "platform": platform,
            "status": "registered",
            "registered_at": now
        }
    
    async def unregister_device(self, user_id: str, device_id: str) -> bool:
        """Unregister a device"""
        result = await self.db.devices.delete_one({
            "_id": ObjectId(device_id),
            "user_id": user_id
        })
        return result.deleted_count > 0
    
    async def get_user_devices(self, user_id: str) -> list:
        """Get all registered devices for a user"""
        cursor = self.db.devices.find({"user_id": user_id, "active": True})
        devices = []
        async for device in cursor:
            devices.append({
                "device_id": str(device["_id"]),
                "platform": device["platform"],
                "registered_at": device["registered_at"],
                "last_seen": device.get("last_seen")
            })
        return devices
    
    # ==================== Quiet Hours ====================
    
    def is_quiet_hours(self, quiet_hours: dict, user_timezone: str = "UTC") -> bool:
        """Check if current time is within quiet hours"""
        if not quiet_hours.get("enabled", True):
            return False
        
        now = datetime.now(timezone.utc)
        current_time = now.time()
        
        start_str = quiet_hours.get("start", "22:00")
        end_str = quiet_hours.get("end", "07:00")
        
        start_hour, start_min = map(int, start_str.split(":"))
        end_hour, end_min = map(int, end_str.split(":"))
        
        start_time = time(start_hour, start_min)
        end_time = time(end_hour, end_min)
        
        # Handle overnight quiet hours (e.g., 22:00 - 07:00)
        if start_time > end_time:
            # Quiet hours span midnight
            return current_time >= start_time or current_time < end_time
        else:
            # Quiet hours within same day
            return start_time <= current_time < end_time
    
    # ==================== Notification Sending ====================
    
    async def can_send_notification(
        self, 
        user_id: str, 
        notification_type: str
    ) -> tuple[bool, Optional[str]]:
        """
        Check if a notification can be sent to the user.
        Returns (can_send, reason_if_not)
        """
        prefs = await self.get_preferences(user_id)
        
        # Check if notifications are enabled globally
        if not prefs.get("enabled", True):
            return False, "notifications_disabled"
        
        # Check if this notification type is enabled
        type_key_map = {
            "stress_alert": "stress_alerts",
            "daily_reminder": "daily_reminders", 
            "goal_reminder": "goal_reminders",
            "streak_reminder": "streak_reminders"
        }
        
        type_key = type_key_map.get(notification_type)
        if type_key and not prefs.get(type_key, True):
            return False, f"{notification_type}_disabled"
        
        # Check quiet hours
        if self.is_quiet_hours(prefs.get("quiet_hours", {})):
            return False, "quiet_hours"
        
        # Check daily limit
        today = datetime.now(timezone.utc).date()
        today_count = await self.db.notification_logs.count_documents({
            "user_id": user_id,
            "sent_at": {
                "$gte": datetime.combine(today, time.min, tzinfo=timezone.utc),
                "$lt": datetime.combine(today, time.max, tzinfo=timezone.utc)
            }
        })
        
        max_per_day = prefs.get("max_per_day", "unlimited")
        if max_per_day != "unlimited" and today_count >= max_per_day:
            return False, "daily_limit_reached"
        
        return True, None
    
    async def send_notification(
        self,
        user_id: str,
        notification_type: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
        force: bool = False
    ) -> dict:
        """
        Send a notification to a user.
        
        Args:
            user_id: Target user ID
            notification_type: Type of notification
            title: Notification title
            body: Notification body
            data: Additional data payload
            force: Skip preference checks (for critical alerts)
        
        Returns:
            Result dict with status and details
        """
        # Check if we can send
        if not force:
            can_send, reason = await self.can_send_notification(user_id, notification_type)
            if not can_send:
                return {
                    "sent": False,
                    "reason": reason,
                    "notification_id": None
                }
        
        # Get user's devices
        devices = await self.get_user_devices(user_id)
        
        if not devices:
            return {
                "sent": False,
                "reason": "no_devices",
                "notification_id": None
            }
        
        # Create notification log
        now = datetime.now(timezone.utc)
        log_data = {
            "user_id": user_id,
            "type": notification_type,
            "title": title,
            "body": body,
            "data": data or {},
            "sent_at": now,
            "delivered": False,
            "read": False,
            "device_count": len(devices)
        }
        
        result = await self.db.notification_logs.insert_one(log_data)
        notification_id = str(result.inserted_id)
        
        # Send via FCM to all devices
        success_count = 0
        for device in devices:
            try:
                message = fcm.Message(
                    notification=fcm.Notification(
                        title=title,
                        body=body
                    ),
                    data={
                        "notification_id": notification_id,
                        "type": notification_type,
                        **(data or {})
                    },
                    token=device.get("fcm_token")
                )
                
                # Note: In production, use fcm.send(message)
                # For now, we'll simulate success
                # response = fcm.send(message)
                success_count += 1
                
            except Exception as e:
                print(f"Failed to send to device {device['device_id']}: {e}")
                # Mark device as potentially invalid
                await self.db.devices.update_one(
                    {"_id": ObjectId(device["device_id"])},
                    {"$set": {"last_error": str(e), "last_error_at": now}}
                )
        
        # Update log with delivery status
        await self.db.notification_logs.update_one(
            {"_id": result.inserted_id},
            {"$set": {"delivered": success_count > 0, "delivered_count": success_count}}
        )
        
        return {
            "sent": success_count > 0,
            "notification_id": notification_id,
            "delivered_to": success_count,
            "total_devices": len(devices)
        }
    
    async def get_notification_history(
        self, 
        user_id: str, 
        limit: int = 20,
        offset: int = 0
    ) -> list:
        """Get notification history for a user"""
        cursor = self.db.notification_logs.find(
            {"user_id": user_id}
        ).sort("sent_at", -1).skip(offset).limit(limit)
        
        notifications = []
        async for notif in cursor:
            notifications.append({
                "notification_id": str(notif["_id"]),
                "type": notif["type"],
                "title": notif["title"],
                "body": notif["body"],
                "sent_at": notif["sent_at"],
                "delivered": notif.get("delivered", False),
                "read": notif.get("read", False)
            })
        
        return notifications
    
    async def mark_notification_read(self, user_id: str, notification_id: str) -> bool:
        """Mark a notification as read"""
        result = await self.db.notification_logs.update_one(
            {"_id": ObjectId(notification_id), "user_id": user_id},
            {"$set": {"read": True, "read_at": datetime.now(timezone.utc)}}
        )
        return result.modified_count > 0