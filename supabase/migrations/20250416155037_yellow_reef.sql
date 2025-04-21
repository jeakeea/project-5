/*
  # Add test scientific advisors

  1. Data Population
    - Adds 10 scientific advisors with diverse research fields
    - Each advisor has:
      - Last name
      - Research field
      - Student limits (bachelors, masters, PhD)
      - Contact information (email, phone)
      - Office hours
*/

INSERT INTO scientific_advisors (last_name, research_field, bachelors_limit, masters_limit, phd_limit, email, phone, office_hours)
VALUES
  ('Петров', 'Искусственный интеллект и машинное обучение', 3, 2, 1, 'petrov@urfu.ru', '+7(900)000-00-01', '{"monday": "14:00-16:00", "wednesday": "10:00-12:00"}'::jsonb),
  ('Иванова', 'Компьютерное зрение и обработка изображений', 2, 2, 1, 'ivanova@urfu.ru', '+7(900)000-00-02', '{"tuesday": "15:00-17:00", "thursday": "11:00-13:00"}'::jsonb),
  ('Сидоров', 'Информационная безопасность', 4, 2, 1, 'sidorov@urfu.ru', '+7(900)000-00-03', '{"monday": "11:00-13:00", "friday": "14:00-16:00"}'::jsonb),
  ('Козлова', 'Анализ данных и большие данные', 3, 2, 2, 'kozlova@urfu.ru', '+7(900)000-00-04', '{"wednesday": "13:00-15:00", "friday": "10:00-12:00"}'::jsonb),
  ('Морозов', 'Робототехника и автоматизация', 2, 3, 1, 'morozov@urfu.ru', '+7(900)000-00-05', '{"tuesday": "10:00-12:00", "thursday": "15:00-17:00"}'::jsonb),
  ('Волкова', 'Программная инженерия', 4, 2, 1, 'volkova@urfu.ru', '+7(900)000-00-06', '{"monday": "15:00-17:00", "wednesday": "11:00-13:00"}'::jsonb),
  ('Соколов', 'Сетевые технологии и телекоммуникации', 3, 2, 1, 'sokolov@urfu.ru', '+7(900)000-00-07', '{"tuesday": "13:00-15:00", "thursday": "10:00-12:00"}'::jsonb),
  ('Попова', 'Веб-технологии и распределенные системы', 3, 2, 1, 'popova@urfu.ru', '+7(900)000-00-08', '{"wednesday": "15:00-17:00", "friday": "11:00-13:00"}'::jsonb),
  ('Лебедев', 'Квантовые вычисления', 2, 2, 2, 'lebedev@urfu.ru', '+7(900)000-00-09', '{"monday": "10:00-12:00", "thursday": "14:00-16:00"}'::jsonb),
  ('Кузнецова', 'Биоинформатика', 3, 2, 1, 'kuznetsova@urfu.ru', '+7(900)000-00-10', '{"tuesday": "11:00-13:00", "friday": "15:00-17:00"}'::jsonb);