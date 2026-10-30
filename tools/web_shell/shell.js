/* Catpat web presentation. Godot owns gameplay and saved state. */
(function () {
    'use strict';
    const canvas = document.getElementById('canvas');
    const viewport = document.getElementById('game-viewport');
    const loading = document.getElementById('loading-panel');
    const orientation = document.getElementById('orientation-panel');
    const errorPanel = document.getElementById('error-panel');
    const progress = document.getElementById('loading-progress');
    const orientationDetail = document.getElementById('orientation-detail');
    const errorTitle = document.getElementById('error-title');
    const errorMessage = document.getElementById('error-message');
    const technical = document.getElementById('error-technical');
    const retry = document.getElementById('retry-button');
    const coarsePointer = window.matchMedia('(pointer: coarse)');
    let phase = 'loading';
    let engine = null;
    let starting = false;
    let started = false;
    let rotationBlocked = false;

    function needsLandscape() {
        return coarsePointer.matches && window.innerHeight > window.innerWidth;
    }
    function releaseAndPause() {
        // Godot4.4.1 listens to canvas blur for WM focus-out and window blur for
        // release_pressed_events. The shared Experience bridge must normalize
        // WM focus-out to the chapter's existing application-pause notification.
        canvas.blur();
        window.dispatchEvent(new Event('blur'));
    }
    function showPanels() {
        const failed = phase === 'error' || phase === 'exited';
        const covered = failed || rotationBlocked || phase === 'loading';
        errorPanel.hidden = !failed;
        orientation.hidden = failed || !rotationBlocked;
        loading.hidden = failed || rotationBlocked || phase !== 'loading';
        canvas.style.pointerEvents = covered ? 'none' : 'auto';
        canvas.tabIndex = covered ? -1 : 0;
        canvas.setAttribute('aria-hidden', covered ? 'true' : 'false');
    }
    function failure(error, message, title) {
        console.error(error);
        phase = 'error';
        errorTitle.textContent = title || 'Oyunu açamadık';
        errorMessage.textContent = message || 'Bu tarayıcıda oyun başlatılamadı. Yeniden deneyebilirsin.';
        technical.textContent = error && error.message ? error.message : String(error || 'Bilinmeyen başlatma hatası');
        if (started) releaseAndPause();
        showPanels();
    }
    function fitCanvas() {
        // The viewport's CSS inset already excludes each safe-area edge. Keep the
        // gameplay16:9 inside it; never move a touch target beneath a device cutout.
        const bounds = viewport.getBoundingClientRect();
        const width = Math.max(1, Math.floor(Math.min(bounds.width, bounds.height * 16 / 9)));
        const height = Math.max(1, Math.floor(width * 9 / 16));
        const ratio = Math.min(2, window.devicePixelRatio || 1);
        const pixelsW = Math.max(1, Math.round(width * ratio));
        const pixelsH = Math.max(1, Math.round(height * ratio));
        const changed = canvas.width !== pixelsW || canvas.height !== pixelsH;
        if (changed && started) releaseAndPause();
        canvas.style.width = width + 'px';
        canvas.style.height = height + 'px';
        if (changed) {
            canvas.width = pixelsW;
            canvas.height = pixelsH;
        }
    }
    function updateOrientation() {
        const next = needsLandscape();
        if (next && !rotationBlocked && started) releaseAndPause();
        rotationBlocked = next;
        orientationDetail.textContent = started
            ? 'Yatay çevirince oyun içinden devam edebilirsin.'
            : 'Yatay olduğunda yolculuğun açılacak.';
        fitCanvas();
        showPanels();
        if (!rotationBlocked && phase !== 'error' && phase !== 'exited') {
            if (!starting && !started) startGame();
            else if (started) canvas.focus();
        }
    }
    function onProgress(current, total) {
        progress.textContent = current > 0 && total > 0
            ? 'Yükleniyor · %' + Math.min(100, Math.floor(current * 100 / total))
            : 'Oyun dosyaları yükleniyor…';
    }
    function startGame() {
        if (starting || started || rotationBlocked || phase === 'error') return;
        starting = true;
        const config = Object.assign({}, GODOT_CONFIG, {
            canvas: canvas,
            canvasResizePolicy: 0,
            focusCanvas: false
        });
        try {
            engine = new Engine(config);
            Promise.resolve(engine.startGame({
                onProgress: onProgress,
                onPrintError: function () {
                    const message = Array.from(arguments).join(' ');
                    if (/SCRIPT ERROR:|Parse Error:|No loader found for resource:|Failed to load script/.test(message)) {
                        failure(message, 'Oyun ekranı hazırlanırken bir sorun oluştu. Yeniden deneyebilirsin.', 'Bir sorunla karşılaştık');
                    } else {
                        console.error(message);
                    }
                },
                onExit: function (code) {
                    if (phase === 'error') return;
                    if (code !== 0) {
                        failure('Godot çıkış kodu: ' + code, 'Oyun beklenmedik biçimde kapandı. Yeniden açabilirsin.');
                        return;
                    }
                    phase = 'exited';
                    errorTitle.textContent = 'Yolculuğa ara verdik';
                    errorMessage.textContent = 'Hazır olduğunda oyunu yeniden açabilirsin.';
                    technical.textContent = 'Oyun normal biçimde kapandı.';
                    showPanels();
                }
            })).then(function () {
                started = true;
                starting = false;
                if (phase !== 'error' && phase !== 'exited') phase = 'playing';
                // Startup can finish while a device is being rotated. It must
                // still receive focus-out and remain behind the rotation card.
                if (needsLandscape() || phase === 'error' || phase === 'exited') releaseAndPause();
                updateOrientation();
            }, function (err) {
                starting = false;
                failure(err, 'Oyun dosyaları yüklenemedi veya başlatılamadı. Bağlantını kontrol edip yeniden deneyebilirsin.');
            });
        } catch (err) {
            starting = false;
            failure(err);
        }
    }
    retry.addEventListener('click', function () { window.location.reload(); });
    window.addEventListener('resize', updateOrientation);
    window.addEventListener('orientationchange', updateOrientation);
    if (window.visualViewport) window.visualViewport.addEventListener('resize', updateOrientation);
    if (coarsePointer.addEventListener) coarsePointer.addEventListener('change', updateOrientation);
    document.addEventListener('visibilitychange', function () {
        if (document.hidden && started) releaseAndPause();
    });
    canvas.addEventListener('webglcontextlost', function () {
        failure('WebGL context lost', 'Görüntü bağlantısı kesildi. Oyunu yeniden açabilirsin.');
    });
    fitCanvas();
    try {
        if (typeof Engine === 'undefined') {
            failure('Godot JavaScript loader could not be loaded', 'Oyun başlatıcısı yüklenemedi. Bağlantını kontrol edip yeniden deneyebilirsin.');
            return;
        }
        const missing = Engine.getMissingFeatures({ threads: GODOT_THREADS_ENABLED });
        if (missing.length) {
            failure(missing.join('\n'), 'Bu tarayıcı oyunun gerektirdiği özellikleri sağlayamadı:\n' + missing.join('\n'), 'Bu tarayıcıda oyun açılamadı');
            return;
        }
        updateOrientation();
    } catch (err) {
        failure(err);
    }
}());
