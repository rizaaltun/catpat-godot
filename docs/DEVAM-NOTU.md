# Çatpat devam notu — T22 kaynak aktarımı ve denetim, 19 Ekim 2026

## Proje ve standartlar

- Oyun: Çatpat: Festival Yolu; Godot 4.4.1 / GDScript.
- Ortak rehber: Epsilon Oyun Geliştirme Rehberi v1.0 (16 Ekim 2026).
- T22 proje arşivi: `Catpat-Godot-T22-Guncel-Proje (4).zip`; temel zincir V21, B05 Festival Alanı kod adayı.
- Geliştirme dalı: `work/t22-source-migration`.

## Tamamlanan aşamalar

- T22 arşivinden 87 Godot ayarı, sahnesi, scripti ve UID dosyası aktarıldı. 85 farklı dosya `source: restore Godot scripts and chapter scenes` commit'inde değişti: https://github.com/rizaaltun/catpat-godot/commit/83f5fea8ae0ac97934bdb3bd7d3016e9cc4523a2
- Tasarım, test ve devir belgeleri ile lisansı doğrulanmış Fredoka yazı tipi ikinci commit'te eklendi: https://github.com/rizaaltun/catpat-godot/commit/257ba3ba8787dec59f383b610ad5ce4fa5f29c27
- B01–B05 sahneleri ve GDScript kaynakları mevcut. `project.godot` başlangıç sahnesi `scenes/polish_v3.tscn` olarak korundu.
- Kullanıcı 19 Ekim 2026'da yayınevi kitabından gelen proje görsellerinin bu oyun için aktarılmasına izin verdi. Birebir PDF/PSD orijinalleri, `preproduction/references/` kitap sayfası taramaları ve taslak temas sayfası public depoya alınmadı.

## Bağımsız denetim bulguları

- Kullanıcının izniyle T22 arşivinden oyunun kullandığı 54 runtime görsel 24.62 MB WebP olarak eklendi; 87.84 MB kaynak PNG toplamına göre yaklaşık %72 küçüldü. Boyutlar korundu ve alfa kanalları kaynakla aynı kaldı; bu yapısal doğrulamadır, Godot içe aktarma testi değildir. Çatpat, Porsuk, Maymun ve Pıtpıt karakter kimliği onayları `USER_PENDING` olarak kalıyor.
- B05 kodu şu an yalnız Çatpat sprite'ını sahneye ekliyor; final metninde arkadaşların katkısı anlatılsa da arkadaş karakterleri veya katkı anları gösterilmiyor. T22 onayı gelmeden karakter kimliği için yeni tasarım üretme.
- B05'te `y=616` boyunca tek parça güvenli zemin var. Üst platformlar görev için zorunlu değil; oyuncu düz zeminde istasyonlara yürüyebilir. Ayrıca `y>820` düşme toparlanması bu tabanla doğal olarak tetiklenmiyor. Kabul hedefi ana parkur ve güvenli/kolay alternatif rotayı birlikte açıkça tanımlamalı.
- B05 üç görevi yakınlık etkileşimi ve tamamlandı bayraklarıyla kaydediyor; beceri/gelişim gözlemi veya ebeveyn raporu yok. B01'deki Yolculuk defteri oyuncuya dönük ilerleme arayüzüdür; ebeveyn raporu değildir. Görev bayrakları yalnızca etkileşimin tamamlandığını kanıtlar, beceri gelişimini değil.
- B05 son metni görülebilir arkadaş katkısı izlenimi veriyor; ilgili karakter/yardım animasyonları henüz mevcut değil. Ekip finali sahne ve metin olarak uygulandıktan sonra bu metin doğrulanmalı.

## Test ve yayın durumu

- Bu çalışma ortamında Godot CLI/editor yok; T22 Godot import, GDScript parse, sahne çalıştırma ve oyun içi görsel inceleme yapılamadı. WebP dosyalarının bütünlüğü, kaynakla boyut eşleşmesi ve alfa kanalları Pillow ile doğrulandı; oyun motoru doğrulaması değildir.
- B01–B04 için T22 regresyonu ve temiz tam koşu kanıtı yok. Arşivdeki V21 testleri tarihsel kanıttır; T22 kaynak hash'ini doğrulamaz. B04→B05 geçişi de T22'de çalıştırılmadı.
- B05 kabul vakaları A50–A54 tasarım aşamasında; görev sırası, düşme/toparlanma, kayıt/yeniden açılış, final tekrarı ve dokunmatik testleri çalıştırılmadı.
- Canlı tarayıcı test bağlantısı bu aşamada yok. Görseller ve WebP yolları geliştirme dalında; Godot importu, oynanabilirlik ve web export henüz doğrulanmadı. Dal tamamlanmış teslim değildir.

## Sıradaki işler

1. Godot 4.4.1 ortamında WebP varlıklarını import et ve GDScript parse hatalarını düzelt; import/oyun içi görsel QA kanıtını build hash'iyle kaydet.
2. B01–B04'ü T22 kaynaklarıyla Godot 4.4.1'de import et ve test et; B04→B05, kayıt şema10, dokunmatik, pause/devam, kesinti ve temiz tam koşu kanıtlarını build/commit hash'iyle kaydet.
3. B05'in ana rota ve kolay rotasını tasarıma göre tamamla; istasyonlara erişim, düşme sonrası checkpoint, görev sırası ve kayıt/yeniden açılış davranışını motor testleriyle doğrula.
4. B05 finalinde dört karakterin görünürlüğü ve katkı anlarını, karakter kimlik onayını aşmadan çözüme kavuştur; testli gerçek sahne görüntüsü/video ve sesle görsel QA yap.
5. Öğrenme/ebeveyn raporu istenen rehber gereksinimlerini ayrı kapsam olarak ele al: ortak beceri kataloğu ve gözlem şeması yok; görev bayraklarını öğrenme kanıtı gibi raporlama.
6. Godot web export'u üret, tarayıcıda gerçekten açıp oynat, sonra canlı test URL'sini ve test kanıtını bu notta kaydet.
