# Başlangıç kıyısı yeniden düzenlemesi — 0.15.7-shore-alpha

## Ürün kararı ve uygulama

“Başlangıç kıyısı”, B04 Rüzgârlı Yamaç bölümünün ilk kıyısıdır. Porsuk girişte öne alındı. Fener kapağı geniş başlangıç zemininin üzerinde; alt basamağa iniş ve karaktere geri dönüş yok. Kapağı kapatıp kısa dokunmalı konuşmayı bitirmek ilk geçide mevcut image köprü varlığını açar. İlk taşıyıcı devre dışı, ikinci taşıyıcı halat göreviyle açılmaya devam eder. Görev ve fizik tamamlanması kayıt başarılı olmadan açılmaz.

Çocuk ilk güvenli düz geçitte yürüme ve eylem-sonuç ilişkisini görür; sonra halatı taşır, birlikte düğüm bağlar ve taşıyıcı kullanır. Düşen oku bulma ve festival yolu kapanışı korunur. Bu bir tasarım değerlendirmesidir; çocuklarla öğrenme etkililiği testi değildir.

Diyalog zamanlayıcısı kaldırıldı. Ekrana dokunma veya masaüstü sol tıklama tek satır ilerletir. Klavye erişimi korunur. İptal edilmiş dokunma ve dokunmadan türetilen fare olayı ilerletmez. Odak kaybı, modal ve açık iptal düğmesi korunur. Bölüm geçişleri ve yakındaki görev eylemleri otomatik kalır.

Ekranda tek kısa hedef, kontrol düğmeleri ve duraklatma kalır; teknik durum, rutin kayıt ve uzun kontrol altlığı normal oyunda gizlenir. Kayıt hataları gizlenmez; kayıt ayrıntıları molada erişilebilir. Mevcut sanat kimliği, image panelleri ve köprü varlığı kullanıldı; yeni karakter tasarımı üretilmedi.

Halat fenerden100px ayrıldı ve fener yanmadan gizlendi; bir sonraki nesne kendiliğinden alınmaz. Mola yardımları yeni yakınlık/dokunma düzenine uyarlandı.

## Bağımsız inceleme

Ayrı inceleyici iptal edilmiş dokunma, gizlenen checkpoint yazma hatası, fener/halat örtüşmesi ve eski yardım metni bulgularını bildirdi. Dördü düzeltildi; son kaynak tekrar incelemesinde kapatıldı. Kaynak/gerçek kare incelemesi teknik ve oyun akışı kanıtıdır, çocuklarla kullanılabilirlik çalışması değildir.

## Kayıt uyumu ve güvenlik

Eski kayıtta ilk fener yapılmadan ileriki kıyıya geçilmişse güvenli dönüş köprüsü açılır; görev tamamlandı gibi yazılmaz. Ekip gerçek köprü üzerinde yürür, ilk taşıyıcı rezervasyonlarını tutmaz. Orta/ileri kıyı kayıt ankrajları ve ikinci taşıyıcı düzeni korunur.

## Doğrulama kaydı

- Yapısal kıyı native testi28/28; ilk köprü fiziksel yürüme, eski kayıt dönüşü, ikinci taşıyıcı kilidi ve gerçek kareler.
- B04 tam görev41/41, yaşam döngüsü19/19 ve sanat26/26 önceki yapısal kontrol turunda geçti.
- Son içerik/UI değişikliklerinden sonra diyalog, çizgi roman25/25, deneyim42/42, onarım38/38, kilitlenme12/12, destekUI62/62 ve başlangıç regresyonları başarılı.
- Son varsayılan native diyalog/akış96/96, 16 gerçek native kare (1280×720 ve666×374); iptal dokunma, sentetik fare, odak kaybı, diyalog zamanlayıcısız bekleme, checkpoint yazma hatası/görünür uyarı/başarılı retry ve fener sonrası ayrı halat hedefi başarılı. Ses akışları test çıkışında kapatılıp temizlendi; engine-error kapısı açık tutuldu.
- İlk CI41654218308: oynanış96/96 geçti; hızlı rendererda8 karelik çıkış beklemesi Ogg ses iş parçacığının temizlenmesine yetmedi ve engine-error kapısı yayını durdurdu. Diğer mevcut native testlerle aynı elapsed-time temizleme deseni uygulanarak0.35 saniye beklendi; hata kapısı korunur. Son CI ve yayın sonucu aşağıya kaydedilecek.

Testler Godot 4.4.1 gerçek scene/physics ve native render üstündedir. WebGL canlı cihazda uzun süre oynanış, gerçek mobil donanım ve çocuklarla kullanılabilirlik çalışması yapılmış sayılmaz. Bütün olası donmaların sıfırlandığı iddia edilmez.
