# Çatpat image üretim kayıtları — 30 Ekim 2026

Yöntem: yerleşik `image_gen`; CLI/API anahtarı kullanılmadı. Kaynak PNGler `assets/source/generated/`, oyuna alınan sürümler `assets/runtime/` içinde. Kaynak klasörü `.gdignore` ile Godot import/export kapsamından ayrıldı. Tam yollar, ölçüler, alfa, SHA256 ve kullanım yerleri `production/ART_MANIFEST_V21.json` içindedir.

## Ortak sanat yönü

Mevcut `assets/polish-v3/forest.webp` görüntüsünün mat guaj dokusu, teal gölgeleri, sıcak yosun/kehribar vurguları kullanıldı. `assets/world/forest.webp` yalnız mevcut ev/sahne konu referansı oldu; onun düz kompozisyonu yeni ortam diye oyuna yapıştırılmadı. Yeni karakter kimliği çizilmedi. Ev, kitabın bir sayfası veya kesin kitabî olay olarak sunulmayan özgün oyun uyarlamasıdır.

## Üretim prompt seti

- **catpat_b05_stage_v001:** tek ayrı runtime sahne; iki doğal dal direği, alçak ahşap döşeme, sade sıcak sarı gölgelik. Yandan/frontal oyun kamerası, sığ üst yüzey, üç karakter için boş merkez. Bayrak, lamba, çiçek, yazı ve çevre olmadan gerçek alfa. Referanslar mevcut orman ve mevcut festival çizimiydi. Sonraki flama üretimi bu sahneyi destekleyici doku referansı olarak kullandı.
- **catpat_b05_bunting_v001:** sarkan doğal ipte yedi el yapımı bez flama; ochre, muted coral, moss green ve dusty teal. İnce bağlar ve guaj kıvrımları; direk/ışık/yazı/arka plan yok. Tek zincir, gerçek alfa. Orman ve yeni sahne referansları kullanıldı.
- **catpat_b05_station_banner_v001:** çatallı kısa ahşap direkte tek altın bez flama ve yosun yeşili dikiş. Baskısız kumaş, sağlam küçük ekran silueti; kişi/sahne/zemin yok, gerçek alfa. Orman ve yeni flama referansları kullanıldı.
- **catpat_b00_home_v001:** oyunun davet sahnesi için özgün ağaç kütüğü evi; eğri meşe kapı, küçük yuvarlak amber pencere, yosun ve eğrelti, boş davet rafı. Tek dekor, collider yok; karakter, yol, sahne, yazı veya kitap sayfası yeniden yapımı yok. Gerçek alfa, bütün siluet içeride. Mevcut orman/ev konusu referansı kullanıldı.
- **catpat_b05_lantern_glow_v001:** tek yumuşak amber oval aydınlık; guaj dokusu, saydam kenarlar ve çok seyrek altın toz. Nesne, ışın çizgisi, ikon, yazı, zemin ve çerçeve yok. Mevcut orman renk referansı. Runtime PNG, kaynak alfasını koruyor; eski başarısız yerel WebP import adayı kullanılmıyor.
- **catpat_shared_ground_shadow_v001:** tek basık mat koyu orman-teal gölge, yumuşak fırça kenarı ve saydamlık; sert çizgi, parlama, benek, nesne, zemin veya yazı yok. Karakter altında yaklaşık60px genişliğinde image gölge olarak kullanım.

## Kabul sınırı

Gerçek alfa ve dosya decode kontrolleri uygulandı; dosyası olmayan prompt asset sayılmadı. Bu kayıt tek başına oyun içi görsel kabul değildir. Motor kareleri, hareket ve dar ekran kullanımları ayrı denetlenir. Kitap asılları ve nihai karakter kimliği onayı bu yeni dekor/effect üretiminden çıkarılmaz.
