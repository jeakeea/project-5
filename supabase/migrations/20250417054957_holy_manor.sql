/*
  # Setup initial calendar for April 2025
  
  This migration initializes the calendar for each advisor with:
  1. Available days based on their consultation schedule
  2. Initial busy slots
*/

-- First, set up available days
DO $$
DECLARE
  advisor RECORD;
  calendar_data JSONB;
  office_hours JSONB;
  available_days INT[];
  day_date DATE;
  day_of_week TEXT;
BEGIN
  FOR advisor IN SELECT * FROM scientific_advisors
  LOOP
    calendar_data := '{"2025-04": {"available_days": [], "busy_slots": {}}}'::JSONB;
    office_hours := advisor.office_hours;
    available_days := ARRAY[]::INT[];

    FOR day IN 1..30 LOOP
      day_date := DATE '2025-04-01' + (day - 1);
      day_of_week := LOWER(TRIM(TO_CHAR(day_date, 'day')));

      IF office_hours ? day_of_week THEN
        available_days := array_append(available_days, day);
      END IF;
    END LOOP;

    calendar_data := jsonb_set(
      calendar_data,
      '{2025-04,available_days}',
      to_jsonb(available_days)
    );

    UPDATE scientific_advisors
    SET 
      calendar = calendar_data,
      updated_at = NOW()
    WHERE id = advisor.id;
  END LOOP;
END $$;

-- Then, add initial busy slots
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
  FOR advisor IN SELECT * FROM scientific_advisors
  LOOP
    calendar_data := advisor.calendar;
    office_hours := advisor.office_hours;
    
    WITH days AS (
      SELECT jsonb_array_elements_text((calendar_data->'2025-04'->'available_days'))::int AS day
    )
    SELECT array_agg(day ORDER BY day) INTO available_days FROM days;
    
    IF array_length(available_days, 1) > 0 THEN
      first_available_day := available_days[1];
      day_date := DATE '2025-04-01' + (first_available_day - 1);
      day_of_week := LOWER(TRIM(TO_CHAR(day_date, 'day')));
      
      consultation_hours := office_hours->>day_of_week;
      
      IF consultation_hours IS NOT NULL THEN
        date_str := '2025-04-' || LPAD(first_available_day::text, 2, '0');
        
        calendar_data := jsonb_set(
          calendar_data,
          '{2025-04,busy_slots}'::text[],
          COALESCE(calendar_data->'2025-04'->'busy_slots', '{}'::jsonb) || 
          jsonb_build_object(
            date_str,
            jsonb_build_array(consultation_hours)
          )
        );
        
        UPDATE scientific_advisors
        SET 
          calendar = calendar_data,
          updated_at = NOW()
        WHERE id = advisor.id;
      END IF;
    END IF;
  END LOOP;
END $$;