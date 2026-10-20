# Çatpat oyun profili ve öğrenme/gözlem taslağı

Durum: proje içi ilk taslak; ortak şirket kataloğu veya uzman onayı yerine geçmez. Son gözden geçirme: 20 Ekim 2026.

## Kimlik ve kaynak

- Önerilen sabit oyun kimliği: `catpat-festival-yolu` (katalog sahibi tarafından kesinleştirilecek).
- Görünen ad: Çatpat: Festival Yolu.
- Kaynak türü: yayınevi kitabından beslenen oyun projesi. Bu depoda kitabın kesin künyesi, yayınevi adı ve hedef okur yaşı belgelenmedi; bunlar doğrulanana kadar bilinmiyor olarak kalır.
- Hedef: Godot 4.4.1, yatay 2D platform macerası; masaüstü ve tarayıcı oynanışı, nihai mobil/iOS kapısı ayrı.
- Karakter tasarımının nihai kitap uyumu/onayı kaynak kaydında hâlâ açık.

## Hikâye ve oynanış

Çatpat festivale giderken arkadaşlarının ihtiyaçlarını dinleyip onlara yardım eder. Oyuncu yürüme, zıplama, çevre nesneleriyle etkileşim ve arkadaşların katkılarıyla kesintisiz bölüm zincirinde ilerler; görevler soru-cevap testi değildir.

- B01 Fenerli Patika: fenerleri açıp Porsuk'un güvenli yol bulmasına yardım et.
- B02 Dostluk Deresi: tahta ve halatı bir araya getirip Maymun'la köprüyü tamamla.
- B03 Papatya Bahçesi: çiçekleri koruyarak bahçe görevini Pıtpıt'la bitir.
- B04 Rüzgârlı Yamaç: önceki arkadaşların yardımlarını ortak geçişte kullan.
- B05 Festival Alanı: sahne ışığı, flamalar ve çiçek hazırlığını tamamla; ekipçe finale ulaş.

Bu özet proje tasarım/kodundan alınmıştır; kitabın metninden doğrudan alıntı değildir.

## Beceri eşlemesi — öneri, ölçüm değil

Epsilon ortak alanlarının geçici eşlemesi:

- Birincil aday: **duyguları ve sosyal durumları anlama** — arkadaşın ihtiyacını dinleme, yardım teklif etme ve ortak katkı.
- İkincil aday: **dil ve anlatım** — kısa diyalogları izleme ve anlatının akışını anlama.
- Mekanik destek alanı: **görsel-uzamsal düşünme / problem çözme** — güvenli platform rotası seçme ve hareketi yeni engelde kullanma.

Bunlar tasarım niyetidir; çocukta beceri kazanımı veya gerçek yaşam gelişimi kanıtı değildir. Yaş, ön beceri, uzman değerlendirmesi ve ortak beceri kimlikleri katalog sahibiyle doğrulanmalıdır.

## Gözlem sınırı ve rapor durumu

Şu anki kayıtlar `quest_flags`, checkpoint ve bölüm durumu taşır. Bunlar yalnızca belirli oyun içi görevlerin tamamlanmasını gösterir. Deneme sayısı, ipucu kullanımı, strateji, bağlamlar arası aktarım ve ebeveyn görünümü mevcut uygulamada doğrulanmış değildir. Bu yüzden ebeveyn raporu **uygulanmış sayılmaz** ve mevcut bayraklardan gelişim iddiası çıkarılmamalıdır.

Önerilen gözlem kaydı uygulama öncesi sözleşmesi:

- Kimlik: `event_id` (tekrarda aynı olayın iki kez sayılmasını önler), `game_id`, `content_version`.
- Bağlam: bölüm, etkinlik/görev, zorluk profili, deneme numarası ve UTC zaman damgası.
- Beceri: ortak sözlükteki `skill_id` ve ilgili öğrenme amacı; yalnızca etkinlikle doğal bağı varsa.
- Kanıt: gözlenen oyun eylemi, yardım/ipucu kullanımı ve sonuç; yorum/çıkarım ayrı alan olmalı.
- Veri sınırı: takma adlı yerel profil kimliği dışında kişisel tanımlayıcı ve telemetri eklenmemeli; mevcut kayıt biçimi değiştirilmeden önce geriye uyum ve ebeveyn kontrolü tasarlanmalı.

Örnek gözlem: “B05 flamaları yerleştirdi” yalnızca etkinlik tamamlamadır. Tek başına sosyal beceriyi veya gelişimi ölçmez. Rapor ancak yeterli sayıda, benzer bağlamda toplanmış gözlenebilir denemeler varsa temkinli oyun içi davranış özeti verebilir; tanı, puan sıralaması veya gerçek yaşam gelişim iddiası veremez.

## Tamamlanma kapıları

1. Ortak katalog kimliği, kitap künyesi, hedef yaş ve ortak beceri ID'lerini doğrula.
2. Gözlem olaylarını mevcut schema10 kayıtlarına geriye uyumlu ve yinelenmeye dayanıklı biçimde bağla.
3. Ebeveyn görünümünü yalnızca gerçek gözlem verisiyle çalıştır; yetersiz veriyi açıkça göster.
4. Oyun içinde ve web export'ta veri silme/ebeveyn kontrolü, kayıt göçü ve rapor senaryolarını test et.

Bu belge bir veri toplama özelliği eklemez; uygulama öncesi taslak ve devir bağlamıdır.
