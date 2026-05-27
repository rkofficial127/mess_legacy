import calendar
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

SUNDAY = 6


def days_in_month(month: int, year: int) -> int:
    return calendar.monthrange(year, month)[1]


def total_meals_in_range(
    meals_per_day: int, month: int, year: int,
    start_day: int = 1, end_day: int | None = None,
) -> int:
    if end_day is None:
        end_day = days_in_month(month, year)
    total = 0
    for day in range(start_day, end_day + 1):
        d = date(year, month, day)
        if d.weekday() == SUNDAY:
            total += 1
        else:
            total += meals_per_day
    return total


def total_meals_in_month(meals_per_day: int, month: int, year: int) -> int:
    return total_meals_in_range(meals_per_day, month, year)


def count_mess_off_meals(
    mess_off_entries: list[dict], meals_per_day: int, month: int, year: int,
    start_day: int = 1, end_day: int | None = None,
) -> int:
    if end_day is None:
        end_day = days_in_month(month, year)

    if meals_per_day == 2:
        plan_meals = {"LUNCH", "DINNER"}
    else:
        plan_meals = {"BREAKFAST", "LUNCH", "DINNER"}

    total = 0
    for entry in mess_off_entries:
        d = entry["date"]
        mt = entry["meal_type"]

        if d.day < start_day or d.day > end_day:
            continue

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
    extra_meals_count: int = 0,
    extra_meal_rate: Decimal = Decimal("0.00"),
    start_day: int = 1,
    end_day: int | None = None,
) -> dict:
    total_days = days_in_month(month, year)
    if end_day is None:
        end_day = total_days

    active_days = end_day - start_day + 1
    if active_days < total_days:
        pro_rated_rate = (monthly_rate * Decimal(active_days) / Decimal(total_days)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
    else:
        pro_rated_rate = monthly_rate

    gross_meals = total_meals_in_range(meals_per_day, month, year, start_day, end_day)
    billable_meals = gross_meals - mess_off_meals

    extra_meals_amount = (extra_meal_rate * Decimal(extra_meals_count)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )

    if billable_meals <= 0:
        return {
            "total_meals": gross_meals,
            "mess_off_meals": mess_off_meals,
            "skipped_meals": user_skips,
            "extra_meals_count": extra_meals_count,
            "extra_meals_amount": extra_meals_amount,
            "deduction_amount": pro_rated_rate,
            "final_amount": extra_meals_amount,
            "plan_rate": pro_rated_rate,
        }

    per_meal = (pro_rated_rate / Decimal(billable_meals)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    deduction = (per_meal * Decimal(user_skips)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    final = (pro_rated_rate - deduction + extra_meals_amount).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )

    return {
        "total_meals": billable_meals,
        "mess_off_meals": mess_off_meals,
        "skipped_meals": user_skips,
        "extra_meals_count": extra_meals_count,
        "extra_meals_amount": extra_meals_amount,
        "deduction_amount": deduction,
        "final_amount": final,
        "plan_rate": pro_rated_rate,
    }
