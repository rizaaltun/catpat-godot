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
