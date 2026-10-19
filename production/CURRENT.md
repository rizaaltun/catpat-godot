# T22 çalışma kopyası — B05 Festival Alanı (19 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim uzunlukta gerçek Godot B05 sahnesi; fiziksel yürüme/zıplama, sekiz alçak platform, kamera sınırları, düşmede güvenli dönme, üç ayrı görev noktası ve sahnede final etkileşimi. Basit dünya çizimleri **geçici teknik görseldir**, kitap sanatı kabulü değildir.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Bu ortamda Godot ikilisi olmadığı için GDScript import/parse, motor yaşam döngüsü, gerçek oyun fiziği, resim testi ve tüm eski regresyonlar **çalıştırılmadı**. Bu paket **motor testi yapılmamış T22 uygulama adayıdır**, tamamlanmış/oynanabilir olduğu onaylanmış oyun değil. B05 çevresi basit teknik geometri ve geçici istasyon işaretleri kullanıyor; kitapla bütünleşik sanat ve arkadaş animasyonları henüz üretilmedi. Gerçek mobil Safari/iPhone denetimi yapılmadı. Karakter USER_PENDING değişmedi.

## Önce yapılacak doğrulama

1. Godot 4.4.1 standart sürümünde `project.godot` aç; import, script parse ve B01-B04 eski testlerini çalıştır.
2. Geçerli B04 waymark.seen kaydından seyir noktasında E ile B05 açılışını dene. Geçersiz kayıt ve kayıt yazma hatasında ilerlemenin korunmasını test et.
3. B05 üç görevi farklı sırayla tamamla, her birinden sonra kaydet/menü/Devam yap; bitişi tekrar oynatınca yinelenen görev kaydı oluşmadığını test et.
4. Farklı genişlik/ekran oranlarında kontrol panelini, kamera ve platform boşluklarını doğrula; dokunmatik hareket tuşlarının basılı tutma davranışını fiziksel cihazda test et.
5. Görsel ve oynanış QA turunu gerçek ekran/video ve loglarla kaydet. Sadece kaynak incelemesi geçiş kanıtı sayılmaz.

## Sonraki somut iş

Önce parse ve B04→B05 gerçek motor geçişini doğrula; hata varsa düzelt. Sonra B05 geçici geometriyi blueprint ve kitap sanatıyla değiştir, 3 arkadaşın fiilen görünen katkı animasyonlarını, festival diyaloglarını ve daha güvenilir dokunmatik kontrolü tamamla.
