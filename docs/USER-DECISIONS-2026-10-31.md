# 31 Ekim 2026 — Kullanıcı kararları ve sıradaki üretim

Bu kayıt Rıza'nın doğrudan oynanış geri bildirimidir; önceki teknik testlerin başarılı olması bu sorunları kapatmaz. Ürün kabulü açık kalır.

| Kimlik | Kesin karar / görülen sorun | Uygulama ve kabul ölçütü | Durum |
| --- | --- | --- | --- |
| UX-01 | Görevler zor; karaktere gidip sürekli E'ye basmak ve geri dönmek yanlış. | B00–B05 görev rotalarını anlamlı eylem, etkileşim ve zorunlu geri dönüş sayısıyla çıkar. Görev nesnesinde doğrudan eylem, kısa yönerge ve yakındaki dünya tepkisi kullan. Aynı yolu görev teslimi için tekrar yürütme; yalnız yakınlığa gelmekle bütün görevi otomatik tamamlamak da çözüm değildir. | B01 sadeleştirildi; diğer bölümler açık |
| UX-02 | Havada toplanan sarı ışınlar gereksiz. | B01 ışık izi toplama, görseller, sayaç, yardım ve ebeveyn metinlerinden kaldırılacak. Eski kayıtların collectibles alanı okunabilir kalacak; eski veriler yeni gözlem/ödül üretmeyecek. Eski toplama testleri yeni kullanıcı kararına göre güncellenecek. | Uygulandı ve 0.15.2 ile yayımlandı |
| ART-01 | Sokak fenerleri salıncağın üstünde anlamsız duruyor. | Hareketli platform/salıncak üstündeki sokak fenerini kaldır veya hikâyeye uygun zeminde konumlandır; parkur zorluğunu bu dekor için koruma. Gerçek bölüm görüntüsüyle kontrol et. | B01 uygulandı, native kare incelendi ve 0.15.2 ile yayımlandı |
| AUDIO-01 | ElevenLabs bağlanacak; sesli anlatım daha iyi olacak. | Türkçe karakter/yönerge seslendirmesi, tekrar dinleme, konuşmada müziği azaltma ve sessiz kullanım karşılığı planla. Bağlantı ve ses seçimi henüz yapılmadı. API anahtarı isteme veya depoya koyma; mevcut özgün müzik/efektler seslendirme sayılmaz. | Bağlantı ve üretim bekliyor |
| UI-01 | Grafik arayüzleri daha heyecan verici olacak. | Mevcut kitap kimliği korunarak image kaynaklı ekran ailesi, karakter tepkileri ve daha canlı yolculuk sunumu üret; süs yoğunluğu yerine anlaşılır eylem ve karşılığına odaklan. | Açık |
| MAP-01 | Bölüm haritası olacak; bir kutudan diğer bölüme geçiş olmayacak. | B00–B05 dünyalarını gösteren gerçek yolculuk haritası; konum, sıradaki bölüm, açılmış bölümler ve güvenli tekrar erişimi. Genel bölüm listesi/kutu yeni harita diye teslim edilmez. Image referansı ve ayrı harita varlıkları gerekir. | Açık |
| NAV-01 | Oyun kolaylaşacak, hızlı geçiş eklenecek. | Gereksiz yürüyüş/geri dönüşleri azalt; açılmış güvenli duraklara veya bölümlere hızlı geçiş sun. Mevcut ana kayıt/profil/tekrar ayrımı korunsun; başarısız geçişte kayıt kaybı olmasın. Harita ve görev rotasıyla birlikte tasarla. | Açık |

## Geçmiş oturumun sınırlı işi — 31 Ekim

Kullanıcı kalan krediyi (%17 olarak belirtti) sıradaki işe harcamayı, ardından kredi yüklendiğinde devam etmeyi istedi. Kredi miktarı araçla ölçülmüş değildir. Yeni büyük görsel/ses üretimi açmadan yarım kalan ebeveyn/profil/yardım entegrasyonunun hedefli kontrolleri ve devredilebilir kaydı tamamlanacak. Bu kararlar yalnız sohbet içinde bırakılmayacak.

## Sonraki oturumda sıra

1. Bu kayıt, DEVAM-NOTU ve güncel git durumunu oku; yarım dosyaları silme veya eski sürümle ezme.
2. B01 için UX-02/ART-01 uygulandı. Son 0.15.2 yayın kaydını kontrol et; bu işleri yeniden başlatma. Diğer bölümlerin teslim/geri dönüşlerini ayrıca sadeleştir.
3. Harita ve hızlı geçişi `JOURNEY-MAP-NEXT.md` kabul sözleşmesiyle birlikte kur; kayıt/tekrar davranışını doğrula. Bu belge çalışan harita değildir.
4. Yeni image arayüz ailesi ve ElevenLabs seslendirmesini gerçek kaynak/bağlantıyla üret.
5. Diğer bölümlerde aynı tekrarlı görev kalıbını düzelt; gerçek cihaz ve çocuk kullanılabilirliği yapılmış sayılmasın.

## 3 Kasım yeni kullanıcı kararları ve uygulama

Ev/platform yerleşimi, yazı azaltma, otomatik diyalog/yerel hikâye eylemi/bölüm sonu, B02 arka plan titremesi ve başlangıç NPC hareketi0.15.6 ile uygulandı ve yayımlandı. Ayrıntı UX-FLOW-2026-11-03.md; kesin CI/yayın DEVAM-NOTU.md. Son B03 donma bildirimi otomatik akış, indirme/ip/sepet/kayıt hata matrisi ve yeniden girişte kaynak temizliğiyle ayrıca sınandı; aynı kullanıcı donma anının birebir tekrarı veya her cihazda bütün donmaların yokluğu iddia edilmez. B03 geri teslim zorunluluğu kaldırıldı. B04 kalan geri dönüşler, gerçek image harita/güvenli hızlı geçiş ve ElevenLabs hâlâ açık. Otomatik bölüm geçişi gerçek harita veya hızlı geçiş diye adlandırılmaz.
