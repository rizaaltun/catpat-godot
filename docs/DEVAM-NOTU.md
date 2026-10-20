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
- CI run 39385190445 (https://github.com/rizaaltun/catpat-godot/actions/runs/39385190445) Godot import/parse, kayıt/diyalog/çizgi roman regresyonları, B01-B03 tam sahne oyun akışı regresyonları, B04 geçiş/ana görev regresyonları, B05 68/68 sözleşme ve hareket kontrolü, ve Web export adımlarının tümünü geçti.
- B01 `--v9-test` (V9 chapter suite), B02 `--v10-test` (V10 river suite), B03 `--v13-test` (V12 garden suite) gerçek sahne ve fizik üstünde otomatik hareket/etkileşim rotalarını yürüttü; her suite başarı mesajı verdi ve CI adımı exit code 0 ile tamamlandı. Bu, otomatik headless rotalara kanıttır; cihazda elle oynanış ya da görsel QA değildir.
- B04 `root_transition.gd` ve `root_main_quest.gd` geçiş/ana görev kontrolleri geçti; B04 parkurunun bütün alternatif oyuncu rotaları ve fiziksel cihaz testi ayrı doğrulanmadı.
- `tests/save_test.gd` ayrıca B01-B04 giriş/orta/çıkış veya banka kayıt noktalarını, ankrajları ve geçersiz kayıt noktalarını doğruluyor (run 39277080713).
- B05 son koşusu 39385190445 içinde 68 kontrolü, 0 başarısızlıkla geçti. Üç katkı, görev sırası, final, kayıt/yeniden açılışın yanında gerçek fizik adımlarıyla giriş kıyısından Porsuk platformuna iki zıplama ve kayıtlı noktaya gerçek düşüş sonrası dönüş sınandı. Diğer istasyonlar ve final parkuruna geçiş hâlâ testte doğrudan konumlanıyor; tam B05 oyuncu rotası sayılmaz. İlk koşuda eksik kalan Porsuk yürüyüş görseli 4547a4158a14e9331a2b174a18a76c7d59809133 ile eklendi.
- Final sonrası b05.stage kayıt noktası gerçek final platformuna taşındı ve yeniden açılış testi 22f6cda81eda9554c6fdc22197ed53cdaddbdbf0 commit'inde eklendi.
- Kullanıcının 19 Ekim 2026 tarihli izniyle oyunun kullandığı 56 yayımlanabilir WebP görsel public dala eklendi (25.45 MB; 90.13 MB kaynak PNG toplamına göre yaklaşık %72 daha küçük). PDF/PSD kitap orijinalleri ve `preproduction/references/` sayfa taramaları public depoya alınmadı.
- GitHub Actions Godot Web export'u başarılı oldu. GitHub Pages kapalı; kullanıcı yayın ayarını şimdilik erteledi. Canlı tarayıcı URL'si henüz yok.
- Görsel viewport/cihaz QA, B04'ün tam elle oynanış rotaları, B05'in tüm istasyonları ve finali kapsayan gerçek hareket rotası, viewport/görsel QA ve farklı ekran oranı/dokunmatik kontrolleri hâlâ açık. Headless testler gerçek cihaz testi yerine geçmez.

## Sıradaki işler

1. B04 parkurunun kalan elle/cihaz rotalarını ve B05'in diğer istasyon/final rotalarını Godot viewport'unda doğrula.
2. Festival final alanı, arkadaş animasyonları, dokunmatik basılı tutma ve pause/devam için viewport/video QA'sı üret.
3. Epsilon rehberine göre ortak oyun kataloğu, beceri sözlüğü ve gözlem şeması eksiklerini kapat; görev bayraklarını beceri gelişimi kanıtı gibi sunma.
4. Pages yayını ve canlı URL'yi kullanıcı yayın ayarını yeniden açtığında tamamla.


## 20 Ekim 2026 — B05 tam fizik rotası CI doğrulaması

- Commit: `6acae68141b10e8675fd9477a74059136a144e41` — `test: traverse B05 stations and finale with physics controls`.
- CI run 39387504240 (https://github.com/rizaaltun/catpat-godot/actions/runs/39387504240) geçti: Godot 4.4.1 import/parse, kayıt/diyalog/çizgi roman testleri, B01, B02, B03 tam oyun akışı, B04 geçiş regresyonları, B05 ve Web export başarılı.
- B05 artık başlangıç kıyısından Porsuk'a, Maymun istasyonuna, Pıtpıt istasyonuna ve final sahnesine yürüme/zıplama/yerçekimi ile ulaşmayı deniyor. Katkıların ve arkadaşların sahneye varışının ardından final anahtarı, final ekranı, kaydın yeniden açılması ve sahne durumunun geri kurulması doğrulandı. Sonuç: 87 kontrol, 0 hata. Tüm hareketler testte kontrollerle yapıldı; istasyon ve final rotaları testin başında doğrudan konumlanmıyor.
- B01–B04 regresyonları aynı koşuda geçti. Tarayıcı Web export'u da başarıyla üretildi; bu GitHub Pages yayını değildir ve henüz canlı test URL'si yoktur.
- Bu yeni CI sonucu, yukarıdaki 68/68 B05 kapsam notunu ve istasyon/finalin doğrudan konumlandırmayla sınandığı eski notu geçersiz kılar. Görsel viewport/animasyon QA'sı, gerçek dokunmatik cihaz testi ve B04'ün elle oynanış QA'sı hâlâ açık. Yerel Godot editörü mevcut değil.
- PDF/PSD kitap orijinalleri ve kitap sayfası taramaları public dala alınmadı.


## 20 Ekim 2026 — GitHub Pages dağıtım akışı ve engel

- Commit `68e1444df4fa1c6330c5f732ee83500d1c4f8e52` Pages dağıtım adımlarını, `349f3d0cefac826f2d043ff76cdb14c8e7047374` ise `work/t22-source-migration` dalına başarılı push sonrasında otomatik dağıtımı ekledi. Build ve regresyonlar başarılı olmadan Web çıktısı Pages'e gönderilmez.
- Kullanıcı repo Settings > Pages içinde kaynak olarak `GitHub Actions` seçti.
- CI run 39397426637 (https://github.com/rizaaltun/catpat-godot/actions/runs/39397426637) Godot 4.4.1 import/parse, kayıt/diyalog/çizgi roman testleri, B01–B04 regresyonları, B05'in 87 kontrolü ve Web export'un tamamını geçti. Pages artifact'i 69.1 MB olarak yüklendi.
- `deploy` işi GitHub Pages ortam korumasında durduruldu: `work/t22-source-migration` dalı `github-pages` ortamında dağıtıma izinli değil. Dolayısıyla canlı URL henüz doğrulanmadı ve dağıtım gerçekleşmedi.
- Gerekli repo ayarı: Settings > Environments > `github-pages` > Deployment branches and tags bölümünde yalnızca `work/t22-source-migration` dalına izin ver. Bu değişiklikten sonra başarısız `deploy` işini yeniden çalıştırıp sayfayı doğrula: `https://rizaaltun.github.io/catpat-godot/`.
- GitHub bağlantısı kaynak ve Actions iş akışına yazabiliyor; ortam dağıtım dalı korumasını değiştiren bir bağlı GitHub aracı bulunmuyor. Bu tek repo ayarı kullanıcı tarafından yapılmalı; kimlik bilgisi istenmemeli.
- PDF/PSD kitap orijinalleri ve hakları doğrulanmamış kaynaklar yayımlanmadı.


## 20 Ekim 2026 — GitHub Pages canlı

- `github-pages` ortamına `work/t22-source-migration` dalı için izin verildikten sonra run 39398487268'in `deploy` işi yeniden çalıştırıldı ve başarılı tamamlandı: https://github.com/rizaaltun/catpat-godot/actions/runs/39398487268.
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/. Tarayıcı sayfası açıldı ve başlık `Çatpat: Festival Yolu` olarak doğrulandı.
- Kullanılan doğrulama tarayıcısı WebGL2 desteği sağlamadığı için Godot canvas'ı bu tarayıcıda başlatamadı. Bu, bu tarayıcı ortamındaki WebGL2 kısıtıdır; B01–B04 regresyonları, B05'in 87 kontrolü ve Godot Web export CI'da başarılıdır. Kullanıcının WebGL2 destekli güncel masaüstü tarayıcısında oyun etkileşimi ayrıca denenmeli.
- PDF/PSD kitap orijinalleri ve hakları doğrulanmamış kaynaklar yayımlanmadı.


## 20 Ekim 2026 — açılış, Türkçe yazılar ve görev kurtarma

- Kullanıcı geri bildirimi: oyunda bazı yazılar görünmüyor, görev tamamlanmıyor ve giriş ekranı hatalı.
- Commit `b3fcb026002fd9d491060aed755b4e6062d8ed7f`, Fredoka fontunun eksik Türkçe glifleri için SIL Open Font License'lı Baloo 2 fallback fontunu ve lisans dosyasını ekledi. Menü başlığı da ortak font oluşturucusuna alındı.
- Aynı commit'te `_dialogue_done` reddedilen görev olayında artık sessizce çıkmıyor; mevcut ilerlemeyi değiştirmeden oyuncu kontrollerini çözüp kurtarma mesajı gösteriyor.
- Commit `8fc7398673be2a33186b2ea7bcad1b43f6c25e0f`, açılış ve glif regresyonundaki test-harness Unicode byte dolaşımını açık kod noktalarıyla düzeltti.
- `tests/startup_regression.gd` 12 Türkçe glifi, başlangıç ana menüsünü, “Yola çık” düğmesinin ilk konuşmayı başlatmasını ve reddedilen görev sonrası kurtarma ekranını denetliyor. Tüm bu kontroller CI'da geçti.
- CI run 39414967417 (https://github.com/rizaaltun/catpat-godot/actions/runs/39414967417) Godot importu, kayıt/diyalog/çizgi roman testleri, yeni açılış/font/kurtarma testi, B01, B02, B03, B04, B05 (87 kontrol), Web export ve GitHub Pages dağıtımını başarıyla tamamladı.
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/ . Bu ortamda Godot canvas'ı görsel olarak oynatacak WebGL2 tarayıcı doğrulaması hâlâ mümkün değil; yeni CI, menünün sahne ağacında gerçekten açıldığını ve başlatma düğmesinin çalıştığını doğruluyor. WebGL2 destekli normal masaüstü tarayıcıda görsel/dokunmatik QA açık.
- PDF/PSD kitap orijinalleri ve hakları doğrulanmamış kaynaklar depoya eklenmedi.


## 20 Ekim 2026 — kullanıcı tekrar bildirimi ve gerçek etkileşim QA'sı

- Kullanıcı, önceki yayındaki arızaların sürdüğünü bildirdi. Canlı GitHub Pages sekmesi bu çalışma ortamında açıldı; Godot başlangıç hata paneli `WebGL2` desteğinin bulunmadığını bildiriyor. Bu nedenle bu tarayıcıda oyun görüntüsü/etkileşimi doğrulanamıyor; önceki headless CI başarıları bu sınırın yerine geçmez.
- Godot 4 Web export'u Compatibility renderer ile WebGL 2.0 gerektirir. Resmî Godot 4.4 dokümantasyonu: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html
- Commit `777c3c2aee2b9b85b58f2083d3e2881b095da07a`, Web export'u commit'e özgü JS/WASM/PCK adlarıyla üretir ve ana HTML'e no-cache yönergeleri ekler. Amaç, tarayıcının eski aynı adlı oyun paketini kullanma olasılığını kaldırmak; CI export aşaması üç hash'li dosyayı ve giriş HTML'sini denetledi.
- B05 önceki sözleşme testi etkileşimi doğrudan `interact()` çağırarak yapıyordu. Gerçek tuş işleyicisi ve görünür eylem düğmesi bu rotadan geçmiyordu. `tests/festival_contract.gd` artık Porsuk için E tuşu işleyicisini; Maymun, Pıtpıt ve final için oyun içi düğme sinyallerini tetikliyor. CI run 39419422369 içinde B05 sözleşmesi 87 kontrol ve 0 hata ile geçti.
- Commit `777c3c2aee2b9b85b58f2083d3e2881b095da07a` Web çıktısını commit SHA içeren dosya adlarıyla üretip ana HTML'e no-cache yönergeleri ekledi; CI run 39418462087 export doğrulaması ve Pages dağıtımını geçti. Ardından commit `5768635a6efa612f6039e6d98210ca584a6cad93` B05 kontrollerini gerçek giriş işleyicileriyle sınadı. CI run 39419422369 tüm B01–B05 regresyonlarını, hash'li Web export'u ve Pages dağıtımını geçti. Canlı URL: https://rizaaltun.github.io/catpat-godot/. Önceki "oyun düzeldi" ifadesi fazla kesin olmuştu: bu araçta WebGL2 olmadığından canlı oyunun görüntüsü/tıklaması denenmemişti. Kalan QA: WebGL2 destekli tarayıcıda görsel oynanış ve dokunmatik rotalar.
- PDF/PSD kitap kaynakları ve hakları doğrulanmamış görseller eklenmedi.


## 20 Ekim 2026 — oyun içi hikâye metni aktarım düzeltmesi

- Kullanıcı yeniden bildirdiğinde menüde yalnızca kısa bir slogan bulunduğu ve B05 finalinde senaryo metninin tek satırlık özetle değiştirildiği denetlendi. production/STORY_SCRIPT.json içindeki D00 açılış ve B05 final metinleri runtime arayüzünde kullanılmıyordu.
- Açılış ekranına D00 senaryosunun üç cümlesi geri eklendi. B05 final paneline arkadaşların yardımını ve birlikte varışı anlatan beş cümle geri eklendi; dar panelde okunması için metin kutusu ve punto düzenlendi.
- tests/startup_regression.gd açılış metninin tamamını, tests/festival_contract.gd final metninin içerik bütünlüğünü doğrulayacak şekilde genişletildi. CI sonucu ve canlı dağıtım SHA'sı tamamlanınca bu not güncellenecek.
