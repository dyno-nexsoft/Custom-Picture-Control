import 'dart:io';
import 'package:npc_tools/ncp.dart';

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
    print(
        "Trạng thái    : ${ncp.modifiedState == 0 ? 'Unmodified (Chưa chỉnh sửa)' : 'Modified (Đã chỉnh sửa)'}");
    print("");
    print("-- Các thông số Slider --");
    print("Sharpening    : ${formatParam(ncp.sharpening)}");
    print("Contrast      : ${formatParam(ncp.contrast, isCurve: true)}");
    print("Brightness    : ${formatParam(ncp.brightness, isCurve: true)}");
    print("Saturation    : ${formatParam(ncp.saturation)}");
    print("Hue           : ${formatParam(ncp.hue)}");

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
      print("");
      print("-- Cài đặt Đơn Sắc (Monochrome) --");
      print("Filter        : ${filters[ncp.filter] ?? 'N/A'}");
      print("Toning        : ${toningStyles[ncp.toning] ?? 'N/A'}");
      print(
          "Toning Str.   : ${ncp.toning == 0xFF ? 'N/A' : ncp.toningStrength}");
    }

    print("");
    print("[2] THÔNG SỐ ĐƯỜNG CONG TÙY CHỈNH (CUSTOM TONE CURVE)");
    print("------------------------------------------------------------");
    print("Điểm đen đầu vào (Black Point) : ${ncp.inputBlackPoint}");
    print("Điểm trắng đầu vào (White Point): ${ncp.inputWhitePoint}");
    print("Giới hạn ngõ ra tối thiểu      : ${ncp.outputMin}");
    print("Giới hạn ngõ ra tối đa         : ${ncp.outputMax}");
    print(
        "Điểm trung tính Halftone       : ${ncp.halftone.toStringAsFixed(2)}");
    print("Số điểm mốc vẽ Curve           : ${ncp.curvePoints.length}");

    if (ncp.curvePoints.isNotEmpty) {
      print("Tọa độ các điểm mốc [Đầu vào -> Đầu ra (0-255)]:");
      for (int i = 0; i < ncp.curvePoints.length; i++) {
        final pt = ncp.curvePoints[i];
        print(
            "  Mốc ${i.toString().padRight(2)}: ${pt.input.toString().padLeft(3)} -> ${pt.output.toString().padLeft(3)}");
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
      print(
          "  Input ${inputIdx.toString().padLeft(3)} => Output ${outVal.toString().padLeft(5)} |$bar|");
    }
    print("============================================================");
  } catch (e) {
    print("Lỗi phân tích file NCP: $e");
  }
}
