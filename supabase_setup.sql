-- ============================================================
-- TORNADO OPS — SUPABASE DATABASE SETUP
-- Run this entire file in Supabase → SQL Editor → New Query
-- ============================================================

-- USERS (app users, not Supabase auth)
create table if not exists users (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  username text unique not null,
  password text not null,
  role text not null check (role in ('manager','supervisor','supporter','coordinator')),
  color text default '#3b82f6',
  initials text,
  assigned_batch text,
  created_at timestamptz default now()
);

-- BATCHES
create table if not exists batches (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  batch_number int,
  dept text not null check (dept in ('Soccer','AMF')),
  day_current int default 1,
  week_current int default 1,
  trainees_count int default 0,
  start_date date,
  pass_threshold int default 70,
  supervisor_name text,
  health text default 'green' check (health in ('green','amber','red')),
  attendance_rate int default 0,
  pass_rate int,
  outlier_count int default 0,
  leaver_count int default 0,
  active boolean default true,
  created_at timestamptz default now()
);

-- TRAINEES
create table if not exists trainees (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  name text not null,
  national_id text,
  email text,
  phone text,
  interview_score numeric,
  performance text check (performance in ('High','Average','Low')),
  status text default 'Active' check (status in ('Active','Outlier','Leaver')),
  supporter_name text,
  created_at timestamptz default now()
);

-- CANDIDATES (interview pipeline)
create table if not exists candidates (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  national_id text,
  email text,
  phone text,
  form_test numeric,
  interview_score numeric,
  knowledge numeric,
  tactics numeric,
  typing_speed int,
  typing_accuracy int,
  total_points numeric,
  rank int,
  performance text,
  status text default 'Pending' check (status in ('Pending','Accepted','Rejected')),
  football_knowledge text,
  interviewer text,
  batch_name text,
  notes text,
  created_at timestamptz default now()
);

-- ATTENDANCE LOG
create table if not exists attendance_log (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  trainee_id uuid references trainees(id),
  trainee_name text,
  date date not null,
  status text not null check (status in ('Present','Late','Absent','Online')),
  submitted_by text,
  submitted_at timestamptz default now()
);

-- MISTAKE LOG
create table if not exists mistake_log (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  trainee_id uuid references trainees(id),
  trainee_name text,
  task text not null,
  error_category text not null,
  description text,
  severity text not null check (severity in ('Minor','Major')),
  occurrence text not null check (occurrence in ('First time','Repeat')),
  supporter_name text,
  logged_at timestamptz default now()
);

-- FEEDBACK LOG
create table if not exists feedback_log (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  trainee_id uuid references trainees(id),
  trainee_name text,
  task text,
  mistakes_discussed text[],
  action_agreed text,
  improvement text check (improvement in ('First Session','Better','Same','Worse')),
  supporter_name text,
  logged_at timestamptz default now()
);

-- FINAL CHECKS
create table if not exists final_checks (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  trainee_id uuid references trainees(id),
  trainee_name text,
  week_number int not null,
  score numeric not null,
  decision text check (decision in ('Continue','Outlier Program','Remove')),
  decision_rationale text,
  decision_date timestamptz,
  entered_by text,
  created_at timestamptz default now()
);

-- EOD FORMS
create table if not exists eod_forms (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  supporter_name text,
  date date not null,
  attendance_submitted boolean default false,
  policy_checked boolean default false,
  outliers_updated boolean default false,
  leaver_event boolean default false,
  schedule_posted boolean default false,
  escalation_text text,
  submitted_at timestamptz default now()
);

-- LEAVERS
create table if not exists leavers (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  trainee_name text not null,
  date date not null,
  reason text not null check (reason in ('Fail','Dropout','Other')),
  final_check_score numeric,
  submitted_by text,
  created_at timestamptz default now()
);

-- INVESTIGATIONS
create table if not exists investigations (
  id text primary key,
  batch_id uuid references batches(id),
  opened_date date not null,
  person_name text not null,
  person_type text not null check (person_type in ('Trainee','Supporter')),
  investigation_type text not null check (investigation_type in ('Policy','Performance','Behaviour','Attendance')),
  description text,
  evidence_available boolean default false,
  immediate_action text,
  status text default 'Open' check (status in ('Open','Closed')),
  finding text check (finding in ('Substantiated','Unsubstantiated','Inconclusive')),
  action_taken text,
  outcome_communicated boolean default false,
  checklist_steps boolean[] default array[false,false,false,false,false,false,false],
  opened_by text,
  created_at timestamptz default now()
);

-- WEEKLY REPORTS
create table if not exists weekly_reports (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  batch_name text,
  week_number int not null,
  attendance_rate int,
  pass_rate int,
  outliers_activated int default 0,
  leavers_count int default 0,
  top_mistake text,
  observation text,
  at_risk_note text,
  supporter_note text,
  recommendation text,
  status text default 'Draft' check (status in ('Draft','Submitted','Reviewed')),
  submitted_by text,
  submitted_at timestamptz,
  reviewed_by text,
  created_at timestamptz default now()
);

-- ROOM RESERVATIONS
create table if not exists room_reservations (
  id uuid default gen_random_uuid() primary key,
  batch_id uuid references batches(id),
  day_number int not null,
  date date,
  room_name text,
  confirmed boolean default false,
  reminder_sent boolean default false,
  created_at timestamptz default now()
);

-- ALERTS
create table if not exists alerts (
  id uuid default gen_random_uuid() primary key,
  type text not null check (type in ('r','a','b','g')),
  text text not null,
  batch_id uuid references batches(id),
  target_role text,
  read boolean default false,
  created_at timestamptz default now()
);

-- GOALS
create table if not exists goals (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  status text not null,
  progress int default 0,
  updated_at timestamptz default now()
);

-- ============================================================
-- SEED DATA — Demo users, one batch, trainees, candidates
-- ============================================================

insert into users (name, username, password, role, color, initials) values
  ('JD Sanders',    'jd',      'admin123', 'manager',     '#8b5cf6', 'JD'),
  ('Karim Hassan',  'karim',   'admin123', 'supervisor',  '#3b82f6', 'KH'),
  ('Sara Khalil',   'sara',    'admin123', 'supporter',   '#22c55e', 'SK'),
  ('Ahmed Tarek',   'ahmed',   'admin123', 'supporter',   '#22c55e', 'AT'),
  ('Layla Ibrahim', 'layla',   'admin123', 'coordinator', '#f59e0b', 'LI')
on conflict (username) do nothing;

insert into goals (name, status, progress) values
  ('Hiring Plans', 'On Track', 75),
  ('TagOnce Training Integration', 'In Progress', 40),
  ('Educational Program for Trainers', 'Planning', 15),
  ('Scorecard Redesign', 'On Track', 60),
  ('Football Data Stability', 'At Risk', 30),
  ('After-Hiring Batches Service', 'Not Started', 0),
  ('AMF Action Plan', 'On Track', 55),
  ('Ice Hockey Collection', 'Planning', 10);

insert into candidates (name, national_id, form_test, interview_score, knowledge, tactics, typing_speed, typing_accuracy, total_points, rank, performance, status, batch_name, interviewer) values
  ('Ahmed Mostafa',  '29012345678901', 88, 85, 90, 87, 52, 96, 87.4, 1, 'High',    'Accepted', 'Batch 82', 'Karim Hassan'),
  ('Sara El-Din',    '29112345678902', 78, 80, 79, 76, 48, 94, 79.1, 2, 'Average', 'Accepted', 'Batch 82', 'Karim Hassan'),
  ('Omar Khaled',    '29612345678907', 92, 90, 93, 89, 58, 98, 91.2, 3, 'High',    'Accepted', 'Batch 82', 'Layla Ibrahim'),
  ('Fatima Nour',    '30012345678910', 61, 64, 60, 62, 38, 82, 63.5, 18,'Low',     'Rejected', '',         'Rami Saad'),
  ('Youssef Adel',   '30112345678911', 83, 81, 84, 80, 50, 93, 82.0, 5, 'High',    'Pending',  '',         ''),
  ('Hana Samir',     '30212345678912', 76, 78, 75, 74, 44, 90, 75.3, 7, 'Average', 'Pending',  '',         '');

-- ============================================================
-- ROW LEVEL SECURITY — Allow all for now (add auth later)
-- ============================================================
alter table users enable row level security;
alter table batches enable row level security;
alter table trainees enable row level security;
alter table candidates enable row level security;
alter table attendance_log enable row level security;
alter table mistake_log enable row level security;
alter table feedback_log enable row level security;
alter table final_checks enable row level security;
alter table eod_forms enable row level security;
alter table leavers enable row level security;
alter table investigations enable row level security;
alter table weekly_reports enable row level security;
alter table room_reservations enable row level security;
alter table alerts enable row level security;
alter table goals enable row level security;

-- Allow full access via anon key (for this app)
create policy "allow all" on users for all using (true) with check (true);
create policy "allow all" on batches for all using (true) with check (true);
create policy "allow all" on trainees for all using (true) with check (true);
create policy "allow all" on candidates for all using (true) with check (true);
create policy "allow all" on attendance_log for all using (true) with check (true);
create policy "allow all" on mistake_log for all using (true) with check (true);
create policy "allow all" on feedback_log for all using (true) with check (true);
create policy "allow all" on final_checks for all using (true) with check (true);
create policy "allow all" on eod_forms for all using (true) with check (true);
create policy "allow all" on leavers for all using (true) with check (true);
create policy "allow all" on investigations for all using (true) with check (true);
create policy "allow all" on weekly_reports for all using (true) with check (true);
create policy "allow all" on room_reservations for all using (true) with check (true);
create policy "allow all" on alerts for all using (true) with check (true);
create policy "allow all" on goals for all using (true) with check (true);
