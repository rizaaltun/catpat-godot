# Çatpat: Festival Yolu

Godot 4.4.1 / GDScript tabanlı yatay 2D platform oyunu. Ana kaynak Godot projesidir; web sürümü aynı projenin Godot export'udur.

## Mevcut durum

- Ana başlangıç sahnesi: `scenes/polish_v3.tscn`.
- Güncel yayımlanmış sürüm: **0.15.8-focus-alpha**. Pencere odağı kaybolduğunda, modal açıkken veya konuşma gizliyken klavye ve gecikmiş arayüz çağrıları diyaloğu ilerletmez. 0.15.7'nin dokunmalı diyalogları ve başlangıç kıyısı korunur. Tüm CI ve Pages yayını başarılı; kabul kaydı `docs/DEVAM-NOTU.md` içinde.
- Son doğrulanmış GitHub Actions koşusu: [41654767114](https://github.com/rizaaltun/catpat-godot/actions/runs/41654767114) — dokunmalı diyalog/varsayılan akış, yeniden düzenlenmiş kıyı, B00–B05 regresyonları, kayıt hata yolları, Web export ve Pages dağıtımı başarılı.
- Canlı test: [https://rizaaltun.github.io/catpat-godot/](https://rizaaltun.github.io/catpat-godot/).
- Türkçe arayüz fontu doğrudan depodaki Baloo 2 dosyasından yükleniyor. Otomatik test font kaynağının Türkçe karakterleri ölçebildiğini doğruluyor; cihazlar arası görsel QA ayrıca takip ediliyor.
- Ana menüdeki ebeveyn özeti B01–B05 görev ilerlemesini yerel kayıttan okur. Becerileri veya gerçek yaşam gelişimini ölçmez; ortak katalog ve gözlem modeli hâlâ taslak durumundadır (`production/GAME_PROFILE.md`).

## Kaynak ve yayın

T22 Godot kaynakları, sahneleri, yayımlanabilir oyun görselleri, yazı tipi ve lisansları mevcut dala aktarıldı. Kullanıcının belirttiği yayınevi görselleri oyunda kullanılan WebP biçiminde tutuluyor. Kitap PDF/PSD orijinalleri ve kitap sayfası taramaları public dala alınmadı. Hakları belirsiz ek kaynaklar yayın girdisi yapılmamalı.

Geliştirme dalı: `work/t22-source-migration`. Ana `main` dalı korunur. Güncel devir noktası ve açık işler `docs/DEVAM-NOTU.md` içindedir.
