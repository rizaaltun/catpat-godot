# Çatpat devam notu — T22 kaynak aktarımı ve test genişletmesi, 20 Ekim 2026

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
- 56 runtime görsel WebP'ye çevrildi (25.45 MB; 90.13 MB kaynak PNG'lerden yaklaşık %72 daha küçük); 22 oyun scriptinin ve ilgili QA/test scriptlerinin görsel yolları WebP'ye çevrildi. Ölçüler ve alfa kanalları kaynakla aynı kaldı; Godot 4.4.1 CI importu geçti.
- B05 kaynak düzeltmesi `329449d175f0a6d1e46f42e7210fcf9847d40548` commit'inde başladı. Sonraki commit'ler orman/şenlik arka planı, yosunlu platform görselleri, festival yön işaretleri ve Pıtpıt görevi tamamlanınca açılan çiçekleri ekledi; yanlış kullanılan konuşma balonu görselleri kaldırıldı. Üç katkı istasyonunun platform çıkışı ve katkı animasyonları, portreli final paneli mevcut. Bazı sahne/zemin geometri parçaları hâlâ teknik poligon; oyun içi görsel QA gerekli.
- `production/.gdignore` Godot'un üretim dokümanları ve CSV tablolarını projeye import etmesini ve oyuna export etmesini önler; kaynak dosyalar GitHub'da kalır. Kod taramasında `res://production` bağımlılığı bulunmadı. Bu değişiklikten sonraki CI importu geçti.
- `c1dc0c2f170cf90d2a34d3cf0e9d5990daa9ebd3` commit'i Godot 4.4.1 import/regresyon/Web export iş akışını ekledi. Godot importu geçti. İlk izole regresyon koşusu `scripts/core/quest_state.gd:31` satırındaki `const EVENTS` dizi birleştirmesinde parse hatasını yakaladı; test komutunu 120 saniyede sonlandırdı. `79072dc2c7469bdbcfa0033d37b44224d64d5e1d` sabit diziyi inline tanımlayarak parse hatasını düzeltti. CI run `39275862970` (https://github.com/rizaaltun/catpat-godot/actions/runs/39275862970) tüm adımları geçti: Godot importu, kayıt/diyalog/çizgi roman regresyonları, B04 geçiş kontrolleri, 49 B05 sözleşme/oyun-içi kontrolü ve tarayıcı Web export'u.

## Bağımsız denetim bulguları

- Kullanıcının izniyle T22 arşivinden oyunun kullandığı 56 runtime görsel 25.45 MB WebP olarak eklendi; 90.13 MB kaynak PNG toplamına göre yaklaşık %72 küçüldü. Ölçüler ve alfa kanalları korundu; Godot CI importu da geçti. Orijinal PDF/PSD ve kitap sayfası taramaları public depoya alınmadı. Çatpat, Porsuk, Maymun ve Pıtpıt karakter kimliği onayları `USER_PENDING`.
- B05 orman, platform, yön tabelası ve çiçek görselleri mevcut oyun kaynaklarını kullanıyor; `Parallax2D` orman arka planı ve kamp görseli CI'da sahneye yüklendi. Üç görev arkadaşının portreleri/katkı hareketleri var. CI gerçek frame görüntüsünü incelemedi; görsel kompozisyon ve animasyon kalitesi editör/cihaz QA'sı bekliyor. Yeni karakter kimliği tasarımı üretilmedi.
- B05 kısa güvenli zemin parçaları, yükseltilmiş görev platformları ve checkpoint'e düşüş dönüşünü içeriyor. Smoke testinde platform altındaki yürüme görevi tetiklemedi; Porsuk ve Pıtpıt platformlarında görev kaydı ile checkpoint yazımı geçti. Üç görevin tüm rotası, düşme/toparlanma ve kolay rota gerçek oyuncu QA'sı bekliyor.
- B05 üç görevi yakınlık etkileşimi ve tamamlandı bayraklarıyla kaydediyor; beceri/gelişim gözlemi veya ebeveyn raporu yok. B01'deki Yolculuk defteri oyuncuya dönük ilerleme arayüzüdür; ebeveyn raporu değildir. Görev bayrakları yalnızca etkileşimin tamamlandığını kanıtlar, beceri gelişimini değil.
- B05 üç görevi görev bayrakları ve checkpoint'lerle kaydediyor; CI smoke testinde Porsuk ve Pıtpıt etkileşimi ve çiçeklerin dünyada görünmesi geçti. Tüm sıra varyasyonları, final paneli, finali tekrar oynatma ve gerçek sahne görüntüsü henüz görsel/oyuncu QA'sından geçmedi.

## Test ve yayın durumu

- Yerel ortamda Godot CLI/editor yok; doğrulama Godot 4.4.1 GitHub Actions üzerinden yapılıyor.
- CI run 39383518955 (https://github.com/rizaaltun/catpat-godot/actions/runs/39383518955) Godot import/parse, kayıt/diyalog/çizgi roman regresyonları, B01-B03 tam sahne oyun akışı regresyonları, B04 geçiş/ana görev regresyonları, B05 sözleşmesi ve Web export adımlarının tümünü geçti.
- B01 `--v9-test` (V9 chapter suite), B02 `--v10-test` (V10 river suite), B03 `--v13-test` (V12 garden suite) gerçek sahne ve fizik üstünde otomatik hareket/etkileşim rotalarını yürüttü; her suite başarı mesajı verdi ve CI adımı exit code 0 ile tamamlandı. Bu, otomatik headless rotalara kanıttır; cihazda elle oynanış ya da görsel QA değildir.
- B04 `root_transition.gd` ve `root_main_quest.gd` geçiş/ana görev kontrolleri geçti; B04 parkurunun bütün alternatif oyuncu rotaları ve fiziksel cihaz testi ayrı doğrulanmadı.
- `tests/save_test.gd` ayrıca B01-B04 giriş/orta/çıkış veya banka kayıt noktalarını, ankrajları ve geçersiz kayıt noktalarını doğruluyor (run 39277080713).
- B05'in 61 kontrolü üç katkıyı, alternatif görev sırasını, katkı checkpoint'lerini, arkadaşların final alanına varmasını, final kilidini, ortak finali ve kanonik kayıt/yeniden açılışı sınar. İlk koşudaki eksik Porsuk yürüyüş görseli 4547a4158a14e9331a2b174a18a76c7d59809133 commit'inde eklendi; yeni run 39383518955 bütün kontrolleri ve Web export'u geçti.
- Final sonrası b05.stage kayıt noktası gerçek final platformuna taşındı ve yeniden açılış testi 22f6cda81eda9554c6fdc22197ed53cdaddbdbf0 commit'inde eklendi.
- Kullanıcının 19 Ekim 2026 tarihli izniyle oyunun kullandığı 56 yayımlanabilir WebP görsel public dala eklendi (25.45 MB; 90.13 MB kaynak PNG toplamına göre yaklaşık %72 daha küçük). PDF/PSD kitap orijinalleri ve `preproduction/references/` sayfa taramaları public depoya alınmadı.
- GitHub Actions Godot Web export'u başarılı oldu. GitHub Pages kapalı; kullanıcı yayın ayarını şimdilik erteledi. Canlı tarayıcı URL'si henüz yok.
- Görsel viewport/cihaz QA, B04'ün tam elle oynanış rotaları, B05 gerçek hareketle tam rota/düşme-kurtarma ve farklı ekran oranı/dokunmatik kontrolleri hâlâ açık. Headless testler gerçek cihaz testi yerine geçmez.

## Sıradaki işler

1. B04 parkurunun kalan elle/cihaz rotalarını ve B05'in gerçek hareketle tam rotasını, düşme/kurtarma ve ekran oranlarını Godot viewport'unda doğrula.
2. Festival final alanı, arkadaş animasyonları, dokunmatik basılı tutma ve pause/devam için viewport/video QA'sı üret.
3. Epsilon rehberine göre ortak oyun kataloğu, beceri sözlüğü ve gözlem şeması eksiklerini kapat; görev bayraklarını beceri gelişimi kanıtı gibi sunma.
4. Pages yayını ve canlı URL'yi kullanıcı yayın ayarını yeniden açtığında tamamla.
