# Vested — Complete Supabase Setup Guide
### For complete beginners. Every step explained. Nothing skipped.

---

## What is Supabase and why do you need it?

Supabase is the backend that powers everything in Vested — it stores your users, their balances, transactions, the crypto list, copy traders, and all platform settings. It also handles login and email sending. You need a free Supabase account to make the app work.

**Time needed: about 20–30 minutes for your first time.**

---

## PART 1 — Create Your Supabase Project

**Step 1.** Open your browser and go to: **https://supabase.com**

**Step 2.** Click **"Start your project"** (or "Sign In" if you already have an account).

**Step 3.** Sign up using your GitHub account or email. It's free.

**Step 4.** Once you're logged in, click the green **"New project"** button.

**Step 5.** Fill in the form:
- **Organization** — leave the default (your name)
- **Name** — type `vested` (or anything you want)
- **Database Password** — click "Generate a password" and then **save that password somewhere safe** (like a notes app). You won't need it often, but losing it is a pain.
- **Region** — pick the one closest to you (e.g. EU West, US East)
- **Plan** — leave it on **Free**

**Step 6.** Click **"Create new project"** and wait. It takes about 60 seconds to spin up. You'll see a loading spinner.

---

## PART 2 — Run the Database Schema

This is where you give the database its structure — the tables, rules, and starter data that Vested needs.

**Step 1.** In your Supabase project, look at the left sidebar. Click on **"SQL Editor"** (it looks like a database icon or says `</>` SQL).

**Step 2.** You'll see a text area. Click **"New query"** at the top left.

**Step 3.** Open the file `schema.sql` from the `artifacts/vested/` folder of this project. Select ALL the text inside it (Ctrl+A / Cmd+A) and copy it.

**Step 4.** Paste everything into the Supabase SQL Editor text area.

**Step 5.** Click the green **"Run"** button (or press Ctrl+Enter / Cmd+Enter).

**Step 6.** Wait a few seconds. You should see a message at the bottom like:
```
Success. No rows returned.
```
If you see red text with an error, scroll down to the **Troubleshooting** section at the bottom of this guide.

> That's it for the schema. The schema already includes OTP columns, seed data (10 cryptocurrencies + 4 copy traders), and all security rules. You do NOT need to run `schema-patch-security.sql` — it's only needed if you ran an older version before.

---

## PART 3 — Get Your API Keys

These are two special codes that connect the Vested app to your Supabase database. Without them, the app won't be able to log in users or load any data.

**Step 1.** In the left sidebar, click **"Project Settings"** (the gear icon at the very bottom).

**Step 2.** In the Settings menu, click **"API"**.

**Step 3.** You'll see two things you need. Copy them and save them somewhere (a notepad, sticky note, etc.):

| What it's called in Supabase | What it's called in Vested |
|---|---|
| **Project URL** | `VITE_SUPABASE_URL` |
| **anon / public** key (under "Project API Keys") | `VITE_SUPABASE_ANON_KEY` |

The URL looks like: `https://abcdefghijklmn.supabase.co`

The anon key is a very long code starting with `eyJhbGci...`

> **Important:** The anon key is safe to use in a frontend app. It only lets users do what your security rules allow. Never use the `service_role` key in the frontend — that one bypasses all security.

---

## PART 4 — Add the Keys to Your App

### If you are using Vercel (recommended for deployment):

**Step 1.** Go to your Vercel dashboard → your Vested project → **Settings** → **Environment Variables**.

**Step 2.** Add these two variables one at a time:

```
Name:  VITE_SUPABASE_URL
Value: https://your-project.supabase.co   ← paste your actual URL
```

```
Name:  VITE_SUPABASE_ANON_KEY
Value: eyJhbGci...   ← paste your actual anon key
```

**Step 3.** Click **Save** after each one.

**Step 4.** Go back to your Vercel project → **Deployments** → click the three dots on your latest deployment → **Redeploy**. This makes the app pick up the new keys.

### If you are running locally (on Replit or your own computer):

**Step 1.** In the `artifacts/vested/` folder, create a new file called `.env.local`

**Step 2.** Paste this into it (replace with your actual values):
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGci...
```

**Step 3.** Save the file. Restart the app. The app will now connect to Supabase.

---

## PART 5 — Set Up Authentication (Email Login)

This tells Supabase where your app lives so it can send emails with the right links.

**Step 1.** In Supabase, go to **Authentication** → **URL Configuration** (in the left sidebar under Auth).

**Step 2.** Set the **Site URL** to your app's address:
- If deployed on Vercel: `https://your-app-name.vercel.app`
- If testing locally: `http://localhost:21058`

**Step 3.** Under **Redirect URLs**, click **"Add URL"** and add:
```
https://your-app-name.vercel.app/**
```
(Replace with your actual Vercel domain. The `/**` at the end is important — it means "any page on this site".)

If also testing locally, add a second one:
```
http://localhost:21058/**
```

**Step 4.** Click **Save**.

---

## PART 6 — Set Up the Email Templates

This makes the emails users receive (signup confirmation, password reset, withdrawal OTP) look like Vested emails — dark theme, your branding — instead of the generic Supabase emails.

### Email 1: Confirm Signup

**Step 1.** Go to **Authentication** → **Email Templates** in the Supabase sidebar.

**Step 2.** Click on **"Confirm signup"**.

**Step 3.** Open the file `email-templates/confirm-signup.html` from this project. Copy all the text inside.

**Step 4.** In Supabase, clear the existing template and paste your copied HTML.

**Step 5.** Set the **Subject** field to:
```
Confirm your Vested account
```

**Step 6.** Click **Save**.

---

### Email 2: Reset Password

**Step 1.** Still on the Email Templates page, click **"Reset password"**.

**Step 2.** Open the file `email-templates/reset-password.html` from this project. Copy all the text inside.

**Step 3.** In Supabase, clear the existing template and paste your copied HTML.

**Step 4.** Set the **Subject** field to:
```
Reset your Vested password
```

**Step 5.** Click **Save**.

> The Withdrawal OTP email (`withdrawal-otp.html`) is sent manually by you (the admin) when you approve a withdrawal — it is NOT set up in Supabase. See Part 9 for how that works.

---

## PART 7 — Make Yourself an Admin

When you first sign up in the Vested app, you are a regular user. To access the admin panel (`/admin`), you need to give yourself the admin role.

**Step 1.** First, go to your Vested app and **create an account** using the Sign Up page. Use your real email — you'll need to confirm it.

**Step 2.** Check your email and click the confirmation link that Supabase sends you.

**Step 3.** Sign in to the Vested app. You should land on the dashboard.

**Step 4.** Now go back to Supabase → **SQL Editor** → **New query**.

**Step 5.** Paste this (replacing the email with the one you signed up with):
```sql
UPDATE public.users
SET role = 'admin'
WHERE email = 'your-email@example.com';
```

**Step 6.** Click **Run**. You should see:
```
Success. 1 rows affected.
```

**Step 7.** Go back to the Vested app and **refresh the page** (or sign out and sign back in). You should now see an **Admin** link in the sidebar.

---

## PART 8 — Configure Platform Settings (Deposit Wallet Addresses)

This is where you set the wallet addresses that users will send crypto to when they deposit. The app reads these from the database.

**Step 1.** In Supabase → **SQL Editor** → **New query**.

**Step 2.** Paste the following and replace the wallet addresses with your actual ones:

```sql
INSERT INTO public.platform_settings (key, value, label)
VALUES
  ('deposit_btc',   'YOUR_BTC_WALLET_ADDRESS_HERE',   'Bitcoin (BTC) Deposit Address'),
  ('deposit_eth',   'YOUR_ETH_WALLET_ADDRESS_HERE',   'Ethereum (ETH) Deposit Address'),
  ('deposit_usdt',  'YOUR_USDT_WALLET_ADDRESS_HERE',  'USDT (TRC-20) Deposit Address'),
  ('deposit_bnb',   'YOUR_BNB_WALLET_ADDRESS_HERE',   'BNB Deposit Address'),
  ('deposit_sol',   'YOUR_SOL_WALLET_ADDRESS_HERE',   'Solana (SOL) Deposit Address')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
```

**Step 3.** Click **Run**.

You can also update these anytime from the admin panel in your app: **Admin → Platform Settings**.

---

## PART 9 — How the Withdrawal OTP System Works

This is a manual security step that you (the admin) control for every withdrawal.

**Here is the full flow:**

1. A user goes to **Transactions** in the app and submits a withdrawal request. It appears in your admin panel as **"Pending"**.

2. You (the admin) go to **Admin → Transactions**. You see the pending withdrawal.

3. You review it. If you want to approve it, click **"Approve"**. The system automatically:
   - Generates a random 6-digit code (the OTP)
   - Saves it to the database with a 15-minute expiry timer
   - Shows the code in your admin panel

4. You copy the OTP code and send it to the user. You can:
   - Send the `email-templates/withdrawal-otp.html` email manually via any email service (Gmail, Outlook, Resend, SendGrid, etc.)
   - Replace `{{OTP_CODE}}` with the actual code, `{{USER_NAME}}` with their name, `{{AMOUNT}}` with the withdrawal amount
   - Or simply message them via WhatsApp, Telegram, etc. — however you communicate with your users

5. The user goes to **Transactions** in the app, finds the approved withdrawal, clicks **"Enter OTP"**, and types in the code you sent.

6. If the code is correct and hasn't expired, the withdrawal is confirmed.

> **Why no automatic email sending?** Supabase does not automatically send custom emails on database changes without additional setup (like a Supabase Edge Function + email API). The manual approach works perfectly for an admin-operated platform. If you want to automate this later, you can use **Resend** or **SendGrid** with a Supabase Edge Function — but that's an optional upgrade.

---

## PART 10 — Verify Everything is Working

After completing all steps above, do this quick test:

**Test 1: Sign up works**
- Go to your app → click Get Started → Sign Up → enter an email and password → click Sign Up
- Check your email for a confirmation link
- Click the link → you should be taken to the app's dashboard

**Test 2: Database has data**
- Sign in → go to Trade page → you should see the list of cryptocurrencies (BTC, ETH, etc.)
- If the list is empty: your API keys might be wrong, or the schema didn't run. Re-check Part 2 and Part 4.

**Test 3: Admin panel works**
- After making yourself admin (Part 7), navigate to `/admin` in your browser
- You should see the Admin Dashboard with stats and navigation

**Test 4: Copy traders show up**
- Go to the Copy Trading page in the app
- You should see 4 traders: Alex Chen, Sarah Kim, Marcus Volta, Elena Torres
- If empty: the schema seeded them — re-check that the schema ran successfully

---

## Troubleshooting Common Problems

### "I see an error when I ran the schema SQL"

**Error: `type "transaction_type" already exists`**
This means you already ran the schema before. Go back to SQL Editor and run this to wipe everything and start fresh:
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```
Then re-run `schema.sql` from scratch.

**Error: `relation "auth.users" does not exist`**
This should not happen on Supabase — their database always has `auth.users`. Make sure you are pasting into the SQL Editor on **your Supabase project**, not somewhere else.

---

### "The app shows a warning about missing Supabase environment variables"

This means the app is running but can't connect to Supabase yet. You haven't added the environment variables yet, or they weren't picked up.
- If on Vercel: Go to Vercel → Settings → Environment Variables → make sure both `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are added → Redeploy.
- If on Replit: Create the `.env.local` file inside `artifacts/vested/` and restart the workflow.

---

### "I signed up but didn't get a confirmation email"

- Check your spam/junk folder
- Make sure your Supabase project's Auth settings have email confirmations enabled (they are on by default)
- To temporarily disable email confirmation for testing: go to **Authentication → Providers → Email** → turn off **"Confirm email"** → Save. (Turn it back on before going live.)

---

### "I can't access /admin even after updating my role"

- Sign out of the app completely and sign back in. The role is checked on login.
- Double-check the SQL ran correctly: in Supabase → **Table Editor** → click `users` table → find your email row → check the `role` column says `admin`.

---

### "Deposit addresses don't show up in the app"

- Make sure you ran the INSERT for `platform_settings` in Part 8.
- Check in Supabase → **Table Editor** → `platform_settings` table → you should see rows with keys like `deposit_btc`.

---

## Quick Reference — Keys You Need

| What | Where to find it | Used in |
|---|---|---|
| `VITE_SUPABASE_URL` | Supabase → Project Settings → API → Project URL | Vercel env vars / `.env.local` |
| `VITE_SUPABASE_ANON_KEY` | Supabase → Project Settings → API → anon key | Vercel env vars / `.env.local` |
| Admin SQL | Run in Supabase SQL Editor | Makes your account admin |
| Deposit wallets | Run in Supabase SQL Editor | Shows in app deposit flow |
| Email templates | Paste in Supabase → Auth → Email Templates | Signup + password reset emails |

---

## You're Done!

Once all 10 parts are complete, your Vested platform is fully operational:
- Users can sign up, confirm email, and log in
- The dashboard shows real portfolio data
- Trade page has 10 live cryptocurrencies
- Copy trading has 4 approved traders
- Deposits show your wallet addresses
- Withdrawals go through the OTP approval flow
- Admin panel is locked to your account only
- All emails match the Vested dark theme
