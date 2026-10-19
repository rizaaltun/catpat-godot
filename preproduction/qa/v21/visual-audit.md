# V21 bağımsız inceleme — Ana hikâyede Rüzgârlı Yamaç

12 Ekim 2026 · Ayrı denetçi `v21_main_chain_audit`. Ürün kodu değiştirilmedi; test ve raporlar yalnız bu klasörde yazıldı.

## Teknik karar

Schema10 ve gerçek B03→B04→menü→Devam yaşam döngüsü için **PASS**: bağımsız servis111/111 ve sahne26/26 kontrol geçti. Yeni B03 tamam/hata ve B04 pause/menü yerleşimi için sınırlı native UI kapısı da **PASS**. Profesyonel sanat, kimlik ve cihaz onayı değildir.

`independent_service_audit.gd`: schema4–9 göçü; eski bölüm/ayar/toplananların korunması; schema7–9 içine summit/B04 enjeksiyonu reddi; her kıyı/yön ve görev aşaması; eksik/yanlış tür/fazla summit alanı; bölüm/kıyı/ekip uyumu; seen↔B04 tamamlandı ilişkisi; checksum; atomik write/rename hataları, göçün ham eski dosyayı koruması, bütün snapshot yedekten kurtarma, iki bozuk kayıtla kapalı kalma. Son `independent-service-04.log`111/111. İlk üç logdaki roundtrip FAIL'ler testin JSON sayı türü ve doğrudan Dictionary kıyasından kaynaklandı; normalize encode karşılaştırmasıyla test düzeltildi, ürün kodu bu sebeple değişmedi.

`independent_scene_audit.gd`: tamamlanmış B03 fixture'ından gerçek sahne yüklemesi; write/rename hatasında B03 korunması; scene failure sonrası rollback; rollback write failure durumunda geçerli güvenli B04 girişi; retry ile gerçek B04 yükleme; ana kayıt adaptörüne görev yazımı; pause save failure menüyü açmaz; menu scene failure tamamlanan kaydı korur; gerçek menü→Devam doğru kıyı/görev/ekibi geri getirir. Seen idempotent ve B01–B03 bayrakları/ayar/toplananlar korunur; tamamlanmış görevi geriye yazma reddedilir. Eksik kayıt, B03 kaydı, eksik ekip ve bozuk kayıt B04'te oyuncu/NPC yaratmadan bloklanır. İzole `user://independent-v21-*` dosyaları kullanıldı, mevcut `festival_v3.json` bytes kontrolü değişmedi. Son `independent-scene-02.log`26/26. İlk scene logu test yardımcısı `seed` ile global Godot fonksiyonunun isim çakışmasıdır; `write_fixture` olarak düzeltildi.

Bu sahne testleri doğru kullanıcı akışıyla aynı gerçek scene/menu/save yollarını çalıştırır; önkoşul ve final durumları fixture'dır. Doğal B01–B04 parkur yürüyüşü veya cihaz testi olarak sunulamaz. Uygulayıcı doğal rota kanıtları bağımsız137 sayısına eklenmedi.

## Kitap ve sanat kapıları

AGENTS.md, QA_AGENT.md, CURRENT.md, MASTER_PLAN.md, BACKLOG.csv ve V21 sözleşmesi okundu. `catpat-original.png`, `monkey-badger-original.png` ve `book-spread-05.png` yeniden görüldü. Önceki baseline'daki72 PNG/referans + karakter onay kaydı **73/73 SHA256 aynı**. Ana SaveService kasıtlı schema9→10 değişikliği olduğundan değişmez baseline'a dahil edilmedi. `independent-baseline.json` kanıttır.

Çatpat/Porsuk/Maymun/Pıtpıt model onayı **USER_PENDING**. Profesyonel nihai sanat **REVISE**. ART-001–ART-010, V15-ART-01, V16-OVERLAP-01, V18-ANIM-01, V19-ANIM-01 ve V20-ANIM-01 bu entegrasyonla kapanmış sayılmadı. Yeni hareket ailesi veya sanat değişimi yok; tam/yavaş animasyon doğrulaması **NOT_TESTED**. Safari, gerçek iPhone/dokunmatik ve IndexedDB dayanıklılığı **NOT_TESTED**.

V14-SCOPE-01 ana B03→B04 zinciri yönünden bu sürümde karşılandı; gerçek festival bölümü ve final sanat ayrı açık kapsamdır.

## Native görsel kanıt

İlk01–07 ve small-01–07 olmak üzere14 gerçek motor karesi1280×720 ve666×375 ölçülerinde incelendi. B03 tamamlanma, yazma/scene rollback hatası, B04 giriş, pause, ana menü ve Devam ekranları görüldü. Başlık/metin/düğmeler ekrana sığıyor; pause üç eylemi birbirinden ayrılıyor, ana menü Nasıl oynanır düğmesi kesilmiyor. Küçük pencereler fiziksel telefon testi değildir.

**V21-UI-01 — P2, KAPALI:** İlk B03 tamamlanma panelinin başlığı görünen üst çerçeveye yalnız2–3piksel mesafedeydi. Uygulayıcı paneli doğru atlas bölgesiyle yeniden yerleştirdi; başlık/metin ve iki alt düğme panel içinde kaldı. `final-01-garden-next-chapter.png` ve `final-small-01-garden-next-chapter.png` üzerinde kapanış doğrulandı. `final-02-transition-save-error.png` ve `final-small-03-transition-scene-error.png` hata paneli de incelendi: Tekrar dene/Ana menü eylemleri ve uzun geri alma mesajı sığıyor.

Uygulayıcının doğal ana kayıt görev koşusu39/39 ve gerçek lifecycle native17/17 kanıtları bağımsız137 toplamına katılmadı. Video tüm oyun/animasyon ailelerinin onay kaydı olarak değerlendirilmedi. B04 giriş karelerinde mevcut gri alt basamaklar, bahçe arka planı ve oyuncu/halat nesnesi örtüşmesi son sanat kapısında açık tutuldu.

Yayın kabulü bu ana zincir ve native arayüz inceleme sürümü içindir; profesyonel nihai mobil oyun kabulü değildir.
