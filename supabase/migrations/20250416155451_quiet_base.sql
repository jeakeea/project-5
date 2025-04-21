/*
  # Add calendar field to scientific advisors

  1. Schema Changes
    - Add calendar field to store advisor's schedule and availability
    - Calendar stored as JSONB to allow flexible scheduling data
    - Update existing records with sample calendar data

  2. Data Structure
    Calendar format:
    {
      "2025-04": {
        "available_days": [1, 2, 3, 15, 16, 17],
        "busy_slots": {
          "2025-04-01": ["10:00-12:00"],
          "2025-04-02": ["14:00-16:00"]
        }
      }
    }
*/

-- Add calendar column
ALTER TABLE scientific_advisors 
ADD COLUMN IF NOT EXISTS calendar jsonb DEFAULT '{}'::jsonb;

-- Update existing records with sample calendar data
UPDATE scientific_advisors
SET calendar = json_build_object(
  '2025-04', json_build_object(
    'available_days', ARRAY[1, 2, 3, 15, 16, 17, 22, 23, 24, 29, 30],
    'busy_slots', json_build_object(
      '2025-04-01', ARRAY['10:00-12:00'],
      '2025-04-02', ARRAY['14:00-16:00'],
      '2025-04-15', ARRAY['11:00-13:00'],
      '2025-04-16', ARRAY['15:00-17:00']
    )
  ),
  '2025-05', json_build_object(
    'available_days', ARRAY[1, 2, 3, 13, 14, 15, 20, 21, 22, 27, 28, 29],
    'busy_slots', json_build_object(
      '2025-05-01', ARRAY['09:00-11:00'],
      '2025-05-02', ARRAY['15:00-17:00'],
      '2025-05-13', ARRAY['10:00-12:00'],
      '2025-05-14', ARRAY['14:00-16:00']
    )
  )
)
WHERE calendar IS NULL OR calendar = '{}'::jsonb;