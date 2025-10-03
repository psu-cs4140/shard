defmodule Shard.Repo.Migrations.AlignRoomsColumns do
  use Ecto.Migration

  def up do
    execute """
    DO $$
    BEGIN
      -- rename x -> x_coordinate if present
      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='x') THEN
        ALTER TABLE rooms RENAME COLUMN x TO x_coordinate;
      END IF;

      -- rename y -> y_coordinate if present
      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='y') THEN
        ALTER TABLE rooms RENAME COLUMN y TO y_coordinate;
      END IF;

      -- add z_coordinate if missing
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                     WHERE table_name='rooms' AND column_name='z_coordinate') THEN
        ALTER TABLE rooms ADD COLUMN z_coordinate integer NOT NULL DEFAULT 0;
      END IF;

      -- add is_public if missing
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                     WHERE table_name='rooms' AND column_name='is_public') THEN
        ALTER TABLE rooms ADD COLUMN is_public boolean NOT NULL DEFAULT true;
      END IF;

      -- add room_type if missing
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                     WHERE table_name='rooms' AND column_name='room_type') THEN
        ALTER TABLE rooms ADD COLUMN room_type varchar NOT NULL DEFAULT 'standard';
      END IF;

      -- add properties if missing
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                     WHERE table_name='rooms' AND column_name='properties') THEN
        ALTER TABLE rooms ADD COLUMN properties jsonb NOT NULL DEFAULT '{}'::jsonb;
      END IF;
    END $$;
    """
  end

  def down do
    execute """
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='x_coordinate') THEN
        ALTER TABLE rooms RENAME COLUMN x_coordinate TO x;
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='y_coordinate') THEN
        ALTER TABLE rooms RENAME COLUMN y_coordinate TO y;
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='z_coordinate') THEN
        ALTER TABLE rooms DROP COLUMN z_coordinate;
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='is_public') THEN
        ALTER TABLE rooms DROP COLUMN is_public;
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='room_type') THEN
        ALTER TABLE rooms DROP COLUMN room_type;
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='rooms' AND column_name='properties') THEN
        ALTER TABLE rooms DROP COLUMN properties;
      END IF;
    END $$;
    """
  end
end
