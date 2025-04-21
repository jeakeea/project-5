/*
  # Create scientific advisors table and policies

  1. New Tables
    - `scientific_advisors`
      - `id` (uuid, primary key)
      - `last_name` (text, not null)
      - `research_field` (text, not null)
      - `bachelors_limit` (integer, default 0)
      - `masters_limit` (integer, default 0)
      - `phd_limit` (integer, default 0)
      - `email` (text)
      - `phone` (text)
      - `office_hours` (jsonb, default '{}')
      - `calendar` (jsonb, default '{}')
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Security
    - Enable RLS on `scientific_advisors` table
    - Add policy for public read access
    - Add policy for authenticated users to manage advisors
*/

-- Create the scientific_advisors table
CREATE TABLE IF NOT EXISTS scientific_advisors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  last_name text NOT NULL,
  research_field text NOT NULL,
  bachelors_limit integer DEFAULT 0,
  masters_limit integer DEFAULT 0,
  phd_limit integer DEFAULT 0,
  email text,
  phone text,
  office_hours jsonb DEFAULT '{}'::jsonb,
  calendar jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE scientific_advisors ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public read access to scientific_advisors"
  ON scientific_advisors
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow authenticated users to manage scientific_advisors"
  ON scientific_advisors
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);