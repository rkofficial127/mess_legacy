import io
from datetime import date
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.bill import MonthlyBill
from app.models.extra_meal import ExtraMeal
from app.models.meal_skip import MealSkip
from app.models.mess_off import MessOffDay

_MEAL_LABEL = {"BREAKFAST": "Breakfast", "LUNCH": "Lunch", "DINNER": "Dinner", "ALL": "All meals"}

_SKIP_ROW_BG = colors.HexColor("#fee2e2")
_MESS_OFF_ROW_BG = colors.HexColor("#f1f5f9")
_EXTRA_ROW_BG = colors.HexColor("#fef3c7")


def generate_bill_pdf(
    bill: MonthlyBill,
    user_name: str,
    skips: list[MealSkip] | None = None,
    mess_offs: list[MessOffDay] | None = None,
    extras: list[ExtraMeal] | None = None,
    full_monthly_rate: Decimal | None = None,
    start_date: date | None = None,
    stop_date: date | None = None,
) -> bytes:
    skips = skips or []
    mess_offs = mess_offs or []
    extras = extras or []
    is_prorated = full_monthly_rate is not None and full_monthly_rate != bill.plan_rate

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph("Mess Monthly Bill", styles["Title"]))
    elements.append(Spacer(1, 6 * mm))

    info_data = [
        ["Name", user_name],
        ["Month / Year", f"{bill.month:02d} / {bill.year}"],
        ["Plan", bill.plan_name],
        ["Plan Rate", f"Rs. {(full_monthly_rate or bill.plan_rate):,.2f} /month"],
    ]
    if is_prorated:
        if start_date is not None and start_date.month == bill.month and start_date.year == bill.year:
            info_data.append(["Active From", start_date.strftime("%d %b %Y")])
        if stop_date is not None and stop_date.month == bill.month and stop_date.year == bill.year:
            info_data.append(["Active Until", stop_date.strftime("%d %b %Y")])
        info_data.append(["This Month's Amount", f"Rs. {bill.plan_rate:,.2f} (pro-rated)"])
    info_table = Table(info_data, colWidths=[50 * mm, 90 * mm])
    info_table.setStyle(
        TableStyle([
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ])
    )
    elements.append(info_table)
    elements.append(Spacer(1, 8 * mm))

    bill_data = [
        ["Description", "Value"],
        ["Total Billable Meals", str(bill.total_meals)],
        ["Meals Skipped (by you)", str(bill.skipped_meals)],
        ["Mess-Off Meals", str(bill.mess_off_meals)],
        ["Deduction (skips)", f"- Rs. {bill.deduction_amount:,.2f}"],
        ["Extra Meals", str(bill.extra_meals_count)],
        ["Extra Meals Charge", f"+ Rs. {bill.extra_meals_amount:,.2f}"],
        ["Final Amount", f"Rs. {bill.final_amount:,.2f}"],
    ]
    bill_table = Table(bill_data, colWidths=[90 * mm, 50 * mm])
    bill_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#334155")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("ALIGN", (1, 0), (1, -1), "RIGHT"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ("TOPPADDING", (0, 0), (-1, -1), 6),
            ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#f1f5f9")),
            ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ])
    )
    elements.append(bill_table)
    elements.append(Spacer(1, 10 * mm))

    elements.append(Paragraph("Itemized Breakdown", styles["Heading2"]))
    elements.append(Spacer(1, 3 * mm))

    entries = []
    for s in skips:
        entries.append((s.date, _MEAL_LABEL.get(s.meal_type.value, s.meal_type.value), "Skipped", "", _SKIP_ROW_BG))
    for m in mess_offs:
        entries.append((
            m.date,
            _MEAL_LABEL.get(m.meal_type.value, m.meal_type.value),
            "Mess Off",
            m.reason or "",
            _MESS_OFF_ROW_BG,
        ))
    for e in extras:
        entries.append((
            e.date,
            _MEAL_LABEL.get(e.meal_type.value, e.meal_type.value),
            "Extra",
            e.note or "",
            _EXTRA_ROW_BG,
        ))
    entries.sort(key=lambda row: row[0])

    if not entries:
        elements.append(
            Paragraph("No skipped, mess-off, or extra meals this month.", styles["Normal"])
        )
    else:
        ledger_data = [["Date", "Meal", "Type", "Note"]]
        row_colors = []
        for date_, meal, type_, note, bg in entries:
            ledger_data.append([date_.strftime("%d %b %Y"), meal, type_, note])
            row_colors.append(bg)

        ledger_table = Table(ledger_data, colWidths=[30 * mm, 30 * mm, 25 * mm, 55 * mm])
        style_commands = [
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#334155")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
        ]
        for i, bg in enumerate(row_colors, start=1):
            style_commands.append(("BACKGROUND", (0, i), (-1, i), bg))
        ledger_table.setStyle(TableStyle(style_commands))
        elements.append(ledger_table)

    doc.build(elements)
    return buf.getvalue()
