# Resimli yolculuk haritası — 0.16.0

`JOURNEY-MAP-NEXT.md` üretim sırasının ilk üç aşaması: tek dünya görseli, kanonik ilerleme modeli ve ana menü/mola bağlantısı. Bölüm içi ziyaret geçmişi, hızlı geçiş ve bölüm sonlarını değiştirme bu sürüme dahil değildir. Çalışan otomatik bölüm sınırları korunur.

## Deneyim

Altı bölge aynı boyalı orman dünyasında gösterilir. Mevcut bölgenin noktası, tamamlanmış bölgelerin onayı ve kilitli bölgelerin önizlemesi canlı metinle çizilir. Başlıklar ve açıklamalar görsele gömülmez. Büyük ekranda bütün dünya görünür; dar ekranda dünya büyür ve kaydırılır. Sağdaki seçili bölge alanı sabit kalır. Harita daima aynı sırayı kullanır; karakter kimlikleri değiştirilmedi.

Ana menü veya mola → Yol haritası. Mevcut bölgede “Kaldığın yerden”; tamamlanan bölgede “Yeniden oyna”; kilitli bölgede yalnız açıklama. Tamamlanmış mevcut bölgede iki eylem ayrı tutulur. Mola haritasından mevcut bölgeye dönüş o bölümün kendi devam düğmesini kullanır; kalan dünya, görev ve kayıt yeniden kurulmaz. Haritayı kapatmak açıldığı mola/menü durumuna döner.

## Kayıt sözleşmesi

Model yalnız Save/Replay hizmetlerini okur. Mevcut kaydı devam ettirmek checkpoint değiştirmez ve dosya yazmaz. Gerçek bölüm/checkpoint son anda yeniden okunur. Geçiş reddedilirse bütün replay/yolculuk metadata bağlamı geri yüklenir. Replay mevcut izole slot hizmetini kullanır. Profil yolları birbirinden bağımsızdır. Bozuk kaydı veya yedeği harita sessizce onarmaz; doğrulanmış yedeği okuyabilir. Eski/atlanmış öğretici, oynanmış gibi işaretlenmez.

Açık haritadaki bir bölgenin durumu değişmişse önce harita yenilenir; eskiden “devam” olan bir düğme aynı basışla “yeniden oyna” başlatmaz. Kilitli alan tıklamak kayıt/keşif/ödül/gözlem yaratmaz. Haritaya ikinci ilerleme sayacı eklenmedi.

## Dokunma ve erişim

Ham dokunma bırakıldığında seçilir. İptal edilmiş dokunma, ikinci parmak ve sürükleme bölge seçmez. Sürükleme yalnız haritayı kaydırır. Dokunmadan türetilen fare olayı tekrar çalıştırılmaz. Odak kaybı girdiyi engeller. Klavye okları bölgeleri seçer; Tab/Enter eylemlere ve geri düğmesine erişir. Dokunma hedefleri en az96×88 mantıksal pikseldir. Büyük yazı1.3 ve iki ekran boyutu denetlenir.

## Yerel kabul

Godot4.4.1 gerçek native renderer:105 kontrol/0 hata; geniş1280×720 ve dar666×374 kareler açılıp incelendi. Metin taşması ve B04/B05 mola dönüşünün ayrı yöntemleri bu turda düzeltildi. Kaynak değişikliği sonrası son test sonucu devam notunda tutulur. Mevcut experience42/42 ve replay93/93 geçti.

Bu kanıt fiziksel telefon/tablet ergonomisi, uzun WebGL oynanışı veya çocuklarla kullanılabilirlik araştırması değildir. Hızlı geçiş için gerçek zeminde durak ziyaret kaydı ve hata/geri alma matrisi hâlâ sıradadır; ziyaret edilmiş gibi geçmiş üretilmez.
