> V21 / 12 Ekim: Ana B03→B04 geçişi, schema10 ve eski4–9 göçü; üç Yamaç görevi ana kayda bağlı, pause/menü/Devam çalışır. Bağımsız137 teknik kontrol ve yeni panellerin native incelemesi geçti. Sıradaki T22 festival girişinin ayrıntılı parkur sözleşmesi. Final sanat/kimlik/cihaz kapıları açık; CURRENT.md günceldir.

> V20 / 12 Ekim: Pıtpıt düşmüş ok/dikme görevi ve ekip seyir durağı; schema4 ortak snapshot, eski1–3 göçü. Üç yardım ortak rotada oynanır. Sıradaki B03→B04 ana entegrasyonu; final sanat/cihaz açık. CURRENT.md güncel devam noktasıdır.

> V19 / 12 Ekim: Maymun halatı, fiziksel taşıma/yerleştirme, karşılıklı diyalog ve schema3 kayıt. Eski ileri kıyı kaydına fiziksel ekip dönüşü eklendi. Bağımsız128 teknik kontrol; sanat/cihaz açık. Sıradaki Pıtpıt yön işareti, ardından B03→B04 ana entegrasyonu. CURRENT.md güncel devam noktasıdır.

> V18 / 12 Ekim: Porsuk yol feneri, fiziksel alt basamak erişimi, karşılıklı diyalog ve schema2 görev kaydı uygulandı. Bağımsız93 teknik kontrol; final sanat/cihaz açık. Sıradaki Maymun halatı; ana B03→B04 entegrasyonu henüz yok. CURRENT.md güncel devam noktasıdır.

> V17 / 9 Ekim: ortak rota güvenli kıyı kaydı, bozuk dosya kurtarma ve pause/reload uygulandı. Ana hikâye şeması9 korunur; B04 görevleri ve ana zincir entegrasyonu sırada. CURRENT.md güncel devam noktasıdır.

> V16 / 9 Ekim: serbest Çatpat + üç arkadaş aynı iki taşıyıcılı rotada; yön değişimi, erken ayrılma ve fiziksel toparlanma native denetlendi. Ortak kayıt/checkpoint, B04 görevleri ve final sanat açık. Canlı önizleme V13; kesin devam CURRENT.md.

> V15 / 9 Ekim: iki taşıyıcılı Z44 çalışma sahnesi; serbest Çatpat rotası ve ayrı kontrollü dört kişilik prova. Alt fiziksel dönüş yolu ve780 birim ara ada. B04 tam bölüm/serbest ekip entegrasyonu halen açık; canlı önizleme V13. CURRENT.md güncel devam noktasıdır.

> V14 / 7 Ekim: T20a hareketli yüzey temeli ve T20c tek taşıyıcı sıra prototipi native olarak sınandı. B04 tam bölüm değil; canlı önizleme V13. Kullanıcı isteğiyle checkpointte duruldu. CURRENT.md ve V14_CARRIER_SPEC.md devam kaydıdır.

> V13 / 7 Ekim: B03 köklü kayalar, alçak bahçe yolu ve siper arkasında rüzgâra tepki veren papatya yatağı. B04 ayrıntılı ön üretim LEVEL_B04_PREPRODUCTION.md içinde, DESIGN ONLY. Güncel kanıt ve devam noktası CURRENT.md.

> V12 / 7 Ekim: B03 Papatya Bahçesi ilk oynanabilir akışı, kaynakla doğrulanmış Pıtpıt rolü, iki rota ve dört kişilik ekip. 100 bağımsız kontrol geçti; profesyonel çevre/animasyon ve mobil kapılar açık. CURRENT.md ve LEVEL_B03_V12.md güncel uygulamayı tanımlar.

> V11 / 7 Ekim: B02 doğal kıyı ve tek destekli köprü sanatı, ortak klavye/dokunmatik kontrol sunumu ve beş native ekran oranı incelemesi. Güncel durum CURRENT.md; final mobil ergonomi/kimlik/animasyon kapıları açık.

> V10 güncellemesi / 7 Ekim: Dostluk Deresi ilk oynanabilir sürümü uygulandı. Sağ kıyı2850, doğal su açıklığı, iki parça kolu, şema8 kayıt geçişi ve Maymun katılımı. Eski blok koordinatlarından farklı kesin uygulama LEVEL_B02_V10.md ve CURRENT.md içindedir; final sanat/cihaz kapıları açık.

> 7 Ekim 2026 V9 kapsam notu: B01 kompakt 4200 birim görev akışı uygulanıp denetlendi; üç farklı erişim, dönüş geçitleri, Porsuk çıkış katkısı. Aşağıdaki5400 birim bütçesi zorunlu uzatma değildir. Kullanıcının güncel sırası genel bölüm işleyişi önce, final karakter sanatı sonra. Güncel kanıt/sıradaki uygulama CURRENT.md ve qa/v9 içindedir. Tam G2 sanat/cihaz kapısı açık tutulur.

# Çatpat: Festival Yolu — ana üretim planı

Sürüm 1.1 • 6 Ekim 2026 • Takvim: Europe/Istanbul

Uygulama ayrıntıları: IMPLEMENTATION_SPEC.md. Fiziksel yerleşim: ZONE_SPEC.csv ve zone_specs.json; bağlantılar CONNECTIONS.csv. Bu dosyalar genel anlatımdan daha günceldir.

## 1. Bu belgenin kararı

Bu plan mevcut Godot projesine aittir; ayrı bir oyun veya sıfırdan yeniden başlama değildir. Çalışan V4 korunacak, eksikleri kapatılacak ve aynı temel üzerinde tam oyun kurulacak. Plan, eski yedi günlük bitirme takvimini ve karakter onayını bütün teknik işlerin önüne koyan eski sırayı geçersiz kılar. Önce genel oynanış, sonra bütün bölüm zinciri, sonra nihai karakter üretimi. Karakter onayı yayın öncesinde yine gereklidir.

Hedef: Çatpat'ın festivale giderken arkadaşlarına yardım ettiği, yardım edilen herkesin yolculuğa katıldığı, yatay ekranlı 2D mobil platform macerası. Yardımlar oyun dünyasında hareket ederek yapılır; soru-cevap veya doğru seçenek testi yoktur. Nihai hedef iOS; tarayıcı sürümü kolay inceleme yoludur. Ana kaynak Godot/GDScript olarak kalır; sonunda başka bir dile çevirme üzerine plan kurulmaz.

İlk tam sürüm için tasarım bütçesi: giriş + beş bölüm, üç katılan arkadaş, yaklaşık 40–55 dakika ilk oynayış, isteğe bağlı keşifle 50–65 dakika. Bunlar ölçülmüş süreler değil, bölüm testleriyle ayarlanacak hedeflerdir. Başlangıç okuma/ergonomi varsayımı 5–9 yaş ve ailece oyun; yaş derecelendirmesi iddiası değildir.

Kapsam dışı: savaş, can/enerji satışı, reklam, çevrimiçi hesap, çok oyunculu mod, açık dünya, günlük görev ve rastgele eşya ekonomisi. Bu kararlar üretim bütçesini anlamlı platform tasarımına ayırır. Tam seslendirme ilk sürümün zorunlu kapısı değildir; tüm hikâye sessiz oynanabilir olmalıdır.

## 2. Gerçek başlangıç noktası

V4'te mevcut: kısa Fenerli Patika; Çatpat/Porsuk hareketi; üç fener; iki konuşma; tek arkadaş takibi; yerel kayıt; menü/pause/yeniden başlatma; ilk bölüm bitişi. Motorun 28 kontrolü ve bağımsız denetim raporu var. Bunlar bütün oyunun kabulü değildir.

Eksik: ölçülmüş hareket parkuru, üretim kamera sistemi, bölüm yöneticisi, birden çok arkadaşın takibi, tam Fenerli Patika, diğer bölümlerin bu kalite temelinde uygulanması, erişilebilir UI, gerçek Safari ve cihaz testi, son karakter seti, ses bütünlüğü ve yayın paketi. Eski 6400 birimlik prototipte bulunması bir özelliğin yeni oyunda tamamlandığını göstermez.

Kitap referansı: Çatpat/Porsuk ve Maymun için projedeki kaynak görseller kullanılacak. Pıtpıt adı/kimliği eski tasarım belgelerinde geçiyor; bu plan onun kitapta doğrulanmış kimliğini varsaymaz. B03 bu doğrulama yapılana kadar “Bahçe Arkadaşı” rolüyle planlanır. Yeni yan karakter uydurup kitaptanmış gibi eklenmez. Aşağıdaki olaylar ve replikler yeni oyun senaryosu önerisidir, kitaptan alıntı değildir.

## 3. Deneyim ve hikâye omurgası

Çatpat festival davetini görür ve yola çıkar. Rüzgâr yol hazırlıklarını dağıtmıştır. Her karşılaşma farklı bir ihtiyacı görünür kılar: Porsuk yolu göremiyor; Maymun derenin karşısında kalan hazırlığını tamamlayamıyor; bahçe arkadaşı savrulan festival süslerini ve çiçekleri korumaya çalışıyor. Yardım alanlar pasif ödül olmaz: sonraki yolda ve finalde kendi katkılarını verirler.

Çatpat'ın değişimi acele etmekten birlikte ilerlemeye geçiştir. Zaman sınırı bu temayla çelişeceği için ana rotada geri sayım yoktur. Final “geç kaldın” cezası vermez. Oyuncunun üç bölümde yaptıkları festivalde görünür: ışıklar, sağlam bağlantılar, çiçek/süs düzeni. Finalde ilk ışık birlikte yakılır.

Ana döngü: çevreden sorunu fark et → kısa konuşma → hareketle çözüm → çevrede görünür değişim → arkadaşın katılması → yeni birlikte geçiş. Her bölüm önce tek mekaniği güvenli ortamda öğretir, sonra bir çeşitleme, sonra iki tanıdık hareketi birleştiren doruk sunar. Yalnız nesne sayısı artırılarak bölüm uzatılmaz.

## 4. Kontrol ve fizik sözleşmesi

Eylemler: yürü, değişken yükseklikte zıpla, bağlama göre etkileş, duraklat. Ayrı saldırı, koşma veya envanter tuşu yok. Etkileşim yalnız erişim mesafesinde ve uygun durumda görünür. Arkadaş yeteneği ilgili nesnede aynı etkileşimle başlar; oyuncu karakter değiştirmek zorunda kalmaz.

Mevcut başlangıç değerleri: hız 300, yerçekimi 1500, sıçrama hızı 700, kenar toleransı 0,12 s, giriş tamponu 0,14 s. Bunlar mevcut kod değerleridir, son tasarım kararı değildir. Değerler tek MovementProfile kaynağına taşınacak. Tam basılı ideal sıçrama hesabı yaklaşık 163 birim yükselme verir; gerçek motor ölçümü ve kısa basma ölçümü parkurda kaydedilecek.

İlk yerleşim bütçesi: zorunlu yükseklik farkı 40–90 birim, zorunlu boşluk 80–150, iniş genişliği en az 100. Ana rotada hiçbir sıçrama ölçülmüş erişimin %70'ini aşmayacak; bu oran genişlik ve yükseklik birlikte değerlendirilerek sınanacak. İsteğe bağlı zor yol %85 sınırında kalabilir; aynı ödülün zorunlu olması yasaktır. Hareketli platformdan kör sıçrama yok. Düşülen yerde yakın güvenli zemin veya kontrol noktası var.

Kamera: yatay önden bakış, küçük düşey ölü bölge, sınırda yumuşak duruş; oyuncu yön değiştirince ani ters sıçrama yok. İniş noktası havalanmadan önce görünür. Ekran dışındaki platforma atlamak gerekmeyecek. Diyalog, pause ve geri yükleme kamerayı rastgele kaydırmayacak. Görsel sarsıntı kapatılabilir.

## 5. Bölüm yapısı ve görev çizelgesi

Bölüm boyları ilk blok yerleşim bütçesidir; görev sırası fiziksel soldan sağa sıraya eşit değildir. B01 ve B02 dönüş bağlantıları aşağıda ayrıca belirtilmiştir; sanat ölçeği veya tekrar eden doku sayısı değildir. Her aralık yerel dünya X koordinatıdır. Y koordinatları gri blok testinde belirlenecek. Bölüm süresi koşu mesafesinden türetilmez; yardım, gözlem, konuşma ve ilk deneme süreleri de ölçülür.

### B00 — Davet ve Ev Önü • 2–3 dakika • 0–2200

Amaç: kontrolü metin duvarı olmadan öğretmek ve festival hedefini göstermek.

- Z00 / 0–450: güvenli başlangıç ve festival daveti. Hareket ipucu ilk adımla kaybolur. Kamera sabittir; tehlike yok.
- Z01 / 450–1000: 40 birim kök, sonra kısa çukur; altta düz geri dönüş yolu. Bir kısa basma, bir uzun basma doğal olarak denenir.
- Z02 / 1000–1650: alçak dal altından yürüyüş ve kolay üst yol. İsteğe bağlı tek festival kurdelesi; ana rota açık.
- Z03 / 1650–2200: manzara durağı, uzaktaki festival ışıkları, sönük patikaya geçiş. Kısa Çatpat iç konuşması.

Görev Q00: davet görüldü → ilk yol tamamlandı → B01 açıldı. Öğretici ilerleme kaydı vardır; tekrar girildiğinde uzun öğretici zorunlu değildir. Kabul: klavye ve dokunmatik ile ipucu kaybolma/sıralama doğru; oyuncu yanlış yoldan kilitlenmez.

### B01 — Fenerli Patika / Porsuk • 7–9 dakika • 0–5400

Amaç: ışığın çevreyi değiştirdiği ilk yardım ve arkadaş katılımı. Mevcut V4 sahnesi bu bölümün teknik tohumu; tam bölüm sayılmaz.

- Z10 / 0–650: gölgeli viraj ve güvenli Porsuk karşılaşması. İlk fener silueti görüş alanında; karanlık kontrolü gizlemez.
- Z11 / 650–1550: kök basamakları, sabit fener mandalı. Yaklaş + etkileş; ışık zemini ve sonraki hedefi görünür kılar.
- Z12 / 1550–2650: devrilmiş ağaç, iki yükseklik ve alt güvenli dönüş yolu. Yukarıdaki fener erişilebilir bir köprücükte. Aynı nesne avının tekrarı yerine farklı rota gerekir.
- Z13 / 2650–3800: yavaş hareketli dal ve sabit kolay alt yol. Üçüncü fenerin siperini kaldır; anahtar ezberi veya zamanlama tuzağı yok.
- Z14 / 3800–4500: bütün yolun ısındığı kısa görsel sonuç. Açılan güvenli alt koridor Z10’daki sabit Porsuk durağına bağlanır; üst platform engelleri tekrar edilmez. Alt yol X=650–4500 boyunca ayrı Y kotundadır; gidiş/dönüş yaklaşık 25 saniye hedefi motor testinde ölçülür.
- Z15 / 4500–5400: çıkış ve birlikte yürüyüş. Katılım konuşması fiziksel olarak Z10’daki Porsuk durağında yapılır; sonra ekip güvenli alt koridordan Z15’e gelir. Porsuk haritada kendiliğinden başka bir noktaya taşınmaz. Porsuk küçük gölgeli geçitte ışık tutar; yeteneği hemen anlam kazanır. Dere sesi sonraki bölümü haber verir.

Q10: Z10 kabul → Z11/Z12/Z13 fener A/B/C → Z14 alt dönüş yolu açık → Z10 katılım konuşması → Porsuk ekipte → alt koridor üzerinden Z15 çıkış. Fenerler ulaşılabildiği sırada yakılabilir; görev bunu bozmaz. Her fener ve katılım ayrı kalıcı olaydır. Üç fener yanmadan katılım, katılmadan bölüm çıkışı olmaz. CP: karşılaşma, ikinci fener öncesi, katılım sonrası.

Diyalog taslağı: Porsuk “Yolun kıvrımını seçemiyorum.” Çatpat “Önce şu feneri yakayım. Sonra birlikte bakarız.” Sonuçta “Şimdi yolu görebiliyorum.” / “Benimle festivale gelir misin?” İlk sahne 4–6, sonuç 4 replik.

### B02 — Dostluk Deresi / Maymun • 8–10 dakika hedef • kompakt merkez

Önceki 0–6000 doğrusal aralıklar kaldırıldı. Gerçek merkez Z24 (x650–1400,y600); Maymun x950, kurulum x1130. Z20 giriş x0–650. Z23 kavşak x1150–1550. Z21 alt tahta kolu x1400–2350,y760; Z22 üst halat kolu x1400–2350,y390–530. Köprü x1400–2500,y600; Z25 çıkış x2500–3600. Böylece parçalar için uzun boş dönüş yapılmaz.

Akış: Z20→Z24 konuşma→Z23 kavşak→Z21/Z22 herhangi sıra→Z24 teslim/kurulum→Z25. Tahta ve halat dünya/carried/installed durumlarıyla kalıcıdır. İki parça birlikte taşınabilir; hareket cezası yok. Köprü supplied/building/ready durumlarına sahiptir; kesinti anındaki davranış IMPLEMENTATION_SPEC D/F/N içinde kesinleşir. Görünür çıkış kapısı bridge.ready olmadan açılmaz.

Kabul: iki parça sırasının ikisi, su düşüşü, kurulum kesintileri ve reload; köprü görsel/fizik eşleşmesi; iki arkadaşla geçiş. Kesin başlangıç platformları ZONE_SPEC.csv'dedir. Bu düzen motor testinden henüz geçmemiş tasarımdır.

### B03 — Papatya Bahçesi / Bahçe Arkadaşı • 7–9 dakika • 0–5400

Kitap rolü doğrulaması T03'ün çıktısına bağlıdır. Mevcut planlardaki Pıtpıt adı ancak kaynak eşleşirse kullanılacak. Beden ve yetenek kitapla çelişirse parkur aynı ihtiyaç üzerinden uyarlanacak; yeni karakter icat edilmeyecek.

- Z30 / 0–650: çiçek bahçesi ve rüzgârın savurduğu süsler. İhtiyaç çiçekleri korumaktır; cezalandırıcı “yanlış yaptın” dili yok.
- Z31 / 650–1700: geniş taş adımlar. Çiçeklere düşünce nazik geri dönüş; can kaybı yok. İniş noktaları yüksek kontrastla okunur.
- Z32 / 1700–2850: iki yükseklikte kurdele rotası. Üst yol kısa, alt yol kolay; yalnız bir göreve gerekli süs demeti.
- Z33 / 2850–3950: sallanan sepeti alçak noktaya indirme ve rüzgâr siperini sabitleme. İki farklı etkileşim aynı temel tuşla yapılır.
- Z34 / 3950–4650: korunan çiçekler ve sepet teslimi. Arkadaş kendi hazırladığı festival süsünü alır.
- Z35 / 4650–5400: katılım ve birlikte çıkış. Kitaba uygun yetenek doğrulanana kadar arkadaş güvenli rotayı işaret eden rolü üstlenir; yeni büyü/güç atanmaz.

Q30: kabul → süs demeti → sepet → siper (erişim elverdiğince sıra bağımsız) → teslim → katılım → çıkış. CP: giriş, sepet öncesi, teslim. Kabul: bahçeye düşmek görev eşyasını sıfırlamaz; üçüncü arkadaş diğerlerinin içine yığılmaz.

Diyalog taslağı: “Rüzgâr hazırladığım süsleri dağıttı.” / “Çiçeklere basmadan şu taşlardan ulaşabilirim.” Sonuçta yardımın bahçeyi nasıl değiştirdiği gösterilir, uzun ders metni verilmez.

### B04 — Rüzgârlı Yamaç / ekip bölümü • 8–10 dakika • 0–6200

Amaç: önceki katkıları birleştirmek. Yeni arkadaş ve yeni kontrol eklenmez. Zorluk arkadaşları tek tek yönetmek değildir.

- Z40 / 0–800: rüzgâr yönünü gösteren flamalar ve güvenli prova. Rüzgâr ilk sürümde okunur çevre etkisi; rastgele oyuncu savurma yok.
- Z41 / 800–2000: Porsuk'un aydınlattığı kaya altı, görünür inişli iki atlayış. Işık olmadan yol gizlenerek oyuncu cezalandırılmaz.
- Z42 / 2000–3300: Maymun'un sabitlediği halat köprüsü. Ekip güvenli noktada bekler, kurulum biter, sırayla geçer.
- Z43 / 3300–4400: bahçe arkadaşının yol işareti/flama düzeni. Kitapta doğrulanan katkıya göre animasyon değişir; görev sırası korunur.
- Z44 / 4400–5450: sallanan iki platformla kısa doruk. Hareketleri fazı sabit, bekleme yerleri geniş; aşağıda kurtarma rotası.
- Z45 / 5450–6200: bütün ekibin göründüğü manzara, festival kapısı. Oyuncu grubun yetişmesini kısa bekleme alanında görür; uzun takip gecikmesi yok.

Q40: ışıklı geçit → bağlantı → işaret → ortak geçiş → kapı. CP her katkı sonrası. Kabul: eksik görevle önceden açılmış collision oluşmaz; takipçi kurtarması ekranda ışınlanma yaratmaz; oyuncu geriye döndüğünde ekip çözülmez.

### B05 — Festival Alanı / final • 6–8 dakika • 0–4400

Amaç: önceki yardımların karşılığını oynatarak göstermek; yalnız video finali değil.

- Z50 / 0–650: giriş ve boş hazırlık alanı; üç katkı noktası tek genel görünümde işaretlenir.
- Z51 / 650–1650: ışık sırası. Çatpat iki alçak sahne platformundan düğmeye ulaşır, Porsuk ışığı taşır.
- Z52 / 1650–2700: Maymun'la flama bağlantısı. Kısa kütük parkuru ve güvenli kurulum.
- Z53 / 2700–3550: bahçe arkadaşıyla süsleri yerleştirme. Sahneye tırmanış, sepet etkileşimi.
- Z54 / 3550–4400: ekip sahnede; oyuncu son ışığı açar. Karşılıklı kısa konuşmalar, ortak kutlama, tamamlanma kaydı. Menüye dön veya alanda dolaş seçenekleri.

Q50: üç hazırlık (sıra bağımsız) → bütün arkadaşlar sahnede → ortak ışık → final tamamlandı. Son konuşma: Çatpat “Hep birlikte geldik.” Arkadaşların her biri önceki katkısına kısa karşılık verir. Final ödülü puan tablosu yerine aydınlanan alan ve ekip anısıdır. Kabul: final tekrarı katılım veya ödülleri çoğaltmaz; bitişten sonra kayıt yeniden açılır.

## 6. Yan yollar, yeniden oynama ve zorluk

B01–B04'te en fazla bir isteğe bağlı kısa yol/anı; toplam dört anı. Albüm, ana zincir tamamlanmadan üretime alınmaz. Anılar kaçırıldığında final veya arkadaş katılımı kilitlenmez. İsteğe bağlı yol 30–60 saniye hedeflenir; tekrar uzun yürüyüş yok.

Can sayısı ve oyun bitti ekranı yok. Hata sonrası 1–2 saniyelik güvenli dönüş hedefi; en son çözülmüş görev korunur. Uzun düşüş animasyonu, ışık çakması veya alay eden replik yok. Yardım modu bekleme süresini artırabilir ve hareketli yüzeyi yavaşlatabilir; bölüm yapısını yeniden yazmaz. Bölüm seçimi yalnız tamamlanan bölümleri açar.

## 7. Görev, kayıt ve ekip sözleşmesi

Bölüm akışı: locked → available → active → resolved → chapter_complete. B01/B02/B03 içinde resolved ile chapter_complete arasında ilgili companion_joined olayı zorunludur. B00/B04/B05 yeni arkadaş eklemez; mevcut ekip durumunu doğrular. Nesne olayları kalıcı tekil anahtarla işlenir. Diyalog tekrar izlenirse görev ikinci kez verilmez. Sıra bağımsız alt görevler tek sayaca indirgenmez; object_id bazında saklanır.

Kayıt: şema sürümü, bölüm, checkpoint_id, tamamlanan olaylar, katılan karakterler, toplanan anılar, ayarlar. Ham X/Y tek kaynak olmaz; değişen bölüm geometrisinde güvenli checkpoint'e taşınır. Bölüm geçişi önce yeni güvenli noktayı doğrular, sonra kaydı kalıcılaştırır. Hasarlı dosyada yedek/son güvenli başlangıç ve anlaşılır mesaj; sessiz ilerleme kaybı yok. V4 kaydı için tek seferlik göç testi.

Ekip: en çok üç takipçi. Rota izleri, güvenli duraklar ve sıra aralığı ayrı yönetilir. Hareketli platforma binme/inme, dar geçitte bekleme, geri dönüş, oyuncu düşüşü, konuşma ve kayıt yükleme ayrı senaryodur. Aynı noktada tüm karakterler üst üste beklemez. Oyuncu ekibi sürekli çekiştirmek zorunda kalmaz. Görünür teleport kabul edilmez; kurtarma gerekiyorsa perde/geçiş arkasındaki güvenli noktaya ve kayıtlı olay olarak yapılır.

## 8. Menü, HUD, diyalog ve erişilebilirlik

Ana menü: devam, yeni oyun (ilerleme varsa onay), tamamlanan bölümler, ayarlar. Ayarlar: müzik/efekt, metin hızı, tam metin, yazı büyüklüğü, hareket azaltma, kontrol boyutu/konumu. Mobilde güvenli alan ve yatay yönlendirme; dik ekranda döndürme yönlendirmesi, yanlış ölçeklenmiş oyun yok.

HUD aynı anda tek ana hedef, gerektiğinde etkileşim ve küçük ekip göstergesi sunar. İlgisiz E düğmesi sürekli çağrı yapmaz. Klavye kullanımında klavye ipucu, dokunmatik kullanımda dokunma simgesi gösterilir. Kontroller dünyadaki iniş alanlarını kapatmayacak; 16:9, uzun telefon oranı ve 4:3 tablette ayrı incelenecek.

Çizgi roman: portreler sağ/sol; balon kuyruğu konuşana; konuşan/dinleyen ifadeleri. Görsel parçalar imagegen ve kitap referansı ile üretilir, Türkçe metin motor katmanında kalır. Bir basış yazıyı tamamlar, sonraki ayrı basış ilerler. Atla özeti görevi anlatır; ödül olayı yalnız bir kez oluşur. Balona sığmayan cümle küçültülmek yerine bölünür. İlk tam senaryo bütçesi 13 sahne, yaklaşık 60–80 kısa replik; uzunluk oyuncu testine göre azaltılır.

## 9. Görsel, animasyon ve ses üretim listesi

Şimdi: mevcut karakter adayları geçici olarak korunur. Yeni bölüm geometrisi önce sade bloklarla oynanır; ardından mevcut orman sanat diliyle giydirilir. Karakter görüntüsünü değiştirerek fizik hatası saklanmaz. Karakter kimliği kontrolü erkenden kaynak envanteri düzeyinde yapılır; nihai çizim/animasyon işi tam bölüm zincirinden sonra gelir.

Çevre bütçesi: ev önü, gece patikası, dere, bahçe, yamaç, festival olmak üzere altı görsel set. Her sette uzak/orta/yakın katman, zemin kenarları, geçiş parçaları, etkileşimli nesnelerin pasif/aktif halleri. Karakteri kaybettiren kontrast ve dekor yoğunluğu azaltılır. Bank, köprü ve hareketli platform görseli collision kaynağıyla eşleştirilir.

Karakter başına son set: idle, walk/run, jump_takeoff, rise, apex/fall, land, turn, talk/listen, help, celebrate. Önce bir karakterde bütün hat doğrulanır; sonra diğer üçüne uygulanır. Kare sayıları kör hedef değildir: yürüyüş için 8–12 tutarlı kare başlangıç bütçesi; alternatif cutout rig yalnız siluet/yüz korunuyorsa kullanılabilir. Çatpat'ın ana hareketleri özel; arkadaşların yardım/kutlama pozları rolüne göre farklıdır. Atlas son paketlemedir, yanlış kesilmiş grid üretim kaynağı değildir.

Ses: altı ortam döngüsü, bölüm ailelerine uygun 3 müzik teması ve final varyasyonu, yaklaşık 20–30 olay efekti. Adım yüzeyi, zıplama/iniş, etkileşim, ışık, köprü, su dönüşü ve menü geri bildirimi ayrılır. Diyalog sırasında müzik seviyesi azalır. Ses kapalıyken gerekli bilgi kaybolmaz. Kullanılan varlıkların köken/kullanım kaydı tutulur.

## 10. Kod iş paketleri ve mevcut projeye eşleme

Mevcut scripts/polish_world.gd aynı anda menü, görev, kayıt, dünya, test ve takip yönetiyor. Tek seferde silinmeyecek. Testler korunarak şu sorumluluklara ayrılacak: GameFlow, LevelDirector, PlayerController/MovementProfile, CameraRig, QuestState, PartyController, SaveService, ComicPanel, InputRouter, AudioDirector. Her çıkarım sonrası V4 regresyonu çalışır; modülerleştirme özellik ekleme olarak sayılmaz.

Sahne hedefleri: chapters/b00_home … b05_festival; shared/player, companion, interactable, checkpoint, moving_platform, comic_panel. Bölüm verisi ve hikâye satırları kalıcı ID taşır. Tasarım ölçüleri production/levels.json, işler BACKLOG.csv, ana kararlar bu belge içinde takip edilir. Canlı V4'ün üzerine hazırlıksız bölüm yazılmaz; geliştirme adımı için geri dönüş sürümü tutulur. GitHub repo sağlandığında aynı proje taşınır, yeni paralel oyun açılmaz.

## 11. Kabul kapıları

G0 Tasarım: her zorunlu görev ve bölümün giriş/çıkış koşulu, parkuru, checkpoint'i, varlık ihtiyacı ve testleri tanımlı. Bu belgenin tamamlanması implementasyonun tamamlandığı anlamına gelmez.

G1 Temel: ölçülmüş hareket parkuru; görünür yüzeyle collision; kamera; menü/girdi; V4 kayıt göçü; bir arkadaşla ileri/geri rota. Aynı senaryolar klavye ve dokunmatik girişte çalışmalı. Safari/gerçek cihaz yolu erişim varsa bu aşamada denenir; yoksa engel açık tutulur.

G2 İlk tam bölüm: B00–B01 baştan sona, farklı üç fener problemi, dönüş kestirmesi, arkadaş katkısı ve duraklat/yükle/yeniden başlat. Bir tam motor videosu ve bağımsız rapor; bilinen P0/P1 yok.

G3 İçerik alfa: B00–B05 kesintisiz oynanır; üç arkadaş finalde; bütün kayıt/geri dönüş yolları açık. Geçici karakter sanatı kabul edilebilir, eksik görev zinciri değil.

G4 Sunum beta: çevre/UI/ses ve nihai karakterler tutarlı; kitap kimliği insan onayı alınmış; küçük ekran metin/kontrast testleri; yeni kapsam eklenmez.

G5 Yayın adayı: gerçek cihazlarda ölçüm, iOS paket/kurulum, arka plana dönme, ses kesintisi, kayıt, uzun oturum ve mağaza materyalleri tamam. Apple hesabı, imzalama ve cihaz erişimi dış bağımlılıktır; mevcut diye varsayılmaz. Güncel mağaza şartları bu aşamada resmi kaynaklardan doğrulanır. Mağaza onayı için tarih garantisi yok.

Hata seviyesi: P0 açılmama/kayıp ilerleme/kilit; P1 zorunlu rotanın bozulması/yanlış etkileşim/ekip kaybı; P2 görsel veya konfor sorunu. Bir sürümde bilinen P0/P1 varsa inceleme sürümü olarak açık etiketlenir; bitmiş diye yayınlanmaz. Kullanıcı hata avcısı olarak atanmaz. Denetçi kullanıcı yerine karakter kimliği onayı vermez.

## 12. Tarihli üretim takvimi

Önceki 40 başlık = 40 gün varsayımı kaldırıldı. BACKLOG.csv artık her paketin iyimser/olası/kötümser aktif gününü ve olası süre üzerinden başlangıç/bitişini içerir. SUBTASKS.csv tasarım, üretim, kabul testi ve bağımsız kapanışı ayrı işlere böler. Bunlar tahmindir; aktif oturum olmadığı gün ilerleme sayılmaz. Hafta sonu dışındaki resmi tatiller/kişisel erişim engelleri ayrıca yeniden planlanır.

T02 hareket/cihaz yolu, T13 ilk tam bölüm süresi ve T32 tek karakter üretim ölçümü üç yeniden tahmin kapısıdır. Takvim kapı geçmediğinde otomatik tamamlanmış sayılmaz. Önce genel oynanış, sonra tam bölüm zinciri, ardından çevre/UI/ses, en son nihai karakterler ve mobil yayın hazırlığı korunur. Tarihler BACKLOG.csv'de tek kaynaktır; mağaza kabul tarihi değildir.

## 13. Her çalışma oturumunun düzeni

Başlangıçta CURRENT.md ve açık hata kayıtları okunur. Tek ana iş paketi seçilir; “her şeyden biraz” yapılmaz. Çıktı üretilir, ilgili kabul senaryosu çalıştırılır, bağımsız ajan kaynak/video/log kanıtını değerlendirir, hatalar aynı ID ile düzeltilir. Sonunda build/kaynak, hangi kapının açık olduğu, bir sonraki iş ve engeller kaydedilir. Kullanıcıya uzun hata listesi çıkarması söylenmez.

Bir günlük ilerleme notu dört şeyi söyler: ne değişti, hangi oyuncu davranışı doğrulandı, ne test edilmedi, sonraki iş. Değişiklik yalnız plandaysa “oyuna eklendi” denmez. Oturumlar arasında çalışma otomatik başlamaz; bu takvim bir üretim belgesidir, kurulmuş otomasyon değildir.

## 14. Şimdi yapılacak ilk uygulama

T01 bu planlama teslimiyle kapanır. Sonraki T02: hareket/kamera ölçüm parkuru ve cihaz testi yolunun kurulması. Mevcut oyunda sadece belirli noktalara giden testin yanına kısa/uzun sıçrama, kenar, iniş, geri dönüş, hareketli platform, farklı ekran oranı ve kontrol çakışması senaryoları konur. Ardından T03 kaynak/rol envanteri ve T04–T08 temel ayrıştırma gelir. B02'ye veya yeni karakter çizimine doğrudan atlanmaz.
