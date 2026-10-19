# Çatpat devam notu — T22 kaynak aktarımı ve denetim, 19 Ekim 2026

## Proje ve standartlar

- Oyun: Çatpat: Festival Yolu; Godot 4.4.1 / GDScript.
- Ortak rehber: Epsilon Oyun Geliştirme Rehberi v1.0 (16 Ekim 2026).
- T22 proje arşivi: `Catpat-Godot-T22-Guncel-Proje (4).zip`; temel zincir V21, B05 Festival Alanı kod adayı.
- Geliştirme dalı: `work/t22-source-migration`.

## Tamamlanan aşamalar

- T22 arşivinden 87 Godot ayarı, sahnesi, scripti ve UID dosyası aktarıldı. 85 farklı dosya `source: restore Godot scripts and chapter scenes` commit'inde değişti: https://github.com/rizaaltun/catpat-godot/commit/83f5fea8ae0ac97934bdb3bd7d3016e9cc4523a2
- Tasarım, test ve devir belgeleri ile lisansı doğrulanmış Fredoka yazı tipi ikinci commit'te eklendi: https://github.com/rizaaltun/catpat-godot/commit/257ba3ba8787dec59f383b610ad5ce4fa5f29c27
- B01–B05 sahneleri ve GDScript kaynakları mevcut. `project.godot` başlangıç sahnesi `scenes/polish_v3.tscn` olarak korundu.
- Kullanıcı 19 Ekim 2026'da yayınevi kitabından gelen proje görsellerinin bu oyun için aktarılmasına izin verdi. PDF/PSD orijinalleri, `preproduction/references/` kitap sayfası taramaları ve taslak temas sayfası public depoya alınmadı.
- 55 runtime görsel WebP'ye çevrildi (25.22 MB; 90.13 MB kaynak PNG'lerden yaklaşık %72 daha küçük); 22 oyun scriptinin ve ilgili QA/test scriptlerinin görsel yolları WebP'ye çevrildi. Ölçüler ve alfa kanalları kaynakla aynı kaldı; Godot 4.4.1 CI importu geçti.
- B05 kaynak düzeltmesi `329449d175f0a6d1e46f42e7210fcf9847d40548` commit'inde başladı. Sonraki commit'ler orman/şenlik arka planı, yosunlu platform görselleri, festival yön işaretleri ve Pıtpıt görevi tamamlanınca açılan çiçekleri ekledi; yanlış kullanılan konuşma balonu görselleri kaldırıldı. Üç katkı istasyonunun platform çıkışı ve katkı animasyonları, portreli final paneli mevcut. Bazı sahne/zemin geometri parçaları hâlâ teknik poligon; oyun içi görsel QA gerekli.
- `production/.gdignore` Godot'un üretim dokümanları ve CSV tablolarını projeye import etmesini ve oyuna export etmesini önler; kaynak dosyalar GitHub'da kalır. Kod taramasında `res://production` bağımlılığı bulunmadı. Bu değişiklikten sonraki CI importu geçti.
- `c1dc0c2f170cf90d2a34d3cf0e9d5990daa9ebd3` commit'i Godot 4.4.1 import/regresyon/Web export iş akışını ekledi. Godot importu geçti. İlk izole regresyon koşusu `scripts/core/quest_state.gd:31` satırındaki `const EVENTS` dizi birleştirmesinde parse hatasını yakaladı; test komutunu 120 saniyede sonlandırdı. `79072dc2c7469bdbcfa0033d37b44224d64d5e1d` sabit diziyi inline tanımlayarak parse hatasını düzeltti. CI run `39275862970` (https://github.com/rizaaltun/catpat-godot/actions/runs/39275862970) tüm adımları geçti: Godot importu, kayıt/diyalog/çizgi roman regresyonları, B04 geçiş kontrolleri, 49 B05 sözleşme/oyun-içi kontrolü ve tarayıcı Web export'u.

## Bağımsız denetim bulguları

- Kullanıcının izniyle T22 arşivinden oyunun kullandığı 55 runtime görsel 25.22 MB WebP olarak eklendi; 90.13 MB kaynak PNG toplamına göre yaklaşık %72 küçüldü. Ölçüler ve alfa kanalları korundu; Godot CI importu da geçti. Orijinal PDF/PSD ve kitap sayfası taramaları public depoya alınmadı. Çatpat, Porsuk, Maymun ve Pıtpıt karakter kimliği onayları `USER_PENDING`.
- B05 orman, platform, yön tabelası ve çiçek görselleri mevcut oyun kaynaklarını kullanıyor; `Parallax2D` orman arka planı ve kamp görseli CI'da sahneye yüklendi. Üç görev arkadaşının portreleri/katkı hareketleri var. CI gerçek frame görüntüsünü incelemedi; görsel kompozisyon ve animasyon kalitesi editör/cihaz QA'sı bekliyor. Yeni karakter kimliği tasarımı üretilmedi.
- B05 kısa güvenli zemin parçaları, yükseltilmiş görev platformları ve checkpoint'e düşüş dönüşünü içeriyor. Smoke testinde platform altındaki yürüme görevi tetiklemedi; Porsuk ve Pıtpıt platformlarında görev kaydı ile checkpoint yazımı geçti. Üç görevin tüm rotası, düşme/toparlanma ve kolay rota gerçek oyuncu QA'sı bekliyor.
- B05 üç görevi yakınlık etkileşimi ve tamamlandı bayraklarıyla kaydediyor; beceri/gelişim gözlemi veya ebeveyn raporu yok. B01'deki Yolculuk defteri oyuncuya dönük ilerleme arayüzüdür; ebeveyn raporu değildir. Görev bayrakları yalnızca etkileşimin tamamlandığını kanıtlar, beceri gelişimini değil.
- B05 üç görevi görev bayrakları ve checkpoint'lerle kaydediyor; CI smoke testinde Porsuk ve Pıtpıt etkileşimi ve çiçeklerin dünyada görünmesi geçti. Tüm sıra varyasyonları, final paneli, finali tekrar oynatma ve gerçek sahne görüntüsü henüz görsel/oyuncu QA'sından geçmedi.

## Test ve yayın durumu

- Bu çalışma ortamında Godot CLI/editor yok; CI, Godot 4.4.1 ile import/parse, kayıt, diyalog, çizgi roman, B04 geçişi, B05 sözleşmesi ve Web export kontrollerini başarıyla çalıştırdı (run `39275862970`). Bu, gerçek cihazda sahne oynanışı veya görsel QA yerine geçmez. WebP bütünlüğü, kaynakla boyut eşleşmesi ve alfa kanalları Pillow ile ayrıca doğrulandı.
- B01–B04 kayıt/diyalog/çizgi roman regresyonları ve B04 geçiş kontrolleri CI'da geçti. Bölümlerin baştan sona oyuncu rotası, fiziksel dokunmatik testleri, pause/devam ve kesinti senaryoları ayrıca doğrulanmalı.
- B05 kayıt/sahne smoke testi 49 kontrolle geçti; Porsuk ve Pıtpıt platform etkileşimleri, platform altından etkileşim engeli, görev kaydı, checkpoint ve çiçek görünürlüğü doğrulandı. A50–A54 tam kabul turu, üç görevin tüm sıra varyasyonları, düşme/toparlanma, final tekrar/yeniden açılış ve dokunmatik testleri hâlâ yapılmalı.
- Godot Web export CI'da başarıyla üretildi. Tarayıcıda oynanış henüz doğrulanmadı. Depo API'si GitHub Pages etkin değil. Kullanıcı Pages yayını adımını şimdilik erteledi; canlı test URL'si sonraki aşamada açılacak. Web export CI'da üretildi, tarayıcı oynanışı henüz test edilmedi. Dal tamamlanmış teslim değildir.

## Sıradaki işler

1. Son doğrulanmış CI run `39275862970`; sonrasında yalnızca bu notlar değişirse CI sonucu gerekmez, oyun kaynakları değişirse tekrar çalıştır.
2. B01–B04'ü T22 kaynaklarıyla Godot 4.4.1'de import et ve test et; B04→B05, kayıt şema10, dokunmatik, pause/devam, kesinti ve temiz tam koşu kanıtlarını build/commit hash'iyle kaydet.
3. B05 üç istasyon rotasını, düşme/checkpoint toparlanmasını, final tekrarı ve kayıt/yeniden açılışı motor/oyuncu testleriyle doğrula; güvenli kolay rotayı tasarımla eşleştir.
4. B05'in gerçek sahne görüntüsünü Godot'ta incele; üç arkadaşın katkı animasyonları ve final dizilimini doğrula. Karakter kimliği onaylarını beklemeden yeni tasarım üretme.
5. Öğrenme/ebeveyn raporu istenen rehber gereksinimlerini ayrı kapsam olarak ele al: ortak beceri kataloğu ve gözlem şeması yok; görev bayraklarını öğrenme kanıtı gibi raporlama.
6. Pages yayını için etkinleştirme yolunu tamamla, başarılı Web export'u tarayıcıda oynat ve canlı test URL'sini/kanıtını bu nota ekle.
