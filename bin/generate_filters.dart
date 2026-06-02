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
  Directory('doc').createSync(recursive: true);

  // Tạo ảnh ColorChecker gốc dạng JPEG chất lượng cao nếu chưa tồn tại
  final origFile = File('doc/colorchecker_original.jpg');
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
  final previewFile = File('doc/$baseName.jpg');
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

  // 1. KP160 (Clear Negative - Kodak Portra 160 Emulation)
  // - Base Profile: PORTRAIT (0x0486)
  // - Sharpening: +2 (mềm mại, da hồng hào tự nhiên)
  // - Saturation: -3 (màu pastel dịu nhẹ, ít rực rỡ)
  // - Hue: +2 (lệch tone xanh mint lạnh và da hồng tự nhiên)
  // - Curve: Lift shadow mạnh tạo nước ảnh airy film bay bổng
  final kp160 = NcpFile()
    ..name = "Clear Neg KP160"
    ..baseProfileId = 0x0486
    ..sharpening = 130
    ..saturation = 125 // 128 - 3
    ..hue = 130 // 128 + 2
    ..curvePoints = [
      CurvePoint(
          input: 0, output: 12), // Lift mạnh điểm đen tạo hiệu ứng mờ sương
      CurvePoint(input: 64, output: 74), // Làm sáng mạnh shadow
      CurvePoint(
          input: 128, output: 138), // Làm sáng vùng da (midtones) trong trẻo
      CurvePoint(input: 192, output: 195), // Nén highlights dịu mắt
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(kp160, "KP160_CLEAR_NEG", 115);

  // 2. KE100 (Rich Negative - Kodak Ektar 100 Emulation)
  // - Base Profile: VIVID (0x00C3)
  // - Sharpening: +4 (sắc nét, gai góc)
  // - Saturation: +4 (màu rực rỡ đậm đà)
  // - Hue: -1 (hơi lệch tone đỏ ấm áp)
  // - Curve: S-curve gắt tạo độ sâu bóng tối lạnh và highlight rực rỡ
  final ke100 = NcpFile()
    ..name = "Rich Neg KE100"
    ..baseProfileId = 0x00C3
    ..sharpening = 132
    ..saturation = 132 // 128 + 4
    ..hue = 127 // 128 - 1
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(
          input: 64, output: 45), // Dìm cực sâu vùng shadow tạo khối bóng
      CurvePoint(
          input: 128, output: 122), // Dìm nhẹ lower-midtones tạo chiều sâu màu
      CurvePoint(
          input: 192,
          output: 218), // Kéo sáng mạnh highlight tạo độ tương phản cao
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(ke100, "KE100_RICH_NEG", 60);

  // 3. KG200 (Warm Negative - Kodak Gold 200 Emulation)
  // - Base Profile: STANDARD (0x0001)
  // - Sharpening: +2
  // - Saturation: +2 (màu nắng rực rỡ)
  // - Hue: -3 (ngả tone ấm màu vàng hổ phách rất mạnh)
  // - Curve: Nâng nhẹ shadow và sáng dịu tạo cảm giác nắng ấm áp hoài cổ
  final kg200 = NcpFile()
    ..name = "Warm Neg KG200"
    ..baseProfileId = 0x0001
    ..sharpening = 130
    ..saturation = 130 // 128 + 2
    ..hue = 125 // 128 - 3
    ..curvePoints = [
      CurvePoint(
          input: 0, output: 4), // Nâng nhẹ điểm tối để shadow bớt bết đen
      CurvePoint(input: 64, output: 56), // Dìm shadow nhẹ
      CurvePoint(
          input: 128,
          output: 132), // Nâng midtone tạo cảm giác nắng ấm tràn ngập
      CurvePoint(input: 192, output: 194),
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(kg200, "KG200_WARM_NEG", 100);

  // 4. NC100 (Classic Negative - Fujifilm Superia Emulation)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +3
  // - Saturation: -2 (màu lặng trầm mặc đặc trưng)
  // - Hue: +1 (tone màu xanh lục hơi lạnh ở vùng shadow)
  // - Curve: Đường tương phản sâu kết hợp highlight nổi bật
  final nc100 = NcpFile()
    ..name = "Classic Neg NC100"
    ..baseProfileId = 0x03C2
    ..sharpening = 131
    ..saturation = 126 // 128 - 2
    ..hue = 129 // 128 + 1
    ..curvePoints = [
      CurvePoint(input: 0, output: 2), // Lift đen cực nhẹ
      CurvePoint(input: 50, output: 34), // Ép shadow sâu tạo tương phản đậm nét
      CurvePoint(input: 128, output: 122), // Dìm midtone tạo vẻ trầm lắng
      CurvePoint(input: 192, output: 210), // Kéo sáng vùng highlight nổi bật
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(nc100, "NC100_CLASSIC_NEG", 90);

  // 5. CC200 (Classic Positive - Fujifilm Chrome Emulation)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +3
  // - Saturation: -4 (độ bão hòa cực thấp cho phong cách phim trong trẻo)
  // - Hue: +3 (xoay tone tạo bầu trời xanh cyan/lạnh trong vắt)
  // - Curve: S-curve nhẹ trong suốt, trung tính và mượt mà
  final cc200 = NcpFile()
    ..name = "Classic Pos CC200"
    ..baseProfileId = 0x03C2
    ..sharpening = 131
    ..saturation = 124 // 128 - 4
    ..hue = 131 // 128 + 3
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 64, output: 48), // Dìm shadow nhẹ tạo khối sắc nét
      CurvePoint(input: 128, output: 126), // Midtones trung tính trong suốt
      CurvePoint(input: 192, output: 208), // Highlights sáng trong vắt sạch sẽ
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(cc200, "CC200_CLASSIC_POS", 110);

  // 6. NN400 (Nostalgic Negative - Fujifilm Nostalgic Neg)
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +2
  // - Saturation: +0
  // - Hue: -2 (ngả vàng/nâu hổ phách đậm chất hoài cổ)
  // - Curve: Nâng điểm đen cực cao (matte look), nén highlights tạo sắc hổ phách cổ kính
  final nn400 = NcpFile()
    ..name = "Nostalgic Neg NN400"
    ..baseProfileId = 0x03C2
    ..sharpening = 130
    ..saturation = 128
    ..hue = 126 // 128 - 2
    ..curvePoints = [
      CurvePoint(
          input: 0,
          output: 16), // Nâng shadow cực cao tạo lớp phủ mờ đục cổ điển
      CurvePoint(input: 64, output: 72), // Làm mềm vùng tối trung tính
      CurvePoint(input: 128, output: 130), // Midtone trầm ấm màu trà cổ
      CurvePoint(
          input: 192, output: 185), // Nén highlights rất phẳng tránh chói
      CurvePoint(
          input: 255,
          output: 245), // Hạ mạnh điểm trắng tối đa tạo tone hổ phách ấm
    ];
  writeProfile(nn400, "NN400_NOSTALGIC_NEG", 130);

  // 7. HARCOURT_VIBRANT (Harcourt Vibrant Studio - Luminous & Vivid Portrait Style)
  // - Base Profile: PORTRAIT (0x0486)
  // - Sharpening: +4 (làm rõ nét chi tiết và vân da)
  // - Saturation: +2 (màu sắc sinh động, rực rỡ nhưng tự nhiên)
  // - Curve: Nâng sáng mạnh midtone và highlights để tạo vẻ rực rỡ, phát sáng (radiant/luminous look)
  final harcourtVibrant = NcpFile()
    ..name = "Harcourt Vibrant"
    ..baseProfileId = 0x0486
    ..sharpening = 132
    ..saturation = 130 // 128 + 2
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 50, output: 42), // Shadow sâu vừa phải
      CurvePoint(input: 128, output: 134), // Đẩy sáng vùng da (midtones)
      CurvePoint(
          input: 195,
          output: 215), // Tăng độ phát sáng vùng highlight (luminous)
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(harcourtVibrant, "HARCOURT_VIBRANT", 90);

  // 8. HARCOURT_CLASSIC (Harcourt Classic Studio - Dramatic Black & White Style)
  // - Base Profile: MONOCHROME (0x064D)
  // - Sharpening: +5 (độ sắc nét cực cao làm nổi bật vân da và khối cơ mặt)
  // - Filter: OFF (Kính lọc màu: Tắt)
  // - Toning: B/W (0x00) (Đen trắng chuẩn nghệ thuật)
  // - Curve: Độ tương phản cực gắt, dìm sâu shadow tạo nền đen và đẩy sáng highlight tạo hiệu ứng ánh sáng spotlight
  final harcourtClassic = NcpFile()
    ..name = "Harcourt Classic"
    ..baseProfileId = 0x064D
    ..sharpening = 133
    ..filter = 0
    ..toning = 0
    ..curvePoints = [
      CurvePoint(input: 0, output: 0),
      CurvePoint(input: 40, output: 16), // Crush shadow sâu để dìm nền tối
      CurvePoint(input: 128, output: 120), // Giữ midtone trầm
      CurvePoint(
          input: 180,
          output:
              220), // Kích sáng cực mạnh highlight tạo độ tương phản spotlight nghệ thuật
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(harcourtClassic, "HARCOURT_CLASSIC", 30);

  // 9. HARCOURT_COLOUR (Harcourt Colour Studio - Muted & Warm Soft Glow Style)
  // - Base Profile: PORTRAIT (0x0486)
  // - Sharpening: +1 (mềm mại, giảm gai góc)
  // - Saturation: -3 (màu lặng hoài cổ)
  // - Hue: -2 (tone màu vàng ấm áp tinh tế)
  // - Curve: Lift nhẹ shadow và nén highlights tạo hiệu ứng soft glow dịu nhẹ mướt mắt
  final harcourtColour = NcpFile()
    ..name = "Harcourt Colour"
    ..baseProfileId = 0x0486
    ..sharpening = 129
    ..saturation = 125 // 128 - 3
    ..hue = 126 // 128 - 2
    ..curvePoints = [
      CurvePoint(input: 0, output: 10), // Lift nhẹ đen tạo hiệu ứng mờ mịn
      CurvePoint(input: 64, output: 70), // Shadow mềm mượt
      CurvePoint(input: 128, output: 130), // Midtone sáng dịu
      CurvePoint(input: 192, output: 190), // Nén highlights tạo sắc độ dịu mắt
      CurvePoint(input: 255, output: 250), // Hạ nhẹ điểm trắng để làm mịn ảnh
    ];
  writeProfile(harcourtColour, "HARCOURT_COLOUR", 120);

  // Tạo file zip cho thư mục CUSTOMPC
  createZipArchive();

  print("TẤT CẢ CÁC FILE ĐÃ ĐƯỢC TẠO THÀNH CÔNG!");
}
