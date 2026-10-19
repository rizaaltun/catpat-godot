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
- 54 runtime görsel WebP'ye çevrildi (24.62 MB; kaynak PNG'lerden %72 daha küçük); 22 oyun scriptinin ve ilgili QA/test scriptlerinin görsel yolları WebP'ye çevrildi. Ölçüler ve alfa kanalları kaynakla aynı kaldı; Godot importu ayrıca test edilecek.
- B05 kaynak düzeltmesi `329449d175f0a6d1e46f42e7210fcf9847d40548` commit'inde: üç katkı istasyonuna platform çıkışı eklendi, görevler ilgili istasyon platformunda etkileşim istiyor, her istasyonda arkadaş sprite'ı ve katkı hareketi var; final paneli üç arkadaş portresi ve katkı replikleri gösteriyor. Dünya zemini teknik poligonlar, sahne ise teknik geometri kullanmaya devam ediyor.
- `c1dc0c2f170cf90d2a34d3cf0e9d5990daa9ebd3` commit'i Godot 4.4.1 import/regresyon/Web export iş akışını ekledi. Godot importu geçti. İlk izole regresyon koşusu `scripts/core/quest_state.gd:31` satırındaki `const EVENTS` dizi birleştirmesinde parse hatasını yakaladı; test komutunu 120 saniyede sonlandırdı. `79072dc2c7469bdbcfa0033d37b44224d64d5e1d` sabit diziyi inline tanımlayarak parse hatasını düzeltti. CI run `39267073041` tüm adımları geçti: Godot importu, kayıt/diyalog/çizgi roman regresyonları, B04 geçiş kontrolleri, B05 sahne-kayıt sözleşmesi ve tarayıcı Web export'u.

## Bağımsız denetim bulguları

- Kullanıcının izniyle T22 arşivinden oyunun kullandığı 54 runtime görsel 24.62 MB WebP olarak eklendi; 87.84 MB kaynak PNG toplamına göre yaklaşık %72 küçüldü. Boyutlar korundu ve alfa kanalları kaynakla aynı kaldı; bu yapısal doğrulamadır, Godot içe aktarma testi değildir. Çatpat, Porsuk, Maymun ve Pıtpıt karakter kimliği onayları `USER_PENDING` olarak kalıyor.
- B05 arkadaşları artık görev istasyonlarında ve final panelinde görünür; katkı anında mevcut kitap türevi poz sprite'ı kısa hareket eder. Karakter kimliği onayları `USER_PENDING`; bu commit yeni kimlik tasarımı üretmedi. Görünüm henüz Godot'ta görsel QA'dan geçmedi.
- B05 zemini kaynakta kısa bölümlere ayrıldı, aralıklardaki düşüş en son checkpoint'e döner. Katkı görevleri artık ilgili yükseltilmiş platform yüksekliğinde yapılabiliyor. Güvenli/kolay alternatif rota ve erişilebilirlik davranışı hâlâ tasarım/oyun testi bekliyor; bu düzeltmeler motor testinden geçmedi.
- B05 üç görevi yakınlık etkileşimi ve tamamlandı bayraklarıyla kaydediyor; beceri/gelişim gözlemi veya ebeveyn raporu yok. B01'deki Yolculuk defteri oyuncuya dönük ilerleme arayüzüdür; ebeveyn raporu değildir. Görev bayrakları yalnızca etkileşimin tamamlandığını kanıtlar, beceri gelişimini değil.
- B05 ekip finali artık üç katkı repliğini ve arkadaş portrelerini gösteriyor; tekrar oynatma ve gerçek sahne görünümü motor testinde doğrulanmalı.

## Test ve yayın durumu

- Bu çalışma ortamında Godot CLI/editor yok; CI, Godot 4.4.1 ile import/parse, kayıt, diyalog, çizgi roman, B04 geçişi, B05 sözleşmesi ve Web export kontrollerini başarıyla çalıştırdı (run `39267073041`). Bu, gerçek cihazda sahne oynanışı veya görsel QA yerine geçmez. WebP bütünlüğü, kaynakla boyut eşleşmesi ve alfa kanalları Pillow ile ayrıca doğrulandı.
- B01–B04 kayıt/diyalog/çizgi roman regresyonları ve B04 geçiş kontrolleri CI'da geçti. Bölümlerin baştan sona oyuncu rotası, fiziksel dokunmatik testleri, pause/devam ve kesinti senaryoları ayrıca doğrulanmalı.
- B05 kabul vakaları A50–A54 tasarım aşamasında; görev sırası, düşme/toparlanma, kayıt/yeniden açılış, final tekrarı ve dokunmatik testleri çalıştırılmadı.
- Godot Web export CI'da başarıyla üretildi. Tarayıcıda oynanış henüz doğrulanmadı. Depo API'si GitHub Pages'in etkin olmadığını bildiriyor; bu nedenle şu anda canlı test URL'si yok. Dal tamamlanmış teslim değildir.

## Sıradaki işler

1. En güncel commit üzerindeki CI koşusunu doğrula; regresyon/B05 sözleşmesi/Web export hatası varsa düzelt.
2. B01–B04'ü T22 kaynaklarıyla Godot 4.4.1'de import et ve test et; B04→B05, kayıt şema10, dokunmatik, pause/devam, kesinti ve temiz tam koşu kanıtlarını build/commit hash'iyle kaydet.
3. B05 platform rotalarını ve güvenli kolay rotayı tasarımla eşleştir; her istasyona gerçek zıplayış, düşme/checkpoint, sıra bağımsız görev ve kayıt/yeniden açılış davranışlarını motor testleriyle doğrula.
4. B05'in gerçek sahne görüntüsünü Godot'ta incele; üç arkadaşın katkı animasyonları ve final dizilimini doğrula. Karakter kimliği onaylarını beklemeden yeni tasarım üretme.
5. Öğrenme/ebeveyn raporu istenen rehber gereksinimlerini ayrı kapsam olarak ele al: ortak beceri kataloğu ve gözlem şeması yok; görev bayraklarını öğrenme kanıtı gibi raporlama.
6. Pages yayını için etkinleştirme yolunu tamamla, başarılı Web export'u tarayıcıda oynat ve canlı test URL'sini/kanıtını bu nota ekle.
