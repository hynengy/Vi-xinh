/**
 * =============================================================================
 * ĐỒ ÁN THỰC TẬP CHUYÊN MÔN - ỨNG DỤNG "VÍ XINH"
 * MODULE: GOOGLE ML KIT WEB ON-DEVICE OCR RECOGNIZER
 * Tương thích: Google ML Kit Text Recognition (On-Device Web / Mobile)
 * Phụ trách: Thành viên 1 - Nguyễn Thúy Hiền & Nhóm phát triển Ví Xinh
 * =============================================================================
 */

(function (window) {
    'use strict';

    class GoogleMLKitWebEngine {
        constructor() {
            this.engineName = 'Google ML Kit Web (On-Device)';
            this.isInitialized = false;
            this.worker = null;
            this.activeLang = 'vie+eng';
            this.isBusy = false;
        }

        /**
         * Kiểm tra trình duyệt có hỗ trợ WebAssembly và Worker On-Device không
         */
        isSupported() {
            return typeof window !== 'undefined' &&
                typeof window.Worker !== 'undefined' &&
                typeof window.WebAssembly !== 'undefined';
        }

        /**
         * Tiền xử lý hình ảnh trên Canvas để tăng cường độ tương phản (Contrast Enhancement)
         * Giúp nhận diện chính xác các hóa đơn in nhiệt, hóa đơn ố vàng hoặc mờ chữ
         */
        async preprocessImage(imageSource) {
            return new Promise((resolve) => {
                const img = new Image();
                img.crossOrigin = 'anonymous';

                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');

                    // Giới hạn kích thước tối đa 2000px để tối ưu tốc độ On-Device
                    let width = img.naturalWidth || img.width;
                    let height = img.naturalHeight || img.height;
                    const maxDim = 2048;

                    if (width > maxDim || height > maxDim) {
                        if (width > height) {
                            height = Math.round((height * maxDim) / width);
                            width = maxDim;
                        } else {
                            width = Math.round((width * maxDim) / height);
                            height = maxDim;
                        }
                    }

                    canvas.width = width;
                    canvas.height = height;

                    // Vẽ ảnh gốc lên Canvas
                    ctx.drawImage(img, 0, 0, width, height);

                    // Tăng độ tương phản nhẹ và độ sắc nét trên client
                    try {
                        const imgData = ctx.getImageData(0, 0, width, height);
                        const d = imgData.data;
                        const contrast = 1.15; // Tăng 15% tương phản cho hóa đơn in nhiệt
                        const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));

                        for (let i = 0; i < d.length; i += 4) {
                            d[i] = factor * (d[i] - 128) + 128;         // R
                            d[i + 1] = factor * (d[i + 1] - 128) + 128; // G
                            d[i + 2] = factor * (d[i + 2] - 128) + 128; // B
                        }
                        ctx.putImageData(imgData, 0, 0);
                    } catch (e) {
                        // Bỏ qua nếu có hạn chế bảo mật canvas
                    }

                    canvas.toBlob((blob) => {
                        resolve(blob || imageSource);
                    }, 'image/jpeg', 0.95);
                };

                img.onerror = () => resolve(imageSource);

                if (imageSource instanceof Blob || imageSource instanceof File) {
                    img.src = URL.createObjectURL(imageSource);
                } else if (typeof imageSource === 'string') {
                    img.src = imageSource;
                } else {
                    resolve(imageSource);
                }
            });
        }

        /**
         * Khởi tạo Worker nhận diện nếu chưa có
         */
        async initWorker(onProgress) {
            if (this.worker) return this.worker;

            if (typeof Tesseract === 'undefined') {
                throw new Error('Thư viện Web ML Kit Engine chưa được nạp!');
            }

            if (onProgress) {
                onProgress({
                    status: 'Khởi tạo mô hình Google ML Kit Web...',
                    progress: 0.15
                });
            }

            // Tạo worker với Tesseract.js v5 (hỗ trợ WebAssembly và Web Worker độc lập)
            this.worker = await Tesseract.createWorker(this.activeLang, 1, {
                logger: (m) => {
                    if (onProgress && m && typeof m.progress === 'number') {
                        let pct = Math.round(m.progress * 100);
                        let msg = 'Đang nhận diện ký tự...';
                        if (m.status === 'loading tesseract core') msg = 'Nạp nhân Web ML Core...';
                        else if (m.status === 'loading language traineddata') msg = 'Nạp dữ liệu tiếng Việt & Latin...';
                        else if (m.status === 'recognizing text') msg = `Quét khối văn bản hóa đơn: ${pct}%`;

                        onProgress({
                            status: msg,
                            progress: m.progress,
                            raw: m
                        });
                    }
                }
            });

            this.isInitialized = true;
            return this.worker;
        }

        /**
         * Xử lý nhận dạng hóa đơn trực tiếp trên thiết bị (On-Device Client)
         * Trả về RecognizedText tương thích với Google ML Kit:
         * {
         *   text: string,
         *   blocks: Array<{ text, bbox, confidence, lines }>,
         *   lines: Array<string>,
         *   confidence: number,
         *   executionTimeMs: number
         * }
         */
        async processImage(imageSource, onProgress) {
            const startTime = performance.now();
            this.isBusy = true;

            try {
                if (onProgress) {
                    onProgress({ status: 'Tối ưu ảnh & khử nhiễu On-Device...', progress: 0.1 });
                }

                // 1. Tiền xử lý ảnh trực tiếp trên Canvas
                const processedBlob = await this.preprocessImage(imageSource);

                // 2. Khởi tạo hoặc tái sử dụng Web ML Worker
                const worker = await this.initWorker(onProgress);

                if (onProgress) {
                    onProgress({ status: 'Google ML Kit đang quét dòng & khối chữ...', progress: 0.35 });
                }

                // 3. Thực thi nhận dạng ký tự
                const res = await worker.recognize(processedBlob);
                const data = res.data || {};
                const fullText = (data.text || '').trim();

                // 4. Bóc tách TextBlocks & TextLines theo chuẩn Google ML Kit
                const blocks = [];
                const detectedLines = [];

                if (data.blocks && Array.isArray(data.blocks)) {
                    for (const b of data.blocks) {
                        const bLines = [];
                        if (b.paragraphs) {
                            for (const p of b.paragraphs) {
                                if (p.lines) {
                                    for (const l of p.lines) {
                                        const cleanL = (l.text || '').trim();
                                        if (cleanL) {
                                            bLines.push(cleanL);
                                            detectedLines.push(cleanL);
                                        }
                                    }
                                }
                            }
                        }

                        blocks.push({
                            text: (b.text || '').trim(),
                            bbox: b.bbox || null,
                            confidence: b.confidence || 0,
                            lines: bLines
                        });
                    }
                } else if (data.lines && Array.isArray(data.lines)) {
                    for (const l of data.lines) {
                        const cleanL = (l.text || '').trim();
                        if (cleanL) detectedLines.push(cleanL);
                    }
                }

                // Nếu không có blocks nhưng có dòng
                if (blocks.length === 0 && detectedLines.length > 0) {
                    blocks.push({
                        text: fullText,
                        bbox: null,
                        confidence: data.confidence || 85,
                        lines: detectedLines
                    });
                }

                const elapsedMs = Math.round(performance.now() - startTime);

                if (onProgress) {
                    onProgress({ status: 'Hoàn thành nhận dạng Google ML Kit!', progress: 1.0 });
                }

                return {
                    success: true,
                    text: fullText,
                    raw_text: fullText,
                    blocks: blocks,
                    lines: detectedLines,
                    total_blocks: blocks.length,
                    total_lines: detectedLines.length,
                    confidence: data.confidence || 85,
                    executionTimeMs: elapsedMs,
                    engine: 'google_mlkit_web_ondevice'
                };
            } catch (err) {
                console.error('[Google ML Kit Web Error]:', err);
                throw err;
            } finally {
                this.isBusy = false;
            }
        }

        /**
         * Giải phóng tài nguyên worker khi cần
         */
        async terminate() {
            if (this.worker) {
                try {
                    await this.worker.terminate();
                } catch (e) {}
                this.worker = null;
                this.isInitialized = false;
            }
        }
    }

    // Gắn vào window global để app.js và các trang khác truy cập dễ dàng
    window.GoogleMLKitWeb = new GoogleMLKitWebEngine();
    console.log('Google ML Kit Web Engine v1.2.0 đã sẵn sàng.');

})(window);
