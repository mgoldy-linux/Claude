-- =============================================================================
-- dbo.asi_fn_po_next_business_day
-- Part of SA-46321 (PO Required Date -- line + header)
--
-- Slides a candidate date forward to the next business day: skips Saturday,
-- Sunday, and any date flagged as a company holiday in service_calendar.
-- Iterative (not a single-step check) so a slide landing on a second holiday
-- (e.g. the day after Thanksgiving) keeps advancing.
--
-- service_calendar repurposed as the holiday source -- P21 has no dedicated
-- holiday table. day_type_cd = 1788 decodes to 'Holiday' in p21_view_code_p21.
-- See feedback_p21_service_calendar_holidays.
-- =============================================================================
CREATE OR ALTER FUNCTION dbo.asi_fn_po_next_business_day (@d DATETIME)
RETURNS DATETIME
AS
BEGIN
    WHILE DATENAME(WEEKDAY, @d) IN ('Saturday', 'Sunday')
       OR EXISTS (
            SELECT 1 FROM service_calendar
            WHERE calendar_date = @d AND day_type_cd = 1788 AND company_id = 1
          )
        SET @d = DATEADD(DAY, 1, @d)

    RETURN @d
END
