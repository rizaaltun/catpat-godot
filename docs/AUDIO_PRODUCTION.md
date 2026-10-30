# Çatpat ses üretimi — 30 Ekim 2026

Bu paket eksik ses katmanını gerçek dosyalar ve çalışan Godot hizmetiyle ekler. Müzik ve efektler bu proje için `tools/generate_audio.py` ile özgün olarak bestelenmiş/düzenlenmiş ve sentezlenmiştir. Dış örnek, hazır melodi, ses kaydı veya ağ kaynağı kullanılmaz. Gerçek müzisyen kaydı veya doğa saha kaydı olduğu iddia edilmez.

## Dosyalar ve kapsam

- `assets/runtime/audio/music_{path,friends,festival,finale}.ogg`: üç uyumlu müzik ailesi ve festival final varyasyonu. Yumuşak telli/tahta tınılar, nefesli melodi, hafif çanlar; nota ve akor düzeni üretim kaynağındadır.
- `ambience_{home,lantern,river,garden,summit,festival}.ogg`: altı ayrı24 saniyelik düşük yoğunluklu ortam döngüsü. Yaprak/rüzgâr, kuş benzeri kısa ötüşler, su ve uzaktaki festival hareketi özgün sentezdir.
- `sfx_*.wav`:24 ayrı menü, adım, zıplama/iniş, etkileşim, fener, halat, nesne alma/yerleştirme, köprü, su dönüşü, kayıt, görev, arkadaş katılımı, final ve sayfa çevirme efekti.
- `manifest.json`: her dosyanın kimliği, süre/kanal/tepe/RMS değeri ve SHA256 kaydı.
- `validation.json`:10 döngünün Vorbis çözümlemesi sonrası boşluk/tepe ve örnek sınırı kontrolleri.

34 runtime dosyası yaklaşık2.47MB. Ham geçici WAV’lar dağıtım paketine çoğaltılmaz; düzenlenebilir nota/sentez kaynağı Python dosyasıdır. Kaynak üretimi aynı tohumla çalışır, runtime yazımları geçici dosya→atomik yeniden adlandırma kullanır.

## Çalışan entegrasyon

`project.godot`, `/root/CatpatAudio` autoload’unu yükler. `scripts/core/audio_service.gd` aşağıdakileri uygular:

- Açılışta ve sahne seçiminde otomatik çalma yoktur. İlk gerçek basılı klavye/fare/dokunma olayı ses kapısını açar; taklit fare veya echo olayları açmaz. Gerçek tarayıcı politikası ayrıca cihazda doğrulanır.
- Bölüm başına ortam ve uygun tema; sahne geçişlerinde kısa müzik çapraz geçişi. Yeniden açılan bitmiş B05 finalinde durum taban çizgisi alınır; kayıtlı eski başarı sesi tekrar üretilmez.
- Mevcut kaydın `settings.music`/`settings.sfx`0–1 değerleri; eski boolean ve `effects` eş adı. `Preferences.apply()` çağrıları doğrudan bu hizmete ulaşır. Ayrı ayar kaydı veya çocuk telemetrisi yoktur.
- Oynanış pause’unda müzik/ortam ve oyun efektlerinin oynatma konumu donar. Menü geri bildirimi açık kalır; uygulama odağı kaybedilince bütün sesler duraklar. Odağa dönmek kullanıcı pause’unu iptal etmez.
- Diyalogda müzik10dB kısılır. B04’ün yalnız diyalog için kullanılan fizik dondurması gerçek pause’dan ayrılır. B05 final sunumu fizik dondurmasına rağmen kutlama müziğini sürdürebilir.
- Sekiz efekt kanalı, olay türüne göre kısa tekrar sınırı; adımlar ve yinelenen görev/ışık olayları üst üste yığılmaz. Tanınmayan olaylar sessizce reddedilir.
- `event(name)`, `apply_settings(dict)`, `unlock_from_gesture()`, `select_chapter(id, completed)`, `set_paused(bool)`, `set_dialogue(bool)` açık entegrasyon noktalarıdır. Sahne/quest bayrakları, karakter adım/zıplama/inişi ve görünür Button basışları da otomatik gözlenir.
- Çıkışta aktif oynatmalar ve akış referansları bırakılır. Hızlandırılmış headless testler, mixer’ın tamamlanması için kısa drain süresi bırakır.

`event()` kimlikleri servis içindeki `EFFECT_NAMES` sabitindedir. Bölüm kodları bir olay için açık çağrı eklerse otomatik gözlemle aynı kimliği kullanabilir; durum efektlerinde tekrar sınırı çift çalmayı azaltır.

## Gerçek kontrol sonucu ve sınır

Godot4.4.1: `tests/audio_service_test.gd` **68 kontrol /0 hata**, çıkış kodu0. Bütün34 dosya başarıyla import edilip süre döndürdü;34/34 dosya SHA/ffprobe doğrulamasından,10/10 döngü decode/tepe/örnek sınırı kontrolünden geçti. Ses kapısı, tercih/mute, tekrar engeli, pause/resume, arka plan, diyalog kısması, final sunumu ve kaynak bırakma sınandı. Son test çıkışında sızıntı uyarısı görülmedi.

Bu sonuç hoparlörden dinleme, estetik müzik kabulü veya gerçek Safari/telefon ses oturumu testi değildir. Ogg örnek sınırı kontrolü tek başına bir döngünün kulağa kusursuz geldiğini kanıtlamaz. Müzik/ortam dengesi ve karakter diyalogu ile kullanım hedef cihazda dinlenerek incelenmelidir. Tam seslendirme bu kapsamın zorunlu öğesi değildir; sessiz oynanış bilgisi görseller/metinlerle korunur.
