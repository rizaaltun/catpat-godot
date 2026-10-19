# Çatpat — uygulama tasarımı ve üretim sözleşmesi

Sürüm 1.1 • 6 Ekim 2026 • Mevcut V4 üzerine uygulanacak tasarım

Bu belge, ana planın “ne yapılacak?” kısmını “nasıl davranacak, nerede olacak, hangi durumda başarısız sayılacak?” düzeyine indirir. Buradaki sayılar motorla ölçülene kadar tasarım başlangıç değeridir. Çalışan oyuna uygulanmış özellik sayılmaz. Öncelik sırası: bu sözleşme → güncel bölüm verisi → ana planın genel anlatımı → tarihsel belgeler. Çelişki sessizce yorumlanmaz, karar kaydına alınır.

## A. Kesin kararlar ve açık kararlar

Kesin kullanıcı yönü: hareket edilen 2D platform oyunu; Çatpat ve arkadaşları kitap kimliğiyle; yardım edilen herkes festivale katılır; sağlı sollu çizgi roman sahneleri; görüntüler imagegen/referans temelli; iMac'te kurulumsuz inceleme; nihai hedef mobil/iOS; önce genel oyun, son aşamada karakter değişimi.

Tasarım kararı: ana rota zamansız, düşmansız, sınırlı kontrollü; oyuncu başarısız olduğunda yakın güvenli noktaya döner. Yardım eşyası bir bulmaca çözümü değilse tekrar toplatılmaz. Her bölüm yeni bir ana kontrol eklemek yerine aynı hareketin yeni kullanımını öğretir. Zorluğu sadece art arda daha uzun sıçramalarla yükseltmeyiz.

Açık karar O01: bahçe arkadaşının kitap kimliği ve rolü. T03 kaynak sayfası eşleşmeden ad/özel yetenek/nihai sanat kilitlenmez. Bağımlı işler bloklanır; kitaptan olmayan karakterle boşluk doldurulmaz.

O02: gerçek en düşük hedef cihaz/OS. T02'de erişilebilir cihaz listesi ve test yolu çıkarılır; T36'ya kadar gizlenmez. O03: seslendirme bütçesi ve ses kaynağı. İlk sürüm yazılı diyalog + efekt ile tamamlanabilir; seslendirme ayrı değişikliktir. O04: kullanıcı karakter kimliği onayı. Sadece nihai karakter üretimini ve yayın kapısını etkiler, genel oyun kodunu durdurmaz.

O05: ilk oynayış süresi. Önceki 40–55 dakika hedefi bir sonuç değildir. İlk bölüm ölçümleri, tekrar yürüyüş ve diyalog süreleriyle yeniden tahmin edilir. Süreyi tutturmak için yeni toplanabilir nesne eklenmez. O06: App Store hazırlığına gerekli hesap/cihaz/hak belgeleri. T02 erişim envanterinde sahipleri ve eksikleri yazılır.

## B. Oyuncu davranışının ayrıntısı

PC: A/D veya sol/sağ hareket, Boşluk zıplama, E etkileşim, Esc pause/geri. Dokunmatik: sol/sağ, zıplama ve bağlama göre yardım. Gamepad ilk sürümün zorunlu kapsamı değildir. Hiçbir görev yalnız klavye kısayoluyla yapılamaz.

Durumlar: grounded, rising, falling, landing, interacting, dialogue, paused, recovering, chapter_transition. Yalnız ilk dört durumda yürüme girdisi uygulanır. Pause fizik/nesne zamanını da durdurur; yalnız karakteri dondurup hareketli platformu yürütmez. Dialogue sırasında yakın tehlikeler ve taşıyıcı platformlar aynı zaman politikasını kullanır. Oyuncu grounded ve güvenli interaction_anchor üzerinde değilse konuşma bekletilir.

Girdi önceliği: sistem kesintisi → modal pencere → diyalog → pause → yardım → zıplama/yürüme. Bir fizik karesinde etkileşim ve zıplama gelirse geçerli yardım hedefi yoksa zıpla; hedef varsa yardım yalnız grounded durumda başlar. Havada E'ye basmak gizli görev tetiklemez. Modal kapanınca elde tutulmuş E/Boşluk yeniden basılmış sayılmaz; bırak-yeniden-bas gereklidir.

Touch sahipliği: her parmak başlangıç düğmesine atanır. Parmak 24 tasarım birimi dışına taşarsa o düğme bırakılır; başka düğmeye kendiliğinden transfer olmaz. İki parmak iki bağımsız eylemdir. Mouse emülasyonunda aynı touch iki kez sayılmaz. Giriş kaybı, resize, uygulamanın arka plana geçmesi bütün sahiplikleri temizler. Bir yönü bırakmak zıplamayı, zıplamayı bırakmak yönü kesmez.

Hareket başlangıç parametreleri mevcut koddan alınır; T02 ölçümü sonrası MovementProfile içinde tek noktadan değiştirilir. Hedef coyote 120 ms, jump buffer 140 ms, erken bırakma ile kısa sıçrama. Çift zıplama yok. Duvar köşesine sürtünme ekstra zıplama sağlamaz. Tavana çarpışma yukarı hızı keser; yatay hareketi kilitlemez. İniş sıkışması görseldir, collider boyu değişmez.

Yüzey sözleşmesi: oynanabilir zemin, dekor ve tek yönlü platform ayrı türdür. Dekor collider taşımaz. Yürünebilir eğim başlangıç üst sınırı 40°; daha dik çizim duvar/engel gibi okunmalıdır. V4'ün 58° toleransı kalıcı seviye standardı sayılmaz. Snap başlangıç 12 birim; basamak kabul yüksekliği 8. Yaprak çıkıntıları collider'a eklenmez, ana basış hattı izlenir. Oyuncu ayağı ile sanat basış hattı farkı düz zeminde ≤6, eğimde ≤12 tasarım birimi hedeflenir. Yanlış pivot collider'ı kaydırarak saklanmaz.

Geometri testinde ayak referansı collider tabanıdır. Nihai karakter görseli sonradan değiştiğinde bu referansa oturtulur. Kamera oyuncunun resmi yerine fizik kökünü takip eder. Karakter resmi ters çevrilirken görev eldeki nesne yanlış ele/geometri içine geçmemelidir; asimetrik poz ayrı iş olarak izlenir.

## C. Kamera ve platform kütüphanesi

1280×720 tasarım çerçevesinde oyuncu merkezde değil, gidiş yönündeki alanı gösteren yaklaşık %42/%58 yatay konum bandında tutulur. Başlangıç önden bakış 90 birim, yön değişimi 0,25 s; düşey ölü bölge 80. Bu değerler T02'de sınanır. Kameranın zıplamanın her karesini yukarı/aşağı aynen izlemesi engellenir. Platform iniş yüzeyi kalkıştan önce en az 100 birimlik okunur kısmıyla görünmelidir.

Diyalog girişi 0,2 s kararma/yerleşim; çıkışta mevcut dünya kamerasına dönülür, oyuncu koordinatı değişmez. Hareket azaltma açıkken kaydırma yerine kısa solma. Bölüm sınırında arka plan boşluğu veya sert doku kesimi kabul edilmez. Kamera hareketi pause sırasında devam etmez.

P-SAFE: düz emniyet yüzeyi; en az 220 genişlik, tüm ekip beklemesi için en az 520. P-STEP: 40–70 yükselme, 120+ iniş. P-GAP: 80–130 boşluk, 140+ iniş; alt kurtarma zemini. P-UPPER: en fazla iki ardışık yükselme, her biri 60–80; arada dinlenme. P-MOVE: 180 genişlik, yatay yol 160, hız 50 birim/s, uçta 0,6 s durma; başlangıç fazı deterministik. P-BRIDGE: tek kurulum olayıyla açılan geçiş, grafik ve fizik aynı durumda. P-RETURN: düşük engelli dönüş koridoru, görev süresini doldurma yolu değildir.

Hareketli platform: fizik güncellemesinde hareket eder; üzerinde duran oyuncu/arkadaş taşıyıcı hızını alır. Zıplama sırasında taşıyıcı hareketinin oyunu bozacak ek sıçrama üretmesi engellenir; miras hızı açık parametredir. Platformun altında ezilme tasarlanmaz: engelle kesişecek rota yoktur. Platform üstünde save yapılırsa load platform üzerinde rastgele fazda doğurmaz; en yakın sabit durak checkpoint'i kullanılır.

## D. Nesne davranış sözleşmeleri

I01 — Etkileşim hedefi seçimi. Oyuncuya 90 yatay/70 düşey birim içindeki erişilebilir hedefler adaydır; arada duvar varsa aday değildir. En yakın geçerli hedef seçilir, eşitlikte stabil object_id. Tek vurgu ve tek etkileşim metni vardır. Oyuncu hedefin öbür yanına geçerse nesne kaymaz; oyuncu güvenli anchor'a yalnız ≤24 birim hizalanabilir. Daha uzaktaysa yürüyerek yaklaşması gerekir.

I02 — Fener A. Durum off → activating → on. E basılınca 0,45 s yardım animasyonu oynar, olay sonunda light.A bir kez kaydedilir. Etkinleşirken tekrar basma ek olay üretmez. Checkpoint, ışık ve HUD aynı olaydan türetilir. Kesinti commit'ten önceyse off, sonraysa on yüklenir. Işık zemini görünür kılar; zorunlu inişler öncesinde tamamen siyah olmaz.

I03 — Fener B. Aynı durum makinesi; erişim farklıdır: üst rota. Ayrı tuş dizisi yok. Oyuncu fenerin altından E ile yakamaz. I04 — Fener C. covered → uncovered → activating → on. İlk etkileşim siper kaldırma, ikinci ayrı basış yakma. Siper açılması kalıcıdır. Araya reload girerse siper kapanmaz; ışık yakılmamışsa off kalır. Oyun hangi adımı beklediğini “Siperi kaldır”/“Feneri yak” ile açıklar.

I05 — Tahta/halat toplama. world → carried → installed. Kabul edilmiş görevden önce görünür ama görev eylemi açılmaz; kısa “Maymun'la konuş” ipucu verilir. Envanter ekranı yok, HUD'da iki küçük görev yuvası vardır. İki parça aynı anda taşınabilir; karakter elinde dev levhayla koşmak yerine küçük temsil/çanta kullanılır. Hız ve jump aynı kalır. Düşüş carried durumunu bozmaz. Spawn ve görsel object_id durumundan türetilir.

I06 — Köprü. broken → supplied → building → ready. İki malzeme installed olmadan building yok. Kurulum 2,5 s kısa sahne; oyuncu ve ekip güvenli soldaki anchor'larda. Collision geçişi yalnız ready olayında açılır. Yarım köprü üzerinde doğma yok. Building sırasında kesinti olursa stable supplied yüklenir ve güvenli yerden kurulum yeniden gösterilir; malzeme yeniden toplatılmaz. ready ise animasyon atlanır ve geçiş hemen güvenlidir. Ekip sahneden önce collision üzerine bindirilmez.

I07 — Süs demeti. world → carried → delivered; tahta ile aynı kalıcılık kuralı. I08 — Sepet. raised → lowering → reachable → collected. Kolu çekme 0,5 s, sepet inişi 1,2 s. Sepet collider'ı oyuncu taşımak için kullanılmaz. Düşmeden sonra sepet yeniden yükselmez. Lowering kesintisinde reachable yükleme güvenlidir; bu terminal durumun commit'iyle tutarlı işlenir.

I09 — Rüzgâr siperi. loose → securing → secure. 0,7 s yardım, sonra çiçekler sakinleşir. Rastgele rüzgâr fiziği görev nesnesini tekrar bozmaz. I10 — Flama bağlantısı. locked → available → tying → tied; Maymun gerekli, callback gelmezse 3 s watchdog teknik hatayı loglar ve stable available'a döner; oyuncu kilitli kalmaz.

I11 — Ekip ışığı/işareti. Görev gereken nesneye yaklaşınca arkadaş otomatik doğru durağa gelir. Oyuncu aynı yardım düğmesiyle başlatır. İlgili arkadaş uzaktaysa “Birlikte yaklaşalım” ve yön işareti; görünür teleport yok. I12 — Festival istasyonları. Üç farklı station_id, available → preparing → ready. Bunlardan herhangi biri önce yapılabilir. Son ortak anahtar üç ready ve üç arkadaşın sahne anchor'ı koşulunu ister. final.complete bir kez kaydedilir; serbest dolaşmada tekrar tetiklenmez.

## E. Görev durumları ve olayların sırası

Görev ön koşulları kodda da veriyle aynı kalır. Görev resolved olması, arkadaşın dünyada gerçekten katılma durumuna alınmasından ayrı bir olaydır. Normal dünyada uygun konuşmayı atlamak bu olayı atlamaz; geçerli bitiş koşuluyla aynı sonuç commit edilir. Sıra bağımsız nesneler tek sayacın yanlış artmasına bırakılmaz.

B00: invitation.read → tutorial.walk → tutorial.jump → home.exit. Yürüyüş öğrenimi en az 100 birim gerçek hareket; zıplama öğrenimi rise ve landing gözlenmesi. Oyuncu öğreticiyi atlamak isterse kontrol açıklaması menüde erişilebilir kalır.

B01: meet → accepted → light.A/B/C → all_lit → return_gate.open → joined.badger → chapter.B01.complete. all_lit tam olarak üç distinct light ID gerektirir; C için cover.open tek başına ışık sayılmaz. Porsuk daima Z10 sabit durağında bekler. Katılım konuşması Z10'da; çıkış Z15. Alt dönüş yolunun erişimi ilk üç ışığa bağlıdır, çıkış kapısı katılıma bağlıdır.

B02: meet → accepted → plank.carried/rope.carried → installed → bridge.ready → joined.monkey → chapter.B02.complete. Malzemeler bağımsız; kurulum merkezi sabittir. Köprünün collision ready hâli load'da material_count üzerinden tahmin edilmez, bridge.ready olayından kurulur.

B03: meet → accepted → decor.carried/basket.collected/shield.secure → garden.restored → joined.garden → chapter.B03.complete. Bahçe arkadaşının anlatısal kimliği doğrulanana kadar scene speaker provisional olarak kalır. Teknik garden ID sabit olabilir; oyuncuya geçici etiket gösterilmez.

B04: light_pass.ready → rope_pass.ready → waymark.ready → summit.crossed → chapter.B04.complete. Yeni katılım yok. Önceki bölümlerden gerekli ekip yoksa bölüm seçimi burayı açmaz. Bozuk kayıtla eksik ekip geldiyse kayıt doğrulama kurtarması yapılır, görev sessizce eksik arkadaş üretmez.

B05: festival.light/flags/flowers.ready → all_on_stage → final.complete. Her istasyon bir arkadaş katkısıyla ilişkilidir; başka arkadaş yanlış animasyonu oynatmaz. Tüm ekip konumu hazır değilse final düğmesi kısa bekleme durumunda kalır, 10 s üzeri bekleme bir hata olarak incelenir.

## F. Kayıt, bölüm geçişi ve kesintiler

Kalıcı alanlar: schema_version, chapter_id, checkpoint_id, quest_flags (set), party_ids (ordered), collectibles (set), settings, ending_seen. Kontrol noktası harita sürümüyle eşleşmelidir. Transient alanlar kaydedilmez: velocity, anim frame, kamera smoothing, touch pointers, yarım typewriter, moving-platform phase.

Commit sırası: olayın geçerliliğini kontrol et → bellekte yeni durum üret → geçici dosyaya yaz/close → atomik değiştir → görsel/HUD/kapıyı bu durumdan yenile. Yazma başarısız olursa eski geçerli kayıt korunur, oyuncuya bir kez “İlerleme kaydedilemedi” ve yeniden dene imkânı; sonsuz popup yok. V4'teki mevcut uygulama bu tam sözleşmenin yalnız ilk kısmını karşılar.

Autosave: görev commit'i, sabit checkpoint, bölüm geçişi, pause/ana menü dönüşü. Her kare yazma yok. Arka plana geçerken güvenli state varsa flush; yapılabilir diye varsayılmaz, cihazda test edilir. Bölüm yükleme başarısızsa önceki tamamlanmış bölüm ve güvenli checkpoint kaybolmaz.

Load sırası: şema/migration → quest tutarlılığı → chapter kaynakları → dünya nesneleri → sabit checkpoint → oyuncu → ekip durakları → kamera reset → input release → kontrol. Yüklenirken hareket girişleri uygulanmaz. Bilinmeyen chapter/object ID kurtarma raporuna yazılır; yanlış bölüme rastgele düşürülmez. Bozuk ana kayıt varsa doğrulanmış yedek; ikisi de bozuksa kullanıcıya açıklamalı yeni oyun seçeneği, eski dosyalar inceleme için korunur.

Diyalog kesintisinde sahne başından tekrar başlatılabilir; tamamlanmış görev geri alınmaz. Restart current chapter, o bölümün başlangıç snapshot'ına döner; önceki bölüm arkadaşları korunur. New game bütün ilerlemeyi siler ve ayrı açık onay ister. “Bölümü tekrar oyna” ilk tam sürümde ayrı replay snapshot'ıdır; ana hikâyenin ileri kaydı üzerine geriye doğru yazmaz.

## G. Arkadaşların davranışı

Durumlar: waiting_story, joining, follow, wait_platform, assisting, dialogue, regroup, celebrating. Her durumda bir hedef sahibi vardır; route follower ile sinematik aynı anda velocity yazmaz. Priority: kesinti → güvenli toparlanma → scriptli yardım → dialogue anchor → normal takip.

Hedef aralıklar başlangıç bütçesi: Çatpat–Porsuk 120, Porsuk–Maymun 100, Maymun–bahçe arkadaşı 100 birim. Toplam kuyruk kamera/inişleri kapatırsa kamera değil durak tasarımı gözden geçirilir. Sakinleşince her arkadaş farklı boş duruş varyasyonu kullanır, baş sallama/yürüme döngüsü sürekli titreme yapmaz.

Rota kaydı yalnız X değildir: jump başlatma noktası, grounded landing, platform ID, yön, güvenli bekleme anchor'ı saklanır. Arkadaş oyuncunun havadaki her noktasını kovalamaz; erişilebilir bir sonraki hareket parçasını izler. Kullanıcı ters dönerse tüketilmemiş rota birleştirilir; kapalı döngü oluşmaz. Sıçrama tekrarı sonsuz döngüye girerse 3 başarısız denemede güvenli bekleme/alternatif rota; debug kaydı tutulur.

Hareketli platformda bir sonraki bekleme alanı doluysa öndeki geçene kadar bekle. Dar geçide ilk sıradaki girer; arkadaki onu fiziksel itmez. Arkadaş collider'ları oyuncuyu itmez/bloklamaz; dünyayla çarpışır. Düşüş oyuncuyu başarısız saydırmaz; yakın güvenli iz noktasından kamera dışı toparlanma veya kısa görünür yardım geçişi, asla anlık ekran içi yer değiştirme yok.

Bölüm sonu yalnız oyuncu X eşiği değildir: görev complete-eligible, ekip gerekli sırada ready, çıkış interaction ve güvenli anchor. Bu koşul tek olay doğurur. 10 s bekleme üst sınırı tasarım hedefidir; kaçıran rota P1'dir, “kullanıcı biraz daha beklesin” diye geçilmez.

## H. Ekran ve UI akışları

S00 Açılış: kısa yükleme, ilerleme durumu; bozuk yükleme retry ve anlaşılır metin. S01 Ana menü: devam (geçerli kayıt varsa), yeni oyun, bölüm seçimi, ayarlar. S02 Silme onayı: açık kayıp açıklaması, Varsayılan odak Vazgeç. S03 Bölüm seçimi: kilitli/erişilebilir/tamamlandı; kilitli öğe nedenini gösterir.

S04 Oyun HUD: bir hedef, etkileşim adı, gerekiyorsa görev eşyaları; bölüme girdi diye uzun panel açılmaz. S05 Comic: iki portre, tek aktif balon vurgusu, Devam, isteğe bağlı Atla; Atla özeti ve koşullu tek sonuç. S06 Pause: devam, ayarlar, bölümü yeniden başlat, ana menü. S07 Ayarlar: ses, metin hızı/büyüklüğü, hareket azaltma, kontrol ölçeği; açıldığı ekrana geri döner.

S08 Bölüm tamamlandı: sonraki bölüme geç, alanda dolaş, ana menü. S09 Final: anı/sahne, serbest dolaş veya menü. S10 Recovery: kısa geri dönüş; oyun kaybı ekranı yok. S11 Yön/güvenli alan: mobil portrede döndürme yönlendirmesi; oyun pause, girişler sıfır. Ekran akışlarının parent dönüş adresi tutulur; her Geri ana menüye atmaz.

Görsel başlangıç bütçeleri: temel metin 24 tasarım birimi, balon 28; küçük fiziksel ekranda eşdeğer okunurluk cihazda ölçülür. Dokunma hedefi platformun mantıksal ekran biriminde en az 48×48 tasarım hedefi; yalnız 1280 canvas piksel sayısı yeterli kanıt değildir. Güvenli kenar platform inset + mantıksal 16; alt kontroller sağ/sol elde erişilebilir bölgede. Büyük metinde balon yüksekliği artar, metin kesilmez; konuşmayı hızlandırmak için yazı küçültülmez.

Game HUD butonları klavyenin Space/Enter kabul tuşunu yanlışlıkla çalmayacak. Dekor tıklama yakalamaz. Modal arkasındaki düğme etkin değildir. Focus görünür ve kararlı, Esc kademeli geri gider. Oyuncunun yanlışlıkla iki kere basması iki sahne geçişi üretmez.

## I. Görsel ve ses üretiminin teslim sözleşmesi

Her varlık kaydı: asset_id, source_reference, chapter, state, dimensions, pivot, export format, license/origin, revision, reviewer, approval_state. Kitap kimliği onayı ile teknik dosya uygunluğu ayrı alan. “Imagegen üretildi” onay anlamına gelmez. Yeni karakterlerin kesim/pivot ölçümü referans kökten yapılır; kare bazında otomatik yeniden ortalama yok.

Nihai karakter seti için ilk tahmin: koşu 8–12 kare, bekleme 4–6, kalkış 2, yükseliş 1–2, tepe/düşüş 2, iniş 3, dönüş 2, konuşma 3 ağız + göz kırpma, dinleme 2, özel yardım 6–10, kutlama 6–8. Bunlar dört karaktere kör çarpılacak dosya sayısı değildir; rig/kare prototipi T32'de teknik kararı belirler. Animasyon olayları kare indeksine bağlanmaz, semantic marker kullanır: foot_contact, help_commit, land_end.

Çevre katmanları ilk bütçe: uzak 0,15, orta 0,4, yakın 0,8 parallax katsayısı; hareket azaltmada düşük/kapalı. Dikişler kamera gezdirilerek incelenir. Zemin üst yüzeyi karakterin ayak kontrastından güçlü olup gözü dağıtmaz. Efektler görev nesnesini örtmez. Işık kaynağı yanınca yalnız sarı disk çizmek yerine ışıklı/pasif obje durumları ve çevre vurgusu tutarlı olur.

Ses olay listesi: ui.focus, ui.accept, ui.cancel, jump.takeoff, land.soft, footsteps.soil/wood/stone, lamp.open/ignite, item.pickup, bridge.build/ready, basket.lower, shield.secure, water.recover, party.join, chapter.complete, finale.light. Yoğun tekrar sesi 80 ms başlangıç cooldown; aynı anda gereksiz adım yığılması sınırlandırılır. Ana ses/müzik/efekt ayrı ayarlanır. Sessiz ve kulaklıklı cihaz testleri farklı kanıttır.

## J. Ölçüm, kabul ve sürüm işlemi

Hedef 60 FPS; desteklenen cihaz T02'de erişime göre tanımlanacak. 60 FPS için 16,7 ms kare bütçesi tasarım hesabıdır; gerçekleşmiş performans diye yazılmaz. İlk profilleme raporu CPU/GPU frame time, yoğun sahne, peak bellek, yükleme, texture resident size ve test cihazını kaydeder. Bellek/indirme üst sınırı cihaz ölçümü olmadan rastgele kilitlenmez; T02 risk listesinde sahibi ve karar tarihi vardır.

Test katmanları: saf görev/kayıt durumu; fizik rotası; gerçek renderer/video; browser yükleme/kontrol; gerçek cihaz; yeni oyuncu oynanışı. Bir katmanın geçmesi diğerlerini PASS yapmaz. Otomatik rota aynı sabit iyi yol dışında ters yön, erken etkileşim, yarıda çıkış, uzun bekleme ve tekrar giriş de içerir.

Her kabul satırı: requirement_id → test_id → build_id → input/setup → beklenen sonuç → gerçek sonuç → kanıt yolu → değerlendirici. Sonuç PASS/FAIL/NOT_TESTED/BLOCKED; planlanan test PASS olamaz. Motor logu ile insan görsel incelemesi ayrı sütundur. İlerleme yüzdesi satır sayısıyla değil kapı sonucu ile raporlanır.

İnceleme sürümü: kaynak snapshot → import/build → ilgili testler → bağımsız review → aynı ID ile düzeltme → tekrar test → yayın/teslim. V4 geri dönüş noktası korunur. Schema migration bir kere yürür ve yedek saklar. Yeni sanat/hareket katmanı eski kabul testlerini devre dışı bırakamaz.

## K. Takvim ve işin gerçekten bölünmesi

Önceki takvimde 40 iş paketinin her birine bir gün verilmesi dayanaklı değildi. Özellikle dört karakter ve hareket setinin beş güne sıkıştırılması riskliydi. Güncellenen BACKLOG.csv başlangıç ve bitiş aralığı, temel odak günü, ek risk günü ve bağımlılık içerir. Bunlar insan-saat veya kesintisiz arka plan taahhüdü değildir; aktif çalışma günleri için başlangıç tahminidir.

T01 plan yazıldı diye üretime tamamen hazır kabul edilmeyecek: kaynak kimliği O01, hareket ölçümleri O02 ve cihaz erişimi açık. T02 bittiğinde bölüm ölçüleri; T13 bittiğinde süre ve içerik; T32 bittiğinde karakter kapasitesi yeniden tahmin edilir. Bu üç nokta takvim yeniden hesaplama kapısıdır. Kaynak/kullanıcı onayı beklemesi süre tahminine sıfır gün diye gizlenmez.

İş paketi dört alt teslimle yürür: tasarım girdisi, uygulanmış sahne/modül, hata/istisna kontrolü, kanıtlı kapanış. Her biri ayrı görev numarası taşır. Testi yazmak, testin geçtiği anlamına gelmez. Görsel işi yapılmamışsa ana iş DONE olmaz. Kullanıcı gün sonu raporuna erişebilir, ama asıl test sorumlusu yapılmaz.

Bir kapsam değişikliği kaydı: istek → etkilenen chapter/object/asset/test ID'leri → mevcut işlere etkisi → yeni tahmin → karar. Örneğin ikinci oynanabilir karakter istemek yalnız sprite işi değil; controller, save, UI, kamera ve bütün rota testini etkiler. Hata düzeltmesi kapsam değişikliği diye kullanıcıya geri yüklenmez.

## L. Açık riskler ve karar zamanı

R01 Kitap kaynak uyuşmazlığı: T03, sorumlu Codex kaynak incelemesi; çıktı kimlik/rol tablosu, çözülmezse B03 kimlik işleri BLOCKED. R02 Kontrol hissi: T02/T13, ölçüm + oynanış kaydı; zıplama değişirse tüm P-GAP düzeni yeniden sınanır. R03 Arkadaş kuyruğu: T07, hareketli platform ve ters dönüş rota kanıtı; aşılmazsa parkurdaki birlikte biniş sadeleştirilir, görünür teleport eklenmez.

R04 Karakter üretim süresi: T32, tek karakter tamset üzerinden kapasite ölçümü; tarih uzatılır veya rig seçeneği referansla karşılaştırılır. R05 Mobil kaynak sınırı: T02 erken export denemesi, T36 gerçek cihaz; texture boyutu göz kararı sınırsız büyütülmez. R06 Görev/kayıt bozuluşu: T06 ve her bölüm çıkışı; snapshot migration testleri.

R07 Monolitik koddan ayrıştırma: T04–T08, bir modül bir seferde; eski çalışan sahneyle aynı senaryo. R08 Tekrarlı yürüyüş: T13 ve T17, amaçsız dönüş süresi toplam bölümün %15'ini aşarsa bağlantı düzeni yeniden tasarlanır. R09 Hikâye okuma yükü: T12, kısa sahne ve atla özeti; okuma süresiyle oynanış süresi ayrı ölçülür. R10 Kullanıcı değerlendirmesinin gecikmesi: teknik işler ilerler, kimlik pending kalır; onay uydurulmaz.

## M. Modül sınırları ve ilk tüketicileri

InputRouter — sahibi physical/touch bindings ve release latch; API sample_actions(), clear_held(), set_context(); sinyal context_changed. İlk tüketici PlayerController, T04. Görev verisi veya oyuncu pozisyonu yazmaz.

PlayerController — sahibi velocity/movement_state; API apply_actions(), freeze(reason), spawn_at(anchor); sinyal landed, recovery_requested. MovementProfile dışında kopya hız/yerçekimi sabiti olmaz. İlk tüketici ölçüm parkuru, T04.

CameraRig — sahibi deadzone/lookahead/limits; API set_target(), set_chapter_bounds(), reset_to_spawn(), set_reduced_motion(). Görev callback'i doğrudan kamera koordinatı yazmaz. T05.

QuestState — sahibi kalıcı flag seti; API can_apply(event_id), propose(event_id), commit(snapshot); sinyal state_changed(changed_ids). Nesneler doğrudan dosyaya yazmaz. T06.

SaveService — sahibi şema/migration/atomik yazma/yedek; API load_validated(), persist(snapshot), migrate_v4(), make_replay_snapshot(); sonuç success/error ile çağırana döner. T06. Persist başarısızlığında event acknowledged sayılmaz; görsel durumun retry yolu korunur.

LevelDirector — sahibi chapter_id, spawn_registry, geçiş kilidi ve bölüm kaynak yaşam döngüsü. API request_exit(exit_id), load_chapter(id,checkpoint), restore_snapshot(); sinyal chapter_ready, transition_failed. Çekirdeği T06'da üretilir, T09–T10'da B00→B01 ile doğrulanır. T24 yalnız bölüm seçimi/replay deneyimini tamamlar. Yeni bölüm eklemek için T24 beklenmez.

PartyController — sahibi üyelik sırası, route segments, slot/anchor reservation; API join(id), set_route(), reserve_platform(), enter_assist(id,anchor), regroup(); sinyal party_ready(anchor_group), assistance_finished. T07. PlayerController ile yardım animasyonu aynı frame farklı komut vermez.

MovingPlatform — sahibi path/phase/passenger list; API pause_world(), reset_to_safe_phase(); sinyal docked. T07'de ortak sahne; ilk gerçek tüketici B01 Z13/T11. Sprite animasyonu platformun fizik pozisyonunu sürmez.

ComicPanel/DialogueRunner — sahibi geçici line/reveal/choice-free flow; API open(scene_id), reveal(), next(), request_skip(), close(); sinyal completed(scene_id,event_proposal). QuestState geçerliliği onaylamadan sonuç commit edilmez. T08.

GameFlow — sahibi menu/play/dialogue/pause/recover/transition/complete bağlamı; InputRouter ve dünya saatini birlikte değiştirir. T08. AudioDirector — sahibi bus/ambience/ducking/pause politikası; T29. UI hiçbir oyun state'ini etiket metninden çıkarmaz.

## N. V4 kayıt göçü ve nesne işlemi örneği

V4 met → quest.lanterns.accepted; lit[0..2] → light.A/B/C; joined=true yalnız üç ışıkla tutarlıysa party.badger; completed=true yalnız joined ile chapter.B01.complete adayı. V4'ün kısa patikası tam B01 ile aynı ilerleme değildir: göç ekranında “Patika yenilendi; arkadaşın ve yakılan ışıkların korunuyor” açıklamasıyla eşdeğer güvenli checkpoint seçilir. Yeni nesne şartları eski save'i kilitlememeli; gerekiyorsa V4 tamamlanmış oyuncuyu B01 çıkış checkpoint'ine yerleştiren açık migration kuralı uygulanır.

V4 x/y doğrudan yeni haritaya kopyalanmaz. met=false → CP10 başlangıç; kısmi light → en son doğrulanmış fener CP; joined → CP15; completed → chapter_complete snapshot. Eksik/yanlış tipli field defaults+validation raporuna gider. Orijinal dosya .v4-backup olarak korunur. Ayarlar yoksa varsayılan, kullanıcı tercihleri varsa korunur.

Köprü örneği işlem günlüğü: plank.carried ve rope.carried doğrula → installed snapshot'ı kalıcılaştır → supplied görseli → güvenli anchor'lar → building animasyonu → ready snapshot'ı kalıcılaştır → bridge collision ve görsel ready → katılım sahnesi. Her ok arasına kesinti testi konur. building animasyonu sırasında supplied save yüklenirse malzemeler kayıp değildir. Ready kaydı başarısızsa köprü görseli/pasajı henüz açılmaz; yeniden dene aynı event_id ile yapılır.

## O. Ekran başına geri dönüş ve kayıt etkisi

Ana menü Devam: load_validated → chapter_ready → input release; doğrudan son ham koordinata atlamaz. Yeni oyun: onay açılır, varsayılan Vazgeç; kabulde ayrı yeni snapshot. Bölüm seçimi: tamamlanmış bölüm replay snapshot; ana kayıt değişmez. Replay bitişinde “Ana yolculuğa dön” ayrı düğme.

Pause→Ayarlar→Geri: pause'a döner, oyun kendi kendine başlamaz. Ana menü→Ayarlar→Geri: ana menüye döner. Yardım modalında Esc/Geri yardım ekranını kapatır. Oyun içinde Esc pause açar, pause'da Esc devam eder. Dialogue sırasında Esc atlama onayı açar; doğrudan görev tamamlamaz. Atla kabul edilince sahneye özel kısa özet gösterilir; özetin Devam düğmesiyle geçerli sonuç işlenir.

Kontrol yerleşimi düzenlemesi pause içinde yapılır; test alanı oyun dünyasını yürütmez. Konumu kaydet/varsayılana dön/iptal ayrı. İptal eski konumu geri getirir. Telefon yön değiştirdiğinde yeniden ölçekleme sonrası parmakların bırakılması beklenir. Hata popup'ı arkasındaki oyun veya düğme input almaz.

Tamamlanma panelinin “Alanda dolaş” eylemi final olayını temizlemez. Tekrar exit bölgesine girmek paneli otomatik yeniden açmaz; yeniden bölüm geçişi yalnız açık etkileşimle. Bölümü yeniden başlatma kendi başlangıç snapshot'ını kullanır; tüm macerayı sıfırlamaz.

## P. Bölüm haritası okumak ve yerleşimi doğrulamak

ZONE_SPEC.csv 33 bölge için amaç, base_y, ilk somut platform/nesne yerleşimleri, completion, kurtarma, checkpoint ve camera/art ölçütü içerir. Koordinatlar sanat çizimi değil gri blok yazım girdisidir. Uzun aralıkların her yeri boşluk değildir: base_y ana zemin, GAP açıkça belirtilen boşluk, STEP/MOVE üst yüzey; çevre geometrisi bunlara göre döşenir. Bu sözleşme motor tarafından henüz yüklenmiyor.

B02, önceki uzun doğrusal tasarımdan kompakt bir merkeze çevrildi: merkez Z24 x650–1400/y600, üst kol y390–530, alt kol y710–760, köprü x1400–2500/y600. İlk iki kola erişim x1280 kavşağından; bu yüzden “kısa kol” artık kilometrelerce geri yürüyüş anlamına gelmiyor. Üst rotadan erken çıkışı önlemek için x2520 görünür kapı bridge.ready şartına bağlıdır. Dekor köprü uzak silueti fizik yüzeyi sayılmaz.

B03 bahçe arkadaşı görev kabulünden sonra sabit güvenli servis yolundan Z34'e yürür: (400,600)→(650,700)→(4100,700)→(4230,600). Bu yol çiçek alanının altından ayrı kotta geçer; oyun içi yürüyüş/animasyon kullanır. Oyuncu yetişirse kısa dinleme repliği, kesinti olursa en yakın sabit durak; doğrudan NPC koordinatı atlama yok. Nihai kitaptaki rol bu yürüyüşle çelişirse kaynak doğrulama kapısında tasarım değişir.

B05 ilk panoramada üç görevin hepsi gerçek collision mesafesinde aynı ekrana sığdırılmaz; uzak dekor/işaretler yön verir. Gerçek nesneler Z51–Z53'tedir. Blueprint şemaları navigasyon/topoloji içindir, sanat onayı veya oynanabilir parkur kanıtı değildir.

## Q. Tek olay sözlüğü ve finalin sahibi

EVENT_REGISTRY.json kalıcı olay kimliklerinin tek kaynağıdır. Bu belgedeki joined.badger gibi okunabilir kısaltmalar prose_aliases içinde gerçek party.badger.joined kimliğine eşlenir; kayıtta kısaltma kullanılmaz. zone_specs.json her bölgenin persistent_events listesini taşır. STORY_SCRIPT.json her sahnenin trigger_anchor, requires_all, entry_transient_conditions, replay_condition ve completion_rule alanlarını içerir. Ön koşulu eksik sahne render edilmeden reddedilir; editörden yanlış sahne çağrısı görev atlatamaz.

Final sırası kesindir: üç istasyon ready → ekip sahne anchorlarında → D51 bitişi festival.final_ready → oyuncunun final anahtarına ayrı etkileşimi festival.switch_activated → ışığın görsel açılışı → D52 → final.complete. final.complete yalnız D52 normal bitişi veya Atla özetinin onayından gelen öneriyle QuestState/SaveService tarafından commit edilir. Nesne veya zone kendi başına final.complete yazmaz. Switch sonrası uygulama kapanırsa D52 baştan gösterilir; switch olayı çoğalmaz. Final tamamlandıysa sahne tekrar izleme görev değiştirmez.

Sepet kesin commit noktası: kol onayında basket.reachable kalıcı durumu yazılır; başarılı yazmadan sonra lowering yalnız görsel geçiştir. Normal akışta collect, görsel reachable'a gelene kadar kapalıdır. Reload terminal reachable görselini doğrudan kurar. Böylece yarıda kapanmada sepet yükselmez ve hiç kaydedilmemiş ilerleme uydurulmaz. Bu kural köprüden farklıdır: köprü ready commit'i kurulum görselinin sonunda, güvenli supplied kaydı üzerinde yapılır. Her nesnenin commit zamanı kayıt senaryosunda ayrı sınanır.

## R. Yerleşim denetiminden çıkan somut düzeltmeler

NPC konuşma anchor'ları kökten 60 birim uzakta: Porsuk kökü(430,600), oyuncu(370,600); bahçe arkadaşı(400,600), oyuncu(340,600). NPC aday seçimi kökün 90 birim yatay mesafesine göre yapılır; anchor oyuncunun durduğu güvenli noktadır. Anchor'a koşulsuz ışınlanma yok; maksimum 24 birim hizalama kuralı korunur.

CP22 üst koldaki 160 geniş platformun merkezine, (1490,530) noktasına taşındı. Bütün checkpoint'lerde collider ayağının iki yanında en az 32 tasarım birimi emniyet payı ve 1 s inputsuz stabil kalma testi zorunludur. Hareketli yüzey üzerine checkpoint tanımlanmaz.

B02 erken üstten geçiş: x2490–2570 kaya cephesi y100–780 boyunca fiziksel bariyerdir; yalnız y490–650 arası geçit kapısı vardır. Kapı bridge.ready'de açılır; kayanın geri kalanı kalır. Üst kolun en yüksek basış kotu390 ve başlangıç jump yükselişi163 ile cephe üstü100e ulaşılmaz; yine de motor maksimum jump testiyle doğrulanır. Engelin tamamı resimde okunur; görünmez yüksek duvar yok.

V4 göçü B01'e doğrudan başlayan eski kayıtlar için legacy onboarding bypass işaretini taşır; invitation/tutorial/home.exit uyumluluk flag'leri migration kaynağıyla verilir, “oyuncu yeni giriş bölümünü oynadı” diye raporlanmaz. Bölüm seçimi B00 öğreticisini tekrar açabilir. Bu bayrakları met alanından yanlış çıkarma yerine migration sürümüyle açıkça yaz.
