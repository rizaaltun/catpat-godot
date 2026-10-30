# iOS / Xcode yolu

Teknik seçim: Godot 4 + GDScript. iOS için Java seçilmedi; bu proje native Godot iOS export hattından Xcode projesine aktarılacak. WebView/HTML kabuğu hedeflenmez.

Resmî kaynak: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html (5 Ekim 2026 kontrol edildi).

1. Mac üzerinde projenin uyumlu Godot sürümünü ve aynı sürüm export templates'i kur.
2. Xcode kurulu ve doğru geliştirici araçları seçili olsun.
3. Godot → Project → Export → Add iOS.
4. Kullanıcının gerçek Apple Team ID ve benzersiz bundle identifier değerlerini gir. Bunlar tahmin edilmez; bu teslimde bilerek export preset'e sahte kimlik konulmadı.
5. Boş bir `build/ios` dizinine export et. Xcode projesini açıp imzalama/cihaz hedefini seç.
6. Fiziksel cihazda performans, dokunma, arka plan dönüşü ve kayıt testlerini yap.
7. İkonlar, mağaza ekran görüntüleri, yaş derecelendirmesi, gizlilik beyanı ve ses/görsel haklarını tamamla; sonra TestFlight/App Store akışına geç.

Gün 1'de macOS/Xcode çalıştırılmadı; `.ipa`, imzalı uygulama ve gerçek `.xcodeproj` teslimi yoktur. Godot kaynağı Apple'a gönderilen dosya değildir. Compatibility renderer projenin varsayılanıdır.

## 30 Ekim 2026 — gerçek paket durumu

Kaynak incelemesinde `export_presets.cfg` yalnız **macOS Test** ve **Web Preview** içeriyor. iOS preset, imzalı `.ipa` veya üretilmiş Xcode projesi mevcut kaynakta yok. Web dağıtımı, native iOS paketi veya cihaz kabulü değildir. Mevcut macOS paket adı/versiyon alanları test değerleridir; nihai iOS kimliği gibi kullanılmaz.

[Godot4.4 iOS yönergesi](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_ios.html)30 Ekim'de yeniden kontrol edildi: iOS export işlemi macOS üzerinde Xcode ve uygun Godot export template'lerini gerektirir. Gerçek Apple Team ID ile benzersiz bundle identifier zorunludur. Bu oturumun Linux yürütme ortamında bağlı Mac/Xcode, uygun signing/provisioning erişimi ve fiziksel iOS cihazı doğrulanmış değildir; bu nedenle paket/kurulum/yayın tamamlandı denmez. Eksik kimlikler tahmin edilerek preset'e doldurulmadı.

Kaynak, sanat, web ve motor testleri bu bağımlılıklardan bağımsız sürdürülebilir. Native kapıda yapılacak somut işler: yetkili Mac'te gerçek uygulama kimliğiyle iOS preset oluşturmak, Godot4.4.1 ile eşleşen template'leri kullanmak, Xcode export/build/signing'i doğrulamak, ardından fiziksel cihazda yükleme, dokunmatik, yön/güvenli alan, ses kesintisi, arka plan dönüşü, kayıt ve performansı ölçmek. Mağaza hesabı/materyal/başvuru ayrıca doğrulanır; mevcut sayılmaz.
