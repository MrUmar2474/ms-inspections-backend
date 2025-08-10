# MS Inspections - Vercel Backend

This is the serverless backend for MS Inspections, designed to run on Vercel Functions with Supabase as the database.

## Quick Deploy to Vercel

1. Push this repository to GitHub
2. Connect to Vercel
3. Set environment variables:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY  
   - SUPABASE_SERVICE_KEY
   - JWT_SECRET
4. Deploy!

## Local Development

```bash
npm install
vercel dev
```

## Environment Variables

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
JWT_SECRET=your-jwt-secret
```

## API Endpoints

- GET /api/health - Health check
- POST /api/auth/login - User login
- GET /api/dashboard/stats - Dashboard statistics
- GET /api/surveys - List surveys

## Database Setup

Run the SQL in `supabase-schema.sql` in your Supabase SQL Editor.
