import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img_lib;

class CurvePoint {
  final int input;
  final int output;

  CurvePoint({required this.input, required this.output});

  @override
  String toString() => '($input, $output)';
}

class NcpFile {
  String version = "0100";
  String name = "";
  int baseProfileId = 0x03C2;
  int modifiedState = 2; // Marked as modified

  int sharpening = 128;
  int contrast = 1;
  int brightness = 1;
  int saturation = 128;
  int hue = 128;
  int filter = 0xFF;
  int toning = 0xFF;
  int toningStrength = 0xFF;

  int inputBlackPoint = 0;
  int inputWhitePoint = 255;
  int outputMin = 0;
  int outputMax = 255;
  double halftone = 1.0;

  List<CurvePoint> curvePoints = [];
  List<int> lut = List.filled(256, 0);

  NcpFile();

  void generateLut(int blackOffset) {
    if (curvePoints.isEmpty) {
      for (int i = 0; i < 256; i++) {
        lut[i] = (blackOffset + (i / 255.0) * (32767 - blackOffset))
            .round()
            .clamp(0, 32767);
      }
      return;
    }

    final pts = List<CurvePoint>.from(curvePoints);
    pts.sort((a, b) => a.input.compareTo(b.input));

    if (pts.first.input != 0) {
      pts.insert(0, CurvePoint(input: 0, output: 0));
    }
    if (pts.last.input != 255) {
      pts.add(CurvePoint(input: 255, output: 255));
    }

    int ptIdx = 0;
    for (int i = 0; i < 256; i++) {
      while (ptIdx < pts.length - 1 && i > pts[ptIdx + 1].input) {
        ptIdx++;
      }
      final p0 = pts[ptIdx];
      final p1 = pts[ptIdx + 1];

      final double t = (i - p0.input) / (p1.input - p0.input);
      final double outputVal = p0.output + t * (p1.output - p0.output);

      lut[i] = (blackOffset + (outputVal / 255.0) * (32767 - blackOffset))
          .round()
          .clamp(0, 32767);
    }
  }

  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.add([0x4E, 0x43, 0x50, 0x00]); // Signature

    // Record 1 (ID = 1, size = 36)
    builder.add([0x00, 0x00, 0x00, 0x01]);
    builder.add([0x00, 0x00, 0x00, 0x24]);

    final r1Data = Uint8List(36);
    final r1Bd = ByteData.sublistView(r1Data);

    final versionBytes = version.codeUnits;
    for (int i = 0; i < 4; i++) {
      r1Data[i] = i < versionBytes.length ? versionBytes[i] : 0x30;
    }

    final nameBytes = name.codeUnits;
    for (int i = 0; i < 20; i++) {
      r1Data[4 + i] = i < nameBytes.length ? nameBytes[i] : 0x00;
    }

    r1Bd.setUint16(24, baseProfileId, Endian.big);
    r1Data[26] = modifiedState;
    r1Data[27] = 0xFF;

    r1Data[28] = sharpening;
    r1Data[29] = contrast;
    r1Data[30] = brightness;
    r1Data[31] = saturation;
    r1Data[32] = hue;
    r1Data[33] = filter;
    r1Data[34] = toning;
    r1Data[35] = toningStrength;
    builder.add(r1Data);

    // Record 2 (ID = 2, size = 578)
    builder.add([0x00, 0x00, 0x00, 0x02]);
    builder.add([0x00, 0x00, 0x02, 0x42]);

    final r2Data = Uint8List(578);
    final r2Bd = ByteData.sublistView(r2Data);

    r2Data[0] = 0x49; // I
    r2Data[1] = 0x30; // 0
    r2Data[2] = inputBlackPoint;
    r2Data[3] = inputWhitePoint;
    r2Data[4] = outputMin;
    r2Data[5] = outputMax;

    final haltInt = halftone.floor();
    final haltFrac = ((halftone - haltInt) * 100).round();
    r2Data[6] = haltInt;
    r2Data[7] = haltFrac;

    r2Data[8] = curvePoints.length;
    for (int i = 0; i < 28; i++) {
      final ptIdx = 9 + i * 2;
      if (i < curvePoints.length) {
        r2Data[ptIdx] = curvePoints[i].input;
        r2Data[ptIdx + 1] = curvePoints[i].output;
      } else {
        r2Data[ptIdx] = 0;
        r2Data[ptIdx + 1] = 0;
      }
    }

    for (int i = 0; i < 256; i++) {
      r2Bd.setUint16(66 + i * 2, lut[i], Endian.big);
    }
    builder.add(r2Data);

    // EOF
    builder.add([0x00, 0x00, 0x00, 0x00]);

    return builder.toBytes();
  }
}

String getBaseProfileName(int id) {
  final profiles = {
    0x0001: 'STANDARD (Tieu chuan)',
    0x03C2: 'NEUTRAL (Trung tinh)',
    0x00C3: 'VIVID (Ruc ro)',
    0x0486: 'PORTRAIT (Chan dung)',
    0x04C7: 'LANDSCAPE (Phong canh)',
    0x064D: 'MONOCHROME (Don sac)',
  };
  return profiles[id] ?? 'UNKNOWN (0x${id.toRadixString(16).toUpperCase()})';
}

String formatParam(int byteVal, {bool isCurve = false}) {
  if (byteVal == 0xFF) return "N/A";
  final val = byteVal - 128;
  if (val == -128) return "Auto (Tu dong)";
  if (val == -127 && isCurve) return "Custom Curve (Duong cong tuy chinh)";
  return (val >= 0) ? "+$val" : "$val";
}

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

String generateReadmeText(NcpFile ncp, String filename, int fileLength) {
  final sb = StringBuffer();
  sb.writeln("# Nikon Custom Picture Control: ${ncp.name}");
  sb.writeln("");
  sb.writeln(
      "Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).");
  sb.writeln("");
  sb.writeln("## 🖼️ Ảnh mô phỏng bộ lọc màu (ColorChecker Preview)");
  sb.writeln(
      "Bảng màu tiêu chuẩn ColorChecker so sánh giữa ảnh gốc và ảnh sau khi áp dụng bộ lọc màu:");
  sb.writeln("");
  sb.writeln("| Ảnh gốc (Original) | Đã áp dụng bộ lọc (Filtered) |");
  sb.writeln("| :---: | :---: |");
  sb.writeln(
      "| ![Original](../colorchecker_original.jpg) | ![Filtered](preview.jpg) |");
  sb.writeln("");
  sb.writeln("## 📊 Thông tin tệp tin");
  sb.writeln("- **Tên tệp**: `$filename`");
  sb.writeln("- **Kích thước**: `$fileLength bytes`");
  sb.writeln("- **Chữ ký**: `NCP\\x00` (Hợp lệ)");
  sb.writeln("");
  sb.writeln("## ⚙️ Các thông số Slider");
  sb.writeln("| Tham số | Thiết lập | Mô tả |");
  sb.writeln("| --- | --- | --- |");
  sb.writeln(
      "| **Profile gốc** | `${getBaseProfileName(ncp.baseProfileId)}` | Cấu hình màu nền |");
  sb.writeln(
      "| **Sharpening (Độ nét)** | `${formatParam(ncp.sharpening)}` | Độ sắc nét chi tiết |");
  sb.writeln(
      "| **Contrast (Tương phản)** | `${formatParam(ncp.contrast, isCurve: true)}` | Độ tương phản sắc độ |");
  sb.writeln(
      "| **Brightness (Độ sáng)** | `${formatParam(ncp.brightness, isCurve: true)}` | Sắc độ sáng |");
  sb.writeln(
      "| **Saturation (Độ rực màu)** | `${formatParam(ncp.saturation)}` | Độ bão hòa màu sắc |");
  sb.writeln(
      "| **Hue (Tông màu)** | `${formatParam(ncp.hue)}` | Độ lệch dải tông màu |");

  if (ncp.baseProfileId == 0x064D) {
    final filters = {
      0: 'OFF',
      1: 'YELLOW',
      2: 'ORANGE',
      3: 'RED',
      4: 'GREEN',
      0xFF: 'N/A'
    };
    final toningStyles = {
      0: 'B/W (Trắng đen)',
      1: 'SEPIA (Nâu đỏ)',
      2: 'CYANOTYPE (Xanh lục)',
      3: 'RED',
      4: 'YELLOW',
      5: 'GREEN',
      6: 'BLUE GREEN',
      7: 'BLUE',
      8: 'PURPLE BLUE',
      9: 'RED PURPLE',
      0xFF: 'N/A'
    };
    sb.writeln(
        "| **Monochrome Filter** | `${filters[ncp.filter] ?? 'N/A'}` | Kính lọc màu |");
    sb.writeln(
        "| **Monochrome Toning** | `${toningStyles[ncp.toning] ?? 'N/A'}` | Tông màu nhuộm đơn sắc |");
    sb.writeln(
        "| **Toning Strength** | `${ncp.toning == 0xFF ? 'N/A' : ncp.toningStrength}` | Độ đậm nhạt màu đơn sắc |");
  }

  sb.writeln("");
  sb.writeln("## 📈 Đường cong tùy chọn (Custom Tone Curve)");
  sb.writeln("- **Điểm đen đầu vào (Black Point)**: `${ncp.inputBlackPoint}`");
  sb.writeln(
      "- **Điểm trắng đầu vào (White Point)**: `${ncp.inputWhitePoint}`");
  sb.writeln("- **Ngõ ra tối thiểu (Out Min)**: `${ncp.outputMin}`");
  sb.writeln("- **Ngõ ra tối đa (Out Max)**: `${ncp.outputMax}`");
  sb.writeln(
      "- **Điểm trung tính Halftone**: `${ncp.halftone.toStringAsFixed(2)}`");
  sb.writeln("- **Số điểm mốc vẽ**: `${ncp.curvePoints.length}`");
  sb.writeln("");

  if (ncp.curvePoints.isNotEmpty) {
    sb.writeln("| Mốc | Đầu vào | Đầu ra |");
    sb.writeln("| --- | --- | --- |");
    for (int i = 0; i < ncp.curvePoints.length; i++) {
      final pt = ncp.curvePoints[i];
      sb.writeln("| Mốc $i | ${pt.input} | ${pt.output} |");
    }
    sb.writeln("");
  }

  sb.writeln("## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)");
  sb.writeln("Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):");
  sb.writeln("```text");
  for (int i = 0; i < 16; i++) {
    final inputIdx = (i * 255 ~/ 15);
    final outVal = ncp.lut[inputIdx];
    final barLength = (outVal * 30 ~/ 32767);
    final bar = '#' * barLength + '.' * (30 - barLength);
    sb.writeln(
        "Input ${inputIdx.toString().padLeft(3)} => Output ${outVal.toString().padLeft(5)} |$bar|");
  }
  sb.writeln("```");

  return sb.toString();
}

void writeProfile(NcpFile ncp, String baseName, int blackOffset) {
  ncp.generateLut(blackOffset);
  final bytes = ncp.toBytes();

  final targetDir = 'filters/$baseName';
  Directory(targetDir).createSync(recursive: true);
  Directory('filters').createSync(recursive: true);

  // Xóa các tệp .png cũ nếu có để tránh rác repo
  final oldOrigFile = File('filters/colorchecker_original.png');
  if (oldOrigFile.existsSync()) {
    try {
      oldOrigFile.deleteSync();
      print("Đã xóa tệp tin cũ: ${oldOrigFile.path}");
    } catch (_) {}
  }
  final oldPreviewFile = File('$targetDir/preview.png');
  if (oldPreviewFile.existsSync()) {
    try {
      oldPreviewFile.deleteSync();
      print("Đã xóa tệp tin cũ: ${oldPreviewFile.path}");
    } catch (_) {}
  }

  // Tạo ảnh ColorChecker gốc dạng JPEG chất lượng cao nếu chưa tồn tại
  final origFile = File('filters/colorchecker_original.jpg');
  late img_lib.Image originalImage;
  if (!origFile.existsSync()) {
    originalImage = createColorChecker();
    origFile.writeAsBytesSync(img_lib.encodeJpg(originalImage, quality: 95));
    print("Đã tạo tệp tin ColorChecker gốc: ${origFile.path}");
  } else {
    originalImage = img_lib.decodeJpg(origFile.readAsBytesSync())!;
  }

  // Áp dụng bộ lọc và lưu ảnh xem trước (preview.jpg)
  final previewImage = applyNcpToImage(originalImage, ncp);
  final previewFile = File('$targetDir/preview.jpg');
  previewFile.writeAsBytesSync(img_lib.encodeJpg(previewImage, quality: 95));
  print("Đã tạo hình ảnh xem trước: ${previewFile.path}");

  // Save NCP file to filters/baseName/baseName.NCP
  final ncpFile = File('$targetDir/$baseName.NCP');
  ncpFile.writeAsBytesSync(bytes);
  print("Đã tạo tệp tin Picture Control: ${ncpFile.path}");

  // Save README.md file (UTF-8 encoded)
  final readmeText = generateReadmeText(ncp, '$baseName.NCP', bytes.length);
  final readmeFile = File('$targetDir/README.md');
  readmeFile.writeAsStringSync(readmeText, encoding: utf8);
  print("Đã tạo tệp tin README.md: ${readmeFile.path}");
  print("------------------------------------------------------------");
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

  // 7. PICCON15: Màu Flat gốc của bạn
  // - Base Profile: NEUTRAL (0x03C2)
  // - Sharpening: +0 (128)
  // - Contrast & Brightness: Custom Curve
  // - Saturation: -2 (126)
  // - Hue: -2 (126)
  // - Curve: Nâng vùng tối (0 -> 23), halftone 1.30
  final flat = NcpFile()
    ..name = "FLAT"
    ..baseProfileId = 0x03C2
    ..sharpening = 128
    ..saturation = 126
    ..hue = 126
    ..halftone = 1.30
    ..curvePoints = [
      CurvePoint(input: 0, output: 23),
      CurvePoint(input: 52, output: 50),
      CurvePoint(input: 111, output: 111),
      CurvePoint(input: 182, output: 175),
      CurvePoint(input: 226, output: 217),
      CurvePoint(input: 255, output: 255),
    ];
  writeProfile(flat, "PICCON15", 108);

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

  print("TẤT CẢ CÁC FILE ĐÃ ĐƯỢC TẠO THÀNH CÔNG!");
}
