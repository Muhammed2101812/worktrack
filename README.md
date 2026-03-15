# WorkTrack 📋

Serbest çalışanlar ve freelancer'lar için geliştirilmiş, müşteri bazlı iş takip uygulaması. Flutter ile yazılmış olup web, mobil ve masaüstü platformlarında çalışır.

## ✨ Özellikler

- **📝 İş Kaydı** — Müşteri, tarih, saat aralığı, iş türü ve not bilgileriyle kayıt ekle/düzenle/sil
- **👥 Müşteri Yönetimi** — Renk etiketli müşteri profilleri oluştur, düzenle ve sil
- **📊 Aylık İstatistikler** — Müşteri bazlı çalışma saatlerini pasta grafiğiyle görselleştir
- **📅 Geçmiş & Filtreleme** — Ay ve müşteriye göre filtrele, kayıtlara detaylı bak
- **☁️ Supabase Senkronizasyonu** — Veriler buluta otomatik senkronize edilir; çevrimdışı çalışmayı da destekler
- **📥 CSV Dışa Aktarma** — Tüm kayıtları Excel uyumlu CSV dosyası olarak indir
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
| Theme Persistence | shared_preferences |
| CSV Export | csv + file_saver |

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

### 3. Supabase yapılandırması

`lib/core/constants.dart` dosyasına Supabase URL ve Anon Key'i gir:

```dart
static const supabaseUrl = 'https://<project>.supabase.co';
static const supabaseAnonKey = '<anon-key>';
```

Supabase'de aşağıdaki tabloları oluştur:

```sql
-- Müşteriler
create table clients (
  id text primary key,
  name text not null,
  color text not null
);

-- İş Kayıtları
create table work_entries (
  id text primary key,
  client_id text,
  client_name text not null,
  date text not null,
  start_time text not null,
  end_time text not null,
  duration_hours real not null,
  work_type text not null,
  notes text default ''
);
```

### 4. Çalıştır

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
├── core/           # Sabitler, router, tema
├── models/         # WorkEntry, Client veri modelleri
├── providers/      # Riverpod state yönetimi
├── services/       # LocalDB, Supabase, Sync, Export servisleri
└── screens/
    ├── home/       # Ana sayfa (günlük kayıtlar)
    ├── history/    # Geçmiş & filtreleme
    ├── stats/      # Aylık istatistik grafikleri
    ├── settings/   # Müşteri yönetimi, tema, export
    ├── add_entry/  # Kayıt ekleme/düzenleme
    └── login/      # Kimlik doğrulama
```

## 📱 Ekranlar

| Ekran | Açıklama |
|-------|----------|
| **Ana Sayfa** | Bugünkü özet kart + son kayıtlar listesi (swipe ile sil) |
| **Geçmiş** | Tüm kayıtlar; ay ve müşteriye göre filtrele (swipe ile sil) |
| **İstatistik** | Seçili aya ait müşteri bazlı pasta grafiği |
| **Ayarlar** | Müşteri yönetimi, tema seçimi, CSV dışa aktarma |

## 🔄 Senkronizasyon Mantığı

1. Kayıt önce yerel SQLite veritabanına eklenir
2. İnternet varsa Supabase'e senkronize edilir
3. Çevrimdışı kayıtlar `synced = false` olarak işaretlenir
4. Bağlantı kurulunca bekleyen kayıtlar otomatik senkronize edilir

---

Made with ❤️ using Flutter & Supabase
