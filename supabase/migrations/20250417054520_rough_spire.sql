/*
  # Insert sample scientific advisors

  This migration adds sample data to the scientific_advisors table
*/

INSERT INTO scientific_advisors (
  last_name,
  research_field,
  bachelors_limit,
  masters_limit,
  phd_limit,
  email,
  phone,
  office_hours
) VALUES 
(
  'Козлова',
  'Анализ данных и большие данные',
  3,
  2,
  2,
  'kozlova@urfu.ru',
  '+7(900)000-00-04',
  '{
    "friday": "10:00-12:00",
    "wednesday": "13:00-15:00"
  }'
);