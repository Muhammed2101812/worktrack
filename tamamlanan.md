# WorkLog - Tamamlanan Dosyalar

## Proje Hakkında
WorkLog, serbest çalışan kişilerin günlük iş kayıtlarını tutması için kullanılacak bir Flutter mobil ve Windows uygulamasıdır. Veri Google Sheets'te tutulur, uygulama hem Windows hem Android'de çalışır.

## Teknolojiler
- **Flutter 3.x**, Dart null-safety
- **State Management**: flutter_riverpod ^2.5.1
- **Routing**: go_router ^13.2.0
- **Local DB**: sqflite ^2.3.2
- **Google API**: google_sign_in ^6.2.1 + googleapis ^13.1.0
- **Connectivity**: connectivity_plus ^6.0.3
- **Grafik**: fl_chart ^0.68.0
- **Tema**: flex_color_scheme ^7.3.1
- **Utilities**: uuid ^4.3.3, intl ^0.19.0, shared_preferences ^2.2.3
- **Dev**: riverpod_generator ^2.4.0, build_runner ^2.4.9

## Tamamlanan Bölümler

### ✅ 1. Proje Kurulumu
- `pubspec.yaml` oluşturuldu ve tüm bağımlılıklar eklendi
- Android ve Windows platformları için proje altyapısı tamamlandı
- `flutter pub get` çalıştırıldı
- `flutter pub run build_runner build` ile Riverpod kod üretimi tamamlandı

### ✅ 2. Veri Modelleri
#### lib/models/work_entry.dart
- WorkEntry sınıfı oluşturuldu
- UUID v4 ile otomatik ID üretimi
- durationHours otomatik hesaplama (startTime - endTime)
- fromMap, toMap, copyWith metodları
- toSheetsMap metodu ile Sheets için formatlama

#### lib/models/client.dart
- Client sınıfı oluşturuldu
- UUID v4 ile otomatik ID üretimi
- Hex renk kodu desteği (#4A90D9 formatında)
- fromMap, toMap, copyWith metodları

### ✅ 3. Çekirdek Dosyalar

#### lib/core/constants.dart
- AppConstants sınıfı
- Uygulama ismi ve sabitler
- Çalışma türleri: Grafik, Yazılım, Diğer
- Müşteri renk paleti (8 renk)
- Sheets ve DB sütun başlıkları
- Windows client ID placeholder

#### lib/core/theme.dart
- AppTheme sınıfı
- FlexColorScheme ile BahamaBlue teması
- Dark mode öncelikli
- Material 3 tasarımı
- Radius: 12.0

#### lib/core/router.dart
- GoRouter yapılandırması
- Rotalar: /login, /home, /home/add, /home/history, /home/settings
- Otomatik yönlendirme (oturum yoksa /login)
- Error handling

### ✅ 4. Servisler

#### lib/services/auth_service.dart
- Google Sign-In entegrasyonu
- signInWithGoogle() - Google hesabıyla giriş
- signOut() - Çıkış yapma
- getCurrentUser() - Mevcut kullanıcıyı al
- getAuthHeaders() - Sheets API için auth header'lar
- getAuthClient() - AutoRefreshingAuthClient oluşturma

#### lib/services/sheets_service.dart
- Google Sheets API entegrasyonu
- initializeSpreadsheet() - Yeni spreadsheet oluşturma
  - "WorkLog Kayıtlar" isimli spreadsheet
  - "Kayıtlar" ve "Müşteriler" sheet'leri
  - Başlık satırlarını yazma
- addEntry() - Kayıt ekleme
- getAllEntries() - Tüm kayıtları çekme
- deleteEntry() - Kayıt silme
- addClient() - Müşteri ekleme
- getAllClients() - Tüm müşterileri çekme
- deleteClient() - Müşteri silme

#### lib/services/local_db_service.dart
- SQLite veritabanı: worklog.db
- work_entries tablosu
- clients tablosu
- CRUD operasyonları: insert, getAll, update, delete
- getUnsyncedEntries() - Senkronize edilmemiş kayıtlar
- getTodayEntries() - Bugünün kayıtları
- getEntriesByDateRange() - Tarih aralığına göre filtreleme

#### lib/services/sync_service.dart
- syncPendingEntries() - Bekleyen kayıtları senkronize etme
- fullSync() - Tam senkronizasyon (Sheets'ten çekme)
- syncEntry() - Tek kayıt senkronizasyonu
- syncClient() - Müşteri senkronizasyonu
- deleteRemoteEntry() - Uzak kayıt silme
- deleteRemoteClient() - Uzak müşteri silme
- Connectivity dinleyicisi: online olunca otomatik sync

### ✅ 5. Riverpod Providers

#### lib/providers/auth_provider.dart
- authServiceProvider - AuthService instance
- AuthNotifier - Oturum yönetimi
  - signIn() - Giriş yapma
  - signOut() - Çıkış yapma
  - refreshUser() - Kullanıcıyı yenileme

#### lib/providers/entries_provider.dart
- localDBServiceProvider - LocalDBService instance
- EntriesNotifier - Kayıt yönetimi
  - addEntry() - Kayıt ekleme
  - deleteEntry() - Kayıt silme
  - updateEntrySync() - Sync durumunu güncelleme
  - refresh() - Listeyi yenileme
- todayEntriesProvider - Bugünün kayıtları
- unsyncedEntriesProvider - Senkronize edilmemiş kayıtlar

#### lib/providers/clients_provider.dart
- ClientsNotifier - Müşteri yönetimi
  - addClient() - Müşteri ekleme
  - deleteClient() - Müşteri silme
  - getClient() - Müşteri getirme
  - refresh() - Listeyi yenileme

#### lib/providers/sync_provider.dart
- syncServiceProvider - SyncService instance
- SyncNotifier - Senkronizasyon yönetimi
  - syncPending() - Bekleyen kayıtları senkronize etme
  - fullSync() - Tam senkronizasyon
  - isSyncing - Senkronizasyon durumu
  - lastSyncTime - Son senkronizasyon zamanı

### ✅ 6. Ekranlar

#### lib/screens/login/login_screen.dart
- Ortada WorkLog logosu ve baslık
- "Google ile Giriş Yap" butonu
- Giriş sonrası Google Sheets otomatik oluşturma
- Hata durumu için SnackBar

#### lib/screens/home/home_screen.dart
- AppBar: WorkLog baslıgı + sync ikonu + ayarlar ikonu
- TodaySummaryCard - Bugünün özeti
  - Tarih, toplam saat, müşteri dağılımı
  - Kayıt yoksa mesaj
- EntryListTile - Kayıt listesi
  - Müşteri ismi, saat aralıgı, iş türü, notlar
  - Sync durumu (ikon ve metin)
  - Swipe-to-delete (onay ile onaylaştırmak)
  - Tıklayınca bottom sheet detayları
- Bottom NavigationBar
  - Ana Sayfa (Icons.home)
  - Geçmiş (Icons.history)
  - Ayarlar (Icons.settings)

#### lib/screens/home/widgets/today_summary_card.dart
- Bugünün özeti kartı
- Toplam çalışma saati
- Müşteri bazlı dağılım
- Hata ve yükleniyor durumları

#### lib/screens/home/widgets/entry_list_tile.dart
- Kayıt kartı
- Müşteri ismi, saat, süre, iş türü
- Notların ilk 50 karakteri
- Sync durumu göstergesi (ikon)
- Swipe-to-delete ve onay dialog'u
- Detay bottom sheet'i

#### lib/screens/add_entry/add_entry_screen.dart
- Müşteri seçimi (DropdownButtonFormField)
  - "➕ Yeni müşteri ekle" seçenei
  - Dialog ile yeni müşteri ekleme (isim + renk)
- Tarih seçimi (showDatePicker)
- Saat aralıgı seçimi (showTimePicker)
  - Otomatik süre hesaplama
- İş türü seçimi (SegmentedButton)
- Notlar (TextFormField, maxLines: 4, maxLength: 500)
- Kaydet butonu
- Form validasyonu
- LocalDB'ye yazma (synced: false)
- Otomatik sync denemesi
- Başarılı olunca HomeScreen'e dönme + SnackBar

#### lib/screens/add_entry/widgets/client_dropdown.dart
- Müşteri dropdown
- Renkli müşteri ikonu
- "➕ Yeni müşteri ekle" seçenei

#### lib/screens/add_entry/widgets/time_picker_row.dart
- Saat seçici satırı
- Başlangıç ve bitiş saati
- Otomatik süre hesaplama ve gösterme

#### lib/screens/add_entry/widgets/work_type_selector.dart
- İş türü seçici (SegmentedButton)
- Grafik | Yazılım | Diğer

#### lib/screens/history/history_screen.dart
- Ay seçici (önceki/sonraki oklar)
- Müşteri filtresi (FilterChip listesi)
- Aylık özet kartı
  - Toplam saat
  - Müşteri bazlı dağılım
- Filtrelenmiş kayıt listesi
- Tıklayınca detay gösterme

#### lib/screens/history/widgets/month_filter.dart
- Ay filtresi
- Önceki ve sonraki ay okları
- Türkçe tarih formatı (MMMM yyyy)

#### lib/screens/settings/settings_screen.dart
- Hesap bölümü
  - Kullanıcı fotoğrafı ve ismi/e-posta
  - Çıkış Yap butonu
- Müşteriler bölümü
  - Müşteri listesi
  - Silme butonu
  - "Müşteri Ekle" butonu (dialog)
  - Senkronizasyon bölümü
  - Son sync zamanı
  - "Manuel Sync" butonu
  - "Tüm Verileri Yenile" butonu (fullSync)
- Hakkında bölümü
  - Uygulama versiyonu (1.0.0)

### ✅ 7. Ana Dosyalar

#### lib/main.dart
- WidgetsFlutterBinding.ensureInitialized()
- SharedPreferences başlatma
- ProviderScope ile uygulama sarma
- runApp(App())

#### lib/app.dart
- MaterialApp.router
- tema: light/dark/system mode
- routerConfig: GoRouter

### ✅ 8. Android Yapılandırması
- `android/app/build.gradle.kts`
  - minSdk: 21
  - targetSdk: 34
  - compileSdk: flutter.compileSdkVersion
- `android/app/src/main/AndroidManifest.xml`
  - INTERNET izni eklendi

### ✅ 9. Windows Yapılandırması
- Windows destekli (flutter create ile oluşturuldu)
- `google_sign_in` web-based OAuth flow kullanır
- Windows client ID placeholder (constants.dart'ta)

## Yapılan İşlemler

1. ✅ Tüm proje dosyaları oluşturuldu
2. ✅ Tüm bağımlılıklar yüklendi (flutter pub get)
3. ✅ Riverpod kod üretimi tamamlandı (flutter pub run build_runner build)
4. ✅ Android ve Windows platformları yapılandırıldı
5. ✅ Kod hataları düzeltildi (LSP hataları bağımlılık yüklenmediği için bekleniyor)

## Kalan İşler

### ⚠️ Google Cloud Console Yapılandırması
1. Google Cloud Console'da yeni proje oluştur
2. Google Sheets API'yi etkinleştir
3. OAuth 2.0 Client ID oluştur
   - Android için: SHA1 fingerprint ile Client ID
   - Windows için: Web Client ID
4. Client ID'leri proje ayarlarına ekle
   - `android/app/build.gradle.kts` dosyasına Android Client ID
   - `lib/core/constants.dart` dosyasına Windows Client ID

### ⚠️ Google Drive API Etkinleştirme
1. Google Cloud Console'da Google Drive API'yi etkinleştir
2. Sheets API ile aynı scope'ları kullan

### ⚠️ İlk Çalıştırma Testi
1. `flutter run` ile uygulamayı başlat
2. Google ile giriş yap
3. İlk girişte Google Sheets otomatik oluşturulmalı
4. Müşteri ekle
5. Kayıt ekle
6. Senkronizasyon test et
7. Geçmiş ekranını test et
8. Ayarlar ekranını test et

### ⚠️ Hata Yönetimi Testleri
1. İnternet yokken kayıt ekleme (offline çalışma)
2. Kayıt ekle, internetsiz kapat
3. Tekrar aç, sync olmalı
4. Token hatası durumunda refresh testi

### ⚠️ UI/UX İyileştirmeleri
1. Loading animasyonları
2. Empty state'lar için güzel placeholder'lar
3. Error state'lar için daha iyi mesajlar
4. Hata durumunda "Yeniden Dene" butonu ekleme

### ⚠️ Ek Özellikler (Opsiyonel)
1. İstatistikler ve grafikler (fl_chart kullanımı)
2. PDF rapor dışa aktarımı
3. CSV dışa aktarımı
4. Dark/Light theme geçişi butonu
5. Dil desteği (İngilizce vb.)
6. Bildirimler (çalışma hatırlatma)
7. Veri yedekleme/geri yükleme

## Proje Yapısı

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   └── router.dart
├── models/
│   ├── client.dart
│   └── work_entry.dart
├── services/
│   ├── auth_service.dart
│   ├── sheets_service.dart
│   ├── local_db_service.dart
│   └── sync_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── entries_provider.dart
│   ├── clients_provider.dart
│   └── sync_provider.dart
└── screens/
    ├── login/login_screen.dart
    ├── home/home_screen.dart
    ├── home/widgets/today_summary_card.dart
    ├── home/widgets/entry_list_tile.dart
    ├── add_entry/add_entry_screen.dart
    ├── add_entry/widgets/client_dropdown.dart
    ├── add_entry/widgets/time_picker_row.dart
    ├── add_entry/widgets/work_type_selector.dart
    ├── history/history_screen.dart
    ├── history/widgets/month_filter.dart
    └── settings/settings_screen.dart
```

## Uygulamayı Çalıştırmak

### Android
```bash
flutter run -d android
```

### Windows
```bash
flutter run -d windows
```

## Önemli Notlar

1. **Google Sign-In Kurulumu**
   - Google Cloud Console'da OAuth 2.0 Client ID oluşturmalısınız
   - Android için SHA1 fingerprint alıp Client ID oluşturmalısınız
   - Windows için Web Client ID oluşturmalısınız
   - Client ID'leri proje ayarlarına eklemelisiniz

2. **Spreadsheet Otomatik Oluşturma**
   - İlk girişte SharedPreferences'ta spreadsheet ID yoksa
   - Otomatik olarak yeni bir spreadsheet oluşturulur
   - "WorkLog Kayıtlar" ismi ile
   - "Kayıtlar" ve "Müşteriler" sheet'leri
   - ID SharedPreferences'a kaydedilir

3. **Tarih Formatı**
   - Tüm tarihler Türkçe formatında gösterilir
   - `DateFormat('d MMMM yyyy', 'tr')` kullanılır
   - Örn: "13 Mart 2026, Cuma"

4. **Saat Hesaplama**
   - Duration = endTime - startTime (dakika cinsinden / 60.0)
   - Negatif değer kontrolü eklendi
   - Otomatik hesaplama yapılır

5. **Senkronizasyon**
   - Online olunca otomatik sync dener
   - Offline çalışma desteği var
   - Sync durumu ikon ve metinle gösterilir
   - Turuncu: bekliyor, Yeşil: senkronize edildi

6. **Platform Koşulları**
   - `kIsWeb` ve `Platform.isWindows` kontrolü
   - Platform özelinde davranış eklendi

7. **Empty State'ler**
   - Liste boşken placeholder widget gösterilir
   - Kayıt yok, müşteri eklenmemiş, vs. mesajları

## Hata Giderme

### Bağımlılık Yükleme Hataları
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Hataları
```bash
flutter clean
flutter pub get
flutter build apk
flutter build windows
```

### Sync Hataları
- İnternet bağlantısını kontrol et
- Google Sheets API key'lerini kontrol et
- Token refresh'i kontrol et
- Console'da hata mesajlarını kontrol et

## Versiyon Geçmişi

1.0.0 - İlk sürüm
- Tüm temel özellikler
- Google Sheets entegrasyonu
- Offline çalışma desteği
- Senkronizasyon sistemi