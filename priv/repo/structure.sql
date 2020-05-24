--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
-- Dumped by pg_dump version 12.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: shadow; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA shadow;


--
-- Name: oban_job_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oban_job_state AS ENUM (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded'
);


--
-- Name: oban_jobs_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.oban_jobs_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  channel text;
  notice json;
BEGIN
  IF NEW.state = 'available' THEN
    channel = 'public.oban_insert';
    notice = json_build_object('queue', NEW.queue, 'state', NEW.state);

    PERFORM pg_notify(channel, notice::text);
  END IF;

  RETURN NULL;
END;
$$;


--
-- Name: setup_jsonb(text); Type: FUNCTION; Schema: shadow; Owner: -
--

CREATE FUNCTION shadow.setup_jsonb(target_table text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


--
-- Name: versioning(); Type: FUNCTION; Schema: shadow; Owner: -
--

CREATE FUNCTION shadow.versioning() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
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
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: apis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apis (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    version integer NOT NULL,
    url character varying(255) NOT NULL,
    state integer NOT NULL,
    kind integer NOT NULL,
    env_id integer,
    "group" character varying(255),
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    pipes jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    methods jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    payload jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: apis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.apis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: apis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.apis_id_seq OWNED BY public.apis.id;


--
-- Name: bindings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bindings (
    id bigint NOT NULL,
    context jsonb[],
    payload json,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bindings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bindings_id_seq OWNED BY public.bindings.id;


--
-- Name: environments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.environments (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: environments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: environments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.environments_id_seq OWNED BY public.environments.id;


--
-- Name: errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.errors (
    id bigint NOT NULL,
    kind integer NOT NULL,
    type integer NOT NULL,
    reason text,
    eid bigint,
    context jsonb[],
    stacktrace jsonb[],
    format_blamed text,
    payload json,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.errors_id_seq OWNED BY public.errors.id;


--
-- Name: history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history (
    id bigint NOT NULL,
    pk bigint NOT NULL,
    table_name character varying(255) NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    op character varying(1),
    query character varying,
    app_session_user_id character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.history_id_seq OWNED BY public.history.id;


--
-- Name: oban_beats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_beats (
    node text NOT NULL,
    queue text NOT NULL,
    nonce text NOT NULL,
    "limit" integer NOT NULL,
    paused boolean DEFAULT false NOT NULL,
    running bigint[] DEFAULT ARRAY[]::integer[] NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    started_at timestamp without time zone NOT NULL
);


--
-- Name: oban_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_jobs (
    id bigint NOT NULL,
    state public.oban_job_state DEFAULT 'available'::public.oban_job_state NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    worker text NOT NULL,
    args jsonb NOT NULL,
    errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    attempted_by text[],
    discarded_at timestamp without time zone,
    priority integer DEFAULT 0,
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    CONSTRAINT queue_length CHECK (((char_length(queue) > 0) AND (char_length(queue) < 128))),
    CONSTRAINT worker_length CHECK (((char_length(worker) > 0) AND (char_length(worker) < 128)))
);


--
-- Name: TABLE oban_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oban_jobs IS '8';


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oban_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oban_jobs_id_seq OWNED BY public.oban_jobs.id;


--
-- Name: proxys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proxys (
    id bigint NOT NULL,
    source character varying(255) NOT NULL,
    state integer NOT NULL,
    proxy character varying(255) NOT NULL,
    reason character varying(1000),
    timeout double precision,
    record_id bigint,
    job_id bigint,
    validated_at timestamp(0) without time zone,
    expired_at timestamp(0) without time zone,
    payload json,
    audit json,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: proxys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proxys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proxys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proxys_id_seq OWNED BY public.proxys.id;


--
-- Name: request_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_records (
    id bigint NOT NULL,
    source character varying(255) NOT NULL,
    state integer NOT NULL,
    content_type integer NOT NULL,
    url character varying(1000) NOT NULL,
    proxy character varying(255),
    version integer,
    attempt integer,
    result character varying(1000),
    timeout double precision,
    method integer NOT NULL,
    trace jsonb[] DEFAULT ARRAY[]::jsonb[],
    extra jsonb DEFAULT '{}'::jsonb,
    input jsonb,
    job_id bigint,
    proxy_id bigint,
    parent_id bigint,
    raw bytea,
    payload jsonb,
    history json,
    data text,
    target character varying(1000),
    api_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: request_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_records_id_seq OWNED BY public.request_records.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variables (
    id bigint NOT NULL,
    env character varying(255),
    key character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    "desc" character varying(255),
    payload jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.variables_id_seq OWNED BY public.variables.id;


--
-- Name: apis id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apis ALTER COLUMN id SET DEFAULT nextval('public.apis_id_seq'::regclass);


--
-- Name: bindings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bindings ALTER COLUMN id SET DEFAULT nextval('public.bindings_id_seq'::regclass);


--
-- Name: environments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments ALTER COLUMN id SET DEFAULT nextval('public.environments_id_seq'::regclass);


--
-- Name: errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.errors ALTER COLUMN id SET DEFAULT nextval('public.errors_id_seq'::regclass);


--
-- Name: history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history ALTER COLUMN id SET DEFAULT nextval('public.history_id_seq'::regclass);


--
-- Name: oban_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs ALTER COLUMN id SET DEFAULT nextval('public.oban_jobs_id_seq'::regclass);


--
-- Name: proxys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proxys ALTER COLUMN id SET DEFAULT nextval('public.proxys_id_seq'::regclass);


--
-- Name: request_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_records ALTER COLUMN id SET DEFAULT nextval('public.request_records_id_seq'::regclass);


--
-- Name: variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables ALTER COLUMN id SET DEFAULT nextval('public.variables_id_seq'::regclass);


--
-- Name: apis apis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apis
    ADD CONSTRAINT apis_pkey PRIMARY KEY (id);


--
-- Name: bindings bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bindings
    ADD CONSTRAINT bindings_pkey PRIMARY KEY (id);


--
-- Name: environments environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);


--
-- Name: errors errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.errors
    ADD CONSTRAINT errors_pkey PRIMARY KEY (id);


--
-- Name: history history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs oban_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs
    ADD CONSTRAINT oban_jobs_pkey PRIMARY KEY (id);


--
-- Name: proxys proxys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proxys
    ADD CONSTRAINT proxys_pkey PRIMARY KEY (id);


--
-- Name: request_records request_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_records
    ADD CONSTRAINT request_records_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: apis_name_version_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX apis_name_version_index ON public.apis USING btree (name, version);


--
-- Name: environments_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX environments_name_index ON public.environments USING btree (name);


--
-- Name: history_pk_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX history_pk_index ON public.history USING btree (pk);


--
-- Name: oban_beats_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_beats_inserted_at_index ON public.oban_beats USING btree (inserted_at);


--
-- Name: oban_jobs_attempted_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_attempted_at_id_index ON public.oban_jobs USING btree (attempted_at DESC, id) WHERE (state = ANY (ARRAY['completed'::public.oban_job_state, 'discarded'::public.oban_job_state]));


--
-- Name: oban_jobs_queue_state_priority_scheduled_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_queue_state_priority_scheduled_at_id_index ON public.oban_jobs USING btree (queue, state, priority, scheduled_at, id);


--
-- Name: request_records_job_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX request_records_job_id_index ON public.request_records USING btree (job_id);


--
-- Name: request_records_parent_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX request_records_parent_id_index ON public.request_records USING btree (parent_id);


--
-- Name: request_records_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX request_records_source_index ON public.request_records USING btree (source);


--
-- Name: variables_env_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX variables_env_key_index ON public.variables USING btree (env, key);


--
-- Name: oban_jobs oban_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER oban_notify AFTER INSERT ON public.oban_jobs FOR EACH ROW EXECUTE FUNCTION public.oban_jobs_notify();


--
-- Name: apis zzz_apis_shadow_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zzz_apis_shadow_trigger BEFORE DELETE OR UPDATE ON public.apis FOR EACH ROW EXECUTE FUNCTION shadow.versioning('apis');


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20200326090253);
INSERT INTO public."schema_migrations" (version) VALUES (20200515015751);
INSERT INTO public."schema_migrations" (version) VALUES (20200515042708);
