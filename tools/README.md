# Üretim araçları

Çalıştırmak için Godot dışında paket gerekmez. Kaynak çıkarımı sırasında psd-tools, atlas sınır ölçümü sırasında Pillow/NumPy/SciPy kullanıldı; bunlar oyun runtime bağımlılıkları değildir. Kaynak PSD/PDF kullanıcı dosyalarıdır, bu repo paketine kopyalanmadı.

Headless test: `godot --headless --path . --quit-after 900 -- --smoke`.
Ekran kaydı (grafik ekranı gerekir): `godot --path . --write-movie preview.avi --fixed-fps 30 -- --preview`.
Ekran görüntüsü: `godot --path . -- --screenshot` → `docs/gameplay.png`.
`--preview` yalnız sunum içindir; arkadaşları baştan ekler, kayıt yazmaz.
