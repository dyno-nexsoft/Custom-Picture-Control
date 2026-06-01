# Nikon Custom Picture Control: Vintage Look

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 🖼️ Ảnh mô phỏng bộ lọc màu (ColorChecker Preview)
Bảng màu tiêu chuẩn ColorChecker so sánh giữa ảnh gốc và ảnh sau khi áp dụng bộ lọc màu:

| Ảnh gốc (Original) | Đã áp dụng bộ lọc (Filtered) |
| :---: | :---: |
| ![Original](../colorchecker_original.jpg) | ![Filtered](preview.jpg) |

## 📊 Thông tin tệp tin
- **Tên tệp**: `VINTAGE_LOOK.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `NEUTRAL (Trung tinh)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+1` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `-2` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `+1` | Độ lệch dải tông màu |

## 📈 Đường cong tùy chọn (Custom Tone Curve)
- **Điểm đen đầu vào (Black Point)**: `0`
- **Điểm trắng đầu vào (White Point)**: `255`
- **Ngõ ra tối thiểu (Out Min)**: `0`
- **Ngõ ra tối đa (Out Max)**: `255`
- **Điểm trung tính Halftone**: `1.00`
- **Số điểm mốc vẽ**: `5`

| Mốc | Đầu vào | Đầu ra |
| --- | --- | --- |
| Mốc 0 | 0 | 25 |
| Mốc 1 | 64 | 75 |
| Mốc 2 | 128 | 128 |
| Mốc 3 | 192 | 180 |
| Mốc 4 | 255 | 245 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output  3357 |###...........................|
Input  17 => Output  5055 |####..........................|
Input  34 => Output  6753 |######........................|
Input  51 => Output  8452 |#######.......................|
Input  68 => Output 10174 |#########.....................|
Input  85 => Output 11974 |##########....................|
Input 102 => Output 13774 |############..................|
Input 119 => Output 15574 |##############................|
Input 136 => Output 17359 |###############...............|
Input 153 => Output 19125 |#################.............|
Input 170 => Output 20891 |###################...........|
Input 187 => Output 22657 |####################..........|
Input 204 => Output 24760 |######################........|
Input 221 => Output 27003 |########################......|
Input 238 => Output 29245 |##########################....|
Input 255 => Output 31488 |############################..|
```
