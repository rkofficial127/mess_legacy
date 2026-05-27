import io
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet

from app.models.bill import MonthlyBill


def generate_bill_pdf(bill: MonthlyBill, user_name: str) -> bytes:
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
        ["Plan Rate", f"₹{bill.plan_rate:,.2f}"],
    ]
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
        ["Deduction (skips)", f"- ₹{bill.deduction_amount:,.2f}"],
        ["Extra Meals", str(bill.extra_meals_count)],
        ["Extra Meals Charge", f"+ ₹{bill.extra_meals_amount:,.2f}"],
        ["Final Amount", f"₹{bill.final_amount:,.2f}"],
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

    doc.build(elements)
    return buf.getvalue()
