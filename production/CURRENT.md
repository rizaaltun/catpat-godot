> **30 Ekim 2026 güncel kaynak:** `docs/DEVAM-NOTU.md` ve `docs/PRODUCTION-2026-10-30.md`. Aşağıdaki kayıtlar üretim geçmişidir; eski "yapılmadı/yayın yok" ifadeleri yeni sonuçları geçersiz kılmaz.

# T22 çalışma kopyası — B05 Festival Alanı ve bölüm regresyonları (20 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim B05 sahnesi; fiziksel yürüme/zıplama, bölünmüş zemin, görev platformları, orman arka planı, festival kamp çizimi, yosunlu platform görselleri, yol işaretleri ve görev tamamlanınca görünür çiçekler. Üç arkadaşın katkı hareketi ve portreli final paneli var. Bazı zemin/sahne şekilleri teknik geometri; oyun içi görsel QA sürüyor.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Yerel ortamda Godot ikilisi yok; Godot 4.4.1 doğrulaması GitHub Actions ile yapılıyor. CI run 39383518955 B01, B02 ve B03 tam sahne/fizik oyun akışı testlerini; B04 geçiş ve ana görev regresyonlarını; B05 68/68 sözleşme/hareket kontrolünü ve Web export'u geçti. B01-B03 senaryoları Godot headless altında gerçek sahne ve oyuncu hareket simülasyonu kullanıyor; elle cihaz QA'sı sayılmaz. B01-B04 kayıt noktası/ankraj eşleşmesi run 39277080713'te geçti. Eksik Porsuk yürüyüş görseli 4547a4158a14e9331a2b174a18a76c7d59809133 ile eklendi; final kayıt ankrajı ve yeniden açılış kontrolü 22f6cda81eda9554c6fdc22197ed53cdaddbdbf0 ile güncellendi.

B05'in son sözleşme testi 68 kontrol, 0 hata verdi: istasyon ve kayıt davranışına ek olarak giriş kıyısından Porsuk platformuna gerçek zıplama ve kayıtlı noktaya düşme dönüşü sınandı. Diğer istasyon ve final erişimi hâlâ testte konumlandırmayla doğrulanıyor; bu tam oyuncu rotası veya görsel QA değildir.

## Son durum ve doğrulama

- 56 runtime görsel kullanıcı izniyle WebP olarak GitHub dalına eklendi; toplam 25.45 MB. Orijinal PDF/PSD ve kitap sayfası taramaları public depoya alınmadı.
- B01-B03 tam sahne/fizik rotaları, B04 geçiş/ana görev, B05 68/68 sözleşme/hareket kontrolü ve Web export: https://github.com/rizaaltun/catpat-godot/actions/runs/39385190445 — başarılı.
- B01-B04 kayıt noktası/ankraj eşleşmesi: https://github.com/rizaaltun/catpat-godot/actions/runs/39277080713 — başarılı.
- GitHub Pages kapalı; kullanıcı canlı yayın ayarını şimdilik erteledi. Hosted tarayıcı testi ve canlı URL açık.

## Önce yapılacak doğrulama

1. B04'ün tam elle oynanış rotasını ve B05'in diğer istasyonlara ve final alanına gerçek zıplama rotasını Godot viewport'unda test et; Porsuk platformuna erişim ve son kayıt noktasına düşüş dönüşü headless senaryoda geçti.
2. Festival final alanı, arkadaş animasyonları ve farklı ekran oranlarını görüntü kaydıyla incele; otomatik headless test görsel kalite onayı değildir.
3. B05 için dokunmatik basılı tutma, pause/devam ve kaydet/yeniden aç akışını cihazda kontrol et.
4. Ortak beceri kataloğu, gözlem şeması ve ebeveyn raporu gereksinimlerini Epsilon rehberine göre sürdür; görev işaretlerini gelişim kanıtı olarak sunma.
5. Pages yayını ve canlı URL'yi kullanıcı bu adımı yeniden açtığında tamamla.


## 20 Ekim 2026 güncellemesi — genişletilmiş B05 rotası

- Yeni test commit'i: `6acae68141b10e8675fd9477a74059136a144e41`.
- CI run 39387504240 başarıyla tamamlandı: B01, B02 ve B03 tam oyun akışı; B04 geçiş/ana görev regresyonu; B05 87 kontrol, 0 hata; Web export.
- B05 test oyuncusu giriş kıyısından Porsuk, Maymun, Pıtpıt ve final alanına fizik ve kontrol girdileriyle ilerliyor. Üç katkı, arkadaşların sahneye varışı, final anahtarı, final paneli, kaydın yeniden açılması ve arkadaş/çiçek/oyuncu konumlarının geri yüklenmesi test edildi. Önceki 68 kontrollü smoke kapsamı ve test içi doğrudan konumlandırma bu yeni rota kapsamıyla güncellendi.
- Bu sonuç headless Godot regresyonudur; görsel kalite, animasyon, farklı en-boy oranları ve dokunmatik cihaz testi değildir. Yerel editör/cihaz QA'sı ve B04 elle rota QA'sı açık kalıyor.
- Web export başarılı; Pages hâlâ kapalı ve canlı tarayıcı URL'si yok. Yayın ayarı daha önce ertelenmişti.
- Orijinal PDF/PSD ve kitap sayfası taramaları public depoya eklenmedi.


## 20 Ekim 2026 — tarayıcı yayını hazırlığı

- Commit `68e1444df4fa1c6330c5f732ee83500d1c4f8e52` Pages dağıtım akışını ekledi. CI run 39390231629 (https://github.com/rizaaltun/catpat-godot/actions/runs/39390231629) B01–B05 doğrulaması ve Web export'u geçti; Pages dağıtımı `publish` seçeneği varsayılan kapalı olduğundan çalıştırılmadı.
- Canlı test linki henüz yok. İlk yayın için repo Settings > Pages kaynağı `GitHub Actions` seçilmeli; ardından Actions > Godot verification > Run workflow, `work/t22-source-migration` ve `publish=true) seçilerek çalıştırılmalı. Akış tüm doğrulamaları geçtikten sonra yayımlar.
- Beklenen adres `https://rizaaltun.github.io/catpat-godot/`; dağıtım tamamlanıp URL kontrol edilmeden canlı bağlantı olarak paylaşılmamalı.
- Repo bağlantısı içerik ve Actions yetkisine sahip olsa da Pages ayarını değiştirme aracı sunmuyor. PDF/PSD kitap orijinalleri yayımlanmadı.
