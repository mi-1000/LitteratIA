--
-- PostgreSQL database dump
--

\restrict O9qaKc9fxo12ujXTYjbqtcmqUcwhja8Z1aiDPfHa46euZpNuathApcLC1hge1OO

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13

-- Started on 2026-04-07 14:36:08 UTC

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

DROP DATABASE IF EXISTS litteratia;
--
-- TOC entry 3453 (class 1262 OID 16384)
-- Name: litteratia; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE litteratia WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


\unrestrict O9qaKc9fxo12ujXTYjbqtcmqUcwhja8Z1aiDPfHa46euZpNuathApcLC1hge1OO
\connect litteratia
\restrict O9qaKc9fxo12ujXTYjbqtcmqUcwhja8Z1aiDPfHa46euZpNuathApcLC1hge1OO

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16386)
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    model_a_name character varying(500),
    model_b_name character varying(500),
    conversation_a jsonb,
    conversation_b jsonb,
    conv_turns integer,
    system_prompt_a text,
    system_prompt_b text,
    conversation_pair_id character varying,
    conv_a_id character varying(500),
    conv_b_id character varying(500),
    session_hash character varying(255),
    visitor_id character varying(255),
    ip character(64),
    model_pair_name text,
    opening_msg text,
    selected_category character varying(255),
    is_unedited_prompt boolean,
    archived boolean DEFAULT false,
    mode character varying(255),
    custom_models_selection jsonb,
    short_summary text,
    keywords jsonb,
    categories jsonb,
    languages jsonb,
    pii_analyzed boolean DEFAULT false,
    contains_pii boolean,
    conversation_a_pii_removed jsonb,
    conversation_b_pii_removed jsonb,
    total_conv_a_output_tokens integer,
    total_conv_b_output_tokens integer,
    ip_map character varying(255),
    postprocess_failed boolean DEFAULT false,
    cohorts text,
    country_portal character varying(255),
    last_message_timestamp timestamp without time zone
);


--
-- TOC entry 215 (class 1259 OID 16385)
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3454 (class 0 OID 0)
-- Dependencies: 215
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- TOC entry 217 (class 1259 OID 16400)
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    level character varying(50) NOT NULL,
    message text NOT NULL,
    query_params jsonb,
    path_params jsonb,
    session_hash character varying(255),
    extra jsonb
);


--
-- TOC entry 219 (class 1259 OID 16406)
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    model_a_name character varying(500) NOT NULL,
    model_b_name character varying(500) NOT NULL,
    refers_to_model character varying(500),
    msg_index integer NOT NULL,
    opening_msg text NOT NULL,
    conversation_a jsonb NOT NULL,
    conversation_b jsonb NOT NULL,
    model_pos character varying(10),
    conv_turns integer NOT NULL,
    system_prompt text,
    conversation_pair_id character varying NOT NULL,
    conv_a_id character varying(500) NOT NULL,
    conv_b_id character varying(500) NOT NULL,
    refers_to_conv_id character varying(500) NOT NULL,
    session_hash character varying(255),
    visitor_id character varying(255),
    ip character(64),
    response_content text,
    question_content text,
    liked boolean,
    disliked boolean,
    comment text,
    useful boolean,
    complete boolean,
    creative boolean,
    clear_formatting boolean,
    incorrect boolean,
    superficial boolean,
    instructions_not_followed boolean,
    model_pair_name jsonb,
    msg_rank integer NOT NULL,
    chatbot_index integer NOT NULL,
    question_id character varying(500),
    archived boolean DEFAULT false,
    rating integer,
    correct boolean DEFAULT false,
    device_type character varying(20),
    interface_lang character varying(10),
    CONSTRAINT reactions_model_pos_check CHECK (((model_pos)::text = ANY ((ARRAY['a'::character varying, 'b'::character varying, 'both_equal'::character varying])::text[])))
);


--
-- TOC entry 218 (class 1259 OID 16405)
-- Name: reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3455 (class 0 OID 0)
-- Dependencies: 218
-- Name: reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;


--
-- TOC entry 221 (class 1259 OID 16420)
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    model_a_name character varying(500) NOT NULL,
    model_b_name character varying(500) NOT NULL,
    model_pair_name jsonb,
    chosen_model_name character varying(500),
    opening_msg text NOT NULL,
    both_equal boolean,
    conversation_a jsonb NOT NULL,
    conversation_b jsonb NOT NULL,
    conv_turns integer,
    system_prompt_a text,
    system_prompt_b text,
    selected_category character varying(255),
    is_unedited_prompt boolean,
    conversation_pair_id character varying NOT NULL,
    session_hash character varying(255),
    visitor_id character varying(255),
    ip character(64),
    conv_comments_a text,
    conv_comments_b text,
    conv_useful_a boolean,
    conv_useful_b boolean,
    conv_complete_a boolean,
    conv_complete_b boolean,
    conv_creative_a boolean,
    conv_creative_b boolean,
    conv_clear_formatting_a boolean,
    conv_clear_formatting_b boolean,
    conv_incorrect_a boolean,
    conv_incorrect_b boolean,
    conv_superficial_a boolean,
    conv_superficial_b boolean,
    conv_instructions_not_followed_a boolean,
    conv_instructions_not_followed_b boolean,
    archived boolean DEFAULT false
);


--
-- TOC entry 220 (class 1259 OID 16419)
-- Name: votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3456 (class 0 OID 0)
-- Dependencies: 220
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.votes_id_seq OWNED BY public.votes.id;


--
-- TOC entry 3281 (class 2604 OID 16389)
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- TOC entry 3287 (class 2604 OID 16409)
-- Name: reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions ALTER COLUMN id SET DEFAULT nextval('public.reactions_id_seq'::regclass);


--
-- TOC entry 3291 (class 2604 OID 16423)
-- Name: votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes ALTER COLUMN id SET DEFAULT nextval('public.votes_id_seq'::regclass);


--
-- TOC entry 3296 (class 2606 OID 16399)
-- Name: conversations conversations_conversation_pair_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_conversation_pair_id_key UNIQUE (conversation_pair_id);


--
-- TOC entry 3298 (class 2606 OID 16397)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 3300 (class 2606 OID 16416)
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- TOC entry 3302 (class 2606 OID 16418)
-- Name: reactions unique_conversation_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT unique_conversation_pair UNIQUE (refers_to_conv_id, msg_index);


--
-- TOC entry 3304 (class 2606 OID 16429)
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


-- Completed on 2026-04-07 14:36:08 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict O9qaKc9fxo12ujXTYjbqtcmqUcwhja8Z1aiDPfHa46euZpNuathApcLC1hge1OO

