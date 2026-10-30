# Çatpat — devam eden tam ürün üretimi

Ana standart Epsilon v2.1; mevcut Godot4.4.1 projesi ve `work/t22-source-migration` korunuyor. Kullanıcı, kısa düzeltme turlarında işi bırakmadan kesinleşmiş kapsamın tamamlanmasını istedi. Yeni repo/HTML oyun kurulmadı.

## Uygulamaya alınan kapsam

- B00 Davet ve Ev Önü: gerçek hareketle yürüyüş/kısa/uzun zıplama öğretimi, güvenli alt dönüş, isteğe bağlı süs, kayıt/geri yükleme, atla/başarısız geçiş koruması. Eski yolculuklar öğreticiyi oynamış sayılmıyor; göç kaynağı açıkça ayrılıyor.
- B05: ortak animasyonlu hareket/fizik, kısa/uzun basış eşliği, buffer/coyote ve hızlı dokunma; image sahne/flama/görev işareti/ışıklar; katkıya bağlı görünür dünya değişimi; görev yardımı ve salt okunur final tekrarı. Bozuk kayıt ekranından menüye dönüş kaynak veriyi değiştirmiyor.
- Tamamlanmış bölüm seçimi: B00–B05 için ayrı replay slotu, giriş ön koşulları/ekip/ayarlar; ana kayıt ve yedeği değişmiyor. Menüye dönünce asıl yolculuk geri geliyor.
- Ayarlar: müzik/efekt, metin hızı/tam metin/boyutu, azaltılmış hareket, büyük düğmeler ve sol el düzeni. Image panelleri, diyalog okuyucusu ve büyüyen HUD kartlarıyla uygulanıyor; yalnız saklanan etkisiz ayar değil.
- Ses:6 ortam döngüsü,3 müzik teması+final,24 efekt; özgün prosedürel besteleme/sentez. Gesture-gated web başlangıcı, pause/background, konuşmada kısılma ve üst üste tetikleme sınırı. Kaynak/provenans `docs/AUDIO_PRODUCTION.md` ve manifestte.
- Web kabuğu: hash'li paket korunuyor; image yükleme/hata/yön kartı, güvenli alan ve portre davranışı, gerçek motor hata görünümü. Focus-out köprüsü mevcut bölümün duraklatma/girdi temizleme akışını kullanıyor; otomatik devam yok.

## Gerçek kanıt ve sıradaki kapı

Yerel hedefli testler ve bağımsız kaynak incelemeleri çalıştırıldı. Yeni native geniş/dar kareler, bütün bölüm regresyonları ve web export tek CI adayı üzerinde yeniden doğrulanacak. Headless başarı görsel/cihaz kabulü değildir. Yeni kayıt/ayar/replay gözlem verisi veya gelişim iddiası eklemiyor.

Godot'un0 çıkışına rağmen SCRIPT ERROR yazabildiği doğrulandı; eski yaşam döngüsü testindeki tek satır lambda hata enjeksiyonu düzeltildi ve callback erişimi ayrıca sınandı. `tools/run_godot_check.py` artık motor hata satırlarını da kapı yapıyor.

## Bitmiş sayılmayan alanlar

Kitap asıllarıyla nihai karakter karşılaştırması/onayı, cihazda görsel/hareket/ses ve performans ölçümü, çocuk kullanılabilirliği, Mac/Xcode/iOS imzalama/kurulum kapıları gerçekten yapılmadan geçilmiş sayılmaz. Mevcut UI image ailesinin bütün eski kaynak dosyaları bu checkout'ta yok; yeni kaynaklar manifestle korunuyor. Tasarım süreleri ölçülmüş çocuk oynama süreleri gibi sunulmuyor.

Bu belge bir ara aşamayı nihai oyun diye etiketlemez; somut açık işler kapatılarak üretim sürer. Güncel doğrulama sonuçları `docs/DEVAM-NOTU.md`ye işlenir.
