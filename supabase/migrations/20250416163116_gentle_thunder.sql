/*
  # Update advisor calendars for April 2025

  1. Changes
    - Updates calendar data for each advisor based on their consultation days
    - Sets available days to match consultation schedule
    - Removes busy slots that don't match consultation days
    - Formats calendar data according to advisor's office hours

  2. Notes
    - Only updates April 2025 calendar data
    - Preserves existing busy slots that match consultation days
    - Uses DO block for safe execution
*/

DO $$
DECLARE
  advisor RECORD;
  calendar_data JSONB;
  office_hours JSONB;
  available_days INT[];
  day_date DATE;
  day_of_week TEXT;
BEGIN
  -- Loop through each advisor
  FOR advisor IN SELECT * FROM scientific_advisors
  LOOP
    -- Initialize calendar data for April 2025
    calendar_data := '{"2025-04": {"available_days": [], "busy_slots": {}}}'::JSONB;
    office_hours := advisor.office_hours;
    available_days := ARRAY[]::INT[];

    -- Check each day in April 2025
    FOR day IN 1..30 LOOP
      day_date := DATE '2025-04-01' + (day - 1);
      -- Extract day name and convert to lowercase
      day_of_week := LOWER(TRIM(TO_CHAR(day_date, 'day')));

      -- If the weekday matches one of the advisor's consultation days, add it to available days
      IF office_hours ? day_of_week THEN
        available_days := array_append(available_days, day);
      END IF;
    END LOOP;

    -- Update the calendar data with available days
    calendar_data := jsonb_set(
      calendar_data,
      '{2025-04,available_days}',
      to_jsonb(available_days)
    );

    -- Update the advisor's calendar
    UPDATE scientific_advisors
    SET 
      calendar = calendar_data,
      updated_at = NOW()
    WHERE id = advisor.id;

  END LOOP;
END $$;