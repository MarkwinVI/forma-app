# forma-app

A Flutter mobile app with Apple Sign In and Supabase authentication.

## Project structure

```
lib/
  core/
    config/        # App-wide constants (Supabase keys)
    widgets/       # Shared/reusable widgets
  data/
    models/        # Data models
    services/      # Auth & Supabase services
  features/
    login/         # Login screen
    home/          # Home screen
  main.dart
supabase/
  schema.sql       # Database schema
```

## Setup

See setup instructions for configuring Supabase and Apple Sign In.
