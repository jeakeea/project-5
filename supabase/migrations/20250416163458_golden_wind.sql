/*
  # Add busy slots for advisors

  1. Changes
    - Adds one busy slot for each advisor based on their consultation schedule
    - Updates the calendar data to include these busy slots
    - Maintains existing available days

  2. Notes
    - Only adds slots for April 2025
    - Slots are added on the first available consultation day
    - Time slots match the advisor's office hours
*/

DO $$
DECLARE
  advisor RECORD;
  calendar_data JSONB;
  office_hours JSONB;
  available_days INT[];
  first_available_day INT;
  day_date DATE;
  day_of_week TEXT;
  consultation_hours TEXT;
  date_str TEXT;
BEGIN
  -- Loop through each advisor
  FOR advisor IN SELECT * FROM scientific_advisors
  LOOP
    calendar_data := advisor.calendar;
    office_hours := advisor.office_hours;
    
    -- Extract available days as an array
    WITH days AS (
      SELECT jsonb_array_elements_text((calendar_data->'2025-04'->'available_days'))::int AS day
    )
    SELECT array_agg(day ORDER BY day) INTO available_days FROM days;
    
    -- Find first available day and its weekday
    IF array_length(available_days, 1) > 0 THEN
      first_available_day := available_days[1];
      day_date := DATE '2025-04-01' + (first_available_day - 1);
      day_of_week := LOWER(TRIM(TO_CHAR(day_date, 'day')));
      
      -- Get consultation hours for that day
      consultation_hours := office_hours->>day_of_week;
      
      IF consultation_hours IS NOT NULL THEN
        -- Create date string with proper padding
        date_str := '2025-04-' || LPAD(first_available_day::text, 2, '0');
        
        -- Add busy slot to calendar
        calendar_data := jsonb_set(
          calendar_data,
          '{2025-04,busy_slots}'::text[],
          COALESCE(calendar_data->'2025-04'->'busy_slots', '{}'::jsonb) || 
          jsonb_build_object(
            date_str,
            jsonb_build_array(consultation_hours)
          )
        );
        
        -- Update the advisor's calendar
        UPDATE scientific_advisors
        SET 
          calendar = calendar_data,
          updated_at = NOW()
        WHERE id = advisor.id;
      END IF;
    END IF;
  END LOOP;
END $$;