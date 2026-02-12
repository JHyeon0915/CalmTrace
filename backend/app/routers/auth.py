from fastapi import APIRouter, Depends
from pydantic import BaseModel
from datetime import datetime, timezone
from app.auth import get_current_user
from app.database import get_database

router = APIRouter()


class TokenVerifyResponse(BaseModel):
    userId: str
    email: str | None
    name: str | None
    tokenVerified: bool


@router.post("/verify", response_model=TokenVerifyResponse)
async def verify_token(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_doc = await db.users.find_one({"_id": current_user["uid"]})
    
    if not user_doc:
        await db.users.insert_one({
            "_id": current_user["uid"],
            "email": current_user.get("email"),
            "name": current_user.get("name"),
            "createdAt": datetime.now(timezone.utc),
        })
    
    return TokenVerifyResponse(
        userId=current_user["uid"],
        email=current_user.get("email"),
        name=current_user.get("name"),
        tokenVerified=True,
    )
