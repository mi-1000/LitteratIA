-- 16/04/2026
-- Align post-rating labels with exact English keys.

DO $$
BEGIN
    -- exactitude -> correct
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'exactitude') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'correct') THEN
            EXECUTE 'UPDATE reactions SET correct = COALESCE(correct, FALSE) OR COALESCE(exactitude, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN exactitude';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN exactitude TO correct';
        END IF;
    END IF;

    -- pertinence -> relevant
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'pertinence') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'relevant') THEN
            EXECUTE 'UPDATE reactions SET relevant = COALESCE(relevant, FALSE) OR COALESCE(pertinence, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN pertinence';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN pertinence TO relevant';
        END IF;
    END IF;

    -- exhaustivite -> complete
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'exhaustivite') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'complete') THEN
            EXECUTE 'UPDATE reactions SET complete = COALESCE(complete, FALSE) OR COALESCE(exhaustivite, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN exhaustivite';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN exhaustivite TO complete';
        END IF;
    END IF;

    -- concision -> concise
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'concision') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'concise') THEN
            EXECUTE 'UPDATE reactions SET concise = COALESCE(concise, FALSE) OR COALESCE(concision, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN concision';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN concision TO concise';
        END IF;
    END IF;

    -- accompagnement -> guiding
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'accompagnement') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'guiding') THEN
            EXECUTE 'UPDATE reactions SET guiding = COALESCE(guiding, FALSE) OR COALESCE(accompagnement, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN accompagnement';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN accompagnement TO guiding';
        END IF;
    END IF;

    -- aide_reflexion -> scaffolding
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'aide_reflexion') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'scaffolding') THEN
            EXECUTE 'UPDATE reactions SET scaffolding = COALESCE(scaffolding, FALSE) OR COALESCE(aide_reflexion, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN aide_reflexion';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN aide_reflexion TO scaffolding';
        END IF;
    END IF;

    -- actionnabilite -> actionable
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'actionnabilite') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'actionable') THEN
            EXECUTE 'UPDATE reactions SET actionable = COALESCE(actionable, FALSE) OR COALESCE(actionnabilite, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN actionnabilite';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN actionnabilite TO actionable';
        END IF;
    END IF;

    -- langue_niveau -> understandable
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'langue_niveau') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'understandable') THEN
            EXECUTE 'UPDATE reactions SET understandable = COALESCE(understandable, FALSE) OR COALESCE(langue_niveau, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN langue_niveau';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN langue_niveau TO understandable';
        END IF;
    END IF;

    -- empathie -> empathetic
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'empathie') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'empathetic') THEN
            EXECUTE 'UPDATE reactions SET empathetic = COALESCE(empathetic, FALSE) OR COALESCE(empathie, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN empathie';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN empathie TO empathetic';
        END IF;
    END IF;

    -- engagement -> engaging
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'engagement') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'engaging') THEN
            EXECUTE 'UPDATE reactions SET engaging = COALESCE(engaging, FALSE) OR COALESCE(engagement, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN engagement';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN engagement TO engaging';
        END IF;
    END IF;

    -- authenticite -> anthropomorphic
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'authenticite') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'anthropomorphic') THEN
            EXECUTE 'UPDATE reactions SET anthropomorphic = COALESCE(anthropomorphic, FALSE) OR COALESCE(authenticite, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN authenticite';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN authenticite TO anthropomorphic';
        END IF;
    END IF;

    -- coherence -> coherent
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'coherence') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'coherent') THEN
            EXECUTE 'UPDATE reactions SET coherent = COALESCE(coherent, FALSE) OR COALESCE(coherence, FALSE)';
            EXECUTE 'ALTER TABLE reactions DROP COLUMN coherence';
        ELSE
            EXECUTE 'ALTER TABLE reactions RENAME COLUMN coherence TO coherent';
        END IF;
    END IF;
END $$;

ALTER TABLE reactions
    ADD COLUMN IF NOT EXISTS relevant BOOLEAN,
    ADD COLUMN IF NOT EXISTS concise BOOLEAN,
    ADD COLUMN IF NOT EXISTS complete BOOLEAN,
    ADD COLUMN IF NOT EXISTS correct BOOLEAN,
    ADD COLUMN IF NOT EXISTS guiding BOOLEAN,
    ADD COLUMN IF NOT EXISTS scaffolding BOOLEAN,
    ADD COLUMN IF NOT EXISTS actionable BOOLEAN,
    ADD COLUMN IF NOT EXISTS understandable BOOLEAN,
    ADD COLUMN IF NOT EXISTS empathetic BOOLEAN,
    ADD COLUMN IF NOT EXISTS engaging BOOLEAN,
    ADD COLUMN IF NOT EXISTS anthropomorphic BOOLEAN,
    ADD COLUMN IF NOT EXISTS coherent BOOLEAN;

DO $$
BEGIN
    -- Legacy mapping: useful -> relevant
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reactions' AND column_name = 'useful') THEN
        EXECUTE 'UPDATE reactions SET relevant = COALESCE(relevant, FALSE) OR COALESCE(useful, FALSE)';
    END IF;
END $$;

ALTER TABLE reactions
    DROP COLUMN IF EXISTS useful,
    DROP COLUMN IF EXISTS creative,
    DROP COLUMN IF EXISTS clear_formatting,
    DROP COLUMN IF EXISTS incorrect,
    DROP COLUMN IF EXISTS superficial,
    DROP COLUMN IF EXISTS instructions_not_followed;
