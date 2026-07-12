# WorkTrack 📋

Serbest çalışanlar ve freelancer'lar için geliştirilmiş, müşteri bazlı iş takip uygulaması. Flutter ile yazılmış olup web, mobil ve masaüstü platformlarında çalışır.

## ✨ Özellikler

- **📝 İş Kaydı** — Müşteri, tarih, saat aralığı, iş türü, proje ve not bilgileriyle kayıt ekle/düzenle/sil. Saatlik veya sabit ücretlendirme desteği.
- **👥 Müşteri Yönetimi** — Renk etiketli müşteri profilleri oluştur, düzenle ve sil
- **💼 Proje Yönetimi** — Müşteri bazlı projeler oluştur ve kayıtları projelere bağla
- **📊 Aylık İstatistikler** — Müşteri ve proje bazlı çalışma saatlerini pasta grafikleriyle görselleştir
- **📅 Geçmiş & Filtreleme** — Ay ve müşteriye göre filtrele, kayıtlara detaylı bak
- **💰 Finans** — Hakediş/ödeme takibi, müşteri bazlı borç durumu, ödeme geçmişi
- **☁️ Supabase Senkronizasyonu** — Veriler buluta otomatik senkronize edilir; çevrimdışı çalışmayı da destekler. Çakışma çözümleme (last-write-wins) ve soft-delete.
- **📥 Excel Dışa/İçe Aktarma** — Tüm kayıtları Excel (.xlsx) olarak indir, örnek şablon indir, Excel dosyasından içe aktar
- **🎨 Tema Seçimi** — Sistem, Açık veya Koyu tema desteği (kalıcı olarak kaydedilir)

## 🛠️ Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| UI Framework | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | go_router |
| Local Database | sqflite / sqflite_common_ffi_web |
| Backend | Supabase (PostgreSQL) |
| Charts | fl_chart |
| Theme | ThemeExtension + shared_preferences |
| Config | flutter_dotenv (.env) |
| Excel Export/Import | excel + file_saver / file_picker |

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Bir Supabase projesi

### 1. Repoyu klonla
```bash
git clone <repo-url>
cd worktrack
```

### 2. Bağımlılıkları yükle
```bash
flutter pub get
```

### 3. Ortam yapılandırması (.env)

Proje köküne bir `.env` dosyası oluştur (gitignore'dadır, commit'lenmez):

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
GOOGLE_SERVER_CLIENT_ID=<google-oauth-web-client-id>.apps.googleusercontent.com
```

Şablon için `.env.example` dosyasına bak. Değerler Supabase Dashboard → Project Settings → API ve Google Cloud Console → Credentials bölümünde bulunur.

### 4. Supabase veritabanı şeması

Güncel şema `supabase/migrations/20260712000000_sync_conflict_softdelete.sql` dosyasındadır. Özet:

```sql
-- clients (müşteriler)
create table clients (
  id text primary key,
  name text not null,
  color text not null,
  created_at text default '',
  updated_at text default '',
  is_deleted boolean not null default false
);

-- work_entries (iş kayıtları)
create table work_entries (
  id text primary key,
  client_id text,
  client_name text not null,
  client_color text not null,
  date text not null,
  start_time text not null,
  end_time text not null,
  duration_hours real not null,
  work_type text not null,
  notes text default '',
  project_id text,
  project_name text,
  billing_type text default 'hourly',
  hourly_rate real default 0.0,
  total_price real default 0.0,
  created_at text default '',
  updated_at text default '',
  is_deleted boolean not null default false
);

-- projects (projeler), payments (ödemeler) — migration dosyasında
```

Tüm tablolarda RLS etkindir (authenticated full-access policy). Performance index'leri ve soft-delete kolonları migration'da tanımlıdır.

### 5. Çalıştır

```bash
# Web
flutter run -d chrome

# Mobil (Android/iOS)
flutter run

# Masaüstü (Windows/macOS/Linux)
flutter run -d windows
```

## 📁 Proje Yapısı

```
lib/
├── core/           # Sabitler, router, tema, widget'lar
├── models/         # WorkEntry, Client, Project, Payment veri modelleri
├── providers/      # Riverpod state yönetimi
├── services/       # LocalDB, Supabase, Sync, Backup, Export/Import servisleri
└── screens/
    ├── home/       # Ana sayfa (günlük kayıtlar)
    ├── history/    # Geçmiş & filtreleme
    ├── finance/    # Finans / ödeme takibi
    ├── stats/      # Aylık istatistik grafikleri
    ├── settings/   # Müşteri yönetimi, tema, dışa/içe aktarma
    ├── add_entry/  # Kayıt ekleme/düzenleme
    └── login/      # Kimlik doğrulama
```

## 📱 Ekranlar

| Ekran | Açıklama |
|-------|----------|
| **Ana Sayfa** | Bugünkü özet kart + son kayıtlar listesi (swipe ile sil) |
| **Geçmiş** | Tüm kayıtlar; ay ve müşteriye göre filtrele (swipe ile sil) |
| **Finans** | Hakediş/ödeme özeti, müşteri bazlı borç durumu, ödeme geçmişi |
| **İstatistik** | Seçili aya ait müşteri/proje bazlı pasta grafikleri |
| **Ayarlar** | Tema seçimi, senkronizasyon, müşteri yönetimi, Excel dışa/içe aktarma |

## 🔄 Senkronizasyon Mantığı

1. Kayıt önce yerel SQLite veritabanına eklenir
2. İnternet varsa Supabase'e senkronize edilir
3. Çevrimdışı kayıtlar `synced = false` olarak işaretlenir
4. Bağlantı kurulunca bekleyen kayıtlar otomatik senkronize edilir
5. Çakışma çözümleme: aynı kayıt iki cihazda değiştirildiyse `updated_at` zaman damgasına göre en yeni olan kazanır (last-write-wins)
6. Silinen kayıtlar soft-delete edilir (`is_deleted = true`), böylece silme işlemi tüm cihazlara yayılır

---

Made with ❤️ using Flutter & Supabase
