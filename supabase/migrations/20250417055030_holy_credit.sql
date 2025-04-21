/*
  # Create scientific advisors table and policies (if not exist)

  This migration creates the scientific_advisors table and its policies
  only if they don't already exist.
*/

-- Create the scientific_advisors table if it doesn't exist
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

-- Enable Row Level Security if not already enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename = 'scientific_advisors'
      AND rowsecurity = true
  ) THEN
    ALTER TABLE scientific_advisors ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Create policies if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'scientific_advisors' 
    AND policyname = 'Allow public read access to scientific_advisors'
  ) THEN
    CREATE POLICY "Allow public read access to scientific_advisors"
      ON scientific_advisors
      FOR SELECT
      TO public
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'scientific_advisors' 
    AND policyname = 'Allow authenticated users to manage scientific_advisors'
  ) THEN
    CREATE POLICY "Allow authenticated users to manage scientific_advisors"
      ON scientific_advisors
      FOR ALL
      TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;