/*
  # Add Default Product Settings

  1. New Settings
    - Default unit type and custom unit settings
    - Price range settings for each tier
    - Price visibility settings
    
  2. Changes
    - Insert default values for all settings
    - Ensure settings exist for proper UI functionality
*/

-- Insert default unit settings if they don't exist
INSERT INTO product_settings (setting_type, setting_key, setting_value, is_encrypted)
VALUES
  ('units', 'default_unit_type', 'unidades', false),
  ('units', 'custom_unit_type', '', false)
ON CONFLICT (setting_type, setting_key) DO NOTHING;

-- Insert default price range settings if they don't exist
INSERT INTO product_settings (setting_type, setting_key, setting_value, is_encrypted)
VALUES
  -- Price 2 settings
  ('prices', 'price_2_from', '100', false),
  ('prices', 'price_2_to', '499', false),
  ('prices', 'show_price_2', 'true', false),
  
  -- Price 3 settings
  ('prices', 'price_3_from', '500', false),
  ('prices', 'price_3_to', '999', false),
  ('prices', 'show_price_3', 'true', false),
  
  -- Price 4 settings
  ('prices', 'price_4_from', '1000', false),
  ('prices', 'price_4_to', '', false),
  ('prices', 'show_price_4', 'true', false)
ON CONFLICT (setting_type, setting_key) DO NOTHING;

-- Create function to validate price ranges
CREATE OR REPLACE FUNCTION validate_price_range_settings()
RETURNS TRIGGER AS $$
BEGIN
  -- Only validate price range settings
  IF NEW.setting_type = 'prices' THEN
    -- Extract tier number from setting key
    DECLARE
      tier INTEGER;
      is_from BOOLEAN;
      value INTEGER;
    BEGIN
      -- Extract tier number and check if it's a "from" setting
      tier := (regexp_matches(NEW.setting_key, 'price_(\d+)_'))[1]::INTEGER;
      is_from := NEW.setting_key LIKE '%_from';
      value := NEW.setting_value::INTEGER;

      -- Skip validation for empty "to" values in price_4
      IF NEW.setting_key = 'price_4_to' AND NEW.setting_value = '' THEN
        RETURN NEW;
      END IF;

      -- Validate ranges
      IF is_from THEN
        -- Check against previous tier's "to" value
        IF tier > 2 THEN
          DECLARE
            prev_to INTEGER;
          BEGIN
            SELECT setting_value::INTEGER INTO prev_to
            FROM product_settings
            WHERE setting_type = 'prices'
              AND setting_key = 'price_' || (tier-1) || '_to';

            IF prev_to IS NOT NULL AND value <= prev_to THEN
              RAISE EXCEPTION 'Invalid range: from value must be greater than previous to value';
            END IF;
          END;
        END IF;
      ELSE
        -- Check against current tier's "from" value
        DECLARE
          curr_from INTEGER;
        BEGIN
          SELECT setting_value::INTEGER INTO curr_from
          FROM product_settings
          WHERE setting_type = 'prices'
            AND setting_key = 'price_' || tier || '_from';

          IF curr_from IS NOT NULL AND value <= curr_from THEN
            RAISE EXCEPTION 'Invalid range: to value must be greater than from value';
          END IF;
        END;

        -- Check against next tier's "from" value if not last tier
        IF tier < 4 THEN
          DECLARE
            next_from INTEGER;
          BEGIN
            SELECT setting_value::INTEGER INTO next_from
            FROM product_settings
            WHERE setting_type = 'prices'
              AND setting_key = 'price_' || (tier+1) || '_from';

            IF next_from IS NOT NULL AND value >= next_from THEN
              RAISE EXCEPTION 'Invalid range: to value must be less than next from value';
            END IF;
          END;
        END IF;
      END IF;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for price range validation
DROP TRIGGER IF EXISTS validate_price_range_settings_trigger ON product_settings;
CREATE TRIGGER validate_price_range_settings_trigger
  BEFORE UPDATE OF setting_value ON product_settings
  FOR EACH ROW
  WHEN (NEW.setting_type = 'prices')
  EXECUTE FUNCTION validate_price_range_settings();