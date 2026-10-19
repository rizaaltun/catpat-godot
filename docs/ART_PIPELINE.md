# Karakter ve animasyon üretimi

## Kaynak gerçekliği

- Kaynak PSD: `catpat kitap ic proje.psd`, 1062×544 belge; 123 descendant katman kaydı.
- Çatpat idle: 118. indeks / Katman 106, bbox (231,133,378,352), 147×219 kaynak.
- Çatpat diğer pozlar: indeks 9 / Eklenmiş Fotoğraf, indeks 51 / Katman 73.
- Maymun ve Porsuk: indeks 119 / Katman 107 içinde birlikte. Tek katman olduğu için sınırdaki ip/dal unsurları referans çıkarımında kalmıştır. Tam temiz kaynak için maskeleme gerekir.
- Pıtpıt bu PSD'nin sağlanan katmanlarında bulunmadı; PDF'nin 5. yayılımı referans alındı.

Kaynak çözünürlüğü sınırlıdır. Kitapla birebirlik için kaynak resmi büyütmek tek başına yeni poz üretmez. Baş/yüz/siluet sabitleri onaylanmalı; gerektiğinde daha yüksek çözünürlüklü orijinal çizim veya rig parçaları kullanılmalı.

## Gün 1 atlasları

Her karakter için ayrı `1536×1024` RGBA atlas, 6 sütun × 2 satır, hücre `256×512`. İlk sıra koşu 0–5; alt sıra idle, blink, crouch, jump, fall, cheer. Oyun `AnimatedSprite2D`/`SpriteFrames` ve `AtlasTexture` kullanır. `launch` pozu atlas ve SpriteFrames'te bulunur ancak henüz kısa hazırlık geçişine bağlanmamıştır; fizik zıplaması bekletilmez.

Üretim yöntemi: yerleşik imagegen, orijinal PSD/PDF referanslarıyla dört bağımsız çağrı. Ana brifler: aynı karakter kimliği, sağa bakan tutarlı ölçek, gerçek karşılıklı kol/bacak hareketi, 6 koşu fazı, altı yardımcı poz, şeffaf arka plan, çizgisel olmayan mat guaj doku, yazı/etiket olmaması. Zemin atlası ayrıca imagegen ile üretildi: çimenli toprak, yosunlu kütük, ağaç kütüğü, tahta köprü.

**Bunlar üretim adayıdır. Birebir kimlik, kare hizası ve anatomi onayı tamamlanmadı.** Özellikle bazı burun/kuyruk sınırları hücreye çok yaklaşır; her kare sanat denetiminden geçmeden son atlas denmez. Tüm karakterlerde koşu ve hava durumları canlı oynar, ancak anatomik tutarlılık ve ağırlık hissi ikinci gün hedefidir.

## Gün 2 kabul listesi

1. Orijinal ve yeni nötr poz yan yana; snout/baş, göz aralığı, kulak, gövde, bacak, toka, çizme ve renk karşılaştırması.
2. Kullanıcının onayından önce mevcut yeni yüzü “kilitli model” sayma.
3. Her hareketi döngü GIF/video olarak göster; tek atlas gösterip animasyon tamamlandı deme.
4. Grid sınırlarını, şeffaf payları, yer pivotunu ve kareler arası ölçeği sabitle.
5. Ayak temasını hareket hızıyla eşle; zıplama hazırlığı/iniş ağırlığı ve konuşma ekle.
6. Telefon boyutunda okunabilirliği incele. Karakter dokusunu vektör/geometrik çizimle değiştirme.
