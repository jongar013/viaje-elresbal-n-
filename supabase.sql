-- Pega todo esto en Supabase > SQL Editor > New query y dale a "Run".
-- ANTES cambia 'CAMBIA-ESTE-PIN' (abajo) por tu PIN de administrador.

create table if not exists votos (
  id text primary key,
  nombre text not null check (char_length(nombre) between 1 and 30),
  favs int[] not null default '{}',
  updated_at timestamptz default now()
);
alter table votos enable row level security;
create policy "todos leen votos" on votos for select using (true);
create policy "todos crean su registro" on votos for insert with check (true);
create policy "todos editan su registro" on votos for update using (true) with check (true);

create table if not exists quitadas (id text primary key, ids int[] not null default '{}');
alter table quitadas enable row level security;
create policy "todos leen quitadas" on quitadas for select using (true);
insert into quitadas (id, ids) values ('lista', '{}') on conflict do nothing;

create table if not exists admin_cfg (pin text not null);
alter table admin_cfg enable row level security;   -- sin políticas: nadie puede leer el PIN
insert into admin_cfg (pin) values ('CAMBIA-ESTE-PIN');

create or replace function es_admin(p text) returns boolean
language sql security definer set search_path = public as $$
  select exists (select 1 from admin_cfg where pin = p)
$$;

create or replace function set_quitadas(p text, nuevos int[]) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not es_admin(p) then raise exception 'no autorizado'; end if;
  update quitadas set ids = nuevos where id = 'lista';
end $$;

grant execute on function es_admin(text) to anon;
grant execute on function set_quitadas(text, int[]) to anon;

alter publication supabase_realtime add table votos, quitadas;
