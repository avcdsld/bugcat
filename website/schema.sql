CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts INTEGER NOT NULL,        -- epoch ms (server)
  session TEXT,               -- ephemeral per-page-load id (not persisted on device)
  type TEXT NOT NULL,         -- page_view | tab | remember | caress | help | lang
  cat INTEGER,                -- 0..4 or NULL
  country TEXT,               -- Cloudflare cf.country (coarse)
  device TEXT,                -- mobile | tablet | desktop
  lang TEXT,                  -- ja | en
  path TEXT,
  ref TEXT                    -- referrer host only (no full URL)
);
CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
