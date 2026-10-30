> **30 Ekim 2026 güncel kaynak:** `docs/DEVAM-NOTU.md` ve `docs/PRODUCTION-2026-10-30.md`. Aşağıdaki kayıtlar üretim geçmişidir; eski "yapılmadı/yayın yok" ifadeleri yeni sonuçları geçersiz kılmaz.

# V8 — 7 Ekim 2026

Son kıyıda güvenli hareketli dal, Porsuk binme/bekleme/iniş/yer açma, üst keşif ışığı ve PartyController eklendi. V7 kayıt sistemi korundu. Ayrıntı production/CURRENT.md ve LEVEL_V8.md; kanıt preproduction/qa/v8. Yeni bölüm ve nihai karakter onayı henüz yok.

# V7 — 7 Ekim 2026

Görev/kayıt modülleri, sabit checkpoint, yedek kurtarma, eski şema göçü, hata/yeniden deneme akışı ve yolculuk defteri eklendi. Gerçek yeni bölüm geçişi henüz yok. Kanıt: preproduction/qa/v7. Devam: production/CURRENT.md.

# Devam noktası — 6 Ekim 2026, V6 parkur düzeltmesi

Kullanıcının V5 itirazları: zeminler iç içe, ikincil menü düğmesi kesik, arka plan birleştirme izi, yalnız yürünen düz rota. V5 teknik PASS bu itirazları kapatmıyor. V6 için önce LEVEL_V6.md yerleşimi yazıldı, sonra aynı Godot projesinde uygulandı.

V6:9 ayrı kıyı ve8 gerçek boşluk; tüm boşluklar90birim, iki yönde yükselme ençok60. Sürekli alt taban ve eski üst üste bankalar kaldırıldı. Her kıyının görünür toprağı tek kaynak bölgesidir; yatay doku tekrarı yok. Tek3:1 panorama kamerayla0.15 hızda kayar, yinelenmez. Nasıl oynanır düğmesinde bütün resim kullanılır. Üst dalda isteğe bağlı keşif, toplam5 ışık izi vardır. Işıklar zorunlu3fener görevinden ayrıdır. Düşüş son güvenli kıyıya döndürür; görev kaybolmaz.

Takipçi boşluğu önden algılar, sıçramanın yatay yönünü inişe kadar korur, geçilmiş hava noktalarını kovalamaz. Ana rota zemini esas alınır; oyuncunun her hava pozunu birebir kopyalama iddiası yok. Konuşmaya katılma yerde gerçekleşir.

33 son motor kontrolü geçti; oyuncu ve arkadaş için başarılı ileri/geri/çıkış rotasında kurtarma0/0. Bilinçli yalnız yürüme denemesinde düşüş ve checkpoint ayrıca sınandı. Üst dal, doğal E katılımı, kayıt diske yazma/okuma, eski kayıttaki boşluk konumunun güvenli taşınması, iki parmak, bırakma ve odak kaybı dahil. Önceki başarısız koşular qa/v6 içinde saklanır. Son test sonucu06-release-gate.log; aynı kayıtlardan tüm rastgele yollar veya cihazlar için onay çıkarma.

Kalan programa devam: T04 MovementProfile ve InputRouter çıkarıldı; T05 CameraRig ve tek geometri kaynağı çıkarıldı. Bunlar bütün G1 veya T04/T05 kabulü değildir. Kalanlar: tekrar edilen UI/device senaryoları, tam kayıt/LevelDirector T06, diğerbölümler. T03 kaynak/rol kimliği hâlâ açık; nihai karakter üretimi genel oyun zincirinden sonra. Sonraki çalışma T06 görev/kayıt modülleri ve bölüm geçişidir; önce V6 kullanıcının görsel geri bildirimi varsa uygula.

Gerçek Safari/iPhone ve browser kullanımı bu ortamda sınanmadı; native motor ve paket smoke ayrı kanıttır. Kitap kimliği, son karakter animasyonları, tam5400birimB01 ve diğerbölümler tamamlanmış sayılmaz.74aktifgün planı koşullu tahmin; arka planda otomatik çalışma yok.

---
Önceki kayıtlar

# Devam noktası — 6 Ekim 2026, V5 ilk bölüm önizlemesi

Kullanıcının son yönlendirmesi teknik test parkuru yerine onaylanan görsel yönün oynanabilir ilk bölüme uygulanmasıdır. Aynı Godot projesinde ve aynı tarayıcı önizlemesinde V5 hazırlanmıştır. Yeni ayrı HTML oyun yapılmadı.

V5: imagegen menü/orman/yosunlu basamak varlıkları, Fredoka OFL tipografi, yuvarlak kontroller, iki güvenli basamak (70 ve50 yükselme,80 boşluk), üçüncü fener üst patikada, ışıkla çevre aydınlanması, sağ/sol balonlu çizgi roman, fizik saatinde kamera ve yumuşak yatay önden bakış. Üç fener → Porsuk'a dönüş → katılım → birlikte çıkış döngüsü korundu.

15 gerçek motor girdili rota kontrolü geçti; dışa aktarılan PCK üzerinde başlangıç/hareket smoke testi geçti. Bağımsız QA üç somut görsel bulguyu kapattı. preproduction/qa/v5/QA.md kapsamı ve kanıtı taşır. Tarayıcı paketi hazır; gerçek browser/Safari/iPhone bu ortamda sınanmadı. Sites statik çıktısının uyumlu dahili geliştirme sunucusu bulunmadığından cloud-browser testi yapılmadı.

V5 mevcut kısa ilk bölüm dilimidir; 5400birimlik tam B01 veya bütün33bölge tamamlanmış sayılmaz. Kitap karakter kimliği ve nihai animasyon hâlâ pending; karakterler bu tur değiştirilmedi. T02'nin61kontrolü tarihsel ayrı ölçüm kanıtıdır; V5'in15kontrolüyle karıştırma.

Sonraki iş: T03 kitap rol/referans doğrulaması açık kalacak şekilde T04/T05 modüler girdi/kamera ve tam B01 bölüm genişlemesi. T03 kaynak belgeye erişim varsa kimlikleri doğrula, nihai karakter üretimini genel oyun zincirinden sonraya bırak. Bölüm haritası ve sonraki bölümler henüz üretilmedi. 74aktifgün takvimi koşullu tahmin; bu tur T04/T05'in tümünü kapatmaz.

---
Önceki kayıtlar:

# 6 Ekim 2026 — T02 ölçüm teslimi

Gerçek kontrolcü ile oynanabilir teknik parkur ve 61 otomatik kontrol tamamlandı. Bağımsız QA ölçüm bulgularını kapattı. Beş bölüm taslağının aralıkları düzeltildi. Canlı oyun değişmedi; telefon/Safari ve bütün bölüm testleri açık. Güncel devam noktası: production/CURRENT.md. Aşağıdaki önceki kayıt tarihçedir.

# Güncel durum — 6 Ekim 2026

Canlı oyun V4; bu tur runtime değişmedi. Kullanıcı v1 üretim planını yetersiz buldu.

Güncel tasarım 1.1: production/MASTER_PLAN.md ve IMPLEMENTATION_SPEC.md. Davranış sözleşmeleri, fiziksel yerleşimler, sahne metinleri, kanonik olaylar, planlanan kabul senaryoları ve süreli iş takvimi mevcut. Devam noktası production/CURRENT.md.

Bağımsız plan denetimi yalnız tutarlılık incelemesidir; oyunun uygulanmış veya cihazda çalışmış olduğu onayı değildir. Yeni testler NOT_RUN_DESIGN olarak kayıtlıdır.

Sonraki uygulama T02 hareket/kamera ölçüm parkuru. T03 kitap kaynak ve rol eşleşmesi açık. Nihai karakter üretimi genel oyun zincirinden sonra. Takvim 74 aktif günlük başlangıç tahmini; T02/T13/T32 ölçümlerinde yeniden hesaplanır.
