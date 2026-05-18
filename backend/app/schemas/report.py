from datetime import date

from pydantic import BaseModel


class UserAttendance(BaseModel):
    user_id: str
    full_name: str
    email: str
    plan_name: str


class MealAttendanceResponse(BaseModel):
    date: date
    meal_type: str
    mess_off: bool
    total_subscribed: int
    total_taking: int
    total_skipped: int
    taking: list[UserAttendance]
    skipped: list[UserAttendance]
