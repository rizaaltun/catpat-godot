# T22 çalışma kopyası — B05 Festival Alanı (19 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim B05 sahnesi; fiziksel yürüme/zıplama, bölünmüş güvenli zemin, istasyonlara çıkan alçak platformlar, üç görev noktası, Porsuk/Maymun/Pıtpıt istasyon görselleri ve katkı hareketleri, portreli final paneli. Zemin ve sahne poligonları hâlâ teknik görseldir; motor testi yapılmadı.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Yerel çalışma ortamında Godot ikilisi yok; T22 GDScript import/parse, motor yaşam döngüsü, fizik, sahne görseli ve eski regresyonlar henüz **çalıştırılmadı**. GitHub Actions'ta Godot 4.4.1 import, test ve Web export işi eklendi (run 39265588944 queued). Bu paket test sonucu gelene dek **oynanabilirliği doğrulanmamış T22 adayıdır**. B05'e kitap türevi görseller ve katkı hareketleri eklendi; gerçek cihaz görsel QA'sı yapılmadı. Karakter kimliği `USER_PENDING`.

## Son durum ve doğrulama\n\n- 54 runtime görsel kullanıcı izniyle WebP olarak GitHub dalına aktarıldı; PDF/PSD ve kitap sayfası taramaları hariç tutuldu.\n- CI run: https://github.com/rizaaltun/catpat-godot/actions/runs/39265588944 (kuyrukta).\n- GitHub Pages depo API'sinde kapalı; canlı tarayıcı bağlantısı henüz yok.\n\n## Önce yapılacak doğrulama

1. Godot 4.4.1 standart sürümünde `project.godot` aç; import, script parse ve B01-B04 eski testlerini çalıştır.
2. Geçerli B04 waymark.seen kaydından seyir noktasında E ile B05 açılışını dene. Geçersiz kayıt ve kayıt yazma hatasında ilerlemenin korunmasını test et.
3. B05 üç görevi farklı sırayla tamamla, her birinden sonra kaydet/menü/Devam yap; bitişi tekrar oynatınca yinelenen görev kaydı oluşmadığını test et.
4. Farklı genişlik/ekran oranlarında kontrol panelini, kamera ve platform boşluklarını doğrula; dokunmatik hareket tuşlarının basılı tutma davranışını fiziksel cihazda test et.
5. Görsel ve oynanış QA turunu gerçek ekran/video ve loglarla kaydet. Sadece kaynak incelemesi geçiş kanıtı sayılmaz.

## Sonraki somut iş

Önce CI run sonucunu al, Godot import/parse ve mevcut regresyon hatalarını düzelt; sonra B05 görev parkurunu ve final görselini gerçek motor ekranında doğrula. Kalan işleri: kolay rota, sahne cilası, görev/checkpoint QA, Web export ve Pages yayını. Canlı link gelmeden oyunu tamamlandı sayma.
