# Çatpat modülü ve yerel ev sahibi bağlamı

Bu belge mevcut Godot uygulamasının dar bağlantılarını tanımlar; çalışan bir çatı uygulama, şirket kataloğu, hesap veya bulut hizmeti iddiası değildir. Yeni genel oyun motoru oluşturulmaz.

## Sahiplik

| Sorumluluk | Mevcut sahip / API |
| --- | --- |
| Yerel profil seçimi, otomatik Yolcu etiketi ve kayıt yolları | `CatpatProfiles`: `active_profile`, `profile_by_id`, `profile_for_path`, `create_profile`, `activate_profile`, `delete_profile` |
| Doğrulanmış bölüm/görev snapshot'ı | `SaveService`: `valid`, `load_progress`, `save`; bölüm kodu görev kurallarını yönetir |
| Geleceğe dönük gözlem günlüğü | `CatpatObservations`: `observe_snapshot`, `record_help`, `report_for`, `forget_profile`; eski bayraklardan gözlem üretilmez |
| Ses ve görünüm tercihleri | `CatpatAudio`, `CatpatExperience`, `Preferences`; sahneye uygulama ve yaşam döngüsü |
| Ebeveyn onayı, güvenli profil değiştirme ve sahneye dönüş | Ebeveyn arayüzü/oyun akışı; profil hizmeti sahne değiştirmez |

## Yerel bağlam sınırı

Profil satırı `profile_id`, `label`, `journey_path`, `journal_path`, `created_at` taşır. Kimlik rastgele opaque değerdir; ad/iletişim bilgisi alınmaz. `journey_save_path`, `journal_save_path` ve `active_profile_id` tree metadata alanları mevcut yerel bağlantıdır. Açık `journey_save_path` verilmişse profil autoload'u bu bağlamı başlangıçta değiştirmez. Profil değiştirme yalnız güvenli menü/ebeveyn akışından açık API çağrısıyla yapılır. `profile_for_path` ve `profile_by_id` salt okunur bağlam sorgularıdır; index yüklenmemişse `{}` döner, disk okuma veya profil oluşturma başlatmaz. `ensure_loaded` yeniden girişte `initializing` döndürerek ilk journey yazısının gözlem hook'undan tekrar profil başlatmasını engeller.

Autoload kendi indexini açamazsa `profile_context_error` metadata alanını ayarlar ve journey yolu atamaz; oyun akışı bu durumda başlangıcı engeller. Geçerli yedekten kendi bağlamını başarıyla kurunca eski hata temizlenir. Açık yabancı host bağlamının yol/hata metası değiştirilmez.

Var olan `user://festival_v3.json` ilk profile yerinde eşlenir; kopyalanmaz/sıfırlanmaz. Yeni profiller gerçek B00 kaydıyla başlar. Tamamlanmış bölümlerin replay dosyaları ana profil yolundan ayrı tutulur; gözlem hizmeti kayıtlı ana yol olmayan replay yollarından gözlem üretmez.

## Aktarım ve silme

`export_bundle(id)` sonucu `{ok,bundle}`; `export_json(id)` ayrıca `text` verir. `import_bundle`/`import_json` doğrulanmış yolculuk ve journal şemasını kabul eder, yeni opaque profile kimliği/otomatik etiket üretir; dışarıdan dosya yolu alınmaz. Journal kök profile bağlantısı değiştirilir, mevcut olay/oturum/deneme kimlikleri ve tarihsel olgular korunur. `import_bundle(bundle, activate=false)` ebeveyn arayüzünde kullanılır: aktarım yeni yolcuyu ekler, etkin yolcu ve ana menünün kayıt yolu değişmez. Varsayılan `activate=true` doğrudan servis çağrılarının önceki davranışını korur.

Silmede index ve doğrulanmış yedeği önce kalıcılaşır; sahne arayüzü onayı hizmet dışında verir. Geri alınmış başarısız silme gözlem cache'ine dokunmaz. Başarılı kaldırma, fiziksel dosya temizliği bekliyor olsa da `forget_profile(id)` bildirir. Temizlik opaque kimlikten türetilen checksum'lı tombstone ile izlenir; `retry_cleanup()` ve sonraki başlangıç yeniden dener. `cleanup_pending` bütün yerel dosyaların silindiği anlamına gelmez.

## Gelecekteki ev sahibi bağlantısı

Çatı ev sahibi eklenirse başlatma bağlamı (oyun/içerik sürümü, opaque profil, kayıt sağlayıcı, tercihler), pause/resume, kaydet/geri yükle, gözlem bildirimi, hata ve çıkış/temizleme işlemleri sürümlü küçük bir adapter sözleşmesine taşınabilir. Mevcut oyun kuralları hesap/ödeme API'lerine bağlanmaz. Canonical şirket skill ID'leri ve kitap künyesi doğrulanana kadar proje içi `catpat.proposed.*` eşlemeleri yalnız tasarım amacı olarak kalır; gelişim ölçümü veya eşdeğer oyun puanı oluşturmaz.
