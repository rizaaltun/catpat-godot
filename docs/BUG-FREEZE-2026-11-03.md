# Donma ve ilerleme kilidi denetimi — 3 Kasım 2026

İncelenen canlı temel: bf1fa568 / 0.15.3; son yayımlanmamış aday: f37d450c / 0.15.4. Kullanıcı oyunda sık donma/kilitlenme bildirdi. Yeni aday 0.15.5-stability-alpha. Bu kayıt, bütün cihazlarda hiçbir donma kalmadığı iddiası değildir.

| Kimlik | Etki / yeniden üretim | Düzeltme | Kanıt |
| --- | --- | --- | --- |
| FREEZE-01 | B02/B03'te oyuncu çıkışta yerde olsa bile geride takılan bir arkadaş, bütün ekibin dar mesafe/zemin koşulunu engelleyerek çıkış konuşmasını kapatıyor. | Katılma önkoşulları ve çıkış konuşması korunur; çıkış eylemi oyuncunun güvenli zeminde olmasına bağlıdır. Görsel takip uzaklığı ilerleme kilidi değildir. | softlock_test.gd arkadaşları bilerek geride dondurur; konuşma, tamamlanma ve gerçek kayıt doğrulanır. |
| FREEZE-02 | B03 katılma konuşması sonrası oyuncu, arkadaşların kesin konumlara gelmesini sınırsız beklerken frozen=true kalır. | Arkadaşlar yaklaşırken oyuncu normal play durumunda kalır. | Aynı test toplanma başlangıcında yürümeyi ve dondurulmuş arkadaşlarla çıkışı sınar. Eski davranışta toplam12 kontrolde8 hata; düzeltilmiş davranışta12/12. |
| FREEZE-03 | Mobil tarayıcı çubuğu/viewport yüksekliğinin1px değişimi bile canvas.blur ile mola tetikliyor. Her küçük değişim oyunu tekrar durduruyor. | Küçük CSS boyut değişimleri ve yalnız DPR değişimi buffer'ı yenilerken mola üretmez. Büyük CSS yerleşim değişimi, yön değiştirme ve görünürlük kaybı güvenli molayı korur. | Gerçek shell.js browserless testinde844×390→844×389→844×388 öncesi blur0→1→2. Yeni jitter testi düzeltme öncesi FAIL; son shell26/26. Gerçek WebGL cihaz testi değildir. |
| FREEZE-04 | Canlı sürümde teslim/sepet indirme yazımı reddedilince hata paneli HUD'ı kaldırır; tekrar deneme eski hint'e yazabilir. Web kabuğu SCRIPT ERROR'u hata paneline yükseltir. | Önceki yayımlanmamış adayın HUD yeniden kurma düzeltmesi yeni pakette korunur; hata paneli gizlenmez. | repair_invitation_test.gd38/38; teslim/indirme/köprü, byte korunumu, tekrar deneme ve konuşma tekrarına ilişkin kontroller. |
| QA-01 | Actions41448206244, B02 fizik rotasında sabit180frame sonunda arkadaşları bekleyen testte başarısız oldu; deploy atlandı. | Fiziksel takip testi gerçek hazır koşulunu en çok720frame bekler; başarısız olursa yine FAIL. Oyuncunun çıkış eylemi bu beklemeden bağımsızdır. | Yeni B02 gerçek kayıt açık fizik rotası PASS. Fiziksel yol bulma sorunları otomatik düzelmiş sayılmaz. |

## Kontrol kapsamı

- softlock_test.gd:12/12; gerçek kayıt ve kasıtlı geride dondurulmuş arkadaşlar.
- repair_invitation_test.gd:38/38; kayıt hata yolları ve eski/yeni onarım noktaları.
- web_shell_test.cjs:26/26; gerçek hazırlanan HTML/JS üstünde sözleşme. WebGL oynanışı değildir.
- web_export_test.py:8/8; kaynak bütünlüğü ve HTML hazırlığı.
- Son B02 tam fizik rotası PASS. Ortak yardım/mola UI62/62 geçti. B03 yeniden fizik kontrolünün sonucu devam notuna yazılacak.
- Bağımsız kaynak denetimi: web jitter gerçek harness ile doğrulandı; yeni çıkış/toplanma değişikliklerinde engelleyici kusur bulunmadı. Normal modal yaşam döngüsünde ayrıca bir kalıcı kilit saptanmadı; bu bütün kullanıcı yollarını kapsayan cihaz testi değildir.

Sunucuda B00–B05 geçişleri, klavye/dokunmatik sözleşmeleri, tam fizik rotaları, gerçek render kareleri, export ve deploy başarılı olmadan yeni aday canlı kabul edilmez. Fiziksel telefon/tablet ve kullanıcının tarayıcısındaki uzun oynanış/perf/bellek ölçümü hâlâ ayrı kabul kapılarıdır. Yeni hata bilgisi gelirse aynı rapora senaryo ve yeniden kontrol sonucu eklenir.
