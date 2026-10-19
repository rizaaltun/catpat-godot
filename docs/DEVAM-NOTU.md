# Çatpat devam notu — 2026-10-19

Kaynaklar: 01-Catpat-Proje-ve-Kitap (2).zip, T22 değişiklik arşivi ve Epsilon Oyun Geliştirme Rehberi v1.0.

B01 Fenerli Patika, B02 Dostluk Deresi, B03 Papatya Bahçesi, B04 Rüzgârlı Yamaç V21 sürümünde uygulanmış olarak devralındı. B05 Festival Alanı T22 kaynak kodunda var; Godot motorunda doğrulanmadı.

**GitHub repo aktarımı kısmi:** henüz tam, oynanabilir oyun değildir. PDF/PSD kaynakları kamuya açık depoya yüklenmeyecek.

Sıradaki işler: eksik güvenli kaynak aktarımlarını bitir; Godot 4 parse/import testleri; B04→B05, schema10 kayıt, basılı tutma dokunmatik hareket, duraklat/devam ve üç festival görevini denetle; son sanat ve ses; web export ile gerçek canlı test bağlantısını doğrula.

Doğrulanmamış şeyi test edilmiş veya yayımlanmış olarak işaretleme.

## 2026-10-19 kaynak aktarım denetimi

- Bu çalışma alanında yalnızca `01-Epsilon_Oyun_Gelistirme_Rehberi.md` mevcut; proje ZIP'i veya T22 arşivi bu oturuma eklenmemiş.
- `main` dalında dokuz izlenen dosya var: `.gitignore`, `README.md`, `project.godot`, `docs/DEVAM-NOTU.md`, `scenes/festival.tscn`, `scripts/core/quest_state.gd` ve üç dizin ağacı kaydı.
- `project.godot` başlangıç sahnesi `res://scenes/polish_v3.tscn` olarak ayarlı; bu dosya depoda yok.
- `scenes/festival.tscn`, `res://scripts/chapters/festival_main.gd` dosyasına bağlı; bu dosya depoda yok. B01–B04 sahneleri ve runtime görsel/ses kaynakları da ağaçta görünmüyor.
- Bu nedenle proje Godot'ta açılamadı; B01–B04 regresyonu, B04→B05, kayıt, dokunmatik, duraklat/devam ve festival görevleri test edilmedi. Ortamda Godot CLI bulunmuyor.
- Sonraki somut adım: önceki projeye ait telifli PDF/PSD'leri dışarıda bırakan kaynak arşivini ve devir belgelerini bu sohbete ekle. Ardından güvenli Godot sahneleri, kodu ve runtime assetlerini küçük, doğrulanan commitlerle taşı; motor testlerini ve web export'u gerçek çıktılarla çalıştır.
- Açık depo sınırı: kitap PDF/PSD'leri veya diğer telifli kaynak belgeleri buraya yüklenmeyecek.
