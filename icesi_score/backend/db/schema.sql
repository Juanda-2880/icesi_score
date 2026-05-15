-- IcesiScore PostgreSQL Schema
-- Run: psql -h <RDS_ENDPOINT> -U icesi_admin -d icesi_score -f schema.sql

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- 1. ENUMs
-- ---------------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('NORMAL', 'ADMIN', 'SUPERADMIN');
CREATE TYPE sport_type AS ENUM ('FOOTBALL', 'VOLLEYBALL');
CREATE TYPE match_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'FINISHED');
CREATE TYPE lineup_status AS ENUM ('STARTER', 'SUBSTITUTE', 'ON_FIELD', 'ON_BENCH', 'EXPELLED');
CREATE TYPE soccer_event_type AS ENUM ('GOAL', 'ASSIST', 'YELLOW_CARD', 'RED_CARD', 'SUBSTITUTION', 'NOTE');
CREATE TYPE volleyball_event_type AS ENUM ('POINT', 'SERVICE_ACE', 'BLOCK', 'ROTATION_FAULT', 'SUBSTITUTION', 'NOTE');

-- ---------------------------------------------------------------------------
-- 2. Tables
-- ---------------------------------------------------------------------------

-- app_users (renamed from 'user' to avoid reserved word conflict)
CREATE TABLE app_users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name     VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    phone         VARCHAR(50),
    university    VARCHAR(255),
    role          user_role NOT NULL DEFAULT 'NORMAL'
);

CREATE TABLE league (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL
);

CREATE TABLE team (
    id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name  VARCHAR(255) NOT NULL,
    sport sport_type NOT NULL
);

CREATE TABLE player (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id           UUID NOT NULL REFERENCES team(id) ON DELETE RESTRICT,
    full_name         VARCHAR(255) NOT NULL,
    standard_position VARCHAR(100),
    jersey_number     INT NOT NULL
);

CREATE TABLE match (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    league_id        UUID NOT NULL REFERENCES league(id) ON DELETE RESTRICT,
    sport            sport_type NOT NULL,
    home_team_id     UUID NOT NULL REFERENCES team(id) ON DELETE RESTRICT,
    away_team_id     UUID NOT NULL REFERENCES team(id) ON DELETE RESTRICT,
    id_admin_creator UUID NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
    match_date       DATE,
    match_time       TIME,
    venue            VARCHAR(255),
    status           match_status NOT NULL DEFAULT 'SCHEDULED',
    home_score       INT NOT NULL DEFAULT 0,
    away_score       INT NOT NULL DEFAULT 0,
    notes            TEXT
);

CREATE TABLE match_lineup (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id            UUID NOT NULL REFERENCES match(id) ON DELETE RESTRICT,
    player_id           UUID NOT NULL REFERENCES player(id) ON DELETE RESTRICT,
    status              lineup_status NOT NULL,
    position_coordinate VARCHAR(50)
);

CREATE TABLE match_period (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_match     UUID NOT NULL REFERENCES match(id) ON DELETE RESTRICT,
    period_label VARCHAR(50) NOT NULL,
    start_time   TIMESTAMP NOT NULL,
    end_time     TIMESTAMP
);

CREATE TABLE soccer_event (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id            UUID NOT NULL REFERENCES match(id) ON DELETE RESTRICT,
    id_admin_registry   UUID NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
    event_type          soccer_event_type NOT NULL,
    main_player_id      UUID NOT NULL REFERENCES player(id) ON DELETE RESTRICT,
    secondary_player_id UUID REFERENCES player(id) ON DELETE RESTRICT,
    event_minute        INT,
    id_parent_event     UUID REFERENCES soccer_event(id) ON DELETE RESTRICT,
    note                TEXT
);

CREATE TABLE volleyball_set (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id            UUID NOT NULL REFERENCES match(id) ON DELETE RESTRICT,
    id_admin_registry   UUID NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
    set_number          INT NOT NULL,
    current_home_score  INT NOT NULL DEFAULT 0,
    current_away_score  INT NOT NULL DEFAULT 0,
    start_time          TIMESTAMP NOT NULL,
    end_time            TIMESTAMP
);

CREATE TABLE volleyball_event (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    set_id              UUID NOT NULL REFERENCES volleyball_set(id) ON DELETE RESTRICT,
    id_admin_registry   UUID NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
    event_type          volleyball_event_type NOT NULL,
    main_player_id      UUID REFERENCES player(id) ON DELETE RESTRICT,
    secondary_player_id UUID REFERENCES player(id) ON DELETE RESTRICT,
    id_team             UUID NOT NULL REFERENCES team(id) ON DELETE RESTRICT,
    event_timestamp     TIMESTAMP NOT NULL DEFAULT NOW(),
    score_moment        VARCHAR(20)
);

-- ---------------------------------------------------------------------------
-- 3. Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_match_status        ON match(status);
CREATE INDEX idx_soccer_event_match  ON soccer_event(match_id);
CREATE INDEX idx_volleyball_event_set ON volleyball_event(set_id);
CREATE INDEX idx_match_lineup_match  ON match_lineup(match_id);
