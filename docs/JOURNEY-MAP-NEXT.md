# Sonraki üretim — Bölüm haritası ve hızlı geçiş

Bu belge uygulama kararı ve kabul ölçütüdür; harita sanatı, çalışan ekran veya hızlı geçiş üretildi demek değildir. Rıza'nın kutu biçimli bölüm geçişlerini kaldırma kararı esas alınır.

## Ekran ve davranış

Image ile üretilecek tek yolculuk dünyasında altı bölge okunur: Ev Önü, Fenerli Patika, Dostluk Deresi, Papatya Bahçesi, Rüzgârlı Yamaç ve Festival. Bölge adları, oyuncunun konumu ve ilerleme yazıları görsele gömülmez; canlı metin olarak yerleştirilir. Düğümler, seçili/aktif/tamamlanmış/henüz açılmamış durumlar aynı image ailesindendir. Küçük ekranda altı küçük hedefi üst üste sıkıştırmak yerine kaydırılabilir harita ve seçili bölge ayrıntısı kullanılır.

| Haritadaki durum | Eylem | Kayıt sözleşmesi |
| --- | --- | --- |
| Mevcut bölüm | Kaldığın yerden devam | Aktif profilin gerçek chapter/checkpoint kaydı açılır; sıfırlanmaz |
| Tamamlanmış bölüm | Yeniden oyna | Mevcut `Replay.start` ile ayrı slot; ana yolculuk ve yedeği değişmez |
| Henüz açılmamış bölüm | Kısa dünya önizlemesi | Bölüm atlatılmaz, sahte tamamlanma veya gözlem üretilmez |
| Etkin bölümde keşfedilmiş güvenli durak | Buraya hızlı geç | Yalnız gerçekten açılan yerel durak; işlem atomik, başarısızlıkta kayıt/bağlam korunur |

Bölüm sonunda mevcut büyük tamamlama kutuları aynı kutuyu yeniden süsleyerek korunmaz. Kısa dünya tepkisi ve haritada bir sonraki bölge vurgusu birlikte tasarlanır. Bir sonraki bölgeye tek anlaşılır eylemle gidilir; durmak veya dönmek isteyen oyuncunun kaydı korunur. Yeni harita gelmeden mevcut çalışan geçişler kaldırılmaz.

## Hızlı geçişin sınırı

Şu an kayıt yalnız son güvenli checkpoint'i tutuyor; bütün durakların ziyaret geçmişi varmış gibi gösterilmeyecek. Durak açılması gerçek zemin/konum olayıyla kaydedilir. Eski kayıt için mevcut checkpoint ve bölüm girişi güvenli başlangıçtır; oynanmamış duraklar geriye dönük açılmaz. Bu geçmiş ebeveyn raporunda yeni beceri/gözlem sayılmaz.

Aktif bölüm dışında bir geçmiş bölgeye gitmek, ana kaydı geriye yazan “hızlı geçiş” olmayacak; ayrı yeniden oynama slotu kullanılacak. Yeni hedef sahne açılamazsa önceki byte'lar ve profil/replay bağlamı geri alınır. Geri alma da başarısızsa eski dünyanın yeni hedef kaydını ezmesi engellenir; 0.15.1'de düzeltilen B04 sınırı tüm yeni geçişlere uygulanır.

## Üretim sırası

1. Mevcut kaynaklarla image harita referansı ve kullanılabilir arka plan/düğüm/durum varlıkları; kaynak ve güvenli metin alanları manifestte.
2. Kanonik kayıt ve replay hizmetini okuyan saf harita modeli; ayrı ikinci ilerleme sayacı yok.
3. Gerçek harita ekranı, klavye/dokunmatik odağı ve ana menü/mola bağlantıları.
4. Doğrulanmış güvenli durak açma ve hızlı geçiş; eski kayıt koruma.
5. Bölüm sonu kutularının sırayla harita akışına dönüşümü; bütün B00→B05 sınırları yeniden kontrol edilir.

## Kabul

Altı bölgenin tüm durumları, iki ekran boyutu, büyük yazı ve sağ/sol el yerleşimi; tüm mevcut/tekrar/açılmamış düğümler; profil değiştirme; aktif replay'den dönüş; yazma/sahne/geri-alma hataları; ana kayıt/yedeğin byte bütünlüğü; gerçek hedefe menü/devam ve dışa aktarılmış pakette bölüm zinciri. Harita UI sanatı kod çizimi veya genel kutu listesiyle ikame edilmez.

Diğer bölümlerin aşırı teslim/geri dönüş akışları bu haritanın arkasına saklanmaz; ayrıca sadeleştirilir. ElevenLabs konuşması için yeni metin akışı sabitlendikten sonra kayıt üretimi yapılır; değişecek metinlere gereksiz ses üretimi açılmaz.
