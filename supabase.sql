-- Run once in Supabase SQL Editor. Never put a service_role key in the browser.
create table if not exists public.reading_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.reading_snapshots enable row level security;
revoke all on public.reading_snapshots from anon;
grant select on public.reading_snapshots to authenticated;
create policy "Users read own snapshots" on public.reading_snapshots
  for select to authenticated using ((select auth.uid())=user_id);
create or replace function public.update_reading_snapshot(expected_revision bigint, new_payload jsonb)
returns bigint language plpgsql security definer set search_path = '' as $$
declare result_revision bigint;
begin
 if auth.uid() is null then raise exception 'Not signed in'; end if;
 if jsonb_typeof(new_payload) is distinct from 'object' then raise exception 'Invalid payload'; end if;
 if pg_column_size(new_payload)>5000000 then raise exception 'Snapshot too large (5 MB max)'; end if;
 insert into public.reading_snapshots(user_id, revision, payload, updated_at)
 select auth.uid(), 1, new_payload, now() where expected_revision=0
 on conflict(user_id) do update set
   revision=public.reading_snapshots.revision+1,
   payload=excluded.payload,
   updated_at=now()
 where public.reading_snapshots.revision=expected_revision
 returning revision into result_revision;
 if result_revision is null then raise exception 'SYNC_CONFLICT: remote revision changed'; end if;
 return result_revision;
end $$;
revoke all on function public.update_reading_snapshot(bigint,jsonb) from public,anon;
grant execute on function public.update_reading_snapshot(bigint,jsonb) to authenticated;
