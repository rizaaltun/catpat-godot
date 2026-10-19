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
