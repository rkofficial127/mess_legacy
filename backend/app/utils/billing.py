import calendar
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

SUNDAY = 6


def days_in_month(month: int, year: int) -> int:
    return calendar.monthrange(year, month)[1]


def count_sundays(month: int, year: int) -> int:
    total = days_in_month(month, year)
    return sum(
        1 for day in range(1, total + 1) if date(year, month, day).weekday() == SUNDAY
    )


def total_meals_in_month(meals_per_day: int, month: int, year: int) -> int:
    total_days = days_in_month(month, year)
    sundays = count_sundays(month, year)
    weekdays = total_days - sundays
    weekday_meals = weekdays * meals_per_day
    sunday_meals = sundays * 1
    return weekday_meals + sunday_meals


def count_mess_off_meals(
    mess_off_entries: list[dict], meals_per_day: int, month: int, year: int
) -> int:
    """
    Each entry has {"date": date, "meal_type": "ALL"|"BREAKFAST"|"LUNCH"|"DINNER"}.
    Returns the total number of deductible meals from mess-off days.
    """
    if meals_per_day == 2:
        plan_meals = {"LUNCH", "DINNER"}
    else:
        plan_meals = {"BREAKFAST", "LUNCH", "DINNER"}

    total = 0
    for entry in mess_off_entries:
        d = entry["date"]
        mt = entry["meal_type"]

        if d.weekday() == SUNDAY:
            if mt == "ALL" or mt == "LUNCH":
                total += 1
        else:
            if mt == "ALL":
                total += meals_per_day
            elif mt in plan_meals:
                total += 1
    return total


def calculate_bill(
    monthly_rate: Decimal,
    meals_per_day: int,
    month: int,
    year: int,
    user_skips: int,
    mess_off_meals: int,
) -> dict:
    gross_meals = total_meals_in_month(meals_per_day, month, year)
    billable_meals = gross_meals - mess_off_meals
    if billable_meals <= 0:
        return {
            "total_meals": gross_meals,
            "mess_off_meals": mess_off_meals,
            "skipped_meals": user_skips,
            "deduction_amount": monthly_rate,
            "final_amount": Decimal("0.00"),
        }

    per_meal = (monthly_rate / Decimal(billable_meals)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    deduction = (per_meal * Decimal(user_skips)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    final = (monthly_rate - deduction).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    return {
        "total_meals": billable_meals,
        "mess_off_meals": mess_off_meals,
        "skipped_meals": user_skips,
        "deduction_amount": deduction,
        "final_amount": final,
    }
