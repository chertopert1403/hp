User name: محمدرضا (Mohammadreza)
§
Prefers proper, fluent Persian language - corrected agent for broken Persian initially
§
Email: jozvahedi@gmail.com (recipient), sender: jozvahedimohammadreza@gmail.com
§
GitHub: chertopert1981, repo: hermes-backup, PAT provided
§
Gmail SMTP: smtp.gmail.com:587, user: jozvahedimohammadreza@gmail.com, App Password provided
§
Telegram bot configured with TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USERS=80124466
§
Wants automated Hermes backup every 12h to GitHub (memories, skills, config, state)
§
Wants daily shahvani.com/dastans scraping at 10 AM: extract /dastan/ links from div.panel-body table, fetch each story's div.panel-body content, create Word doc, email + Telegram delivery
§
Prefers automation via cron jobs, values proper Persian writing standards
§
Cron jobs created for user:
1. Hermes Backup Every 12h (job_id: ddb5cf016bcb) - runs backup-hermes-secure.sh
2. Shahvani Daily Links to GitHub (job_id: 497f4a9bcb2c) - 08:00 daily, runs scrape_shahvani_links.py
3. Shahvani Daily Content to GitHub (job_id: 9b743c0ad6b9) - 09:00 daily, runs scrape_story_content.py  
4. Env Token Reminder - Daily at 12:00 (job_id: cron_827de74c9b15) - runs daily at 12:00, reads and displays .env contents in private chat