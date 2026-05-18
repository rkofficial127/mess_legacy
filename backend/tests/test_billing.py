"""Unit tests for pure billing calculation functions."""
from datetime import date
from decimal import Decimal

from app.utils.billing import (
    calculate_bill,
    count_mess_off_meals,
    count_sundays,
    days_in_month,
    total_meals_in_month,
)


def test_days_in_month():
    assert days_in_month(2, 2024) == 29  # Leap year
    assert days_in_month(2, 2025) == 28
    assert days_in_month(3, 2026) == 31
    assert days_in_month(4, 2026) == 30


def test_count_sundays():
    assert count_sundays(3, 2026) == 5  # March 2026 has 5 Sundays
    assert count_sundays(6, 2026) == 4  # June 2026 has 4 Sundays


def test_total_meals_3_per_day():
    # March 2026: 31 days, 5 Sundays, 26 weekdays
    # 26*3 + 5*1 = 78 + 5 = 83
    assert total_meals_in_month(3, 3, 2026) == 83


def test_total_meals_2_per_day():
    # March 2026: 26*2 + 5*1 = 52 + 5 = 57
    assert total_meals_in_month(2, 3, 2026) == 57


def test_count_mess_off_meals_all_weekday():
    # One full weekday off for a 3-meal plan = 3 meals
    entries = [{"date": date(2026, 6, 3), "meal_type": "ALL"}]  # Wednesday
    assert count_mess_off_meals(entries, 3, 6, 2026) == 3


def test_count_mess_off_meals_all_sunday():
    # One full Sunday off = 1 meal (only lunch on Sunday)
    entries = [{"date": date(2026, 6, 7), "meal_type": "ALL"}]  # Sunday
    assert count_mess_off_meals(entries, 3, 6, 2026) == 1


def test_count_mess_off_meals_partial():
    # Dinner off on a weekday for a 2-meal plan = 1
    entries = [{"date": date(2026, 6, 3), "meal_type": "DINNER"}]
    assert count_mess_off_meals(entries, 2, 6, 2026) == 1


def test_count_mess_off_meals_breakfast_on_2_plan():
    # Breakfast off for a 2-meal plan: breakfast not in plan → 0
    entries = [{"date": date(2026, 6, 3), "meal_type": "BREAKFAST"}]
    assert count_mess_off_meals(entries, 2, 6, 2026) == 0


def test_calculate_bill_spec_example():
    """Verify the billing example from the plan spec.

    Plan: Veg 3-Times, ₹2800, March 2026 (31 days, 5 Sundays)
    Weekday meals: 26*3=78, Sunday: 5*1=5, Total=83
    1 full weekday mess-off: -3 → billable=80
    Per meal: 2800/80=35.00
    5 user skips → deduction = 175.00
    Final = 2625.00

    Note: the spec example used 4 Sundays but March 2026 actually has 5.
    """
    result = calculate_bill(
        monthly_rate=Decimal("2800.00"),
        meals_per_day=3,
        month=3,
        year=2026,
        user_skips=5,
        mess_off_meals=3,
    )
    assert result["total_meals"] == 80
    assert result["mess_off_meals"] == 3
    assert result["skipped_meals"] == 5
    assert result["deduction_amount"] == Decimal("175.00")
    assert result["final_amount"] == Decimal("2625.00")


def test_calculate_bill_no_skips():
    result = calculate_bill(
        monthly_rate=Decimal("2300.00"),
        meals_per_day=2,
        month=6,
        year=2026,
        user_skips=0,
        mess_off_meals=0,
    )
    assert result["final_amount"] == Decimal("2300.00")
    assert result["deduction_amount"] == Decimal("0.00")


def test_calculate_bill_all_mess_off():
    # Edge case: all meals are mess-off
    total = total_meals_in_month(2, 6, 2026)
    result = calculate_bill(
        monthly_rate=Decimal("2300.00"),
        meals_per_day=2,
        month=6,
        year=2026,
        user_skips=0,
        mess_off_meals=total,
    )
    assert result["final_amount"] == Decimal("0.00")
