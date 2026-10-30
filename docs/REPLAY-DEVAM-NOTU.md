# Çatpat bölüm seçimi ve güvenli tekrar oynama — 30 Ekim 2026

## Uygulanan kapsam

- `scripts/core/replay_service.gd`: tamamlanmış B00–B05 bölümlerini doğrulanmış ana kayıttan listeler; yeni/bozuk kayıtta bölüm açmaz. B00 için göç veya kullanıcının öğreticiyi atlaması, oynanmış öğretici diye listelenmez.
- `scripts/ui/chapter_select_panel.gd`: mevcut image panel/düğme sanatıyla Türkçe canlı etiketler, yalnız tamamlanmış bölümler, klavye odağı, geri dönüş ve başarısız seçimde yeniden deneme açıklaması.
- `tests/replay_test.gd`: gerçek altı sahnenin giriş kapıları, tamamlanmış hedefin sıfırlanması, ön koşullar/ekip/ayarlar, deterministik snapshot, ana kayıt/yedek byte bütünlüğü, başarısız yazma/geçiş/geri dönüş, bozuk kaynak, doğrulanmış yedekten salt okunur erişim ve arayüz sınırları.

## Ana API ve ev sahibi bağlantısı

- `completed_chapters(primary_path) -> Array`: tamamlanan bölüm kimlikleri.
- `prepare(chapter, primary_path) -> Dictionary`: `ok`, `data`, `path`, `primary_path`, `scene_path`, `chapter`; disk veya metadata değişmez.
- `start(chapter, primary_path, navigation=Callable()) -> Dictionary`: ayrı tekrar slotunu yazar ve geçişi başlatır. İsteğe bağlı geçiş callback'i `scene_path:String` alır, bir Godot Error tamsayısı döndürür; yalnız açık `OK` başarıdır.
- `return_to_primary(navigation=Callable()) -> Dictionary`: ana yolculuk yolunu geri yükler, tekrar metadata'sını temizler, ana menüyü açar. Geçiş başarısızsa önceki metadata geri gelir.

Tekrar slotu `user://catpat-replay-<ana-yol-hash16>.json` olarak ana dosya ve yedeğinden ayrıdır. Ana kayıt yalnız okunur. Hazırlanan bölüm girişinde önceki bölüm gerçekleri ön koşul olarak oluşturulur; hedef/final tamamlanması ve hedef nesne durumları kopyalanmaz. B04 başlangıcı bank0/facing1/fener unseen/halat loose/işaret loose ve dört kişilik ekiple tutarlıdır. Ayarlar derin kopyalanır; schema10 korunur.

Başarılı başlangıç root metadata alanlarını ayarlar: `journey_save_path` tekrar slotu; `replay_primary_path` ana yol; `replay_chapter` hedef. B01 için `journey_autostart` ve `replay_autostart` true; diğer bölümlerde false. Aktif tekrardayken yeni seçim isteği ana kaynak olarak tekrar slotunu değil `replay_primary_path` yolunu kullanır. Başarısız geçişte önceki slot/yedek/geçici dosyalar ve metadata geri konur; ana dosya/yedek hiçbir noktada yazılmaz.

Ana menü girişinin ve oyun içi “Ana yolculuğa dön” düğmesinin bağlanması Experience/ana üretici sorumluluğudur. Bu dosyaları hazırlayan alt ajan mevcut bölüm, ana menü ve `project.godot` dosyalarını değiştirmedi.

## Kontrol sonucu ve sınırlar

İlk Godot4.4.1 headless koşusu88 kontrol/0 hata verdi; B00, B01, B02, B03, B04, B05 sahneleri gerçek giriş kayıtlarını açtı. Aynı anda yeni B05 sanatının importu tamamlanmadığı için kaynak yükleme uyarıları vardı; temiz son doğrulama olarak sunulmaz. Ek yedek/arayüz/boş callback kontrolleriyle ikinci koşu93 kontrol/0 hata verdi. Ancak B05 ışık WebP dosyasının import sidecar kaydı `valid=false` kaldığından7 runtime kaynak yükleme uyarısı sürdü. Bu önceden başarısız olmuş import önbelleği ana üreticiye bildirildi; temiz final koşusu bu kayıt yenilendikten sonra yapılacak. Tüm testlerin geçmesi tek başına sanat varlığının yüklenmesini kanıtlamaz.

Opsiyonel gerçek render: `godot --path . --rendering-method gl_compatibility --script res://tests/replay_test.gd -- --replay-capture`. `VISUAL_CAPTURE:replay-wide` ve `replay-small` kareleri günlükte çıkar. Headless koşu görüntü veya fiziksel telefon ergonomisi kanıtı değildir. Kitap kimliği, gelişim ölçümü veya çocuklarla test iddiası eklenmedi.

## Bağımsız yaşam döngüsü test denetimi

`preproduction/qa/v21/root_transition.gd` içinde tek satırlık lambda tanımından sonraki `g.go_summit(); await ...` ifadeleri yanlışlıkla lambda gövdesinde ve `return` sonrasında kalmıştı. Önceki “scene_failure_rolls_back_source” kontrolü gerçekten çağrılmış bir geçiş hatası olmadan geçebiliyordu. Bu yüzden eski17 kontrol sayısı, bu hata enjeksiyonunun çalıştığına kanıt değildir.

Her iki geçiş hatası callback'i çok satırlı yapıldı; asıl geçiş/await çağrıları lambda dışına alındı. İki yeni sayaç callback'lere gerçekten ulaşıldığını doğrular. Başarılı rollback tam kaynak snapshot'ı ile karşılaştırılır; rollback yazımı da başarısızsa doğrulanmış B04 güvenli girişi ve açık director kilidi denetlenir. `root_main_quest.gd` incelendi; aynı injection deseni bulunmadı.

Yeni headless sonuç: **19 kontrol,0 hata**; günlükte SCRIPT ERROR/ERROR/FAIL yok. Gerçek görüntü yakalama bu headless koşuya dahil değildir. Günlük: çalışma alanı `tooling/lifecycle-lambda-fixed.log`.

## Son tekrar oynama doğrulaması

Ana üretici aynı üretilmiş ışık sanatını Godot'un başarılı import ettiği PNG çalışma çıktısına bağladı. Bu bağımlılık düzeltmesinden sonra `tests/replay_test.gd` yeniden çalıştırıldı: **93 kontrol,0 hata**; günlükte SCRIPT ERROR/Parse Error/ERROR/FAIL yok. Standalone servis testinde CatpatExperience otomatik gözlemi kapatılır; normal host entegrasyonu `tests/experience_test.gd` tarafından ayrıca sınanır. Gerçek altı sahne, doğrulanmış yedekten okuma, başarısız geçiş/yazım, hedef görevin sıfırlanması, ayarlar/ekip ve ana kayıt+yedeğin byte değişmezliği kapsandı. Arayüzde varsayılan tema yerine gerçek image skinleri; gerçek font minsize sonrası düğmelerin çakışmaması ve Türkçe etiketlerin sığması doğrulandı. Headless koşu gerçek görüntü/cihaz onayı değildir.

Son günlük: çalışma alanı `tooling/replay-clean-final.log`. Üç üretim/test dosyası ve bu devam notu alt ajan tarafından hazırlandı; commit yapılmadı.

Yeni CatpatExperience autoload ile yaşam döngüsü yeniden çalıştırıldığında, B03 HUD yeniden kurulurken eski Label referansına `is Label` uygulanması kaynaklı bir GDScript hatası yakalandı.19 assertion geçse de günlük temiz olmadığından bu koşu kabul edilmedi. İlgili servis sahibi geçerlilik korumalarını düzeltti. Ardından aynı gerçek B03→B04→menü→Devam koşusu tekrar çalıştı: **19 kontrol,0 hata**, SCRIPT ERROR/Parse Error/ERROR/FAIL yok (`tooling/lifecycle-guard-final.log`). Bu, yalnız assertion sayısına veya Godot exit0 sonucuna güvenilmemesi gerektiğini gösteren somut denetim kaydıdır.
