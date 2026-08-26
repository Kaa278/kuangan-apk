create extension if not exists pgcrypto;

create table if not exists public.signup_otps (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  name text not null,
  token text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists signup_otps_email_idx on public.signup_otps(email);
