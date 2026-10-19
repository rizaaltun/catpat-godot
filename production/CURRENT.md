# T22 çalışma kopyası — B05 Festival Alanı (19 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim B05 sahnesi; fiziksel yürüme/zıplama, bölünmüş zemin, görev platformları, orman arka planı, festival kamp çizimi, yosunlu platform görselleri, yol işaretleri ve görev tamamlanınca görünür çiçekler. Üç arkadaşın katkı hareketi ve portreli final paneli var. Bazı zemin/sahne şekilleri teknik geometri; oyun içi görsel QA sürüyor.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Yerel ortamda Godot ikilisi yok; GitHub Actions Godot 4.4.1 CI run `39275862970` başarılı: Godot import/parse, kayıt/diyalog/çizgi roman regresyonları, B04 geçişleri, B05 sözleşme+oyun-içi smoke (49 kontrol, 0 hata) ve Web export geçti. Smoke testi B05’i gerçek canonical save ile açtı, platform dışından etkileşimi engelledi, Porsuk/Pıtpıt platformlarında checkpoint kaydetti ve çiçek görünürlüğünü doğruladı. Tam rota, final tekrarı, cihaz ve görsel QA sürüyor. Karakter kimliği `USER_PENDING`. Karakter kimliği `USER_PENDING`.

## Son durum ve doğrulama

- 55 runtime görsel kullanıcı izniyle WebP olarak GitHub dalına aktarıldı; orijinal PDF/PSD ve kitap sayfası taramaları hariç tutuldu.
- Başarılı CI run: https://github.com/rizaaltun/catpat-godot/actions/runs/39275862970 — Godot importu, kayıt/diyalog/çizgi roman regresyonları, B04 geçişi, 49 B05 sözleşme/oyun-içi kontrolü ve Web export başarılı.
- GitHub Pages kapalı; kullanıcı canlı yayın ayarını şimdilik erteledi. Web çıktısı CI'da üretildi, hosted tarayıcı testi ve canlı URL bekliyor.

## Önce yapılacak doğrulama

1. B01–B04 tam bölüm rotalarını ve B04→B05 geçişini gerçek oyuncu akışında doğrula; mevcut hedefli CI regresyonları geçti.
2. Geçerli B04 waymark.seen kaydından seyir noktasında E ile B05 açılışını dene. Geçersiz kayıt ve kayıt yazma hatasında ilerlemenin korunmasını test et.
3. B05 üç görevi farklı sırayla tamamla, her birinden sonra kaydet/menü/Devam yap; bitişi tekrar oynatınca yinelenen görev kaydı oluşmadığını test et.
4. Farklı genişlik/ekran oranlarında kontrol panelini, kamera ve platform boşluklarını doğrula; dokunmatik hareket tuşlarının basılı tutma davranışını fiziksel cihazda test et.
5. Görsel ve oynanış QA turunu gerçek ekran/video ve loglarla kaydet. Sadece kaynak incelemesi geçiş kanıtı sayılmaz.

## Sonraki somut iş

Sonraki işler: B01–B04 tam rotaları, B05 görev sırası/düşme/final tekrarı ve dokunmatik kullanım testleri; B05 sahne/animasyon görsel QA'sı; daha sonra kullanıcının tercihiyle Pages ayarı ve hosted tarayıcı testi. Canlı link gelmeden oyunu tamamlandı sayma. Canlı link gelmeden oyunu tamamlandı sayma.
