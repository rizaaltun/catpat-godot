# Sanat ve animasyon üretim standardı

## Öncelik sırası

1. Kitap karakteri tanınmalı; kıyafet/aksesuar eşleşmesi tek başına yeterli değil.
2. Siluet ve beden oranı hareket boyunca korunmalı.
3. Platformun basılabilir yüzeyi ve tehlikesi okunmalı.
4. Doku, ışık, atmosfer ve küçük çevre hareketleri bu temelin üzerine eklenmeli.

## Karakter modeli

Çatpat: kitabın yeşil kız timsahı; geniş/küt burun, göz yerleşimi, baş-gövde ilişkisi, sarı toka, turuncu çizmeler, göbek lekesi ve sırt çıkıntıları kaynakla eşleştirilecek. Porsuk: uzun sivrilen burun, baştan burna uzanan açık lekenin şekli, göz/kulak ve gövde oranı özellikle korunacak. Şişkin kafa, değişen burun uzunluğu, yanak renginin doğru olmasıyla telafi edilemez. Maymun: büyük kulak ve yüz maskesi kadar ince kuyruk/siluet önemli. Pıtpıt: kulak boyu/açısı, alın tutamı, göz/kirpik ve bıyık yerleşimi.

Her model kartı: kitap referans sayfası, gerçek kaynak katman adı, nötr poz, ön/yan/üç çeyrek yönler, 6 ifade (nötr, merak, endişe, düşünme, sevinç, konuşma), siluet ve ölçüm işaretleri. Oranlar rastgele hedef sayıyla belirlenmez; kaynak üzerinden işaretlenip saklanır. Farklı pozun bounding box'ı farklı olabilir; bu tek başına ölçek hatası değildir.

Orijinal PNG'ler immutable tutulur; temiz maske/parça/yeniden çizim ayrı sürümlerdir. Kaynaklar düşük çözünürlüklü: Çatpat idle 147×219 px. Yüksek çözünürlük gerektiğinde kimlik onayı olmadan AI büyütme/yeniden yorumlama yapılmaz.

## Yeni animasyon hattı

`source → model-approved → frames/rig → motion-review → packed-atlas → in-engine review`.

Yeni hareketler alt alta çok karakterli tek büyük görselde üretilip otomatik dilimlenmeyecek. Her poz bağımsız ve tam karakter; kontrol edilebilir boşluk ve ortak tasarım tuvali. 512×512 başlangıç çalışma tuvali; kuyruk/burun sığmazsa aynı animasyon ailesinin tüm kareleri 768×512 gibi daha geniş ortak tuvale alınır. Karakteri tuvale sığdırmak için ayrı kareyi küçültmek yasak.

Metadata her kare için: kaynak PNG, canvas_size, pivot, anatomical_root, ayak temas işaretleri, süre, ifade ve kaynak model sürümü. Anatomik kök aynı noktadır; bütün görünür piksellerin ortası değildir. Havada kıvrılan ayağı yere yapıştırmak amacıyla farklı offset verme. Ayak temas işaretleri fizik kökünden ayrı tutulur.

Paketleyici görünür alanı kırpabilir ancak source_size/trim_offset/pivot bilgisini korur. En az 16 px dış güvenlik payı; filtre sızıntısı için 2–4 px atlas extrusion/gutter başlangıç standardı. Otomatik sınır teması uyarısı tetiklenirse yeni kaynakta düzelt; eşiği değiştirip uyarıyı susturma. Kuyruk/kulak gibi ayrı alpha bileşenlerini 'en büyük parça değil' diye atma.

Hedef animasyon seti (kesin üretim sayısı hareket denemesinden sonra): idle 4–6, walk/run 8, jump anticipation 2, rise/apex/fall toplam 3–5, land 2–3, talk 4, listen 3, karaktere özel help 6–10, celebrate 6. Havada/inişte yalnız tek kareyle uzun süre beklemek örnek bölümün nihai kalitesi sayılmaz.

## Üslup ve çevre

Kitabın mat guaj dokusu, yuvarlak organik biçimleri ve sıcak yanak renkleri korunur. Sabit resimdeki perspektif, yandan platform oyununun basılabilir düzlemiyle yeniden tasarlanır. Ön planda yürünebilir yüzeyin tonu/kenarı tutarlı, arka plan daha düşük kontrastlı. Gökyüzü, uzak ağaç, orta bitki, oynanabilir zemin, ön bitki ayrı katmanlar. Dekor karakterin ayaklarını veya bir sonraki iniş noktasını örtmez.

Zemin çizimini x yönünde esnetip y yönünde sabit tutma. Sol kapak/tekrar eden orta parça/sağ kapak ve köşe/eğim birleşimleri hazırlanır. Kök, taş ve kütüklerin destekleri görünür olmalı. Yüzen yaprak/halatlı platform varsa hikâyede ve görselde neden askıda olduğu anlaşılır. Rastgele tekrarlanan ada dizisi olmaz.

Çarpışma çizgisi görsel üst yüzeyle ayrı debug görünümünde karşılaştırılır. Fırça çıkıntıları mikro çarpışma yapmaz; yürüyüş yüzeyi kontrollü pürüzsüzdür. Arka plan dekorundaki köprü/zemin yanlışlıkla basılabilir görünmemeli.

## Hareket hissi

İniş hafif ağırlık hissi, yüz ifadesi, yaprak/toz tepkisi ve uygun sesle desteklenir. Ekran sarsıntısı zorunlu değildir; çocuk oyunu için hafif ve kapatılabilir tasarlanır. Yaprak/ışık hareketi az ve amaçlıdır. Karakter çiziminin tümünü sallamak uzuv animasyonunun yerine geçmez.

## Teknik dayanak

Godot TileSet/TileMapLayer ile collision ve modüler zemin düzeni; bu oyundaki çizimler özel raster sanat olarak kalır. Resmî doküman: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html. Kemik/cutout yaklaşımı için küçük doğrulama denemesi yapılmadan tam üretim kararı verilmez.
