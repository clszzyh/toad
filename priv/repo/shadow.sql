CREATE SCHEMA IF NOT EXISTS shadow;

CREATE OR REPLACE FUNCTION shadow.versioning()
    RETURNS TRIGGER AS $$
    DECLARE
    target_table text;
    BEGIN
    target_table := TG_ARGV[0];
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    EXECUTE ('INSERT INTO public.history' ||
      '(pk, table_name, op, query, inserted_at, app_session_user_id, data)' ||
      'VALUES ($1.id, $2, $3, $4, $5, $6, to_jsonb($1))')
      USING OLD, target_table, LEFT(TG_OP, 1), current_query(), current_timestamp, current_setting('app.session_user_id', true)::text;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION shadow.setup_jsonb(
    target_table text
    ) RETURNS void AS $T1$
    DECLARE
    create_trigger text;
    BEGIN
    create_trigger := 'CREATE TRIGGER zzz_%s_shadow_trigger
      BEFORE UPDATE OR DELETE ON %s
      FOR EACH ROW EXECUTE PROCEDURE shadow.versioning(''%I'')';
    create_trigger := FORMAT(
      create_trigger,
      target_table,
      target_table,
      target_table
    );
    RAISE INFO 'EXECUTE SQL: %', create_trigger;
    EXECUTE(create_trigger);
END
$T1$ LANGUAGE plpgsql SECURITY DEFINER;
