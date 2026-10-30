# Native kare denetimi — run41062108276

İncelenen sürüm: GitHub Actions [41062108276](https://github.com/rizaaltun/catpat-godot/actions/runs/41062108276), verify job124084157266.41 gerçek `VISUAL_CAPTURE` karesi günlükten çıkarıldı. Mevcut9 WebP dosyası korunarak eksik32 dosya eklendi; dosyalar çalışma alanı `tooling/qa/production` altında. Boyut/hash indeksi `capture-index-run-41062108276.json` olarak aynı yerde tutulur. Görüntüler yeni oyun asseti değildir ve Git'e eklenmedi.

B01(5), B02(4), B04(9), B05(9) olmak üzere27 kare tek tek açılarak incelendi. Ayrıca B03 küçük görev karesi karşılaştırma için açıldı. Bu, native motor karelerine dayalı görsel kontroldür; web canvas etkileşimi, hareket akıcılığı veya fiziksel cihaz ergonomisi deneyi değildir. Bu alt ajan B04 kurtarma görselini daha önce uygulamıştır; o alanın bu incelemesi ayrı bir dış sanat onayı sayılmaz.

## Yeni bulgular ve kanıt

| Kimlik | Kare | Önem / gözlem | İşlem / yeniden kontrol |
| --- | --- | --- | --- |
| NATIVE-021 | `B02-touch-small`, `B02-bridge-ready` | Görev ipucu ayrıntılı kaya/su resmi üzerinde küçük, zeminsiz yazı olarak kalıyor. Küçük karede “Köprü hazır! Maymun'u yanına çağır.” metni zor seçiliyor. | B02'ye mevcut image paneli ve26pt tek satır eklendi. TextRect için motorun gerçek78px minimumu ayrıldı; y584'te bitiş662, panel y568/h110. Görünürlük yalnız dolu görev metni ve play/building durumuna bağlı. Yeni native kare bekleniyor. |
| NATIVE-051 | `task-complete`, `small-touch` | Çatpat, Porsuk görev merkezinde Porsuk'un önüne geliyor; Porsuk gövde/yüzünün çoğu örtülüyor. Bu, büyük kontrolün oyuncuyu kapatmasından farklı bir karakter–karakter çakışması. | Festival kaynak sahibi ana üreticiye bildirildi. Ayrı karakter/etkileşim ankrajıyla iki siluetin okunur kalması önerildi; bu ajan festival kaynağına dokunmadı. Yeni kare bekleniyor. |
| CAPTURE-052 | `stage-world`, `final`, `small-final` | Stage-world karesinde oyuncu yok, sahne ve ekip sağdan kesiliyor. Final karelerinde fixture bayrakları tamamlanmışken arka HUD1/3 kalmış. | `festival_capture.add_final_flags` aktörü sahneye doğrudan koyuyor; camera smoothing sıfırlanıp fizik karelerinde beklenmiyor ve HUD fixture değişikliğinden sonra yenilenmiyor. Bu nedenle önce capture kanıtı eksikliği olarak bildirildi; normal yürüyüşte aynı kamera hatası kanıtlanmış sayılmadı. HUD/camera yerleşimi ve oyuncu+üç arkadaşın görünürlük assertion'ı önerildi. |
| NATIVE-041 | `B04-scaled-hud` | Büyük görev ve kayıt metni eski başlık/durum yazılarıyla üst solda çakışıyor. | Ana üreticinin bu koşu sonrasındaki ExpandedHUD/eski backing gizleme düzeltmesi kapsamında; yeni B04 scaled kareyle yeniden kontrol gerekli. |

## Bilinen, tekrar yeni bulgu sayılmayanlar

Panel PNG alfa boşlukları nedeniyle başlık/eylem sınırlarının dışarıda görünmesi ana üreticinin ortak panel crop düzeltmesi kapsamındadır. Büyük kontrol modunda B00/B01/B05 aktör örtüşmesi de mevcut düzeltme kapsamındadır. Bunlar bu tabloda yeni sorun sayılarak çoğaltılmadı. Sonraki koşu bu düzeltmelerin gerçekten kapandığını göstermelidir.

## B02 düzeltmesinin kontrolü

`river_world.gd` içinde görev paneli ve canlı26pt metin; mevcut uzun görev/kurulum/davet yönergelerinin gerçek font genişliği testi; native küçük karede panel görünürlüğü/metin dikdörtgenini içermesi kontrolü eklendi. İlk42px metin alanı denemesi motorun78px gerçek Label minimumu nedeniyle enclosure kontrolünde reddedildi; alan yeterli yüksekliğe taşındı.

Düzeltilmiş mevcut B02 tam doğal rota: **37 kontrol,0 hata**, `V10 RIVER SUITE PASSED`. Günlükte SCRIPT ERROR/ERROR/FAIL yok (`tooling/river-hint-verified.log`). Bu headless sonuç yeni gerçek piksel kontrastını onaylamaz; sonraki native `B02-touch-small` karesiyle kapanır.

## Diğer incelenen akışlar

- B01 üst fener/çizgi roman/tamamlanma, B02 konuşma/köprü/tamamlanma metinleri geniş karelerde okunuyor; ilgili ana eylemler görünür. Bilinen panel-crop ve büyük kontrol bulguları dışındaki yeni bir temel çakışma saptanmadı.
- B04 normal giriş, duraklatma, kayıttan devam, Maymun diyaloğu, halat hazır ve ortak rota sonu incelendi. Image kurtarma dalları mevcut; gri blok sanatı görünmüyor. Kontroller, yardım eylemi ve alt yönerge normal boyda ayrışıyor. Büyük HUD ayrı bulgudur.
- B05 giriş, katkı, dokunmatik, yardım, pause ve final kareleri açıldı. Metin ve eylemler görülüyor; Porsuk çakışması ile final dünya kanıtı eksikleri yukarıda ayrıldı. Sabit karelerden animasyon kalitesi veya oyunun eğlence düzeyi onaylanmadı.

Kitap PDF/PSD asılları ve kaynak kimlik onayları bu görüntü denetiminde yoktur. Karakter kitap kimliği, çocuklarla kullanılabilirlik, pedagojik etkililik ve fiziksel cihaz kabulü açık kalır.

## Ana üretici düzeltmeleri — yeni native kanıt bekleniyor

Bütün ortak paneller gerçek boyalı bölgeye kırpıldı. ExpandedHUD eski panel/anonim başlıklarını gizleyip normal ayarda geri getiriyor; ilk frame sıfır genişlik font yerleşimi ve B00 üst ipucunun yanlış footer rezervi düzeltildi. B00 yeni83/83, B05 görünürlük/gerçek giriş+üst sıçrama55/55, B05 tam fizik111/111 yerel temiz geçti. B05 yardımcıları etkileşim merkezinden115px sola, mevcut platform üstüne taşındı;35/35 sanat/final kontrolü geçti. Sahne dokunmatik eyleminin proximity değişimini izlememe hatası da gerçek testle bulundu ve düzeltildi. Yeni final çekimi HUD yeniliyor, kamerayı yerleştiriyor ve oyuncu/üç yardımcı görünürlüğünü ayrıca şart koşuyor. Bu satırlar eski kusurlu kareleri geçti diye etiketlemez; sonraki CI kareleri her bulguyu yeniden kapatmalıdır.
