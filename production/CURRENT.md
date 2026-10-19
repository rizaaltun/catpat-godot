# T22 çalışma kopyası — B05 Festival Alanı (19 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim B05 sahnesi; fiziksel yürüme/zıplama, bölünmüş güvenli zemin, istasyonlara çıkan alçak platformlar, üç görev noktası, Porsuk/Maymun/Pıtpıt istasyon görselleri ve katkı hareketleri, portreli final paneli. Zemin ve sahne poligonları hâlâ teknik görseldir; motor testi yapılmadı.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Yerel ortamda Godot ikilisi yok; GitHub Actions Godot 4.4.1 CI run `39267073041` başarılı: import/parse, kayıt/diyalog/çizgi roman regresyonları, B04 geçiş kontrolleri, B05 sahne-kayıt sözleşmesi ve Web export geçti. Bu kontroller temel motor/doğrulama kapılarını kapatır; gerçek cihazda B05 oynanışı, tam bölüm rotaları ve görsel QA hâlâ yapılmadı. Karakter kimliği `USER_PENDING`.

## Son durum ve doğrulama

- 54 runtime görsel kullanıcı izniyle WebP olarak GitHub dalına aktarıldı; PDF/PSD ve kitap sayfası taramaları hariç tutuldu.
- Başarılı CI run: https://github.com/rizaaltun/catpat-godot/actions/runs/39267073041 — Godot importu, kayıt/diyalog/çizgi roman regresyonları, B04 geçişi, B05 sahne-kayıt sözleşmesi ve Web export başarılı.
- GitHub Pages repo ayarlarında kapalı; canlı tarayıcı bağlantısı henüz yok. Web çıktısı CI'da üretildi ancak hosted tarayıcı testi bekliyor.

## Önce yapılacak doğrulama

1. Godot 4.4.1 standart sürümünde `project.godot` aç; import, script parse ve B01-B04 eski testlerini çalıştır.
2. Geçerli B04 waymark.seen kaydından seyir noktasında E ile B05 açılışını dene. Geçersiz kayıt ve kayıt yazma hatasında ilerlemenin korunmasını test et.
3. B05 üç görevi farklı sırayla tamamla, her birinden sonra kaydet/menü/Devam yap; bitişi tekrar oynatınca yinelenen görev kaydı oluşmadığını test et.
4. Farklı genişlik/ekran oranlarında kontrol panelini, kamera ve platform boşluklarını doğrula; dokunmatik hareket tuşlarının basılı tutma davranışını fiziksel cihazda test et.
5. Görsel ve oynanış QA turunu gerçek ekran/video ve loglarla kaydet. Sadece kaynak incelemesi geçiş kanıtı sayılmaz.

## Sonraki somut iş

Sonraki işler: B01–B04 tam bölüm rotası ve B05 görev/checkpoint oynanışını doğrula; kolay rota ve sahne cilasını tamamla; tarayıcıda Web build'i oynat ve Pages yayını için etkinleştirme yolunu çöz. Canlı link gelmeden oyunu tamamlandı sayma.
