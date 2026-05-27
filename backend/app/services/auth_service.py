from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.utils.security import verify_password


async def authenticate(db: AsyncSession, login: str, password: str) -> User | None:
    login_lower = login.strip().lower()
    result = await db.execute(
        select(User).where(
            or_(User.email == login_lower, User.phone == login.strip())
        )
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        return None
    if user.password_hash is None:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
