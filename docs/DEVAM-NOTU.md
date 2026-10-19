# Çatpat devam notu — T22 kaynak aktarımı, 19 Ekim 2026

## Proje ve standartlar

- Oyun: Çatpat: Festival Yolu; Godot 4.4.1 standard / GDScript.
- Ortak rehber: Epsilon Oyun Geliştirme Rehberi v1.0 (16 Ekim 2026).
- T22 proje arşivi: `Catpat-Godot-T22-Guncel-Proje (4).zip`; temel zincir V21, B05 Festival Alanı kod adayı.
- Geliştirme dalı: `work/t22-source-migration`.

## Tamamlanan bu aşama

- T22 arşivinden 87 Godot ayarı, sahnesi, scripti ve UID dosyası dala taşındı. 85 farklı dosya `source: restore Godot scripts and chapter scenes` commit'inde değişti: https://github.com/rizaaltun/catpat-godot/commit/83f5fea8ae0ac97934bdb3bd7d3016e9cc4523a2
- B01–B05 sahneleri ile B05 kodu mevcut. `project.godot` başlangıç sahnesi `scenes/polish_v3.tscn` olarak kaldı.
- Fredoka yazı tipi ve OFL lisans metni kaynak olarak doğrulanabildi; sonraki aktarım aşamasında eklendi.
- PDF/PSD kitap orijinalleri ve `preproduction/references/` kitap görselleri public depoya alınmadı.

## Açık güvenlik ve sanat kapısı

- Kaynak arşivinde runtime PNG'lerin oyun kullanım hakkını açıklayan bir lisans/dağıtım kaydı yok. Kitap referanslı karakter görsellerinin model onayı da `USER_PENDING`. Bu nedenle oyun PNG'leri public depoya henüz taşınmadı.
- Eksik runtime görselleri nedeniyle GitHub dalı tamamlanmış veya oynanabilir proje değildir. Görsel dosyaları için yayın hakkını gösteren bir belge veya dosya bazında onaylı liste gerekir; PDF/PSD ve kitap sayfası taramaları her durumda dışarıda kalır.

## Test durumu

- Bu çalışma ortamında Godot CLI/editor bulunmuyor.
- T22 için import/parse, B01–B04 regresyonu, B04→B05 geçişi, kayıt şema10, dokunmatik, pause/devam, gerçek oyun akışı, görsel QA ve web export çalıştırılmadı.
- Arşivdeki V21 test sonuçları tarihsel kanıttır; T22'nin test edildiği anlamına gelmez.
- Canlı tarayıcı test bağlantısı bu aşamada üretilmedi. Önce hakları doğrulanmış runtime görselleri ve Godot web export'u gerekir.

## Sıradaki somut işler

1. Public dağıtım hakkı doğrulanmış runtime görselleri listele; onaysız kitap referansları, orijinaller, PDF/PSD ve test ekran görüntülerini dışarıda tut.
2. Godot 4.4.1 ile temiz import ve script parse yap; hata varsa küçük commitlerle düzelt.
3. B01–B04 regresyonlarını çalıştır; B04→B05, B05 görev sırası, kayıt/geri yükleme, düşme/toparlanma, pause/devam ve dokunmatik hareketi denetle.
4. Festival parkurunu, üç arkadaşın görünür katkısını, görsel/animasyon/ses kalitesini gerçek motor görüntüsü ve video ile incele.
5. Web export'u üret ve GitHub üzerinden canlı test URL'sini ancak başarıyla açıp oynadıktan sonra ekle.
