import 'dart:io';
import 'dart:typed_data';

/// Đại diện cho một điểm mốc trên đường cong tùy chỉnh (Custom Tone Curve).
class CurvePoint {
  final int input;
  final int output;

  CurvePoint({required this.input, required this.output});

  @override
  String toString() => '($input, $output)';
}

/// Lớp đại diện và phân tích cú pháp tệp tin Nikon NCP
class NcpFile {
  String version = "0100";
  String name = "";
  int baseProfileId = 0x03C2;
  int modifiedState = 0;
  
  int sharpening = 130;
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

  factory NcpFile.fromBytes(Uint8List bytes) {
    if (bytes.length < 4 || 
        bytes[0] != 0x4E || // N
        bytes[1] != 0x43 || // C
        bytes[2] != 0x50 || // P
        bytes[3] != 0x00) {  // \0
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
        throw FormatException("Bản ghi ID $recordId yêu cầu kích thước $recordSize vượt quá dung lượng file còn lại.");
      }

      final recordData = Uint8List.sublistView(bytes, offset, offset + recordSize);
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
}

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

String formatParam(int byteVal, {bool isCurve = false}) {
  if (byteVal == 0xFF) return "N/A";
  final val = byteVal - 128;
  if (val == -128) return "Auto (Tu dong)";
  if (val == -127 && isCurve) return "Custom Curve (Duong cong tuy chinh)";
  return (val >= 0) ? "+$val" : "$val";
}

void main(List<String> args) {
  if (args.isEmpty) {
    print("=============================================================");
    print(" CÔNG CỤ XEM CHI TIẾT FILE NIKON PICTURE CONTROL (.NCP)");
    print("=============================================================");
    print("Sử dụng: dart run view_ncp.dart <đường_dẫn_file.NCP>");
    print("Ví dụ:  dart run view_ncp.dart PICCON01.NCP");
    print("");
    return;
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print("Lỗi: Không tìm thấy tệp tin tại đường dẫn: '$filePath'");
    return;
  }

  try {
    final bytes = file.readAsBytesSync();
    final ncp = NcpFile.fromBytes(bytes);

    print("============================================================");
    print("         THÔNG TIN FILE NIKON PICTURE CONTROL (.NCP)        ");
    print("============================================================");
    print("Đường dẫn     : ${file.path}");
    print("Kích thước    : ${bytes.length} bytes");
    print("Chữ ký file   : NCP\\x00 (Hợp lệ)");
    print("");
    print("[1] CẤU HÌNH & THÔNG SỐ ĐIỀU CHỈNH");
    print("------------------------------------------------------------");
    print("Phiên bản     : ${ncp.version}");
    print("Tên Profile   : ${ncp.name}");
    print("Profile gốc   : ${getBaseProfileName(ncp.baseProfileId)}");
    print("Trạng thái    : ${ncp.modifiedState == 0 ? 'Unmodified (Chưa chỉnh sửa)' : 'Modified (Đã chỉnh sửa)'}");
    print("");
    print("-- Các thông số Slider --");
    print("Sharpening    : ${formatParam(ncp.sharpening)}");
    print("Contrast      : ${formatParam(ncp.contrast, isCurve: true)}");
    print("Brightness    : ${formatParam(ncp.brightness, isCurve: true)}");
    print("Saturation    : ${formatParam(ncp.saturation)}");
    print("Hue           : ${formatParam(ncp.hue)}");

    if (ncp.baseProfileId == 0x064D) {
      final filters = {0: 'OFF', 1: 'YELLOW', 2: 'ORANGE', 3: 'RED', 4: 'GREEN', 0xFF: 'N/A'};
      final toningStyles = {
        0: 'B/W (Trắng đen)', 1: 'SEPIA (Nâu đỏ)', 2: 'CYANOTYPE (Xanh lục)', 3: 'RED', 
        4: 'YELLOW', 5: 'GREEN', 6: 'BLUE GREEN', 7: 'BLUE', 8: 'PURPLE BLUE', 9: 'RED PURPLE', 0xFF: 'N/A'
      };
      print("");
      print("-- Cài đặt Đơn Sắc (Monochrome) --");
      print("Filter        : ${filters[ncp.filter] ?? 'N/A'}");
      print("Toning        : ${toningStyles[ncp.toning] ?? 'N/A'}");
      print("Toning Str.   : ${ncp.toning == 0xFF ? 'N/A' : ncp.toningStrength}");
    }

    print("");
    print("[2] THÔNG SỐ ĐƯỜNG CONG TÙY CHỈNH (CUSTOM TONE CURVE)");
    print("------------------------------------------------------------");
    print("Điểm đen đầu vào (Black Point) : ${ncp.inputBlackPoint}");
    print("Điểm trắng đầu vào (White Point): ${ncp.inputWhitePoint}");
    print("Giới hạn ngõ ra tối thiểu      : ${ncp.outputMin}");
    print("Giới hạn ngõ ra tối đa         : ${ncp.outputMax}");
    print("Điểm trung tính Halftone       : ${ncp.halftone.toStringAsFixed(2)}");
    print("Số điểm mốc vẽ Curve           : ${ncp.curvePoints.length}");
    
    if (ncp.curvePoints.isNotEmpty) {
      print("Tọa độ các điểm mốc [Đầu vào -> Đầu ra (0-255)]:");
      for (int i = 0; i < ncp.curvePoints.length; i++) {
        final pt = ncp.curvePoints[i];
        print("  Mốc ${i.toString().padRight(2)}: ${pt.input.toString().padLeft(3)} -> ${pt.output.toString().padLeft(3)}");
      }
    }
    
    print("");
    print("[3] BẢNG TRA CỨU ÁNH XẠ ĐỘ SÁNG (LUT - 256 Entries)");
    print("------------------------------------------------------------");
    print("Đồ thị thu gọn (Mức độ sáng đầu ra tương ứng từ 0-32767):");
    
    // In mẫu 16 giá trị đại diện của bảng LUT dùng ký tự ASCII tiêu chuẩn để không bị lệch cột
    for (int i = 0; i < 16; i++) {
      final inputIdx = (i * 255 ~/ 15);
      final outVal = ncp.lut[inputIdx];
      final barLength = (outVal * 30 ~/ 32767);
      final bar = '#' * barLength + '.' * (30 - barLength);
      print("  Input ${inputIdx.toString().padLeft(3)} => Output ${outVal.toString().padLeft(5)} |$bar|");
    }
    print("============================================================");

  } catch (e) {
    print("Lỗi phân tích file NCP: $e");
  }
}
