# Çatpat devam notu — T22 kaynak aktarımı ve test genişletmesi, 20 Ekim 2026

## Proje ve standartlar

- Oyun: Çatpat: Festival Yolu; Godot 4.4.1 / GDScript.
- Ortak rehber: Epsilon Oyun Geliştirme Rehberi v2.1 (28 Ekim 2026); önceki üretim geçmişi v1.0 ile yürütülmüştür. v2.1 sanat/izlenebilirlik kapıları henüz tamamlanmış değildir.
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
- tests/startup_regression.gd açılış metninin tamamını, tests/festival_contract.gd final metninin içerik bütünlüğünü doğrulayacak şekilde genişletildi.
- Commit `517f60d239ffeb9b3843a24d81ca99010fd2e498` CI run `39421114316` içinde başarıyla doğrulandı: Godot import/parse, açılış/font/kurtarma, B01–B04 regresyonları, B05 88 kontrolü, Web export ve GitHub Pages dağıtımı geçti. Canlı sayfa: https://rizaaltun.github.io/catpat-godot/.
- Testler metinlerin sahne ağacında bulunduğunu ve export'un üretildiğini doğrular. Bu oturumun tarayıcısında WebGL2 yok; gerçek piksel çizimi ve yerleşimini gözle kontrol edemedim. WebGL2 destekli tarayıcıda okunurluk kontrolü açık.


## 20 Ekim 2026 — Windows ekran görüntüsündeki boş yazılar

- Kullanıcının Windows ekran görüntüsünde arka plan ve düğme kaplamaları görünürken ana başlık, menü yazıları ve düğme etiketlerinin tamamı boştu. Belirti işletim sisteminin kendisinden çok ortak font kaynağının çizilmediğini gösteriyor; Windows nedeni doğrulanmış değil.
- Ortak arayüz fontu `FontVariation` sarmalayıcısı ve iki değişken ekseni/fallback zinciri yerine tek, depoda bulunan `assets/fonts/Baloo2.ttf` dosyasından doğrudan yükleniyor. Menü başlığındaki ek değişken-font override kaldırıldı.
- Açılış regresyonuna font kaynağının Türkçe metin için gerçek ölçü döndürdüğü kontrolü eklendi. Commit `634c0b9bfa0d5894620bbe66f2eb6a2359d726cf`, CI run `39424591956` içinde Godot importu, açılış/font, B01–B05 ve Web export adımlarını geçti; Pages dağıtımı başarılı oldu: https://github.com/rizaaltun/catpat-godot/actions/runs/39424591956. Windows PC'de ekran çizimini gözle doğrulama, kullanıcı bilgisayarındaki test kopyasına erişemediğim için açık.


## 20 Ekim 2026 — devam oturumu: yayın durumu ve katalog taslağı

- Kullanıcı Türkçe metin sorununun düzeldiğini bildirdi; bu oturumda Windows cihazında yeni görsel yakalama yapılmadı. Son kod düzeltmesi doğrudan `assets/fonts/Baloo2.ttf` kaynağını kullanıyor; CI font ölçüm testini geçiyor.
- Devam notu eklenirken son doğrulanmış oyun kodu head'i `9839de17dc8423dabeefb540db791199f9f1d792` idi. CI run 39425479868 başarılı: Godot 4.4.1 import, açılış/font/kurtarma, B01–B04 regresyonları, B05, Web export ve Pages dağıtımı.
- Canlı test bağlantısı: https://rizaaltun.github.io/catpat-godot/ . Doğrudan görsel/touch QA bu oturumda çalıştırılmadı; geçmiş uzak tarayıcı WebGL2 desteklemedi.
- README'deki “oynanabilir değil / test edilmedi / canlı link yok” bilgisi artık yanlıştı; güncel CI, canlı URL ve kaynak hakları sınırıyla düzeltildi.
- `production/GAME_PROFILE.md` eklendi. B01–B05 tasarım amacı ve geçici beceri eşlemesi kayıt altına alındı. Kitap künyesi/hedef yaş ve uzman onayı depoda yok; varsayılmadı. Mevcut `quest_flags` yalnızca bölüm ilerlemesidir; beceri gözlemi veya ebeveyn raporu uygulanmış sayılmıyor.
- Yeni özellik kodu veya çocuk verisi toplanması eklenmedi; gözlem/rapor maddeleri uygulama öncesi sözleşme olarak işaretlendi. PDF/PSD ve kitap sayfası taramaları eklenmedi.
- Sıradaki somut iş: B04 elle rotası ve web viewport/touch görsel QA'sı için WebGL2 uyumlu cihazda test; paralel devamda katalog kimliği/yaşın doğrulanması ve ebeveyn gözlemi katmanının geriye uyumlu teknik tasarımı.


- Düzeltme kaydı: doküman commit'i oluşturulurken ağaç tabanı `517f60d` sürümünden alındığı için son Baloo 2 font fix'ini ve buna bağlı açılış regresyonunu geri almıştı. Bu commit `9839de1` ile doğrulanan `scripts/polish_ui.gd`, `scripts/polish_world.gd` ve `tests/startup_regression.gd` sürümlerini geri yükleyip CI ile yeniden doğruluyor. Bundan sonraki ağaç tabanları her zaman güncel branch head'inden alınmalı.


## 20 Ekim 2026 — font düzeltmesi geri yüklendi ve yeniden doğrulandı

- `ba011321` doküman commit'i için yanlışlıkla eski Git tree taban alınmış; ortak font dosyasını ve açılış regresyonunu önceki sürüme döndürmüştü. `c4584a235062210fce8b83a5cecb4434294094b9` bu üç dosyayı `9839de17` doğrulanmış içeriklerine geri aldı: `scripts/polish_ui.gd`, `scripts/polish_world.gd` ve `tests/startup_regression.gd`.
- Run 39427875628 tamamlandı ve başarılı oldu: import, kayıt/diyalog/çizgi roman, Türkçe font/açılış/kurtarma, B01, B02, B03, B04, B05, Web export ve Pages deploy.
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/ .
- Bundan sonraki kod yazımında ağaç tabanı güncel branch head'inden alınmalı; dosya farkları commit öncesi karşılaştırılmalı.


## 20 Ekim 2026 — B05 dokunmatik kontrolleri

- Godot 4.4 belgeleri standart Button düğmelerinin çoklu dokunmayı desteklemediğini belirtiyor. B05 yön düğmeleri basma/bırakma sinyallerini birleştiriyordu; basılı tutma ve eşzamanlı yön+zıplama güvenilir değildi.
- B05 oyun kontrolü artık ham parmak olaylarını InputRouter ile okuyor; HUD görselleri korundu. Her parmak başladığı kontrolde kalıyor, yön ve zıplama birlikte çalışıyor. Touch kaynaklı mouse olayı ikinci kez işlenmiyor. Pause ve uygulama odağı kaybı tutulmuş girdileri temizliyor.
- tests/festival_contract.gd gerçek touch olaylarıyla bırakmadan önce hareketi, eşzamanlı yön/zıplamayı, release davranışını ve Maymun/Pıtpıt etkileşim alanını kontrol edecek biçimde genişletildi.
- Gerçek cihaz ergonomisi ayrıca kontrol edilmeli; CI sonucu eklenecek.


- B05 dokunmatik kontrol uygulaması CI run 39430536599 içinde Godot import, B01–B04, B05 fizik/etkileşim rotaları, Web export ve Pages deploy ile geçti. B05 sonucu 92 kontrol, 0 hata; test basılı parmakla hareketi, aynı anda yön+zıplamayı ve Maymun/Pıtpıt görevlerine touch ile dokunmayı kapsıyor.
- Final sahne etkileşimi de son test commit'inde gerçek touch rotasına alındı. CI run 39431638234 B01–B05, web export ve Pages dağıtımını geçti; B05 tekrar 92 kontrol, 0 hata verdi. Final ışığı dokunmayla açıldı, final paneli ve kayıtlı final yeniden açılışı doğrulandı.
- Canlı test adresi son başarılı dağıtımdan sonra güncel: https://rizaaltun.github.io/catpat-godot/.


## 20 Ekim 2026 — B05 duraklatma sırasında sahne yürüyüşü

- Oyun içi düzeltme: B05'te üç görev tamamlanınca arkadaşları sahneye götüren Godot Tween animasyonları, sahne `paused` durumuna geçse de ilerliyordu. Hem arkadaşların katkı animasyonları hem sahneye yürüyüş Tween'leri pause/resume düğmesiyle birlikte durup devam ediyor; final ekranı da güvenli şekilde donduruyor.
- `tests/festival_contract.gd` görev katkı animasyonu ve sahne yürüyüşü sürerken duraklatmayı, 24 fizik karesinde arkadaşların ve Catpat'in konumlarının değişmemesini, devam ettikten sonra arkadaşların sahneye varmasını denetliyor.
- Oyun kodu commit'i `28eaab2adde73e39c1bb759bca92f8951e2d26bc`; CI run `39434597233` başarılı tamamlandı: Godot import/parse, kayıt/diyalog/çizgi roman, açılış/font/kurtarma, B01–B04 regresyonları, B05, Web export ve GitHub Pages dağıtımı geçti.
- B05 fizik/etkileşim sözleşmesi 96 kontrol ve 0 hata verdi. Yeni üç pause kontrolü geçti; devamdan sonra arkadaşların sahneye ulaşması da doğrulandı.
- Canlı test adresi: https://rizaaltun.github.io/catpat-godot/. Bu ortamda görsel WebGL2 tarayıcı QA'sı ve gerçek cihaz dokunmatik ergonomisi ayrıca denenmeli.

- Takip commit'i `b4e8f907ecec64eafeffbaa81c7a3977791d28d3` görev katkı animasyonlarını da pause kapsamına aldı. CI run `39436712367` doğrulama işi başarılı: B01–B04 regresyonları, B05 (97 kontrol, 0 hata) ve Web export geçti. İlk Pages deploy denemesi GitHub `updating_pages` durumunda zaman aşımına uğradı; yalnızca deploy işi yeniden çalıştırıldı ve ikinci denemede başarılı oldu. Canlı URL güncel: https://rizaaltun.github.io/catpat-godot/.
- Commit `3d0db050c17ed092eb47fd294cd2f5233960abeb` B05'e karartmalı duraklatma paneli ve `Devam et` düğmesi ekledi. CI run `39440972900` Godot importu, kayıt/diyalog/çizgi roman, açılış/font/kurtarma, B01–B04 regresyonları, B05, Web export ve Pages dağıtımını başarıyla tamamladı. B05: 100 kontrol, 0 hata; panelin açılıp kapanması ve final paneliyle çakışmaması doğrulandı. Canlı oyun: https://rizaaltun.github.io/catpat-godot/. Görsel viewport ve gerçek cihaz dokunmatik ergonomisi ayrıca QA bekliyor.


## 21 Ekim 2026 — B05 duraklatma menüsünden çıkış

- Commit `68a7639b960b524b264aeeb6710ddbc56351ea65` pause paneline `Ana menü` çıkışını ekledi. Menüye dönmeden önce kanonik ilerleme tekrar yazılıyor ve aynı kayıt yolu ana menüye aktarılıyor.
- CI run `39577223887` başarılı: B01–B04 regresyonları, B05, web export ve Pages dağıtımı geçti. B05 sözleşmesi 105 kontrol ve 0 hata verdi; çıkış düğmesi bağlantısı, görev bayrakları/checkpoint ve menüye kayıt yolu aktarımı doğrulandı.
- Canlı oyun güncel: https://rizaaltun.github.io/catpat-godot/. Görsel viewport ve gerçek dokunmatik cihaz QA'sı ayrıca açık.


## 22 Ekim 2026 — B04 denetim düzeltmesi ve ebeveyn ilerleme özeti

- B04 jump_to regresyon yardımcısı artık başarıyı hem hedef x/y konumu hem de zeminde olma koşuluna bağlıyor. Farklı x koordinatında yere inmenin başarı sayılmadığını doğrulayan bir kontrol eklendi.
- B04 denetim düzeltmesi: commit ac361985d534f8b62ec0c4138af62c735a540e47; CI run [39777841840](https://github.com/rizaaltun/catpat-godot/actions/runs/39777841840) başarılı. B01–B05 regresyonları, Godot importu, Web export ve Pages dağıtımı geçti.
- Ana menüye, mevcut yerel kayıt şemasından B01–B05 tamamlanma durumlarını ve görev sayaçlarını gösteren salt okunur “Ebeveyn özeti” eklendi. Yeni kişisel veri veya telemetri toplamıyor. Ekran, bunu beceri gelişimi/gerçek yaşam davranışı ölçümü saymadığını açıkça belirtiyor.
- İlk rapor test koşusu eksik Quest preload’u nedeniyle açılış regresyonunda durdu. Test preload’u eklendi: commit 2ac0ee6d2fb53541ee65289a643ac82b62e993e3.
- Nihai doğrulama CI run [39779275202](https://github.com/rizaaltun/catpat-godot/actions/runs/39779275202) ile başarılı: import, kayıt/diyalog/çizgi roman, menü/font/kurtarma ve ebeveyn özeti regresyonları, B01–B05, Web export, GitHub Pages deploy.
- Canlı test: https://rizaaltun.github.io/catpat-godot/.
- Gerçek piksel/yerleşim incelemesi ve dokunmatik cihaz ergonomisi hâlâ yapılmadı. Bu çalışma tarayıcısında WebGL2 olmadığından canlı oyunun görsel oynanışı doğrulanmış sayılmıyor. B05’te Polygon2D ile çizilen zemin/sahne parçalarının sanat QA’sı ayrıca açık.
- Sonraki somut iş: web ekran görüntülerinde giriş, pause, görev ve final yerleşimlerini incelemek; ardından WebGL2 masaüstü tarayıcı ve dokunmatik cihazda deneyimi doğrulamak. Kitap künyesi, hedef yaş, ortak oyun kimliği/beceri ID’leri ve karakter onayı katalog sahibi tarafından doğrulanmamış; beceri çıkarımı eklenmedi.


## 23 Ekim 2026 — B05 kontrol ipuçları ve doğrulama

- Commit [d71b482](https://github.com/rizaaltun/catpat-godot/commit/d71b4829406c4de85986909193a1fcb0e27e99e6) B05 ekranının altına masaüstü hareket/zıplama/E etkileşimi ipucu ekledi. Dokunmatik girdi algılanınca açıklama ekrandaki yön, zıplama ve etkileşim düğmelerine göre değişiyor.
- tests/festival_contract.gd masaüstü ve dokunmatik ipucu metinlerini denetliyor. CI run [39950109447](https://github.com/rizaaltun/catpat-godot/actions/runs/39950109447) başarılı: Godot import, başlangıç/kayıt/diyalog testleri, B01–B04 regresyonları, B05 tam fizik/etkileşim rotası (107 kontrol, 0 hata), Web export ve GitHub Pages dağıtımı geçti.
- Canlı test: https://rizaaltun.github.io/catpat-godot/ . Bu çalışma tarayıcısında WebGL2 bulunmadığı için oyunun piksel görüntüsü/etkileşimi burada doğrulanamadı; bu kısıt Windows cihazındaki tarayıcının çalışmadığını göstermez.
- Sonraki görsel QA: WebGL2 destekli tarayıcıda giriş, B05 görevleri, pause ve final ekranlarını 1280×720 ve 666×375 ölçülerinde incele; geometri ve sanat düzenlemesini bu karelere göre yap.


## 23 Ekim 2026 — B05 gerçek kare QA ve düzen düzeltmesi

- Önceki bölümlerde kullanılan Godot kare yakalama düzeni B05’e taşındı. Xvfb/llvmpipe ile CI’da giriş, görev tamamlanma, pause ve final ekranı 1280×720 boyutunda çiziliyor; WebP kareler geçici olarak Actions logunda tutuluyor. Görsel dosyaları Git’e eklenmedi, proje ZIP’i oluşturulmadı.
- Kare incelemesi iki gerçek UI kusurunu yakaladı: Porsuk portresi final hikâyesinin son satırına giriyordu; pause paneli `Ana menü` düğmesinin altında erken bitiyordu. Final senaryosu tek satırlık etiketlere bölünüp portre satırı aşağı alındı; pause kartı uzatıldı. Platform alt dolgusu da ekran karesindeki toprak dokusuna yaklaştırıldı.
- Commit `f8e306497fd75b6ea820c2c943ab09b4ca60611f` sahne düzenini düzeltti; `d30a00e1db27d03fc381499c85c016a7f8501c1e` sığma regresyonunu ve ekrandan kare yakalamayı doğruladı. CI run [39959692803](https://github.com/rizaaltun/catpat-godot/actions/runs/39959692803) başarılı: Godot import, B01–B04 regresyonları, B05 tam fizik/etkileşim rotası (**109 kontrol, 0 hata**), dört görsel kare, Web export ve Pages dağıtımı geçti.
- Görsel inceleme sonucu: giriş ekranında HUD/hedef ve kontrol ipucu okunuyor; görev tamamlanma metni görünüyor; pause kartı iki eylemi de içeriyor; final hikâyesi ve üç arkadaş portresi çakışmıyor. B05 platform taban rengi koyu toprak tonuna çekildi.
- Canlı oyun güncel: https://rizaaltun.github.io/catpat-godot/ . Görsel kareler WebGL2 gerektirmeyen Godot native CI penceresinde alındı. Bu uzak web tarayıcısı WebGL2 sağlamadığından canlı web canvas etkileşimi ayrıca doğrulanamadı.
- Dar görünüm de CI’da doğrulandı. Godot penceresi 666×374, alınan viewport karesi 664×374 olarak raporlandı; dokunmatik kontroller ve final kartı karede görünür ve okunur. Commit `86acb603700aa776d57e10c72d66363554a2d431` küçük pencere karelerini ekledi; `0855ea5d6f1021933d282da45bf5b0e1497354b6` pencere/görüntü boyutlarını raporluyor. CI run [39962944323](https://github.com/rizaaltun/catpat-godot/actions/runs/39962944323) başarılı: B01–B05 regresyonları, B05 109/109 kontrol, altı render karesi, Web export ve Pages deploy geçti.
- Sıradaki görsel kalite işi: B01–B04 için aynı gerçek render karesi incelemesini sürdür; gerçek dokunmatik cihazda düğme ergonomisini ayrıca doğrula.

## 27 Ekim 2026 — B03–B04 gerçek render QA

- Commit [b8fa581](https://github.com/rizaaltun/catpat-godot/commit/b8fa581cf728005125f653e3833ee8fcc0009cc3), B03→B04 geçiş ve B04 görev akışından seçilmiş gerçek Godot viewport karelerini Actions günlüklerinde WebP olarak yakalıyor; oyun dosyalarına kare/ZIP eklenmiyor.
- CI run [40472359103](https://github.com/rizaaltun/catpat-godot/actions/runs/40472359103) başarılı: B01–B04 regresyonları, B04 doğal görev rotası (**40 kontrol, 0 hata**), B05 kontrolleri, Web export ve Pages deploy geçti.
- Karelerde B03 bahçe tamamlama paneli ve yamaç geçişi; B04 Pıtpıt çizgi romanı, oyun içi görev yazıları, pause/devam ve Festival Yolu son hedefi görsel olarak kontrol edildi. Türkçe yazılar okunur; tamamlanma ve devam düğmeleri görünür. Sunucu CI'daki ALSA uyarısı ses çıkış aygıtı bulunmamasından kaynaklandı; Godot sessiz sürücüyle devam edip testleri tamamladı.
- B04 bitiş karesinde sol ekran kenarında tek karakter kırpılması görüldü. Görsel QA bulgusu olarak açık; B04 world hint/viewport sınır yerleşimi incelenecek. B01–B02 için de aynı render incelemesi henüz yapılmadı; gerçek dokunmatik cihazda ergonomi doğrulaması ayrıca gerekli.
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/ . Bu koşuda Pages deploy başarılı; mevcut uzak tarayıcı WebGL2 sağlamadığı için canlı canvas etkileşimi doğrulanamadı.
- PDF/PSD kitap orijinalleri veya hakları doğrulanmamış kaynaklar eklenmedi.

## 27 Ekim 2026 — B01–B04 gerçek render QA

- B01 ve B02 tam fizik/etkileşim regresyonlarına seçilmiş gerçek viewport kareleri eklendi; B03→B04 geçişi ve B04 görev akışı kareleri aynı Godot renderer’ında yakalanıyor. Kareler geçici olarak GitHub Actions günlüklerinde WebP base64 olarak duruyor; Git’e görsel veya ZIP eklenmiyor.
- B01’in mevcut test ve capture bayrakları aynı doğal oyun rotasını iki kez başlatıyordu. Düzeltme commit’i [cd0317f](https://github.com/rizaaltun/catpat-godot/commit/cd0317f67fb708e37b8c0e4db0bd4445965bfdd6) ile tek koşuya indirildi; B01/B02 render komutları ve tüm bölüm regresyonları geçti.
- B04 ekran karesindeki kısmi dünya yazısı kırpılmasını düzeltmek için dünya etiketleri yalnızca viewport kenarından kısmen kesildikleri sırada saydamlaşıyor; hedef ekran dışındaysa görev etiketi etkin kalıyor ve görünür alana girince tekrar çiziliyor. B04 yön işareti metni ve 41 doğal rota kontrolü geçti.
- Son yeşil CI run [40477480587](https://github.com/rizaaltun/catpat-godot/actions/runs/40477480587): import, kayıt/diyalog/çizgi roman/açılış kontrolleri; B01–B04 tam oynanış/geçiş regresyonları; B05 sözleşmesi ve gerçek viewport yakalama; Web export ve GitHub Pages deploy başarılı. B01 ve B02 suite'leri başarıyla tamamlandı; B04 doğal rota 41 kontrol, 0 hata.
- B01 giriş/orta/çıkış ekranları, B02 çizgi roman/köprü/tamamlanma, B03 bahçe→yamaç geçişi ve B04 görev/pause/bitiş kareleri incelendi. Türkçe yazılar, görev işaretleri ve butonlar görünür. B04 bitişindeki sol kenar dünya yazısı kayboldu; visible_world_hints_not_clipped kontrolü geçti.
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/ . Son Pages deploy başarılı. Bu uzak tarayıcı oturumu WebGL2 desteklemediği için canlı canvas etkileşimi burada sınanamadı; gerçek WebGL2 tarayıcı ve dokunmatik cihaz QA'sı hâlâ açık.
- CI ALSA ERR_CANT_OPEN satırları, GitHub sunucusunda fiziksel ses çıkışı bulunmamasından kaynaklanıyor; Godot sessiz sürücüyle çalıştı ve testler geçti. PDF/PSD kitap orijinalleri veya hakları doğrulanmamış kaynaklar eklenmedi.

## Sıradaki işler

1. B05 dokunmatik düğme ergonomisini gerçek telefonda/tablette doğrula; B01–B04 dokunmatik ve dar ekran karelerini genişlet.
2. WebGL2 destekli masaüstü tarayıcıda canlı Pages oyununu açıp menü, görev tamamlanması, kayıt/devam ve B05 final geçişini elle dene.
3. Epsilon rehberindeki ortak beceri sözlüğü/katalog kimlikleri kaynak sahibi tarafından doğrulandığında, uygun kayıt ve ebeveyn özeti kapsamını yeniden değerlendir; doğrulanmamış beceri gelişimi iddiası ekleme.


## 27 Ekim 2026 — B01–B02 dar ekran ve dokunmatik QA

- B01 ve B02’nin gerçek Godot oyun rotaları, seçilmiş sahne durumlarında 666×374 viewport karesi alacak şekilde genişletildi. Test, dört dokunmatik hareket/etkileşim düğmesinin görünür olduğunu ve 1280×720 mantıksal oyun alanının içinde kaldığını doğruluyor; CI kareleri ölçeklenmiş gerçek pikselleri gösteriyor.
- B01/B02 alt görev ipucu 669’dan 624 mantıksal Y koordinatına alındı. Küçük ekran karelerinde yazının alt kenara sıkışması görüldü; regresyon, ipucunun 670 çizgisinden önce bittiğini denetliyor.
- Kod commit’leri: [60e9b7e](https://github.com/rizaaltun/catpat-godot/commit/60e9b7eb1971fefa154d81b228a62af6fe766619) render ve dokunmatik kontrol yakalamalarını ekledi; [3638505](https://github.com/rizaaltun/catpat-godot/commit/363850531ff04b2b1ae48b999d867b7e2a06ea76) alt ipucu yerleşimini düzeltti.
- CI run [40489262928](https://github.com/rizaaltun/catpat-godot/actions/runs/40489262928) başarılı: B01, B02, B03, B04 ve B05 regresyonları; B01/B02 dar ekran render ve güvenli boşluk kontrolleri; Web export ve Pages dağıtımı geçti. Canlı test adresi güncel: https://rizaaltun.github.io/catpat-godot/.
- B01 ve B02 küçük ekran kareleri Godot CI render’ında incelendi; dokunmatik düğmeler çerçeve içinde, alt görev ipucu taşınmış durumda. Bu, gerçek telefon/tablet dokunma ergonomisi testi değildir. WebGL2 destekli masaüstü tarayıcı ve fiziksel dokunmatik cihaz QA’sı hâlâ açık.
- Bu aşamada yeni varlık eklenmedi; PDF/PSD kitap orijinalleri ve hakları doğrulanmamış kaynaklar depoya aktarılmadı.

## Sıradaki işler

1. WebGL2 destekli masaüstü tarayıcıda canlı oyunda menü, görev tamamlanması, kayıt/devam ve B05 final geçişini elle doğrula.
2. Gerçek telefonda/tablette B01–B05 dokunmatik düğme ergonomisini dene.
3. Epsilon rehberindeki ortak beceri sözlüğü/katalog kimliklerini kaynak sahibi doğrulayınca ebeveyn özeti ve kayıt kapsamını yeniden değerlendir; doğrulanmamış beceri gelişimi iddiası ekleme.


## 28 Ekim 2026 — yeni GPT hesabına proje devri

- Hesap değişikliğinde oyun kaybolmasın diye [yeni GPT hesabı devir yönergesi](YENI_GPT_HESABI_DEVRALMA.md) eklendi. Bu dosya, GitHub dalını, canlı test URL’sini, son yeşil Actions koşusunu, açık cihaz QA’sını ve kopyalanabilir başlangıç metnini içeriyor.
- 27 Ekim’deki son kod doğrulaması [run 40490221402](https://github.com/rizaaltun/catpat-godot/actions/runs/40490221402) başarılı; B01–B05, Web export ve Pages deploy geçti. Canlı oyun: https://rizaaltun.github.io/catpat-godot/.
- Yeni GPT hesabında GitHub bağlantısına `rizaaltun/catpat-godot` için yazma yetkisi verilmesi gerekir. Epsilon rehberi bu konuşmaya ekli ayrı dosyadır; Public depoya kopyalanmadı ve yeni GPT konuşmasına ayrıca yüklenmelidir.
- ChatGPT hesap geçmişi/ayarları GitHub projesinden ayrı kalır. Eski konuşma geçmişi gerekiyorsa OpenAI veri dışa aktarma sürecini izleyip ilgili JSON dosyasını yeni konuşmaya referans olarak ekle; bu, eski sohbetleri/ayarları veya aboneliği yeni hesaba taşımaz.
- PDF/PSD kitap orijinalleri veya hakları doğrulanmamış kaynaklar Public depoya eklenmedi.


## 30 Ekim 2026 — devir sonrası dokunmatik ve dar ekran denetimi

- `work/t22-source-migration` dalı `f4c99a0` commit'inden devralındı. GitHub üzerinden son koşu 40669118241 ve önceki oyun koşusu 40490221402 başarıyla doğrulandı. Yeni proje veya depo oluşturulmadı.
- Ana standart artık çalışma alanındaki Epsilon v2.1. Kitap kimliği değiştirilmedi; mevcut yayımlanabilir image varlıkları yeniden kullanıldı. Tüm UI/sahne sanatının kaynak izlenebilirliği ve v2.1 kapsam denetimi henüz tamamlanmadı.
- Bağımsız kod denetimi B03 alt görev ipucunu, B04 küçük dokunma hedeflerini ve dokunma + taklit fare çift sayımını buldu. `docs/QA-2026-10-30.md` bulgu kaydıdır.
- B03 ipucu, B01/B02'deki düzeltmeyle aynı şekilde y624'e alındı. B04 üretim sahnesinde hareket/zıplama hedefleri en az112×112 mantıksal piksele büyütüldü; router bölgeleri gerçek düğme dikdörtgenlerine bağlandı. Varsayılan düğme görünümü mevcut `jump-button.webp` sanatıyla değiştirildi; yeni sanat çizilmedi.
- Ortak InputRouter yalnız `InputEvent.DEVICE_ID_EMULATION` fare olaylarını reddediyor; gerçek fare desteği korunuyor. Yeni 10 kontrollü regresyon eski kodda5 hata verdi, düzeltmeden sonra10/10 geçti.
- B05 finali açıkken Escape'in fiziği yeniden başlatması engellendi; final açılırken parmak sahipliği temizleniyor. Godot4.4.1 yerel B05 sözleşmesi111/111, B03→B04→menü→Devam yaşam döngüsü17/17 geçti.
- B03 oynanış ve B04 giriş/duraklatma için666×374 gerçek render yakalamaları ve sınır/çakışma kontrolleri mevcut CI yakalayıcısına eklendi. Bu kaydın yazıldığı anda yeni render ve tüm CI sonucu bekleniyor; sonuç ayrıca kaydedilecek.
- Canlı Pages sayfası açıldı; bu oturumun tarayıcısı açıkça WebGL2 eksikliği bildirdi. Canlı canvas oynanışı test edilemedi. Bu, kullanıcının cihazındaki oyunun açılmadığı anlamına gelmez.
- Gerçek telefon/tablet ergonomisi, sesin cihazda dinlenmesi ve gerçek WebGL2 tarayıcıda elle yolculuk hâlâ açık. Ortak katalog/beceri kimlikleri ve kitap referansları doğrulanmadan beceri gelişimi iddiası eklenmedi.
- Sıradaki iş: yeni CI/render sonuçlarını incele, bulunan yerleşim kusurlarını kapat; ardından v2.1 UI kaynak/kullanım envanteri ve mevcut sanat eksiklerini tamamla. Fiziksel cihaz doğrulamasını ayrı tut.

### İlk sunucu doğrulaması ve yakalama iyileştirmesi

- Kod commit'i `821c6b84de421d06cf854e6bcc079bd388cd7f1b`, run [41044387281](https://github.com/rizaaltun/catpat-godot/actions/runs/41044387281): tüm doğrulama adımları başarılı. B01/B02/B03 doğal oynanış, B04 doğal rota/geçiş, B05 sözleşmesi111/111, InputRouter10/10 ve Web export geçti. Genişletilmiş yaşam döngüsü34/34; B05 altı gerçek kare,0 hata.
- B04 gerçek666×374 giriş ve pause kareleri incelendi: hareket/zıplama düğmeleri image dokusunu kullanıyor; eylem düğmesi ve alt açıklamayla çakışmıyor; pause panelinin üç eylemi okunur ve görünür. Bu, fiziksel ergonomi onayı değildir.
- B03 ilk küçük karede tamamlanmış kayıt hub'da olduğundan görev ipucu boştu. Yalnız konum kontrolüyle yetinilmedi: yakalama gerçek yürüyüşle ulaşılan çıkışa taşındı ve `hint.text` boş olmamalı kontrolü eklendi. Bu ek testin sonucu bir sonraki koşuda kaydedilecek.

### İkinci görsel denetim düzeltmesi

Bağımsız denetçi B04 giriş/pause karelerinde değişen kontrolleri ve menüyü uygun buldu; ancak eski iki satırlık klavye yönergesinin dar görünümde küçük kaldığını ve dokunmatik moda uygun olmadığını bildirdi. B04 artık gerçek dokunma algılandığında tek satırlık26 punto dokunmatik yönerge gösteriyor; klavyeye dönülünce önceki klavye açıklaması geri geliyor. Alt kart içinde ek boşluk bırakıldı. Dar yakalama dokunmatik sunumu gerçekten etkinleştiriyor ve metin/puntoyu denetliyor. B03'te boş olmayan çıkış yönergesi de aynı koşuda kontrol edilecek.

### B03 metin kontrastı — gerçek kare bulgusu

İkinci koşuda gerçek çıkış yönergesi görünür olarak yakalandı; zemin üstündeki küçük yazının kontrastı yeterince güçlü değildi. B03 görev yönergesi26 puntoya çıkarıldı ve mevcut `panel.webp` sanatıyla arka plan eklendi. Panel yalnız dolu yönerge olan oynanış durumunda görünür; boş süs paneli bırakılmadı. Yeni dar ekran kontrolü panel görünürlüğü, metin alanını kapsaması ve puntoyu denetliyor. Son CI sonucu aşağıya eklenecek.

## 30 Ekim kapanış — doğrulanmış kod `db65748`

[Run41046315077](https://github.com/rizaaltun/catpat-godot/actions/runs/41046315077) doğrulama işi başarılı: Godot4.4.1 import/parse, kayıt60/60, InputRouter10/10, diyalog/çizgi roman/açılış, B01/B02/B03 doğal oynanış, B04 doğal rota41/41, genişletilmiş B03→B04→menü→Devam38/38, B05 sözleşmesi111/111, B05 altı gerçek kare ve Web export geçti. B03/B04 dar ekran kareleri ana üretici ve bağımsız denetçi tarafından kontrol edildi. Ebeveyn özeti bağımsız kaynak denetiminden geçti.

Bu teknik/dar ekran iyileştirme aşaması tamamlandı; tam ürün veya bütün sanat için kabul değildir. Açık işler: fiziksel telefon/tablet ergonomisi, gerçek WebGL2 masaüstü tarayıcıda elle yolculuk, cihaz ses/hareket incelemesi; v2.1 UI kaynak/kullanım envanteri ve kod çizimli B05 sanat eksikleri; kitap kimliği, kapsam ve ortak katalog/beceri kaynağı doğrulaması. Eski plan tarihlerinden yeni teslim takvimi çıkarılmadı.

Sıradaki bağımsız üretim işi, mevcut manifest/kullanımları v2.1 ile eşleştirip eksik image sanatını gerçek ekranlar üzerinden tamamlamak. Kitap kimliğini değiştirecek yeni karakter üretimi için kaynak karşılaştırması eksik; mevcut kimlik korunuyor. Gerçek cihaz kapısı bu ortamda yapılmış sayılmıyor.


## 30 Ekim 2026 — tam ürün kapsamını sürdürme,0.14.0 üretim adayı

Kullanıcı kısa düzeltme turunda işi bırakmamayı ve mevcut kapsamın tamamı için çalışmayı açıkça istedi. Çalışma dalı/proje korunarak `docs/PRODUCTION-2026-10-30.md` kapsamı uygulandı. YeniB00 öğreticisi,6 bölüm art zinciri, B05 ortak hareket+görünür katkılar+yardım+saltokunur finaltekrarı, bölüm seçimi/izole replay, uygulanmış erişilebilirlik tercihleri,34 özgün sesvarlığı ve hash'li web kabuğu eklendi.

Yerel kabul kanıtları: Home53/53, Save60/60, InputRouter23/23, B05 hareket19/19, B05 fizikrotası111/111, B05image/dünya/final29/29, B05reddedilenkayıt19/19; Replay93/93, Preferences21/21, Settings17/17, Experience42/42, en büyükHUD43/43, B04image23/23+eskisolorota14/14, B01/B04imageefekt23/23 ve B01tamrotasıPASS. Audio68/68;34 dosya/hash/decode ve döngüsınırı kontrolleri. Web8Python+19Node, gerçek öncekiCIpaketinde JS/WASM/PCKdeğişmeden.

Bunlar tek sürümdeki native görsel/cihaz kabulü değildir. Yeni CI adayı tüm bölümleri, geniş/dar ayar/replay/HUD/ev/festival karelerini ve Web export'u birlikte doğrulayacak. Sonraki satırlarda gerçek koşu/commit/kare bulguları kaydedilecek; kaynak değiştiğinde eski sonuç nihai kabul diye taşınmayacak.

Eski yaşam döngüsü testindeki aynı satır lambda hata enjeksiyonu gerçekten çalışmıyordu; multiline callback+erişimsayacıyla düzeltildi,19/19 temizlog geçti. Godot0 çıkışına rağmen motor hata satırı yazabildiği için CI artık `tools/run_godot_check.py` ile ERROR/SCRIPT ERROR/ParseError satırlarında başarısız olur; Dummy ses sürücüsü donanımgürültüsünü ayırır.

Altı yeni image kaynağı ve runtime çıktıları `production/ART_MANIFEST_V21.json`, prompt seti `docs/ART-BRIEFS-V21.md` içindedir. KaynakPNGler `assets/source/.gdignore` ile runtimeimport/exporttan ayrılır. EskiUIimage ailesi yeniden kullanıldı; orijinal üretimdosyaları bucheckout'ta yoksa varmış gibi gösterilmedi.

Asıl kitap/PSD için erişilebilir dosya araması yalnız mevcut aktarımZIP'ini döndürdü; buradan tüm hesaplarda kaynak yoktur sonucu çıkarılmadı. Kitap sayfaları veya PSD asılları publicrepo'ya eklenmedi, karakter kimliği yeniden çizilmedi. Kaynakla nihai kitap/karakter eşleşmesi hâlâ dışbağımlılık.

Gerçek cihaz/WebGL2 oynanış, cihazda sesdinleme/perfölçümü, Mac/Xcode/iOS imzalama/kurulum yapılmış sayılmıyor. Uygulanabilir bağımsız üretim/denetim devam ediyor; yalnız gerçek erişim/kitapreferansı gerektiren kapılar engelli kalır.

### İlk üretim koşusu ve gerçek karelerin yakaladığı kusurlar

Kod `2db8f3a1985c5a450d1fe9d8ca10cab64247a127`, Actions41062108276: tüm test/export ve Pages deploy başarılı.41 native kare çıkarıldı; bağımsız görsel denetim `docs/NATIVE-VISUAL-AUDIT-2026-10-30.md` içinde. Otomatik başarıya rağmen panel alfa payları, büyük kontrollerin oyuncuyu örtmesi, B02 metin kontrastı, B05 karakter örtüşmesi ve final çekiminin yerleşim eksikleri görüldü. Üretim bu bulgular kapanmadan bitmiş sayılmadı.

Sonraki aday ortak panel crop, doğru expandedHUD/üst-ipucu yerleşimi, B00 ve B05 dinamik güvenli kamera, B02 okunaklı yardım kartı, B05 ayrı NPC duruşu, sahnede otomatik görünür dokunmatik final eylemi ve daha sıkı gerçek sıçrama/kare assertionları içerir. B03 aktif görev/konuşma/ekip için6 ek native kare de hazırlanmıştır. Yeni tek aday CI sonucu ve gerçek görüntüler ayrıca kaydedilecektir.

## 31 Ekim 2026 — Kullanıcı geri bildirimi ve güvenli çalışma durağı

**Öncelikli güncel kararlar:** `docs/USER-DECISIONS-2026-10-31.md`. Kullanıcı mevcut görevleri zor ve tekrarlı buldu: sürekli karaktere gidip E basma/geri dönme azaltılacak; gereksiz havadaki sarı ışıklar kaldırılacak, salıncak üstündeki sokak fenerleri düzeltilecek. Gerçek bölüm haritası, kolaylaştırma ve hızlı geçiş, daha heyecan verici image arayüzleri ve ElevenLabs seslendirmesi kesin iş listesine eklendi. Eski otomatik rota başarısı bu ürün sorunlarını kapatmaz.

Kalan krediyle yarım ebeveyn/profil/yardım entegrasyonu hedefli olarak doğrulandı. Aktarımın etkin yolcuyu sessizce değiştirmesi, büyük yazı onay yerleşimi, B04 mola/denetim çakışması ve devralınan actor sabitinin native sınıf adıyla çakışması giderildi. **374 hedefli kontrol ve açılış regresyonu geçti**; kapsam, gerçek kare incelemesi ve sınırları `docs/QA-2026-10-31.md` içinde. `docs/MODULE_HOST_CONTEXT.md` servis sahipliği ve veri sözleşmesini açıklar. Mevcut karakter performans çalışması korunmuştur; nihai hareket kabulü değildir.

Kaynaklar, testler ve kararlar geliştirme durağı olarak kaydedilecek; bu tur canlı Pages yayını yapılmadı. Önceki yeşil CI son paketin tüm kabulü diye kullanılmaz. Gerçek cihaz, kitap/PSD kimlik karşılaştırması ve tüm bölüm rotalarının yeni sürümde toplu kabulü açık.

**Sonraki somut iş:** B01'de sarı toplama izlerini ve buna bağlı sayaç/yardım/rapor/test beklentilerini kaldır; eski kayıt okunabilirliğini koru. Hareketli platform üstündeki feneri ve gereksiz Porsuk'a dönüşü yeni kolay akışta çöz. Ardından harita/hızlı geçişi kur; tasarım kaydındaki sırayı izle. Kullanıcıya projeyi yeniden anlattırma.

## 1 Kasım 2026 — Hata düzeltmeleri yeni özelliklerin önünde

Kullanıcı gerçek oyunda çok sayıda hata ve bazı bölüm geçişlerinde tıkanma bildirdi; önce baştan sona rapor ve düzeltme istedi. Yeni üretim işleri bu hata kapısının arkasına alındı. Ana kayıt `docs/BUG-AUDIT-2026-11-01.md`; önceki genel test sayıları kullanıcı deneyimini doğrulamak yerine kullanılmayacak.

0.15.1-audit-alpha adayı B04 shared modda mola/konuşma sonrası kaybolan dokunmatik kontrolleri ve B04→B05 sahne/geri-alma çift hatasında eski dünyanın yeni kaydı ezmesini düzeltir. Son checkpoint CI'sının B04 pause assertion hatası da gerçek kontrol yaşam döngüsüne uygun düzeltildi. `--require-output` ile yarıda kapanan sıfır kodlu testin başarılı sayılması engellendi.

Gerçek GUI fare/klavye geçiş zinciri 45, dokunmatik/taklit fare 46, B04 hata/dokunmatik sözleşmesi 12 kontrol geçti. B01 rotası, gerçek kayıt açık B02/B03 rotaları, B04 doğal 41 kontrol ve B03→B04 native yaşam döngüsü 40 kontrol geçti. Önceki 25 sözleşme dosyası bu oturumda çalıştırıldı; yeni kayda eski koşu sonucu taşınmadı. Son toplu CI/export/yayın sonucu ayrıca rapora yazılacak.

Teknik düzeltmelerden sonra 31 Ekim kullanıcı kararları korunarak B01 sadeleştirmesine dönülecek. Gerçek cihaz ve özgün kitap referansı kabulü hâlâ ayrı; denenmiş sayılmıyor.

Yayın engeli: aynı proje deposuna yükleme otomatik onay incelemesinde iki kez reddedildi; ikinci gerekçe public GitHub için doğrudan kullanıcı onayı eksikliği. Depo sahibi/yazma erişimi ve seçilen kaynak/test/rapor paketi doğrulandı. Alternatif yükleme yoluyla red aşılmadı. Kullanıcıdan mevcut public depoya kayıt + başarılı toplu doğrulamadan sonra Pages güncellemesi için somut onay istenecek. Bu sırada yerel PCK export'u ve paket içi kontroller sürdürüldü; canlı sürüm henüz değiştirilmedi.

Yerel kaynak kaydı `8acd005`, dal `work/t24-bug-audit-local`. PCK kaynak klasörü dışında açılarak gerçek sahne geçişi/menü-devam 45/45 ve hata kurtarma 12/12 geçti. Uzak Chrome canlı kabukta WebGL2 eksikliğini gösterdi; tarayıcı oynanışı yapılmış sayılmadı. Onay sonrası bu yerel kaynağı mevcut depoya aktar, tam CI/export'u tamamla ve ancak başarılı olunca Pages'i güncelle. Sonraki tasarım işini bu kabul kapısından sonra sürdür.

### Kullanıcı onayı, hata yayını ve B01 devamı

Kullanıcı “düzelt o zaman sonra kaldığın yerden devam et” diyerek somut yayın isteğini onayladı. `379ab27065c863d81cff8caaec2ca4781d67304f` mevcut yayın dalına kaydedildi; Actions **41247016804** verify ve deploy başarıyla tamamlandı. Önceki yayın engeli kapandı; 0.15.1 hata düzeltmeleri canlıya geçti.

Sonra B01 ileri görev akışına dönüldü: toplanan sarı ışıklar/sayaçlar kaldırıldı, eski kayıtlar korundu; fenerler sabit kıyılara alındı, iki salıncak oyun alanından çıkarıldı; üçüncü fenerle Porsuk aynı kalıcı snapshot'ta katılıp fiziksel olarak gelir, başlangıca dönüş gerekmez. Konuşma, yardım ve ebeveyn etiketleri güncellendi. `docs/B01-UX-2026-11-01.md` uygulama kapsamını açıklar. Yeni rota hem otomatik hem gerçek kayıt açık kontrolden geçti; son native görüntü/kadraj ve 0.15.2 toplu CI/yayın sonucu ayrıca kaydedilecek.

0.15.2 yerel son kabul: salıncaksız fizik rotası ve gerçek kayıt açık rota PASS; image etkiler 25, kayıt 60, gözlem 53, yardım 102/UI57, açılış ve diyalog temiz; 205 kadraj yeniden geçti. Son native dar karede toplanan ışıklar/salıncaklar yok, fener zeminde ve kontroller içinde. Yeni paket toplu CI/yayın doğrulamasına hazırlanıyor. Kalan üretim: diğer bölümlerin teslim/geri dönüş döngüsü, gerçek bölüm haritası ve güvenli hızlı geçiş, image UI yenilemesi, ElevenLabs bağlantısı/seslendirme.

### 0.15.2 yayın sonucu ve kesin devam noktası

`a6d842cd901be97fba7ebcc77fafcc537fba28d5`, Actions **41248326738**: verify, tüm bölüm ve gerçek kayıt açık rota testleri, native kareler, Web export ve Pages deploy başarıyla tamamlandı. Canlı oyun artık 0.15.2 B01 sadeleştirmesini içeriyor. 0.15.1 hata kapısı da önceki **41247016804** koşusunda tamamen geçti ve yayımlandı.

Son ek kanıt: yeni PCK'de dokunmatik B00→B05/menü-devam 46/46; eski üç-fenerli ve iki tarihsel toplama kaydında başarısız yazma byte'ları koruyor, yeniden deneme Porsuk'u bir kez katıyor, geçmiş toplama verisi değişmiyor. `USER-DECISIONS-2026-10-31.md` durumları güncellendi.

**Sıradaki iş:** `JOURNEY-MAP-NEXT.md` içindeki harita/hızlı geçiş kabul sözleşmesini gerçek image referansı ve varlıklarıyla uygulamak. Mevcut genel bölüm kutusu gerçek harita diye sunulmayacak. Diğer bölümlerin teslim/geri dönüşleri, UI yenilemesi ve ElevenLabs hâlâ açık. Fiziksel telefon/tablet ve WebGL2 manuel oynanış yapılmış sayılmıyor. Bu oturumda yeni hata ve B01 paketi tamamlandı; oyun bütünü nihai kabul edilmiş değildir.


## 2 Kasım 2026 — Yetki ve hata öncelikli çalışma programı

Kullanıcı rutin işler için yeniden onay istemeden hata düzeltmelerinden başlanıp çalışma programıyla devam edilmesini istedi. Program `WORK-PLAN-2026-11-02.md` içinde. Depodaki güncel devir doğrulandı: 0.15.1 geçiş ve 0.15.2 B01 sadeleştirmesi zaten yayımlanmıştı; bunlar yeniden yapılmış gibi raporlanmadı.

Yeni bulgu: ortak bölüm yeniden başlatmasında sahne/yazma hatasıyla birlikte geri alma başarısızlığı, panelden eski dünyaya dönüşü açık bırakıyordu. Eski dünya artık işlenmez; tekrar başlatma kapalıdır; ana menü kurtarması başarısızsa modal kapanmaz. Başarısız geri almada gözlem yazımı askıda kalır. Yeni hata enjeksiyonu dahil bölüm destek UI testi 62/62 geçti; son iki kontrol gerçek SceneTree ana menü değişiminde eski sahnenin kapanmasını ve kayıt byte bütünlüğünü doğruladı. Godot 4.4.1 yerel ek regresyon: bölüm destek 102/102, deneyim 42/42, klavye bölüm zinciri 45/45, dokunmatik zincir 46/46, B04 geçiş kurtarma 12/12. Çalıştırıcı motor hata satırlarını reddederek geçti. İlk düzeltme `eba39c9`, Actions 41430381146: tüm doğrulama, native kareler, Web export ve Pages deploy başarılı. Fiziksel cihaz/WebGL2 oynanış bu kayıtla denenmiş sayılmaz.


### B02/B03 onarım sonrası gereksiz etkileşim

B02 köprü ve B03 siper onarımının başarılı kayıt adımı artık `river_join` / `garden_join` konuşmasını kendiliğinden başlatır; oyuncu aynı yerde yeniden E basmaya veya arkadaşına yaklaşmaya zorlanmaz. Konuşma ve gerçek katılma olayı korunur; köprü hazır kaydı ile katılma kaydı birbirine karıştırılmaz. Kayıt başarısızsa konuşma başlamaz; başarılı yeniden denemede bir kez açılır. Eski hazır-ama-katılmamış kayıtların konuşma yolu korunur. Bildirim artık katılmış Maymun'u yeniden çağırmayı istemez.

Yeni `repair_invitation_test.gd` iki bölümde 20/20; gerçek kalıcılık açık B02 fizik rotası `V10 RIVER SUITE PASSED`. Rota artık otomatik açılan konuşmayı doğrular ve ikinci E olmadan ilerler. Bu, B02'nin uzun malzeme dönüş parkurunu tamamen kaldırmış sayılmaz; daha kapsamlı güzergâh kolaylaştırması ve harita hâlâ sıradadır. Önceki hata düzeltmesinin CI koşusu 41430381146 verify/deploy başarılı. Bu ikinci aday ayrıca toplu CI doğrulamasına gönderilecek.


### Kesintiye uğrayan B02/B03 onarım kaydının devamı

Yeni kritik bulgu: `SUPPLIED` / `GARDEN_SUPPLIED` kaydı başarılı fakat `READY` / `PROTECTED` henüz yazılmadan çıkıldığında onarım tekrar açılamıyordu. B02 açılışında yeniden başlatma yoktu; B03 yeniden başlatmayı deniyor fakat zaten tamamlanmış teslim olayını yeniden uyguladığı için callback reddediliyordu. Teslim edilmiş kayıtta onarım doğrudan başlar; teslim edilmemiş kayıtta önce mevcut atomik teslim yazımı yapılır. B02 açılışı da eksik onarımı sürdürür.

`repair_invitation_test.gd` iki bölümün gerçek sahnesini teslim edilmiş kayıttan açarak yeniden başlamayı doğrular; toplam 20/20. Kaydetme reddi, byte korunumu, yeniden deneme, konuşmanın bir kez açılması, eski hazır kayıt ve katılma bayrakları da aynı testtedir. B02 ve B03 gerçek kayıt açık tam fizik rotaları bu oturumda PASS verdi; son devam düzeltmesinin toplu CI sonucu ayrıca eklenecek. Sürüm 0.15.3-recovery-alpha.


### 0.15.3 doğrulama takibi / kesin devam noktası

Kaynak `8b6d3412bd1cee25ddf6e349b4f9d00d039b93a1`, Actions **41432193571**. Bu kayıt yazılırken import, kayıt/girdi/profil/yeniden başlatma, diyalog, bölüm geçiş/kurtarma ve yeni20/20 onarım kontrolü başarılı; gerçek kalıcılık açık fizik rotaları devam ediyor. Tam doğrulama/export/deploy tamamlanmış sayılmıyor. İş akışı başarı sonrasında aynı Pages sürümünü otomatik günceller.

İlk düzeltme `eba39c9` / Actions41430381146 verify+deploy başarılı ve canlıda. İkinci adayın sonucu doğrulanınca buraya ekle; başarısız adımı önce düzelt. Sonra WORK-PLAN-2026-11-02.md ve JOURNEY-MAP-NEXT.md kapsamıyla devam et. Henüz harita/hızlı geçiş, uzun malzeme geri dönüşleri veya ElevenLabs tamamlanmış değildir. Kullanıcının rutin uygulama/yayın yetkisi geçerlidir; projeyi yeniden anlattırma veya aynı onayı tekrar isteme.

### 2 Kasım — 0.15.3 sunucu sonucu ve görüntü testi düzeltmesi

Actions 41432193571 doğrulaması başarısız; deploy atlandı. Import, kayıt/yeniden başlatma/geçiş, 20/20 onarım kontrolü ve gerçek kalıcılık açık B02/B03 rotaları geçti. Başarısız adım B02 görüntülü tam rota: `bridge-ready` artık otomatik katılma konuşması sırasında çekildiğinden kaldırılmış HUD düğümleri ve hint_panel okunuyordu. Bu, geçersiz nesne erişimi ve dokunmatik kadraj assertion hatası üretti.

Yerel dc734bc düzeltmesi konuşma karesini korur; küçük ekran dokunmatik/HUD denetimini katılma konuşması tamamlandıktan sonraki yeni `companion-ready` karesinde çalıştırır. Assertionlar kaldırılmadı. Yeni yerel Godot 4.4.1 çalıştırması `V10 RIVER SUITE PASSED`; repair_invitation_test.gd 20/20. Yerel Xvfb yok; görüntülü rota bu ortamda yeniden doğrulanamadı. Sunucuda tam görüntülü CI yeniden çalışmadan paket kabul/yayın sayılmaz.

GitHub update_file gönderimi otomatik onay incelemesince hedef depoya açık yetki doğrulanamadığı gerekçesiyle reddedildi. Alternatif gönderim yolu denenmedi. Kullanıcı rutin çalışma/yayın yetkisini daha önce vermiş olsa da incelemenin istediği hedef-depo teyidi bu turda kabul edilmedi. Düzeltme yerel Git kaydında korunuyor; uzak dal veya canlı sürüm değişmiş sayılmıyor. Kesin sonraki iş: rizaaltun/catpat-godot work/t22-source-migration hedefi için engel çözülünce dc734bc değişikliğini gönder; görüntülü B02 ve tüm CI/export/deploy sonucunu doğrula, sonra çalışma programının görev kolaylaştırma aşamasına devam et.

### 2 Kasım — Hedef depo onayı ve ek konuşma düzeltmesi

Kullanıcı mevcut rizaaltun/catpat-godot deposuna gönderim ve başarılı doğrulama sonrası yayın için açık onay verdi. B02 görüntü düzeltmesi 302709d6e84143ac65012042f709e02c79e923d4 ile gönderildi; Actions 41445977957 başladı. Önceki gönderim engeli çözüldü.

Ek denetim, önceki tekrarlı callback testinin yalnız ilk cümlede kaldığı için konuşmanın başa sarılmasını yakalamadığını gösterdi. Test artık bir sonraki cümleye ilerleyip bitiş callback'ini tekrar çağırıyor. Düzeltme öncesi iki bölümde de hata üretildi (22 kontrol / 2 hata). finish_build yalnız building durumunda ve hazır bayrağı yokken çalışacak şekilde korundu. Sonuç: 22 kontrol / 0 hata; B02 ve B03 gerçek kalıcılık açık fizik rotaları da bu yerel değişikliklerle PASS.

Üç dosya atomik kaynak kaydı bf1fa56866f5eaa95b28e90ee8a0d837034b160d ile aynı geliştirme dalına gönderildi; Actions 41446380954 başladı. Bu not yazılırken sunucu doğrulama/export/yayın sonucu henüz kesinleşmedi; başarılı sayılmadı. İlk görüntü düzeltmesi ve ek konuşma koruması bu son adayda birlikte bulunur. Yeni rota veya harita arayüzü henüz eklenmedi.

### 0.15.4 B02 ileri rota adayı ve teslim hatası kurtarması

302709d / Actions41445977957 verify ve deploy başarılı: önceki B02 görüntülü test engeli kapandı ve paket canlıya çıktı. bf1fa56 / Actions41446380954 verify başarılı; bu not yazılırken deploy sıradaydı. Bu aday tekrar çağrının ilerlemiş konuşmayı başa döndürmesini de engeller.

Yeni 0.15.4-river-alpha yerel adayı B02'de üstteki halattan sağa yürüyerek tahtaların kıyısına inişi, orada açık görev eylemiyle onarımı ve tek yönlü köprünün üstüne sıçrayarak ileri geçişi kullanır. Hikâye ve yardım aynı sırayı tarif eder. Test rotası onarım öncesi 13 sıçrama ve iki geri dönüşten, dört yükseliş sıçraması + onarım sonrası bir köprü sıçramasına iner. Malzeme toplama ve onarım eylemleri korunur; yalnız yakınlığa gelmek görevi tamamlamaz. Eski başlangıç onarım noktası ve bütün mevcut kayıt bayrakları korunur; yeni sahte keşif/ödül/rapor olayı eklenmedi. Köprünün tek yönlü yüzeyi alttaki kıyıdan üstüne çıkmayı mümkün kılar. B03 geri dönüş güzergâhı henüz sadeleştirilmedi.

Ek hata: teslim yazımı reddedildiğinde hata paneli HUD'ı kaldırıyordu. Başarılı yeniden denemedeki başlangıç callback'i eski hint nesnesine yazıyordu. İki bölümün onarım başlangıcı ve B03 sepet indirme başlangıcı artık HUD'ı yeniden oluşturur. Hata motor satırıyla gerçekten üretildi, sonra giderildi. Genişletilmiş repair_invitation_test.gd 38/38; eski/yeni onarım noktası, havada engel, başarısız teslimde byte korunumu, tekrar deneme, konuşma tekrarı ve sepet indirme kurtarmasını kapsar. Chapter support102/102. Son B02 kısa rota ve B03 değişmemiş fizik rotası gerçek kayıt açık PASS. Aynı oturumda bağımsız kaynak denetimi yardım sırası uyumsuzluğunu buldu; düzeltildi. Bu denetim görüntülü/cihaz testi değildir.

Yeni paketin görüntülü CI/export/yayın kabulü ayrıca doğrulanacak; önceki 0.15.3 başarıları bu yeni rotanın görsel kabulü yerine geçmez. Sonraki iş B03'ün aynı gereksiz geri dönüşlerini azaltmak, ardından JOURNEY-MAP-NEXT.md sözleşmesiyle image harita/hızlı geçiş. Fiziksel cihaz ve WebGL2 manuel oynanış hâlâ yapılmış sayılmaz.

Kesin devam kaydı: 0.15.3 ek konuşma koruması bf1fa568 / Actions41446380954 verify+deploy başarılı, canlıda. 0.15.4 ileri rota ve teslim kurtarma paketi f37d450c963f60855903f7929c71d3ee10068b8c ile gönderildi; Actions **41448206244** çalışıyor. Sonraki oturum önce bu koşunun tamamını doğrulamalı; başarısızsa o adımı düzeltmeli. Başarılı doğrulama sonrası mevcut iş akışı Pages'i otomatik günceller. Ardından B03 kolaylaştırmasına devam et. Bu son adayın yayını henüz doğrulanmadı.

## 3 Kasım — Kullanıcının sık donma/kilitlenme bildirimi

Yeni özellikler durduruldu; öncelik donma ve ilerleme kilitleri. Ana hata kaydı BUG-FREEZE-2026-11-03.md. Önceki0.15.4 Actions41448206244 başarısız: B02 fizik testinde sabit180frame sonunda iki arkadaşın çıkışa ulaşması koşulu sağlanmadı; deploy atlandı. Canlı temel0.15.3 olarak kaldı.

Yeni0.15.5-stability-alpha: B02/B03 çıkışında katılmış arkadaşların dar fiziksel mesafesi oyuncunun ilerlemesini kilitlemez; oyuncunun güvenli zemini, katılma olayları ve çıkış konuşması/kaydı korunur. B03 katılma sonrası oyuncuyu bütün arkadaşlar kesin konumlara gelene kadar donduran sınırsız bekleme kaldırıldı; arkadaşlar normal fiziksel takip ederken oyuncu yürür. Yeni softlock_test.gd eski davranışla12 kontrolde8 hata üretti; düzeltilmiş kaynakta12/12. Bu, arkadaşların bütün fiziksel rotalarının düzeltilmiş olduğu iddiası değildir. B02 fiziksel takip denetimi sabit3 saniye yerine en çok12 saniye gerçek hazır koşulunu bekler ve başarısızlığı yine reddeder; oyun çıkış eylemi bundan bağımsızdır.

Bağımsız denetim ayrıca gerçek web shell harness'inde1px viewport değişiminin her seferinde mola ürettiğini doğruladı. Küçük CSS değişimleri ve yalnız DPR değişimi artık oyunu molaya almaz; büyük yerleşim değişikliği, yön değiştirme ve sekme gizlenmesi güvenli molayı korur. Yeni jitter testi önce FAIL, sonra web shell26/26; export sözleşmesi8/8. Bu browserless kanıt gerçekWebGLcihaz oynanışı değildir.

Önceki adayın teslim/indirme retry sırasında eskiHUDnesnesine yazma düzeltmesi bu pakette korunur; bu hata canlıda web kabuğunun yeniden yüklemelik hata paneline yol açabiliyordu. Kaynak hata düzeltilir, hata paneli gizlenmez. Repair38/38, softlock12/12, ortak destekUI62/62 ve B02 gerçek kayıt açık tam fizik rotası PASS. B03 ve genel geçiş sonucu son paket sunucu doğrulamasıyla ayrıca kaydedilecek. Yeni softlock denetimi CI'a zorunlu adım olarak eklendi. Yayın onayı önceden verilmiştir; yeni adayın tümCI/export/deploy sonucunu doğrulamadan canlı sayma. B03 güzergâh kolaylaştırması ve harita bu hata kapısı kapandıktan sonra devam eder.

### 0.15.5 kesin kabul ve yayın sonucu

Kaynak **fe6424d878f447e4d77887cb1e68c2a697911cb8**, Actions **41602732821**: verify ve deploy başarıyla tamamlandı. Yeni softlock senaryoları, kayıt/onarım, klavye ve dokunmatik bölüm zincirleri, B00–B05 rota/sözleşme/görüntü kontrolleri, web export ve Pages yayını geçti. Canlı oyun0.15.5-stability-alpha: https://rizaaltun.github.io/catpat-godot/ . Önceki yayımlanmamış0.15.4 kaynak düzeltmeleri de bu kabul edilmiş pakete dahildir.

Ek yerel kanıt: B03 gerçek kayıt açık tam fizik rotası PASS. B04 gerçek sahnede bir üye ve taşıyıcı rezervasyonu kasıtlı bozuldu; mevcut kayıtlı kıyıya dönüş rezervasyonları temizleyip dört üyeyi topladı, kayıt byte'ları değişmedi. Yerel klavye geçiş denemesi tamamlanma marker'ı vermediği için başarı sayılmadı; bu kapı yeni sunucu koşusunda geçti. Ayrıntılar BUG-FREEZE-2026-11-03.md. B04 takım/taşıyıcı mekaniği kaldırılmadı; doğal oynanıştan yeni bir eski-rezervasyon vakası üretilmiş sayılmaz.

Bu sürüm bulunan somut kilitleri kapatır; her cihazda bütün donma türlerinin yok olduğuna veya fiziksel telefon/WebGL2 uzun kullanım/perf testine kanıt değildir. Yeni kullanıcı hata bilgisi gelirse hata önceliği sürer. Aksi hâlde sıradaki üretim B03 gereksiz geri dönüşlerinin azaltılması, sonra image harita/güvenli hızlı geçiştir. Gönderim ve başarılı doğrulama sonrası yayın yetkisi geçerlidir; yeniden rutin onay isteme.

## 3 Kasım — Yeni kullanıcı geri bildirimi / 0.15.6 akış adayı

Kullanıcı girişte ev/platform yerleşimini ve yazı yoğunluğunu eleştirdi; otomatik bölüm/diyalog ilerlemesi ve gereksiz yaklaş–E döngüsünün kaldırılmasını istedi. B02 arka plan titremesi, ilk girişte hareketsiz NPC'ler ve B03'te yeniden donma bildirdi. Rutin uygulama/yayın yetkisi korunuyor. Ana kapsam ve kanıt sınırı `UX-FLOW-2026-11-03.md` içinde.

Uygulama: üretim hostunda NaturalFlow; kısa/tek balonlu otomatik konuşmalar, yakınlık hikâye/nesne eylemleri, gizli tamamlanma kutusu ve otomatik beş bölüm sınırı. Sekme/mola/modal/hata durakları; tek otomatik deneme + görünür kurtarma; finalin tekrar açılma kilidi ve B04 iptal döngüsüne koruma. B00 zemin/ev/kök kartları düzeltildi; mevcut image varlıkları yeniden kullanıldı, karakter kimliği yeniden çizilmedi. NPC karşılama/idle ve azaltılmış hareket; tek viewport sahibi arka plan, eski koordinat yazımlarının kaldırılması; B03 sepet kıyısında onarım ve yukarı sıçrama, eski hub uyumu. B04'ün bütün fiziksel geri dönüşleri veya harita henüz bitmiş değildir.

Yeni varsayılan üretim akışı yerel native70/70 ve10 geniş/dar kare geçti. Son ek B03 ip/sepet hata matrisi dahil varsayılan headless64/64 geçti. Manuel/fault/physics testleri isteğe bağlı eski etkileşim yolunu açıkça opt-in ile sınar; yeni otomatik akışın görsel kabulü yalnız yeni zorunlu native suite ve karelerle değerlendirilir. Diğer yerel sonuçlar: B0083/83; repair38/38; softlock12/12; experience42/42; supportUI62/62; açılış PASS; B03 gerçek kayıt açık manuel tam fizik rotası PASS.

Sonraki zorunlu kapı: bu adayın tümCI, varsayılan otomatik native suite, eski fizik/manuel hata yolları, Web export ve deploy. Başarısız adımı düzeltmeden canlı sayma. Son B03 donmasının tam kaydı olmadığı için aynı kullanıcı hatası birebir yeniden üretilmiş gibi raporlama. Yeni güvenlik/ilerleme senaryoları eklendi; gerçek cihaz ve uzun WebGL2/perf ölçümü ayrı kalır. CI başarı/yayın sonucu buraya eklenecek. Kullanıcıya aynı yetkiyi tekrar sordurma.

### Tam yan karakter kapsamı / son aday takibi

İlk akış kaydı e28c78aef0dbb06e697a80a7b1628ffc845c6c17, Actions41614707191 ile sunucuya gönderildi. Yeni varsayılan render suite sunucuda geçti; kalan eski regresyonlar sürerken B05'in fiziksel Actor yerine image Sprite kullanan bekleyen arkadaşlarına da aynı azaltılmış harekete duyarlı idle eklendi. B04 shared/solo giriş pozları da karşılama kapsamına alındı; konuşma rolü ezilmez. Bu küçük tamamlayıcı aday ayrıca doğrulanacak; ilk koşunun sonucu son kaydın kabulü yerine geçmez.

Ek B05 yaşam hareketi dahil varsayılan headless65/65. Native başlangıç70/70 ve10 kare; ilk sunucu koşusunda ek ip/sepet matrisiyle varsayılan native74kontrolün tamamı geçti. Son test ayrıca festival girişinin geniş/dar karesini alır. Son kaynak ve CI kimliği yayın kontrolü sonrasında buraya eklenecek.

### 0.15.6 kesin sonuç — 3 Kasım 2026

Son üretim kaynağı **ad37d7fc5637bd5c85b248fb8df3e849c1b21ae7**, Actions **41615428806**: verify ve deploy başarılı. İlk e28c78a / Actions41614707191 de başarıyla geçti; nihai kabul son kaynak içindir. Varsayılan üretim hostunda otomatik akış, son B03 hata matrisi ve tüm yan karakterler dahil **native77/77**; **12 geniş/dar gerçek kare**. Eski manuel/kayıt hata denetimleri ve bütün fizik rotaları, yeni otomatik akış, B00–B05 grafik/sözleşme testleri, Web export ve Pages yayını geçti. Canlı sürüm0.15.6-flow-alpha.

Ek yerel B03 yeniden giriş probu: altı yükleme/boşaltma çevriminde sahne boşaltma sonrası düğüm sayısı16, kaynak33, doku belleği6.768.001 byte olarak sabit kaldı. Statik bellek32.704.899→32.709.611 byte değişti; sıfır bellek değişimi veya uzun dönem/cihaz sızıntı garantisi iddia edilmez. Bu kısa native çevrimde sahne/doku birikimi saptanmadı. Tam kullanıcı donma anının aynısı yeniden üretilmiş değildir; eski kayıt/cihaz WebGL2 uzun kullanım ayrı kabul kapısıdır.

Yayınla kapananlar: ev/zemin/kök yerleşimi; kısa metin/tek balon; otomatik konuşma, yerel eylem ve beş bölüm sınırı; Porsuk'u bekleyen son çıkış ve zorunluE; B03 sepet-hub geri dönüşü; sabit kamera-arka plan sahipliği; NPC karşılama/idle, azaltılmış hareket; otomatik hata/final yeniden açılma döngülerine koruma. Sonraki kapsam: yeni kullanıcı hata verisi öncelikli; ardından B04 gereksiz geri dönüşleri, gerçek image yolculuk haritası ve güvenli hızlı geçiş, arayüz sanat yenilemesi, ElevenLabs. Bunlar bu sürümle bitmiş sayılmaz. Rutin yetki geçerlidir; yeniden onay isteme.

## 3 Kasım 2026 — 0.15.7 başlangıç kıyısı ve dokunmalı diyalog

Güncel karar ve uygulama: `docs/SHORE-REDESIGN-2026-11-03.md`. Son karar diyalog otomatiğini kaldırır; tek dokunma/tıklama ilerletir. B04 ilk kıyı geniş zeminde fener ve sabit köprüyle kolaylaştırıldı; halat, ikinci taşıyıcı, yön işareti ve final korunur. Rutin ekran metni azaltıldı, kayıt hataları ve mola ayrıntıları korunur. Yayın tamamlandı: kaynak `33fc63f01abee10789e772c8452900cf0316343e`, [CI41654767114](https://github.com/rizaaltun/catpat-godot/actions/runs/41654767114) verify+deploy başarılı. Yerel native varsayılan akış96/96 ve16 kare; yeni kıyı28/28. Canlı `https://rizaaltun.github.io/catpat-godot/?v=0.15.7` HTTP200 ve aynı SHA executable ile doğrulandı. Sonraki iş gerçek mobil/WebGL uzun oynanış ve çocuk kullanılabilirliği incelemesidir; her cihazda bütün donmalar giderildi iddiası yok.

## 8 Kasım 2026 — Sohbet devamı ve diyalog odak koruması

Mevcut depo ve `work/t22-source-migration` dalı devralındı; son 0.15.7 koşusu41654767114 verify+deploy başarılı olarak GitHub üzerinden yeniden doğrulandı. Önceki kıyı/dokunma çalışması yeniden yapılmış gibi sayılmadı.

Yeni gerçek hata: B02 konuşmasında pencere odağı kaybolduktan sonra dokunma engellenirken Enter, bölümün doğrudan klavye callback'i üzerinden cümleyi ilerletiyordu. `natural_flow_test.gd` gerçek viewport girdi dağıtımıyla önce FAIL verdi. Ortak comic görünürlük/odak/modal kapısı B01–B04 bölüm callback'lerine uygulandı; gizlenen veya silinmeyi bekleyen konuşma da geç girdi kabul etmez. Diyalog zamanlayıcısı eklenmedi.

0.15.8-focus-alpha adayı: yeni callback regresyonu16/16, Godot4.4.1'de geçti. Ortak konuşma25/25 ve saf diyalog testi aynı motorda geçti. Godot4.6.3'te varsayılan tam akış81/81; kayıt60/60, klavye bölüm zinciri45/45, softlock12/12 geçti. Bu yerel motor sürüm farkı 4.4.1 yayın kanıtı yerine kullanılmaz. Yeni test CI'ın zorunlu konuşma adımına eklendi. Tam4.4.1 akışı ve sunucu/görüntülüCI/Web export/deploy sonuçları ayrıca izlenecek; henüz bu aday canlı sayılmaz.

Sıradaki ürün işleri: B04 kalan geri dönüşler, JOURNEY-MAP-NEXT sözleşmesiyle gerçek yolculuk haritası ve güvenli hızlı geçiş. Gerçek mobil/WebGL uzun oynanış ve çocuk kullanılabilirliği hâlâ açık. Rutin gönderim/yayın yetkisi geçerlidir; başka sohbet veya yeniden açıklama gerekmiyor.

### 0.15.8 kesin kabul ve yayın — 8 Kasım 2026

Kaynak **cf6abcad57afae8e0c49538427c158b7486732c4**, [Actions42461341445](https://github.com/rizaaltun/catpat-godot/actions/runs/42461341445): verify ve deploy başarılı. Godot4.4.1 yeni16/16 odak denetimi, varsayılan görüntülü dokunma/otomatik akış, kıyı, kayıt/geçiş/kurtarma, eski tam fizik rotaları, B00–B05 görüntü/sözleşme kontrolleri ve Web export geçti. Yerel4.4.1 tam akış da81/81 tamamlandı.

Canlı `https://rizaaltun.github.io/catpat-godot/?v=0.15.8` HTTP200; executable `catpat-cf6abcad57afae8e0c49538427c158b7486732c4` olarak doğrulandı. Bu bir canlı paket doğrulamasıdır; fiziksel mobil/WebGL uzun oynanış veya çocuk kullanılabilirliği testi değildir. Kaynakta artık0.15.8-focus-alpha yayımlanmıştır; önceki aday notunun yayın bekleme durumu geçersizdir. Sıradaki ürün kapsamı değişmedi.

## 8 Kasım 2026 — 0.16.0 resimli yolculuk haritası adayı

`JOURNEY-MAP-2026-11-08.md`: ana menü ve molada altı bölgelik boyalı harita; kanonik kayıt okuma, aynı dünyaya moladan dönüş, izole replay ve kilitli bölge önizlemesi. Dar ekranda ham dokunmayla kaydırma; büyük yazı ve klavye erişimi. `production/JOURNEY_MAP_ART_V1.json` kaynak/brif/ölçü/sha ve canlı metin alanlarını kaydeder. Yeni karakter tasarımı veya kitap orijinali eklenmedi.

Yerel Godot4.4.1 native105/105, iki gerçek kare açılıp incelendi; experience42/42 ve replay93/93. Test yeni bir eski-ekran durumundan yanlışlıkla replay başlatma yolunu, B04 farklı devam düğmesini ve B05'in donmuş oyun/pause panelini birlikte çözme gereğini yakaladı; düzeltildi. Ham dokunma, iptal, sürükleme ve türetilmiş fare testleri zorunlu. Yeni CI native harita adımı ve kare artifact'i eklendi. Son ek görünürlük koruması dahil sunucuCI/export/yayın ayrıca doğrulanacak; bu aday henüz canlı sayılmaz.

Bu teslim JOURNEY-MAP-NEXT üretim sırasının1–3 aşamasıdır. Yeni durak geçmişi/hızlı geçiş ve bölüm sonlarını harita akışına dönüştürme hâlâ4–5 aşamasıdır. Ziyaret edilmemiş duraklar açılmaz; mevcut otomatik geçişler kaldırılmaz. Fiziksel mobil/WebGL uzun kullanım QA'sı açıktır.

### 0.16.0 kesin kabul ve yayın — 8 Kasım 2026

Kaynak **7de6f0dc180e68564c97f669cccfefef85953311**, [Actions42463741437](https://github.com/rizaaltun/catpat-godot/actions/runs/42463741437): verify ve deploy başarılı. Zorunlu native harita denetimi ve iki kare artifact'i, diyalog/odak/varsayılan otomatik akış, kıyı, kayıt/yeniden başlatma/geçiş/kurtarma, tam fizik rotaları, B00–B05 görüntü/sözleşme testleri ve Web export geçti. Son kaynak yerel headless101/101; native görüntülü105/105. Ek kilitli festival önizlemesi ve tamamlanmış festivalin ayrı devam/replay eylemleri native görüntülerde incelendi.

Canlı `https://rizaaltun.github.io/catpat-godot/?v=0.16.0` HTTP200 ve executable `catpat-7de6f0dc180e68564c97f669cccfefef85953311` ile doğrulandı. Ana menüde ve gerçek mola ekranlarında **Yol haritası** açılır. Bu kanıt fiziksel mobil/WebGL uzun oynanış testi değildir. Önceki adayın yayın bekleme durumu geçersizdir.

Kesin sonraki iş: gerçek zemin/konumla açılan güvenli durak geçmişi, yalnız aktif bölümde atomik hızlı geçiş, eski kayıt ve geri alma hata matrisi; sonra bölüm sonlarının harita akışına dönüşümü. Harita ekranı bu işler bitmiş gibi göstermez ve ziyaret geçmişi uydurmaz. Mevcut rutin uygulama/doğrulama/yayın yetkisi korunur; aynı projede bu sohbetten devam edilebilir.
