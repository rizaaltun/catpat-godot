# Web açılışı, yön ve güvenli alan

30 Ekim 2026. `tools/prepare_web_export.py`, gerçek Godot4.4 export HTML'inden config/hashed çalıştırıcı adını okur; JS/WASM/PCK dosyalarını değiştirmeden image destekli Türkçe kabuk üretir. `index.html` ve hash adlı HTML aynı kabuğu kullanır. Kabuk CSS/JS, font ve sanat da export hash'ine ait `web-assets/<çalıştırıcı-adı>/` altında tutulur; yeni kodun eski kabuk önbelleğiyle karışması önlenir. Önceki `\\n` metin enjeksiyonu kaldırılmıştır; HTML dosyasına gerçek satır sonları yazılır. No-cache metaları korunur.

## Davranış

- `GODOT_CONFIG` ve gerçek thread gereksinimi korunur. Dosyalar ve config'teki boyutlar uyuşmuyorsa hazırlama başarısızdır. Loader yokluğu, eksik WebGL2, başlatma Promise reddi, sıfır olmayan çıkış ve WebGL context kaybı açıklamalı hata gösterir. Gerçek eksik özellikler/teknik tanı korunur; yön kartı bu hatanın üstünü örtemez.
- Coarse-pointer cihaz dik konumdaysa ilk başlatma yataya geçene kadar bekler. Oyunu oynayan cihaz dik konuma dönerse tuşlar bırakılır, canvas focus-out gönderilir ve giriş kapatılır. Yatay dönüş oyunu yeniden başlatmaz ve otomatik devam ettirmez; oyun içindeki mola ekranından devam edilir. Klavyeli masaüstü portre penceresi engellenmez.
- CSS `env(safe-area-inset-*)` ile gerçek güvenli alan ayrılır. Canvas bu alan içinde16:9 olarak boyutlanır; `canvasResizePolicy=0` ve en çok2 cihaz piksel oranı kullanılır. Boyut değişince basılı girişler bırakılır. `viewport-fit=cover` etkindir. Bunlar gerçek cihaz kesik/ergonomi ölçümü yerine geçmez.
- Bilinen indirme toplamında gerçek yüzde, toplam bilinmiyorsa belirsiz yükleme metni gösterilir. Native progress bar veya kodla yeni UI sanatı çizilmez. Arka plan, kart, buton ve karakter mevcut image varlıklarıdır; metin/sayılar canlıdır. Düz sayfa rengi yalnız kaynak yüklenmeden önce okunur teknik zemin sağlar.

## Kaynak ve sınırlar

Kopyalanan sanat/font: `assets/polish-v3/{forest,panel,button}.webp`, `assets/review-v2/catpat-idle-r2.webp`, `assets/fonts/Baloo2.ttf` ve fontun mevcut `Baloo2-OFL.txt` lisansı. Bunlar `build/web/web-assets` altına hazırlanır; kaynak kitap görselleri veya üretim PNG'leri web'e kopyalanmaz.

Godot4.4.1 kaynak kodunda canvas blur, WM window focus-out üretir; window blur basılı girişleri bırakır. Bu projedeki ortak Experience hizmeti WM focus-out olayını bölümün mevcut uygulama odağı/mola davranışına bağlamalıdır. Kabuk oyun mantığına veya kaydına doğrudan yazmaz. Yön dönüşünde otomatik resume yoktur.

Bir bağlantı/başlatma hatası için “Yeniden dene” yalnız sayfayı yeniden yükler; kayıt silme çağrısı yapılmaz. Bu, tarayıcının depolama kalıcılığı veya gerçek WebGL oynanışı onayı değildir.

## Kanıt

- `tests/web_export_test.py`:8 export sözleşme testi; config/hash dosyası korunması, eksik/uyuşmayan kaynakta durma, idempotent hazırlama, gerçek asset kopyası, safe-area/no-cache ve metin güvenliği.
- `tests/web_shell_test.cjs`:23 browserless JS sözleşme kontrolü; coarse/desktop yön ayrımı, başlangıcın bekletilmesi, gerçek hata önceliği, runtime script/parse/failed-resource hatası, gizli sekmede tamamlanan açılış, input/focus bırakma, yüzde ve güvenli alan boyut hesabı. Sahte Engine/DOM ile çalışır; gerçek WebGL testi sayılmaz.
- Önceden doğrulanmış gerçek CI Web artifact'i12972433175 (kod `db65748`) üzerinde helper çalıştırıldı; HTML/config ve gerçek dosya boyutları doğrulandı. JS/WASM/PCK ve worklet SHA256 değerleri hazırlama öncesi/sonrası aynı kaldı.
- Son kaynakların gerçek Godot export'u, tarayıcı ekranı ve fiziksel cihaz doğrulaması ana üreticinin son CI/QA turunda ayrıca kaydedilir.

## Birincil teknik kaynaklar

- [Godot4.4 custom HTML shell](https://docs.godotengine.org/en/4.4/tutorials/platform/web/customizing_html5_shell.html): export config, async startGame ve yükleme bildirimi.
- [Godot4.4 HTML shell API](https://docs.godotengine.org/en/4.4/tutorials/platform/web/html5_shell_classref.html): canvasResizePolicy0, onProgress ve onExit. Belge kendisini kısmen güncellenmemiş olarak işaretlediğinden, kullanılan akış gerçek4.4.1 export HTML'i ve kaynak koduyla da karşılaştırıldı.
- [Godot4.4.1 web display bridge](https://github.com/godotengine/godot/blob/4.4.1-stable/platform/web/js/libs/library_godot_display.js): canvas/window blur ve policy0 davranışı.

## 30 Ekim gerçek web girişi

`2db8f3a` koşusu41062108276 Web export ve Pages deploy adımlarını geçti. Canlı sayfa bu oturumun Chrome tarayıcısında açıldı; mevcut WebGL2 eksikliğini Türkçe başlık, ayrıntı ve yeniden dene düğmesiyle gösterdi. Orman/font/buton kaynakları görünür. Bu ortamda canvas oynanışı açılamadı; tarayıcı oynanış kabulü olarak kaydedilmedi. Panel alfa payı gerçek ekranda başlık ve düğmenin boyalı alan dışında kalmasına yol açtığı için CSS aynı `(91,118,1980,482)` boyalı kaynak bölgesine eşlendi; bu yeni crop sonraki yayında tekrar görülecek.
