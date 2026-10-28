# Çatpat — Yeni GPT hesabı için proje devri

Güncelleme: 28 Ekim 2026

## Kaynaklar

- GitHub deposu: https://github.com/rizaaltun/catpat-godot
- Çalışma dalı: `work/t22-source-migration`
- Canlı oyun: https://rizaaltun.github.io/catpat-godot/
- Güncel doğrulama ve Pages dağıtım koşusu: https://github.com/rizaaltun/catpat-godot/actions/runs/40490221402
- Önceki devir notu: [docs/DEVAM-NOTU.md](DEVAM-NOTU.md)
- Epsilon Oyun Geliştirme Rehberi, bu hesabın konuşmasına eklenmiş ayrı bir dosyadır. Yeni hesaptaki GPT konuşmasına dosyayı ayrıca yükleyin.

## Proje durumu

- Oyun: Çatpat: Festival Yolu; Godot 4.4.1 / GDScript.
- B01–B04 oynanış ve geçiş regresyonları, B05 Festival Alanı fizik/etkileşim kontrolleri, Web export ve GitHub Pages dağıtımı son doğrulamada başarılı.
- B01 ve B02 için 666×374 dar ekran dokunmatik render kareleri ve kontrol yerleşimi kontrolleri eklendi. Görev ipuçlarının alt kenara yakınlığı düzeltildi.
- Son kod değişikliği: [3638505](https://github.com/rizaaltun/catpat-godot/commit/363850531ff04b2b1ae48b999d867b7e2a06ea76). Son başarılı tam koşu: [40490221402](https://github.com/rizaaltun/catpat-godot/actions/runs/40490221402).
- Açık QA: Mac'te/WebGL2 destekli masaüstü tarayıcıda canlı oyunu elle denemek; gerçek telefonda/tablette dokunmatik ergonomiyi denemek. CI kareleri fiziksel cihaz testi yerine geçmez.
- Ebeveyn özeti yalnızca kaydedilmiş görev ilerlemesini gösterir. Doğrulanmış ortak beceri/katalog kimlikleri olmadan beceri gelişimi veya gerçek yaşam davranışı iddiası eklenmemeli.

## Yeni hesapta devam etme

1. Bu GitHub deposunu yeni GPT hesabındaki GitHub bağlantısına yetkilendir. Yazma/commit için `rizaaltun/catpat-godot` deposunda write erişimi gerekir; herkese açık repo bağlantısı tek başına commit yetkisi vermez.
2. Aşağıdaki proje başlangıç metnini yeni bir konuşmaya yapıştır.
3. Epsilon rehberini aynı konuşmaya dosya olarak ekle.
4. İlk iş olarak `work/t22-source-migration` dalını ve Actions durumunu kontrol et. `main` dalından yeni bir proje başlatma veya ayrı repo oluşturma.
5. Her anlamlı aşamada bu devir notunu güncelle. Kod değişikliklerini küçük commit’lerle kaydet ve CI geçmeden canlı oyunun düzeldiğini iddia etme.

## Kopyalanabilir başlangıç metni

> Çatpat Godot projesini kaldığı yerden devral. Önce `docs/DEVAM-NOTU.md` ve bu devralma dosyasını, yüklediğim Epsilon Oyun Geliştirme Rehberi'ni ve GitHub Actions son koşusunu incele.
>
> Mevcut projeyi ve `work/t22-source-migration` dalını koru; yeni repo veya proje ZIP'i oluşturma. Kaynak: https://github.com/rizaaltun/catpat-godot — canlı test: https://rizaaltun.github.io/catpat-godot/
>
> B01–B04 regresyonlarını koru; B05 Festival Alanı'nı tamamlanmış, oynanabilir bölüm olarak görsel ve cihaz QA'sıyla iyileştir. Küçük, doğrulanmış commit’lerle çalış; her aşamada `docs/DEVAM-NOTU.md` güncelle. Rutin teknik kararlar için onay isteme; önemli yaratıcı kararları ve gerçek engelleri bildir.
>
> Kitap PDF/PSD orijinallerini veya hakları doğrulanmamış kaynakları Public depoya yükleme. Rehberdeki beceri/katalog kimlikleri doğrulanmadan oyun veya ebeveyn özetinde beceri gelişimi iddiası ekleme. Fiziksel cihaz ve tarayıcı testini CI kanıtından ayrı raporla.

## Kaynak hakları

Oyunun GitHub dalına yayımlanabilir runtime kaynakları aktarılmıştır. Orijinal kitap PDF/PSD dosyaları ve hakları doğrulanmamış kaynaklar depoya eklenmemiştir. Yeni hesaptaki GPT'ye yalnızca projeye aktarılmasına izin verilen kaynakları yükleyin.
