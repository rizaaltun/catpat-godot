# T22 çalışma kopyası — B05 Festival Alanı (19 Ekim 2026)

Önceki doğrulanmış sürüm: V21 (12 Ekim 2026). Bu çalışma V21 kaynaklarının üzerine yapılmıştır; eski test sonuçları bu değişikliklere aktarılmaz.

## Kaynakta değiştirilenler

- `scenes/festival.tscn`, `scripts/chapters/festival_main.gd`: 4400 birim B05 sahnesi; fiziksel yürüme/zıplama, bölünmüş zemin, görev platformları, orman arka planı, festival kamp çizimi, yosunlu platform görselleri, yol işaretleri ve görev tamamlanınca görünür çiçekler. Üç arkadaşın katkı hareketi ve portreli final paneli var. Bazı zemin/sahne şekilleri teknik geometri; oyun içi görsel QA sürüyor.
- `scripts/chapters/summit_main.gd`: B04 seyir görevinden sonra E ile festival girişini önce geçerli ana kayda yazar, sonra sahneyi değiştirir; başarısız sahne geçişinde önceki B04 kaydını geri yüklemeyi dener.
- `scripts/core/{quest_state,save_service,level_director}.gd`: B05 görev kimlikleri, ön koşullar, checkpoint'ler ve kayıt doğrulaması. Mevcut ana kayıt **schema10 olarak korunmuştur**. B05 görevleri quest_flags ve ending_seen içindedir; ayrı kullanıcı kaydı yaratılmaz.
- `scripts/polish_world.gd`: menünün Devam işlevi B05 kaydını da açar.

## Açık kalite ve doğrulama kapıları

Yerel ortamda Godot ikilisi yok; Godot 4.4.1 doğrulaması GitHub Actions ile sürdürülüyor. CI run 39277080713 B01–B04 sahne/kayıt noktası eşleşmelerini ve B04 gerçek geçiş regresyonunu geçti. B05 runtime sözleşmesi run 39277643051 içinde 61 kontrol, 0 başarısızlıkla geçti; log eksik bir Porsuk yürüyüş karesini yakaladı. Asset 4547a4158a14e9331a2b174a18a76c7d59809133 ile eklendi. Final kayıt ankrajı ve yeniden açılış kontrolü 22f6cda81eda9554c6fdc22197ed53cdaddbdbf0 ile güncellendi. Son baş commit için CI run 39278911359 devir notu yazılırken sıradaydı; final sonucu henüz doğrulanmadı.

B05'in 61 kontrolü üç katkıyı, alternatif görev sırasını, katkı checkpoint'lerini, arkadaşların final alanına varmasını, final kilidini, ortak finali ve kanonik kayıt/yeniden açılışı sınar. Bu smoke testi elle oynanan tam parkur ya da görsel QA değildir. Son değişikliklerle birlikte temiz Web export ve log doğrulaması bekleniyor.

## Son durum ve doğrulama

- 56 runtime görsel kullanıcı izniyle WebP olarak GitHub dalına eklendi; toplam 25.45 MB. Orijinal PDF/PSD ve kitap sayfası taramaları public depoya alınmadı.
- Başarılı B01–B04 hedefli CI: https://github.com/rizaaltun/catpat-godot/actions/runs/39277080713
- B05 61/61 sözleşme/oyun-içi test: https://github.com/rizaaltun/catpat-godot/actions/runs/39277643051 — testler geçti; logdaki eksik asset ve son final ankrajı düzeltmeleri sonraki commit'lerde.
- Son baştaki asset+ankraj doğrulaması: https://github.com/rizaaltun/catpat-godot/actions/runs/39278911359 — devir güncellemesi sırasında beklemede.
- GitHub Pages kapalı; kullanıcı canlı yayın ayarını şimdilik erteledi. Web çıktısı CI'da üretilmiş olsa da hosted tarayıcı testi ve canlı URL açık.

## Önce yapılacak doğrulama

1. Run 39278911359 tamamlanınca B05 test çıktısında resource error olmadığını, final checkpoint konumunu, bütün regresyonları ve Web export'u doğrula.
2. B01–B04 tam rota, B04→B05 geçişinin kullanıcı kontrollü oyuncu akışı, farklı kayıt/geri yükleme ve gerçek dokunmatik kontrollerini sürdür.
3. B05'i gerçek zıplama/düşme/checkpoint toparlanmasıyla, finalden sonra dolaşma ve farklı ekran oranlarıyla viewport'ta incele.
4. Tam sahne/animasyon görüntü QA'sını Godot ekran kaydıyla yap; yalnız kaynak ve headless testi profesyonel görsel teslim kanıtı sayma.
5. Pages yayını ve canlı URL'yi kullanıcı bu adımı yeniden açtığında tamamla.

