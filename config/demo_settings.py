"""
Impostazioni Django per la demo locale isolata (TASK-017).

- Nessun .env richiesto: SECRET_KEY fittizia impostata prima dell'import
  (stesso pattern di config/test_settings.py).
- Database SQLite su file dedicato in .demo/db.sqlite3 (mai :memory:,
  la demo deve persistere tra comandi separati: migrate, demo_full,
  creazione demo_admin, ispezione dati).
- Upload file isolati in .demo-media/, mai la media/ reale (stesso
  principio di isolamento di config/test_settings.py, vedi TASK-012).
- Non deve mai essere usata per la suite di test (scripts/test.sh usa
  sempre config.test_settings) né in produzione.
"""

import os

os.environ.setdefault('SECRET_KEY', 'demo-secret-key-not-for-production-use-only')
os.environ.setdefault('DEBUG', 'True')
os.environ.setdefault('ALLOWED_HOSTS', '127.0.0.1,localhost')

from config.settings import *  # noqa: E402, F403

DEMO_DIR = BASE_DIR / '.demo'
DEMO_DIR.mkdir(parents=True, exist_ok=True)

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': DEMO_DIR / 'db.sqlite3',
    }
}

MEDIA_ROOT = BASE_DIR / '.demo-media'

EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
