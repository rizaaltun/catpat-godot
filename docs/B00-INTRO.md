# B00 — Davet ve Ev Önü

30 Ekim 2026. Mevcut oyun projesine eklenen giriş bölümü; ayrı oyun veya yeniden yazım değildir. Yeni kitap olayı veya kitabın ev çizimi olduğu iddia edilmez. Senaryo D00'ın mevcut davet cümlelerini kullanır.

## Uygulanan yolculuk

Yeni oyuncu / onaylı yeni yolculuk B00'a girer. Davetini alır, en az100 gerçek yerde hareket birimi yürür,40 birim yüksekliğindeki köke kısa basışla zıplar,120 birim açıklığı daha uzun basışla aşar ve karşı kıyıya iner. Sonraki alçak üst dala çıkmak ve festival süsünü almak isteğe bağlıdır; süs olmadan da patikaya ilerlenebilir. Küçük açıklığın altında iki alçak basamaklı güvenli dönüş yolu vardır; can veya ceza yoktur.

Sahne `scenes/home.tscn`; uygulama `scripts/chapters/home_main.gd`. Mevcut `polish_actor.gd`, MovementProfile ve CameraRig kullanılır; karakter yeniden çizilmez. Tüm görünür çevre/arayüz mevcut veya image ile üretilmiş raster dosyalardır; çarpışma şekilleri görünmez teknik geometri olarak kalır.

Kalıcı olay sırası: `invitation.read → tutorial.walk → tutorial.short_jump → tutorial.long_jump → tutorial.jump → home.exit`. Sadece gerçek havalanma/yükselme/zemine iniş gözlemi kısa/uzun denemeyi tamamlar. Tek bekleme veya havada E basma ilerleme üretmez. `b00.ribbon` isteğe bağlı hatıradır, bölüm çıkışının ön koşulu değildir.

Checkpoint'ler: b00.entry, b00.walk, b00.short, b00.long, b00.exit. İlgili tamamlanma olayı olmayan ileri checkpoint reddedilir. Olay/hatıra önce doğrulanıp kalıcılaştırılır; sonra görünüm güncellenir. Yazma hatası aynı adımı yeniden deneme fırsatı verir. B00→B01 hedef kaydı sahne değişiminden önce yazılır; sahne hatasında B00 çıkış kaydı geri yüklenir, geri alma da yazılamazsa güvenli B01 hedef kaydı korunur. Başarılı geçiş ilk Porsuk karşılaşmasını araya ikinci ana menü koymadan açar.

Mola ve odak kaybı oyuncuyu/kamerayı durdurur ve tüm basılı girişleri bırakır. Devam için yeni basış gerekir. “Kontrolleri biliyorum” seçeneği ayrı açıklama/onaydan sonra öğreticiyi geçebilir; kayıtta `onboarding_origin=user-skipped-v1` vardır, yapılmış motor kontrolü gibi raporlanmaz.

## Kayıt uyumluluğu

Mevcut schema10 alanları korunur. `fresh()` mevcut bölüm/QA tüketicilerinin B01 başlangıcını korur; yalnız gerçek yeni oyuncu akışı `fresh_journey()` ile B00 oluşturur. Yeni bölüm/olay/hatıra kimlikleri aynı şeklin içine eklenir; eski B01–B05 kayıtları geçerli kalır.

Üretim menüsünden eski kayıtla Devam seçildiğinde `migrate_onboarding` bölüm, checkpoint, görevler, arkadaşlar, anılar ve tercihleri koruyarak giriş uyumluluk olaylarını ekler. Kaynak `onboarding_origin=legacy-bypass-v1` olarak açıkça yazılır; bu, oyuncunun yeni öğreticiyi oynadığı iddiası değildir. İşlem idempotenttir. `persist_onboarding_migration` ilk göç öncesi geçerli kaydın doğrulanmış pending→rename adımıyla değişmez `.onboarding-v1.original` kopyasını ve mevcut atomik yazma/yedek zincirini korur. Genel decoder ve mevcut4–10 göçleri sessizce değiştirilmedi.

## Sanat eşlemesi

| Kullanım | Runtime kaynak | Durum / sınır |
| --- | --- | --- |
| Ev dışı | assets/runtime/environments/catpat_b00_home_v001.webp | Parent üretici image çıktısı; kaynak PNG assets/source/generated/catpat_b00_home_v001.png. Oyuna özgü uyarlama, kitabın evi iddiası yok. HomeExteriorArt başlangıç kapısında, collision yok. |
| Uzak çevre | assets/chapter-v6/panorama.webp | Mevcut image varlığı; parallax katmanı. |
| Yürünebilir zemin | assets/chapter-v5/platform.webp | Mevcut image bölgeleri, tekbiçimli ölçek; collision üst yüzeyi ayrıca QA edilir. |
| İsteğe bağlı dal | assets/chapter-v6/branch.webp | Mevcut image varlığı, tek yönlü platform. |
| Festival süsü | assets/world/props.webp alt sağ bölge | Mevcut flama/kurdele kompozisyonu; bağımsız yeni sanat üretilmedi. |
| Çıkış yönü | assets/chapter-v20/festival-arrow.webp | Mevcut yön işareti. |
| Karakter | polish_actor.gd tarafından yüklenen mevcut Çatpat kareleri | Kimlik değiştirilmedi; genel kitap onayı açık kalır. |
| Kart/buton/denetimler | assets/polish-v3/panel.webp, button.webp, jump-button.webp | Image raster sanatı; metinler canlı. |

## Kontrol kanıtı

`tests/home_contract.gd`: geçerli yeni kayıt, ön koşullar, tüm eski bölüm kayıtlarının korunması, göçün idempotansı ve yazma hatası, gerçek kısa/uzun sıçrama, kararlı checkpoint'e yeniden açılış, odak/mola, isteğe bağlı dala gerçek sıçrama ve süs toplama, çıkış yazma/sahne hataları, gerçek B00→B01 ilk konuşma ve ilk menüden B00 yönlendirmesi. `--home-capture` ile davet/kayıt hatası/uzun sıçrama/çıkış durumları1280×720 ve666×374 gerçek motor kareleri üretir; dar görünümde hedef sınırları denetlenir. CI bu native render yolunu çalıştırır.

Yerel headless kanıtı fiziksel telefon ergonomisi, görüntü/animasyon onayı veya çocuklarla kullanılabilirlik testi değildir. Yeni ev ve zemin/dal birleşimleri gerçek render kareleri üzerinden ana üretici/bağımsız görsel denetimi bekler; başka bölümün geçmiş görsel kabulü buraya taşınmaz.

## Ek güvenli geçiş davranışı

Öğreticiyi geç seçimi B01 hedefini kalıcılaştırdıktan sonra sahne açılamazsa eski B00 dünyası devam ettirilmez: bellek hedef kayıtla eşlenir, oyun dondurulur ve yalnız güvenli ana menü dönüşü sunulur. Normal bölüm çıkışında sahne geçişi ve geri alma yazısı birlikte başarısız olursa aynı koruma uygulanır. Böylece Escape eski kaynak durumunu daha yeni hedef kaydının üzerine yazamaz. Bu yollar callback seam ile gerçek sahne hatası ve yazma hatası enjekte edilerek test edilir.

B00 süsü B01 ışık izi sayacına katılmaz. Ebeveyn özeti B00 ilerlemesini ayrı gösterir; legacy bypass için “öğretici oynanmadı”, kullanıcının açık geçişi için “oyuncunun seçimiyle geçildi” der. Uyumluluk olaylarını gerçek öğrenme ya da beceri kanıtı saymaz.

Ders ipucu üstte, HUD'ın altında yer alır; açıklığın alt güvenli dönüş basamaklarını veya karakteri örten alt orta panel bırakılmadı.
