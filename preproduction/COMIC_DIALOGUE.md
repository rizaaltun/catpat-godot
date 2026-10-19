# Sağlı sollu çizgi roman konuşmaları

## Görsel karar

Kullanıcının istediği gibi iki karakter aynı sahnede karşılıklı görünür: genellikle Çatpat solda, konuştuğu arkadaş sağda. Bel hizası/üst gövde portreleri yüz ifadesini okumaya yetecek büyüklükte; birbirlerine dönük. Bu düzen kitap çizimine benzeyen arka plan, boyanmış balon çerçeveleri ve gerektiğinde panel geçişleriyle sunulur. Hazır çizgi roman sayfasının rastgele bir dilimini sağa koymak kullanılmaz.

Portreler, balon çerçeveleri ve arka plan ayrı, tam ve şeffaf/uygun katmanlı resimlerdir. Karakterler CSS veya geometrik şekillerle çizilmez. Türkçe metin ayrı katmanda kalır: doğru yazım, ölçek ve erişilebilirlik için. Balonun kuyruğu konuşana yönelir; metin kutusunun konumu konuşma sırasında sebepsiz zıplamaz.

## Sahne davranışı

1. Güvenli noktada oyuncu girdisi kilitlenir, hareket tuşları sıfırlanır.
2. Karşılaşma paneli açılır; iki karakter de görünür.
3. Konuşan karakter talk/ifade animasyonu kullanır; diğeri dinler, göz kırpar. Dinleyeni tamamen karartmak yerine hafif vurgu farkı kullanılır.
4. Bir dokunma yazının tamamını gösterir; ikinci ayrı dokunma sonraki repliktir. Hızlı çift girişin istemsiz atlaması engellenir.
5. Bölüm aralarında tek geniş panelden iki yakın panele geçiş veya bir nesneye kısa ara plan kullanılabilir. Her cümlede kamera efekti yapılmaz.
6. Son replikte görev olayı yalnız bir kez işlenir; kontrol geri gelir. Tekrar izle görev ödülünü tekrar vermez.

Konuşmalar otomatik zaman aşımına uğramaz. Metin hızı/tek seferde göster seçenekleri; ileride seslendirme. Atlama özeti, oyuncunun görevi anlamasına yetecek kadar kısa tutulur.

## Yerleşim başlangıç kılavuzu

1280×720 yatay referans: dış güvenli alan yaklaşık %5; portreler alt sol/sağ bölgede; balonlar üst sol/sağ bölgede, ortada çevreyi gösteren açıklık. Bunlar sabit piksel kutuları değil uyarlanan container yerleşimidir. 16:9, 19.5:9 ve tablet 4:3'te denenecek. Yüz veya balon kuyruğu çentik altında kalmaz. Metin en uzun Türkçe replikle ve büyütülmüş yazı ayarıyla taşma testinden geçer.

Her balon genellikle 1–2 kısa cümle. Cümleyi sığdırmak için fontu sürekli küçültmek yerine repliği böl. Kullanılan yazı tipinin Türkçe İ/ı/ğ/ş/ç/ö/ü karakterleri kontrol edilir; fontun kullanım lisansı kaydedilir.

## Porsuk karşılaşması — örnek senaryo

| Replik | Taraf / ifade | Metin | Görsel olay |
|---|---|---|---|
| 1 | Sağ / endişeli | Çatpat? Yolun kıvrımını göremiyorum. | Porsuk patikaya bakar; sönük fener ara planı |
| 2 | Sol / dinleyen | Buradayım. Sana nasıl yardım edebilirim? | Çatpat yürümeyi bırakır ve Porsuk'a döner |
| 3 | Sağ / açıklayan | Rüzgâr üç feneri söndürdü. Biri şu kökün üstünde. | Porsuk ilk feneri işaret eder |
| 4 | Sol / düşünceli | Önce yakındakini yakayım. Sonra birlikte bakarız. | Çatpat hedefe bakar; görev başlar |

## Yardım sonrası

| Replik | Taraf / ifade | Metin | Olay |
|---|---|---|---|
| 1 | Sağ / rahatlamış | Şimdi yolu görebiliyorum. Teşekkür ederim! | Sıcak ışık her iki yüze yansır |
| 2 | Sol / sevinçli | Ben festivale gidiyorum. Birlikte yürüyelim mi? | Çatpat'ın davet eli |
| 3 | Sağ / sevinçli | Seve seve! Fenerimi de alayım. | Porsuk el fenerini alır; katılım olayı |
| 4 | Sol / meraklı | Dereden bir ses geliyor. Haydi bakalım! | Sonraki bölüme yön; kontrol açılır |

Bu replikler yeni oyun senaryosudur; kitapta aynen geçtikleri iddia edilmez. `story/lantern-dialogue.json` bu taslağın veri karşılığıdır, henüz oyuna bağlanmamıştır.

## Uygulama sözleşmesi

Önerilen yapı: DialogueRunner durum makinesi + ComicPanel sahnesi + PortraitActor + Balloon + DialogueResource/veri. Her satır `id`, `speaker`, `side`, `expression`, `text`, `next` alanlarını içerir. Görev ödülleri repliğin kendisinden rastgele tetiklenmez; idempotent olay anahtarı ve tamamlanma koşulu kullanılır. Konuşma atlaması, duraklatma, kontrol geri verme ve kayıt ayrı test edilir.

## 6 Ekim uygulama notu

JSON artık ayrı `scenes/comic_review.tscn` inceleme sahnesine bağlıdır; ana görev akışına bağlı değildir. Güncel kanıt ve sınırlar: `review-v2/README.md`. Tasarımın tüm maddeleri uygulanmış sayılmaz.
