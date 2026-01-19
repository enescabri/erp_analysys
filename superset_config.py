import os

# === GÜVENLİK ===
SECRET_KEY = os.getenv('SECRET_KEY', 'varsayilan_gizli_anahtar')

# === VERİTABANI (Metadata için Postgres kullanıyoruz) ===
SQLALCHEMY_DATABASE_URI = f"postgresql://admin:{SECRET_KEY}@postgres:5432/shared_metadata"

# === DİL VE ZAMAN ===
BABEL_DEFAULT_LOCALE = 'tr'

# === REDIS ÖNBELLEK (Hız için kritik!) ===
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,  # 24 saat
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_URL': 'redis://redis:6379/0'
}

DATA_CACHE_CONFIG = CACHE_CONFIG
FILTER_STATE_CACHE_CONFIG = CACHE_CONFIG
EXPLORE_FORM_DATA_CACHE_CONFIG = CACHE_CONFIG

# === SATIR BAZLI GÜVENLİK (ERP için kritik) ===
ENABLE_ROW_LEVEL_SECURITY = True

# === PERFORMANS OPTİMİZASYONU ===
SUPERSET_WEBSERVER_TIMEOUT = 300
SQLLAB_TIMEOUT = 300
SQLLAB_ASYNC_TIME_LIMIT_SEC = 600

# === ÖZELLEŞTİRME ===
APP_NAME = os.getenv('MUSTERI_ADI', 'ERP Analiz')
FAVICONS = [{"href": "/static/assets/images/favicon.png"}]

# === CSV EXPORT LİMİTİ (ERP raporları büyük olabilir) ===
CSV_EXPORT = {
    "encoding": "utf-8",
}

# === SMTP (Zamanlanmış raporlar için) ===
SMTP_HOST = os.getenv('SMTP_HOST', 'localhost')
SMTP_STARTTLS = True
SMTP_SSL = False
SMTP_USER = os.getenv('SMTP_USER', '')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
SMTP_MAIL_FROM = os.getenv('SMTP_USER', 'noreply@erp.com')

# === FEATURE FLAGS ===
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "HORIZONTAL_FILTER_BAR": True,
    "DASHBOARD_RBAC": True,  # Satır bazlı güvenlik için
}

# === ANDON EKRANLARI İÇİN OTOMATİK YENİLEME ===
# Dashboard'lar otomatik yenilenecek (fabrika ekranları için)
SUPERSET_DASHBOARD_POSITION_DATA_LIMIT = 0  # Limitsiz grafik
SUPERSET_DASHBOARD_PERIODICAL_REFRESH_LIMIT = 5  # 5 saniyede bir yenilenebilir
SUPERSET_DASHBOARD_PERIODICAL_REFRESH_WARNING_MESSAGE = None  # Uyarı mesajını kaldır

# === TAM EKRAN MODU (Andon için) ===
# URL: /superset/dashboard/1/?standalone=true
# Bu modda menüler gizlenir, sadece grafikler görünür
