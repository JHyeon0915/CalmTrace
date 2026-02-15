from motor.motor_asyncio import AsyncIOMotorClient
from app.config import get_settings
import certifi

settings = get_settings()

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

async def init_db():
    db.client = AsyncIOMotorClient(
        settings.mongodb_url,
        tlsCAFile=certifi.where()
    )
    db.db = db.client[settings.database_name]
    
    # Create indexes
    await db.db.streaks.create_index("user_id", unique=True)
    await db.db.daily_goals.create_index([("user_id", 1), ("date", 1)])
    await db.db.notification_preferences.create_index("user_id", unique=True)
    await db.db.devices.create_index([("user_id", 1), ("fcm_token", 1)])
    await db.db.notification_logs.create_index([("user_id", 1), ("sent_at", -1)])
    
    print(f"Connected to MongoDB: {settings.database_name}")

async def close_db():
    if db.client:
        db.client.close()
        print("Closed MongoDB connection")

def get_database():
    return db.db