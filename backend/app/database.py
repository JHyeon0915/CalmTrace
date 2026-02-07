from motor.motor_asyncio import AsyncIOMotorClient
from app.config import get_settings

settings = get_settings()


class Database:
    client: AsyncIOMotorClient = None
    db = None


db = Database()


async def init_db():
    db.client = AsyncIOMotorClient(settings.mongodb_url)
    db.db = db.client[settings.database_name]
    await db.db.streaks.create_index("user_id", unique=True)
    await db.db.daily_goals.create_index([("user_id", 1), ("date", 1)])
    print(f"Connected to MongoDB: {settings.database_name}")


async def close_db():
    if db.client:
        db.client.close()


def get_database():
    return db.db
