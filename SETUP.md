# CampusComp — real authentication and database setup

This is a working starter application using Supabase Auth, PostgreSQL and Row Level Security. The frontend can be hosted on GitHub Pages.

## 1. Create Supabase project
1. Create a project at https://supabase.com.
2. Open **SQL Editor → New query**.
3. Copy all of `supabase_schema.sql` into the editor and click **Run**.
4. Open **Project Settings → API** (or API Keys). Copy the **Project URL** and **anon/public key**.
5. Paste both into `config.js`, replacing the two `PASTE_...` values.

**Never use the `service_role` key in frontend code.** It is secret and bypasses Row Level Security.

## 2. Create the first faculty account
1. Use the website's Student sign up form to create an account for the faculty member using their official email.
2. Confirm the email if email confirmation is enabled.
3. In Supabase SQL Editor run this query, replacing the email:
```sql
update public.profiles p set role='faculty'
from auth.users u where p.id=u.id and u.email='faculty@example.com';
```
4. Faculty member logs out and back in. Their Faculty Dashboard will appear.
Only a trusted administrator should run this query. Public users cannot promote themselves.

## 3. Configure Auth URLs
In Supabase **Authentication → URL Configuration**:
- Site URL: `https://YOUR-USERNAME.github.io/campuscomp/`
- Add the same address under Redirect URLs if required.
For local testing, add your local URL too. If email confirmation is enabled, students must confirm their email before logging in. Configure SMTP for reliable production email.

## 4. Test locally
Do not open the HTML as a `file://` URL. In a terminal opened in this folder run:
```bash
python -m http.server 8000
```
Open http://localhost:8000.

## 5. Publish on GitHub Pages
Upload these files to the repository root: `index.html`, `style.css`, `config.js`, `app.js`, `supabase_schema.sql`, `SETUP.md`. Commit. Go to **Settings → Pages**, choose **Deploy from a branch**, branch `main`, folder `/(root)`, then Save. After publishing, use `https://YOUR-USERNAME.github.io/campuscomp/` and set it as the Supabase Auth Site URL.

## Included features
- Student sign-up and login, password reset
- Faculty login with administrator-controlled faculty role
- Role-specific dashboards
- Create, publish and unpublish competitions
- Student registration with duplicate-registration protection
- Faculty view of registrations
- Publish student results and certificate URLs
- Student view of registrations and achievements
- Database Row Level Security policies

## Scope and limitations
This is a functional academic project starter, not a security-audited production deployment. The capacity field is stored but capacity enforcement is not yet implemented. Registration approval/rejection controls, certificate file upload/generation, multi-college tenancy, teams, attendance and reporting can be added as future modules. Certificate URLs are links, not generated files. Configure email/SMTP and review security settings before using real student data.
