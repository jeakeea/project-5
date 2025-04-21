/*
  # Scientific Advisors Database Schema

  1. New Tables
    - `scientific_advisors`
      - `id` (uuid, primary key)
      - `last_name` (text) - Фамилия
      - `research_field` (text) - Сфера научных исследований
      - `bachelors_limit` (int) - Лимит студентов-бакалавров
      - `masters_limit` (int) - Лимит магистрантов
      - `phd_limit` (int) - Лимит аспирантов
      - `email` (text) - Email
      - `phone` (text) - Телефон
      - `office_hours` (jsonb) - Календарь консультаций
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on scientific_advisors table
    - Add policies for read access
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'scientific_advisors'
  ) THEN
    CREATE TABLE scientific_advisors (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      last_name text NOT NULL,
      research_field text NOT NULL,
      bachelors_limit integer DEFAULT 0,
      masters_limit integer DEFAULT 0,
      phd_limit integer DEFAULT 0,
      email text,
      phone text,
      office_hours jsonb DEFAULT '{}',
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    ALTER TABLE scientific_advisors ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Allow public read access to scientific_advisors"
      ON scientific_advisors
      FOR SELECT
      TO PUBLIC
      USING (true);

    CREATE POLICY "Allow authenticated users to manage scientific_advisors"
      ON scientific_advisors
      FOR ALL
      TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;