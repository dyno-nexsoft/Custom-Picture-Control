import 'dart:io';
import 'package:image/image.dart' as img_lib;
import 'package:archive/archive_io.dart';
import 'package:npc_tools/ncp.dart';

List<double> rgbToHsv(int r, int g, int b) {
  double rd = r / 255.0;
  double gd = g / 255.0;
  double bd = b / 255.0;

  double max = rd;
  if (gd > max) max = gd;
  if (bd > max) max = bd;

  double min = rd;
  if (gd < min) min = gd;
  if (bd < min) min = bd;

  double h = 0.0;
  double s = 0.0;
  double v = max;

  double d = max - min;
  s = max == 0.0 ? 0.0 : d / max;

  if (max != min) {
    if (max == rd) {
      h = (gd - bd) / d + (gd < bd ? 6.0 : 0.0);
    } else if (max == gd) {
      h = (bd - rd) / d + 2.0;
    } else if (max == bd) {
      h = (rd - gd) / d + 4.0;
    }
    h /= 6.0;
  }

  return [h * 360.0, s, v];
}

List<int> hsvToRgb(double h, double s, double v) {
  double hd = h / 360.0;
  int i = (hd * 6.0).floor();
  double f = hd * 6.0 - i;
  double p = v * (1.0 - s);
  double q = v * (1.0 - f * s);
  double t = v * (1.0 - (1.0 - f) * s);

  double r = 0.0;
  double g = 0.0;
  double b = 0.0;

  switch (i % 6) {
    case 0:
      r = v;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v;
      b = p;
      break;
    case 2:
      r = p;
      g = v;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v;
      break;
    case 4:
      r = t;
      g = p;
      b = v;
      break;
    case 5:
      r = v;
      g = p;
      b = q;
      break;
  }

  return [
    (r * 255.0).round().clamp(0, 255),
    (g * 255.0).round().clamp(0, 255),
    (b * 255.0).round().clamp(0, 255),
  ];
}

img_lib.Image createColorChecker() {
  final img = img_lib.Image(width: 800, height: 670);
  // Tô nền màu xám than sang trọng (Charcoal)
  img_lib.fill(img, color: img_lib.ColorRgb8(32, 32, 32));

  final patchColors = [
    // Hàng 1
    [115, 82, 68], [194, 150, 130], [98, 122, 157], [87, 108, 67],
    [129, 128, 174], [103, 189, 170],
    // Hàng 2
    [223, 124, 47], [73, 91, 166], [193, 81, 95], [91, 59, 114], [180, 189, 64],
    [238, 162, 52],
    // Hàng 3
    [35, 63, 147], [67, 149, 74], [175, 46, 53], [231, 189, 52], [187, 82, 149],
    [8, 133, 161],
    // Hàng 4
    [243, 243, 242], [200, 200, 200], [160, 160, 160], [122, 122, 121],
    [85, 85, 85], [52, 52, 52]
  ];

  final patchSize = 100;
  final gap = 16;
  final startX = 60;
  final startY = 40;

  // Vẽ lưới ô màu Macbeth
  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 6; col++) {
      final color = patchColors[row * 6 + col];
      final x = startX + col * (patchSize + gap);
      final y = startY + row * (patchSize + gap);

      // Vẽ viền đen bao quanh ô màu (2px rộng hơn)
      img_lib.fillRect(img,
          x1: x - 2,
          y1: y - 2,
          x2: x + patchSize + 2,
          y2: y + patchSize + 2,
          color: img_lib.ColorRgb8(0, 0, 0));

      // Vẽ ô màu chính
      img_lib.fillRect(img,
          x1: x,
          y1: y,
          x2: x + patchSize,
          y2: y + patchSize,
          color: img_lib.ColorRgb8(color[0], color[1], color[2]));
    }
  }

  // Vẽ 4 thanh dải màu chuyển (Gradients) ở bên dưới
  final gradStartX = 60;
  final gradWidth = 680;
  final gradHeight = 18;

  final gradConfigs = [
    // [yStart, isGrayscale, isRed, isGreen, isBlue]
    [520, true, false, false, false],
    [548, false, true, false, false],
    [576, false, false, true, false],
    [604, false, false, false, true]
  ];

  for (final config in gradConfigs) {
    final yStart = config[0] as int;
    final yEnd = yStart + gradHeight;

    // Vẽ viền đen 2px bao quanh thanh gradient
    img_lib.fillRect(img,
        x1: gradStartX - 2,
        y1: yStart - 2,
        x2: gradStartX + gradWidth + 2,
        y2: yEnd + 2,
        color: img_lib.ColorRgb8(0, 0, 0));

    // Vẽ thanh màu chuyển sắc từng pixel dọc theo chiều rộng
    for (int dx = 0; dx < gradWidth; dx++) {
      final val = (dx * 255 ~/ (gradWidth - 1)).clamp(0, 255);
      final r = (config[1] as bool || config[2] as bool) ? val : 0;
      final g = (config[1] as bool || config[3] as bool) ? val : 0;
      final b = (config[1] as bool || config[4] as bool) ? val : 0;

      img_lib.fillRect(img,
          x1: gradStartX + dx,
          y1: yStart,
          x2: gradStartX + dx,
          y2: yEnd,
          color: img_lib.ColorRgb8(r, g, b));
    }
  }

  return img;
}

img_lib.Image applyNcpToImage(img_lib.Image source, NcpFile ncp) {
  final output = source.clone();

  final double sFactor = 1.0 + 0.15 * (ncp.saturation - 128);
  final double hShift = 3.0 * (ncp.hue - 128);

  for (final pixel in output) {
    int r = pixel.r.toInt();
    int g = pixel.g.toInt();
    int b = pixel.b.toInt();

    // 1. Áp dụng bảng tra cứu LUT (Luminance mapping)
    int rLut = (ncp.lut[r] * 255 ~/ 32767).clamp(0, 255);
    int gLut = (ncp.lut[g] * 255 ~/ 32767).clamp(0, 255);
    int bLut = (ncp.lut[b] * 255 ~/ 32767).clamp(0, 255);

    // 2. Áp dụng Saturation (độ bão hòa màu)
    final double y = 0.299 * rLut + 0.587 * gLut + 0.114 * bLut;
    int rSat = (y + sFactor * (rLut - y)).round().clamp(0, 255);
    int gSat = (y + sFactor * (gLut - y)).round().clamp(0, 255);
    int bSat = (y + sFactor * (bLut - y)).round().clamp(0, 255);

    // 3. Áp dụng Hue shift (xoay vòng màu sắc)
    if (hShift != 0.0) {
      final hsv = rgbToHsv(rSat, gSat, bSat);
      double newH = (hsv[0] + hShift) % 360.0;
      if (newH < 0) newH += 360.0;
      final rgb = hsvToRgb(newH, hsv[1], hsv[2]);
      rSat = rgb[0];
      gSat = rgb[1];
      bSat = rgb[2];
    }

    // 4. Monochrome Filter & Toning (nếu là Monochrome)
    if (ncp.baseProfileId == 0x064D) {
      // Chuyển ảnh về đen trắng (grayscale) dựa trên kính lọc màu
      double mono;
      if (ncp.filter == 1) {
        // YELLOW
        mono = 0.35 * rSat + 0.55 * gSat + 0.10 * bSat;
      } else if (ncp.filter == 2) {
        // ORANGE
        mono = 0.45 * rSat + 0.50 * gSat + 0.05 * bSat;
      } else if (ncp.filter == 3) {
        // RED
        mono = 0.65 * rSat + 0.30 * gSat + 0.05 * bSat;
      } else if (ncp.filter == 4) {
        // GREEN
        mono = 0.20 * rSat + 0.70 * gSat + 0.10 * bSat;
      } else {
        // OFF hoặc khác
        mono = 0.299 * rSat + 0.587 * gSat + 0.114 * bSat;
      }

      int gray = mono.round().clamp(0, 255);

      // Áp dụng Toning màu nếu được bật
      if (ncp.toning != 0xFF && ncp.toning != 0) {
        // Nhuộm tông màu đơn sắc
        // Toning: 1 = Sepia (nâu đỏ), 2 = Cyanotype (xanh lục), ...
        double tr = 1.0, tg = 1.0, tb = 1.0;
        if (ncp.toning == 1) {
          // SEPIA
          tr = 1.15;
          tg = 1.0;
          tb = 0.85;
        } else if (ncp.toning == 2) {
          // CYANOTYPE
          tr = 0.85;
          tg = 1.0;
          tb = 1.15;
        }

        final double str =
            ncp.toningStrength / 4.0; // Toning strength từ 0 đến 4
        rSat = (gray + (gray * (tr - 1.0)) * str).round().clamp(0, 255);
        gSat = (gray + (gray * (tg - 1.0)) * str).round().clamp(0, 255);
        bSat = (gray + (gray * (tb - 1.0)) * str).round().clamp(0, 255);
      } else {
        rSat = gSat = bSat = gray;
      }
    }

    pixel.r = rSat;
    pixel.g = gSat;
    pixel.b = bSat;
  }

  return output;
}

void writeProfile(NcpFile ncp, String baseName, int blackOffset) {
  ncp.generateLut(blackOffset);
  final bytes = ncp.toBytes();

  Directory('CUSTOMPC').createSync(recursive: true);
  Directory('previews').createSync(recursive: true);

  // Tạo ảnh ColorChecker gốc dạng JPEG chất lượng cao nếu chưa tồn tại
  final origFile = File('previews/colorchecker_original.jpg');
  late img_lib.Image originalImage;
  if (!origFile.existsSync()) {
    originalImage = createColorChecker();
    origFile.writeAsBytesSync(img_lib.encodeJpg(originalImage, quality: 95));
    print("Đã tạo tệp tin ColorChecker gốc: ${origFile.path}");
  } else {
    originalImage = img_lib.decodeJpg(origFile.readAsBytesSync())!;
  }

  // Áp dụng bộ lọc và lưu ảnh xem trước
  final previewImage = applyNcpToImage(originalImage, ncp);
  final previewFile = File('previews/$baseName.jpg');
  previewFile.writeAsBytesSync(img_lib.encodeJpg(previewImage, quality: 95));
  print("Đã tạo hình ảnh xem trước: ${previewFile.path}");

  // Lưu file NCP vào thư mục CUSTOMPC
  final ncpFile = File('CUSTOMPC/$baseName.NCP');
  ncpFile.writeAsBytesSync(bytes);
  print("Đã tạo tệp tin Picture Control: ${ncpFile.path}");
  print("------------------------------------------------------------");
}

void createZipArchive() {
  print("=============================================================");
  print(" ĐANG TẠO TỆP TIN ZIP: CUSTOMPC.zip");
  print("=============================================================");
  try {
    final encoder = ZipFileEncoder();
    encoder.create('CUSTOMPC.zip');
    encoder.addDirectory(Directory('CUSTOMPC'));
    encoder.close();
    print("Đã tạo thành công file: CUSTOMPC.zip");
  } catch (e) {
    print("Lỗi khi tạo file zip: $e");
  }
}

void main() {
  print("=============================================================");
  print(" BẮT ĐẦU TẠO CÁC BỘ LỌC MÀU CHUYÊN BIỆT (NIKON PICTURE CONTROL)");
  print("=============================================================\n");

  // 1. BEACH_PORTRAIT: Chân dung đi biển
  // - Base Profile: PORTRAIT (0x0486)
  // - Sharpening: +3 (độ nét vừa phải cho chân dung da dẻ hồng hào)
  // - Contrast & Brightness: Custom Curve (kéo sáng shadow để giảm tương phản gắt dưới nắng biển)
  // - Saturation: +1 (tăng nhẹ độ bão hòa màu trời xanh và cát ấm)
  // - Curve: Nâng nhẹ vùng tối (giúp mặt sáng đều), nén bớt vùng cháy sáng (highlight)
  final beachPortrait = NcpFile()
    ..name = "Beach Portrait"
    ..baseProfileId = 0x0486
    ..sharpening = 131 // 128 + 3
    ..saturation = 129 // 128 + 1
    ..curvePoints = [
      CurvePoint(
        input: 0,
        output: 8,
      ), // Nâng nhẹ điểm đen để tối sáng hơn, không bị bết
      CurvePoint(
        input: 50,
        output: 56,
      ), // Làm sáng vùng trung tính tối (shadows)
      CurvePoint(input: 128, output: 135), // Làm sáng nhẹ da (midtones)
      CurvePoint(
        input: 200,
        output: 195,
      ), // Hạ nhẹ vùng sáng mạnh (highlights) để tránh cháy cát/nước
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(beachPortrait, "BEACH_PORTRAIT", 120);

  // 2. MOUNTAIN_SEA: Đi check-in núi biển (Phong cảnh sắc nét, trong trẻo)
  // - Base Profile: LANDSCAPE (0x04C7)
  // - Sharpening: +5 (tối đa chi tiết cây cối, sóng nước, vách đá)
  // - Contrast & Brightness: Custom Curve (đường cong S-curve tương phản cao)
  // - Saturation: +2 (độ rực rỡ cao cho rừng núi xanh lá và đại dương xanh dương)
  // - Curve: Tăng độ tương phản bằng cách kéo sâu shadow và kích sáng highlight
  final mountainSea = NcpFile()
    ..name = "Mountain Sea"
    ..baseProfileId = 0x04C7
    ..sharpening = 133 // 128 + 5
    ..saturation = 130 // 128 + 2
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(
        input: 64,
        output: 50,
      ), // Kéo sâu vùng tối tạo độ nổi khối (contrast)
      CurvePoint(input: 128, output: 128),
      CurvePoint(
        input: 192,
        output: 210,
      ), // Kích sáng vùng trời mây tạo độ trong trẻo (clear sky)
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(mountainSea, "MOUNTAIN_SEA", 60);

  // 3. VINTAGE_LOOK: Màu ảnh phim hoài cổ (Matte shadow, màu hơi úa nhẹ cổ điển)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +1 (mềm mại như chụp phim cổ)
  // - Contrast & Brightness: Custom Curve
  // - Saturation: -2 (Màu nhạt đặc trưng của phim cũ)
  // - Hue: +1 (hơi nghiêng tone vàng ấm)
  // - Curve: Nâng cực mạnh điểm đen tạo lớp phủ mờ (matte/faded shadow), nén chặt vùng sáng
  final vintageLook = NcpFile()
    ..name = "Vintage Look"
    ..baseProfileId = 0x03C2
    ..sharpening = 129 // 128 + 1
    ..saturation = 126 // 128 - 2
    ..hue = 129 // 128 + 1 (hơi ngả tone vàng ấm cổ điển)
    ..curvePoints = [
      CurvePoint(
        input: 0,
        output: 25,
      ), // Nâng điểm đen cực cao tạo hiệu ứng sương mù/matte film
      CurvePoint(input: 64, output: 75), // Phẳng hóa vùng tối trung tính
      CurvePoint(input: 128, output: 128),
      CurvePoint(input: 192, output: 180), // Nén vùng highlight tạo sự dịu mắt
      CurvePoint(
        input: 255,
        output: 245,
      ), // Hạ điểm trắng tối đa tránh chói lóa
    ];
  writeProfile(vintageLook, "VINTAGE_LOOK", 160);

  // 4. CINE_LOOK: Màu phim điện ảnh Cine (Teal & Orange)
  // - Base Profile: STANDARD (0x0001)
  // - Sharpening: +3 (độ nét tốt)
  // - Contrast & Brightness: Custom Curve
  // - Saturation: +1 (màu rực rỡ điện ảnh)
  // - Hue: +2 (dịch tông màu đỏ sang cam ấm và cyan sang xanh teal)
  // - Curve: S-curve có nâng nhẹ điểm đen (shadow lift) tạo nước ảnh điện ảnh trong trẻo
  final cineLook = NcpFile()
    ..name = "Cine Look"
    ..baseProfileId = 0x0001
    ..sharpening = 131 // 128 + 3
    ..saturation = 129 // 128 + 1
    ..hue = 130 // 128 + 2 (tạo hiệu ứng chuyển đổi màu cam - teal rõ rệt hơn)
    ..curvePoints = [
      CurvePoint(
        input: 0,
        output: 10,
      ), // Nâng nhẹ điểm đen tạo hiệu ứng mờ tối nhẹ
      CurvePoint(input: 60, output: 50), // Nén nhẹ vùng tối trung tính
      CurvePoint(input: 128, output: 130), // Đẩy sáng trung tính vùng da
      CurvePoint(
        input: 195,
        output: 215,
      ), // Kích sáng vùng highlight tạo độ tương phản trong vắt
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(cineLook, "CINE_LOOK", 100);

  // 5. CLASSIC_CHROME: Màu phim Fujifilm cổ điển (Classic Chrome)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +2 (độ sắc nét vừa phải)
  // - Saturation: -1 (màu trầm ấm, giảm bão hòa nhẹ)
  // - Curve: S-curve mạnh, vùng highlight và shadow nén chặt tạo độ sâu hình ảnh
  final classicChrome = NcpFile()
    ..name = "Classic Chrome"
    ..baseProfileId = 0x03C2
    ..sharpening = 130 // 128 + 2
    ..saturation = 127 // 128 - 1
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(
        input: 64,
        output: 52,
      ), // Dìm sâu shadow để tạo độ tương phản cao ở vùng tối
      CurvePoint(
        input: 128,
        output: 122,
      ), // Kéo nhẹ midtone xuống một chút để tạo sự trầm lắng
      CurvePoint(input: 192, output: 205), // Đẩy highlight cao lên
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(classicChrome, "CLASSIC_CHROME", 110);

  // 6. STREET_MONO: Trắng đen tương phản cao (Street Monochrome)
  // - Base Profile: MONOCHROME (0x064D)
  // - Sharpening: +4 (độ sắc nét cực cao)
  // - Filter: RED (0x03) (Kính lọc đỏ: dìm tối bầu trời xanh cực mạnh, tăng tương phản mây trắng và mặt)
  // - Toning: B/W (0x00)
  // - Curve: S-curve cực gắt tạo độ đen sâu thẳm và trắng cháy sáng cho ảnh đen trắng đường phố nghệ thuật
  final streetMono = NcpFile()
    ..name = "Street Mono"
    ..baseProfileId = 0x064D
    ..sharpening = 132 // 128 + 4
    ..filter = 3 // RED filter
    ..toning = 0 // B/W style
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 50, output: 25), // Ép shadows cực sâu (crush blacks)
      CurvePoint(input: 128, output: 128),
      CurvePoint(
        input: 200,
        output: 230,
      ), // Kéo highlights cực sáng tạo tương phản mạnh
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(streetMono, "STREET_MONO", 40);

  // 8. KP160 (Clear Negative - Kodak Portra 160 Emulation)
  // - Base Profile: PORTRAIT (0x0486)
  // - Sharpening: +2 (mềm mại, da hồng hào tự nhiên)
  // - Saturation: -1 (màu pastel nhẹ nhàng, thanh lịch)
  // - Curve: Lift shadow nhẹ, nén sáng (airy look)
  final kp160 = NcpFile()
    ..name = "Clear Neg KP160"
    ..baseProfileId = 0x0486
    ..sharpening = 130
    ..saturation = 127
    ..curvePoints = [
      CurvePoint(input: 0, output: 6), // Lift nhẹ điểm đen
      CurvePoint(input: 64, output: 68), // Làm sáng nhẹ vùng tối
      CurvePoint(input: 128, output: 133), // Midtone sáng trong trẻo
      CurvePoint(input: 192, output: 190), // Nén nhẹ vùng highlight
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(kp160, "KP160_CLEAR_NEG", 115);

  // 9. KE100 (Rich Negative - Kodak Ektar 100 Emulation)
  // - Base Profile: VIVID (0x00C3)
  // - Sharpening: +4 (sắc nét, gai góc)
  // - Saturation: +3 (màu cực kỳ rực rỡ, đỏ và xanh biển rực mạnh)
  // - Curve: S-curve mạnh cho tương phản gắt gao, rực rỡ phong cảnh
  final ke100 = NcpFile()
    ..name = "Rich Neg KE100"
    ..baseProfileId = 0x00C3
    ..sharpening = 132
    ..saturation = 131
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 50, output: 35), // Dìm tối mạnh vùng shadow
      CurvePoint(input: 128, output: 128),
      CurvePoint(input: 192, output: 215), // Tăng sáng mạnh vùng highlight
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(ke100, "KE100_RICH_NEG", 60);

  // 10. KG200 (Warm Negative - Kodak Gold 200 Emulation)
  // - Base Profile: STANDARD (0x0001)
  // - Sharpening: +2
  // - Saturation: +1 (ấm áp)
  // - Hue: -2 (tone màu vàng ấm cổ điển)
  // - Curve: Midtone ấm, chuyển vùng mượt mà
  final kg200 = NcpFile()
    ..name = "Warm Neg KG200"
    ..baseProfileId = 0x0001
    ..sharpening = 130
    ..saturation = 129
    ..hue = 126 // 128 - 2 (lệch tone ấm)
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 64, output: 58),
      CurvePoint(input: 128, output: 130), // Nâng nhẹ vùng trung tính ấm
      CurvePoint(input: 192, output: 196),
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(kg200, "KG200_WARM_NEG", 100);

  // 11. NC100 (Classic Negative - Fujifilm Superia Emulation)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +3
  // - Saturation: -1 (màu trầm, lạnh ở vùng shadow)
  // - Curve: Shadows cực sâu kết hợp highlight nổi bật
  final nc100 = NcpFile()
    ..name = "Classic Neg NC100"
    ..baseProfileId = 0x03C2
    ..sharpening = 131
    ..saturation = 127
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 50, output: 36), // Ép shadow sâu tạo khối sắc sảo
      CurvePoint(input: 128, output: 125), // Dìm nhẹ lower-midtones
      CurvePoint(input: 192, output: 206), // Đẩy highlight cao sáng rõ
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(nc100, "NC100_CLASSIC_NEG", 90);

  // 12. CC200 (Classic Positive - Fujifilm Chrome Emulation)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +3
  // - Saturation: -2 (Màu lặng, ít rực rỡ nhưng chiều sâu lớn)
  // - Curve: S-curve trầm mặc
  final cc200 = NcpFile()
    ..name = "Classic Pos CC200"
    ..baseProfileId = 0x03C2
    ..sharpening = 131
    ..saturation = 126
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 64, output: 52),
      CurvePoint(
        input: 128,
        output: 120,
      ), // Dìm sáng midtone cho ảnh đậm chất trầm mặc
      CurvePoint(input: 192, output: 200),
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(cc200, "CC200_CLASSIC_POS", 110);

  // 13. NN400 (Nostalgic Negative - Fujifilm Nostalgic Neg)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +2
  // - Saturation: +0
  // - Hue: -1 (ngả vàng hổ phách nhẹ)
  // - Curve: Điểm đen nâng cao (matte look), nén trắng tạo sắc hổ phách vàng ấm vùng sáng
  final nn400 = NcpFile()
    ..name = "Nostalgic Neg NN400"
    ..baseProfileId = 0x03C2
    ..sharpening = 130
    ..hue = 127 // 128 - 1 (vàng ấm)
    ..curvePoints = [
      CurvePoint(input: 0, output: 14), // Matte shadow nhẹ nhàng
      CurvePoint(input: 64, output: 70), // Làm mềm vùng tối trung tính
      CurvePoint(input: 128, output: 130), // Nâng nhẹ midtone tạo nước ảnh ấm
      CurvePoint(
        input: 192,
        output: 188,
      ), // Nén vùng highlight tạo sắc hổ phách cổ
      CurvePoint(input: 255, output: 250), // Hạ nhẹ điểm trắng tối đa
    ];
  writeProfile(nn400, "NN400_NOSTALGIC_NEG", 130);

  // Tạo file zip cho thư mục CUSTOMPC
  createZipArchive();

  print("TẤT CẢ CÁC FILE ĐÃ ĐƯỢC TẠO THÀNH CÔNG!");
}
