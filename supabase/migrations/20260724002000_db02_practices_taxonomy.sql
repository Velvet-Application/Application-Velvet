begin;

create type public.taxonomy_item_kind as enum (
  'practice',
  'intention',
  'relationship_style',
  'venue_preference',
  'communication_style'
);

create type public.preference_level as enum (
  'not_for_me',
  'curious',
  'interested',
  'desired',
  'experienced'
);

create type public.boundary_level as enum (
  'hard_limit',
  'soft_limit',
  'conditional',
  'open',
  'enthusiastic'
);

create table public.taxonomy_items (
  id uuid primary key default extensions.gen_random_uuid(),
  kind public.taxonomy_item_kind not null,
  code extensions.citext not null,
  label_fr text not null,
  description_fr text,
  parent_id uuid references public.taxonomy_items(id) on delete restrict,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  is_sensitive boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint taxonomy_items_code_format check (code::text ~ '^[a-z0-9][a-z0-9_.-]{2,79}$'),
  constraint taxonomy_items_label_not_blank check (length(trim(label_fr)) between 2 and 120),
  constraint taxonomy_items_parent_not_self check (parent_id is null or parent_id <> id),
  constraint taxonomy_items_code_uq unique(kind, code)
);

create index taxonomy_items_kind_active_idx
  on public.taxonomy_items(kind, sort_order, label_fr)
  where is_active;

create trigger taxonomy_items_set_updated_at
before update on public.taxonomy_items
for each row execute function public.set_updated_at();

alter table public.taxonomy_items enable row level security;

create policy taxonomy_items_select_active
on public.taxonomy_items for select to authenticated
using (is_active);

revoke insert, update, delete on public.taxonomy_items from anon, authenticated;
grant select on public.taxonomy_items to authenticated;
grant all on public.taxonomy_items to service_role;

insert into public.taxonomy_items(kind, code, label_fr, description_fr, sort_order, is_sensitive)
values
  ('intention','discover','Découvrir','Découvrir le milieu et avancer progressivement.',10,false),
  ('intention','meet_couples','Rencontrer des couples','Faire connaissance avec des profils couple.',20,false),
  ('intention','meet_women','Rencontrer des femmes','Faire connaissance avec des femmes seules.',30,false),
  ('intention','meet_men','Rencontrer des hommes','Faire connaissance avec des hommes seuls.',40,false),
  ('intention','events','Participer à des événements','Sorties, clubs, spas, voyages ou soirées privées.',50,false),
  ('relationship_style','occasional','Occasionnel','Rencontres ponctuelles selon les disponibilités et le feeling.',10,false),
  ('relationship_style','regular','Suivi','Créer des liens suivis avec des personnes de confiance.',20,false),
  ('relationship_style','friends_first','Connexion avant tout','Privilégier la discussion, la confiance et l’alchimie.',30,false),
  ('venue_preference','private_evening','Soirée privée','Rencontre dans un cadre privé et maîtrisé.',10,false),
  ('venue_preference','club','Club','Sortie dans un club libertin.',20,false),
  ('venue_preference','spa','Spa','Sortie dans un spa libertin.',30,false),
  ('venue_preference','travel','Voyage','Week-end ou voyage communautaire.',40,false),
  ('communication_style','conversation_first','Discussion préalable','Échanger suffisamment avant toute rencontre.',10,false),
  ('communication_style','face_required','Visage visible','Mettre un visage sur un profil avant d’aller plus loin.',20,true),
  ('communication_style','slow_pace','Rythme progressif','Laisser la relation évoluer sans pression.',30,false);

commit;
