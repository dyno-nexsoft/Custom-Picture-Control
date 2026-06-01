import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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

String generateInfoText(NcpFile ncp, String filename, int fileLength) {
  final sb = StringBuffer();
  sb.writeln("============================================================");
  sb.writeln("         THÔNG TIN FILE NIKON PICTURE CONTROL (.NCP)        ");
  sb.writeln("============================================================");
  sb.writeln("Đường dẫn     : $filename");
  sb.writeln("Kích thước    : $fileLength bytes");
  sb.writeln("Chữ ký file   : NCP\\x00 (Hợp lệ)");
  sb.writeln("");
  sb.writeln("[1] CẤU HÌNH & THÔNG SỐ ĐIỀU CHỈNH");
  sb.writeln("------------------------------------------------------------");
  sb.writeln("Phiên bản     : ${ncp.version}");
  sb.writeln("Tên Profile   : ${ncp.name}");
  sb.writeln("Profile gốc   : ${getBaseProfileName(ncp.baseProfileId)}");
  sb.writeln("Trạng thái    : Modified (Đã chỉnh sửa)");
  sb.writeln("");
  sb.writeln("-- Các thông số Slider --");
  sb.writeln("Sharpening    : ${formatParam(ncp.sharpening)}");
  sb.writeln("Contrast      : ${formatParam(ncp.contrast, isCurve: true)}");
  sb.writeln("Brightness    : ${formatParam(ncp.brightness, isCurve: true)}");
  sb.writeln("Saturation    : ${formatParam(ncp.saturation)}");
  sb.writeln("Hue           : ${formatParam(ncp.hue)}");
  sb.writeln("");
  sb.writeln("[2] THÔNG SỐ ĐƯỜNG CONG TÙY CHỈNH (CUSTOM TONE CURVE)");
  sb.writeln("------------------------------------------------------------");
  sb.writeln("Điểm đen đầu vào (Black Point) : ${ncp.inputBlackPoint}");
  sb.writeln("Điểm trắng đầu vào (White Point): ${ncp.inputWhitePoint}");
  sb.writeln("Giới hạn ngõ ra tối thiểu      : ${ncp.outputMin}");
  sb.writeln("Giới hạn ngõ ra tối đa         : ${ncp.outputMax}");
  sb.writeln(
    "Điểm trung tính Halftone       : ${ncp.halftone.toStringAsFixed(2)}",
  );
  sb.writeln("Số điểm mốc vẽ Curve           : ${ncp.curvePoints.length}");

  if (ncp.curvePoints.isNotEmpty) {
    sb.writeln("Tọa độ các điểm mốc [Đầu vào -> Đầu ra (0-255)]:");
    for (int i = 0; i < ncp.curvePoints.length; i++) {
      final pt = ncp.curvePoints[i];
      sb.writeln(
        "  Mốc ${i.toString().padRight(2)}: ${pt.input.toString().padLeft(3)} -> ${pt.output.toString().padLeft(3)}",
      );
    }
  }

  sb.writeln("");
  sb.writeln("[3] BẢNG TRA CỨU ÁNH XẠ ĐỘ SÁNG (LUT - 256 Entries)");
  sb.writeln("------------------------------------------------------------");
  sb.writeln("Đồ thị thu gọn (Mức độ sáng đầu ra tương ứng từ 0-32767):");

  for (int i = 0; i < 16; i++) {
    final inputIdx = (i * 255 ~/ 15);
    final outVal = ncp.lut[inputIdx];
    final barLength = (outVal * 30 ~/ 32767);
    final bar = '#' * barLength + '.' * (30 - barLength);
    sb.writeln(
      "  Input ${inputIdx.toString().padLeft(3)} => Output ${outVal.toString().padLeft(5)} |$bar|",
    );
  }
  sb.writeln("============================================================");
  return sb.toString();
}

void writeProfile(NcpFile ncp, String baseName, int blackOffset) {
  ncp.generateLut(blackOffset);
  final bytes = ncp.toBytes();

  // Ensure target directories exist
  Directory('filters/ncp').createSync(recursive: true);
  Directory('filters/info').createSync(recursive: true);

  // Save NCP file to filters/ncp/
  final ncpFile = File('filters/ncp/$baseName.NCP');
  ncpFile.writeAsBytesSync(bytes);
  print("Đã tạo tệp tin Picture Control: ${ncpFile.path}");

  // Save info file to filters/info/ (UTF-8 encoded)
  final infoText = generateInfoText(
    ncp,
    'filters/ncp/$baseName.NCP',
    bytes.length,
  );
  final infoFile = File('filters/info/$baseName.info');
  infoFile.writeAsStringSync(infoText, encoding: utf8);
  print("Đã tạo tệp tin thông tin tương ứng: ${infoFile.path}");
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
    ..sharpening =
        131 // 128 + 3
    ..saturation =
        129 // 128 + 1
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
    ..sharpening =
        133 // 128 + 5
    ..saturation =
        130 // 128 + 2
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
    ..sharpening =
        129 // 128 + 1
    ..saturation =
        126 // 128 - 2
    ..hue =
        129 // 128 + 1 (hơi ngả tone vàng ấm cổ điển)
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
    ..sharpening =
        131 // 128 + 3
    ..saturation =
        129 // 128 + 1
    ..hue =
        130 // 128 + 2 (tạo hiệu ứng chuyển đổi màu cam - teal rõ rệt hơn)
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
    ..sharpening =
        130 // 128 + 2
    ..saturation =
        127 // 128 - 1
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
    ..sharpening =
        132 // 128 + 4
    ..filter =
        3 // RED filter
    ..toning =
        0 // B/W style
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
    ..hue =
        126 // 128 - 2 (lệch tone ấm)
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
    ..hue =
        127 // 128 - 1 (vàng ấm)
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
