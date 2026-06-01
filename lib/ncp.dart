import 'dart:typed_data';

/// Đại diện cho một điểm mốc trên đường cong tùy chỉnh (Custom Tone Curve).
class CurvePoint {
  final int input;
  final int output;

  CurvePoint({required this.input, required this.output});

  @override
  String toString() => '($input, $output)';
}

/// Lớp đại diện và phân tích cú pháp/sinh tệp tin Nikon NCP
class NcpFile {
  String version = "0100";
  String name = "";
  int baseProfileId = 0x03C2;
  int modifiedState = 2; // Mặc định là đã chỉnh sửa (cho các file sinh ra)

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

  /// Phân tích cú pháp tệp tin NCP từ chuỗi byte nhị phân.
  factory NcpFile.fromBytes(Uint8List bytes) {
    if (bytes.length < 4 ||
        bytes[0] != 0x4E || // N
        bytes[1] != 0x43 || // C
        bytes[2] != 0x50 || // P
        bytes[3] != 0x00) {
      // \0
      throw FormatException("Chữ ký file không hợp lệ. Phải là 'NCP\\x00'.");
    }

    final ncp = NcpFile();
    final byteData = ByteData.sublistView(bytes);
    int offset = 4;

    while (offset + 8 <= bytes.length) {
      final recordId = byteData.getUint32(offset, Endian.big);
      final recordSize = byteData.getUint32(offset + 4, Endian.big);
      offset += 8;

      if (recordId == 0) {
        break; // EOF
      }

      if (offset + recordSize > bytes.length) {
        throw FormatException(
            "Bản ghi ID $recordId yêu cầu kích thước $recordSize vượt quá dung lượng file còn lại.");
      }

      final recordData =
          Uint8List.sublistView(bytes, offset, offset + recordSize);
      ncp._parseRecord(recordId, recordData);
      offset += recordSize;
    }

    return ncp;
  }

  void _parseRecord(int id, Uint8List data) {
    if (id == 1) {
      final bd = ByteData.sublistView(data);
      version = String.fromCharCodes(data.sublist(0, 4));

      int nameEnd = 4;
      while (nameEnd < 24 && data[nameEnd] != 0) {
        nameEnd++;
      }
      name = String.fromCharCodes(data.sublist(4, nameEnd));

      baseProfileId = bd.getUint16(24, Endian.big);
      modifiedState = data[26];

      if (data.length >= 36) {
        sharpening = data[28];
        contrast = data[29];
        brightness = data[30];
        saturation = data[31];
        hue = data[32];
        filter = data[33];
        toning = data[34];
        toningStrength = data[35];
      }
    } else if (id == 2) {
      inputBlackPoint = data[2];
      inputWhitePoint = data[3];
      outputMin = data[4];
      outputMax = data[5];
      halftone = data[6] + data[7] * 0.01;

      final numPoints = data[8];
      curvePoints = [];
      for (int i = 0; i < numPoints; i++) {
        final ptIdx = 9 + i * 2;
        if (ptIdx + 1 < data.length) {
          curvePoints.add(CurvePoint(
            input: data[ptIdx],
            output: data[ptIdx + 1],
          ));
        }
      }

      if (data.length >= 66 + 512) {
        final bd = ByteData.sublistView(data, 66);
        lut = List.generate(256, (i) => bd.getUint16(i * 2, Endian.big));
      }
    }
  }

  /// Tính toán bảng màu tra cứu LUT 256 phần tử tuyến tính (Linear Interpolation).
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

  /// Xuất cấu trúc NcpFile ra mảng byte nhị phân chuẩn định dạng NCP.
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.add([0x4E, 0x43, 0x50, 0x00]); // Chữ ký

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

/// Trả về tên hiển thị của cấu hình màu cơ bản dựa theo ID.
String getBaseProfileName(int id) {
  final profiles = {
    0x0001: 'STANDARD (Tieu chuan)',
    0x03C2: 'NEUTRAL (Trung tinh)',
    0x00C3: 'VIVID (Ruc ro)',
    0x0486: 'PORTRAIT (Chan dung)',
    0x04C7: 'LANDSCAPE (Phong canh)',
    0x064D: 'MONOCHROME (Don sac)',
    0x0014: 'D2XMODE1',
    0x03D5: 'D2XMODE2',
    0x00D6: 'D2XMODE3',
  };
  return profiles[id] ?? 'UNKNOWN (0x${id.toRadixString(16).toUpperCase()})';
}

/// Định dạng giá trị byte thông số slider thành dạng chuỗi dễ đọc.
String formatParam(int byteVal, {bool isCurve = false}) {
  if (byteVal == 0xFF) return "N/A";
  final val = byteVal - 128;
  if (val == -128) return "Auto (Tu dong)";
  if (val == -127 && isCurve) return "Custom Curve (Duong cong tuy chinh)";
  return (val >= 0) ? "+$val" : "$val";
}
