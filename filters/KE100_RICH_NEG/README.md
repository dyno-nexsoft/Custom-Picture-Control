# Nikon Custom Picture Control: Rich Neg KE100

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `KE100_RICH_NEG.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `VIVID (Ruc ro)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+4` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `+3` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `+0` | Độ lệch dải tông màu |

## 📈 Đường cong tùy chọn (Custom Tone Curve)
- **Điểm đen đầu vào (Black Point)**: `0`
- **Điểm trắng đầu vào (White Point)**: `255`
- **Ngõ ra tối thiểu (Out Min)**: `0`
- **Ngõ ra tối đa (Out Max)**: `255`
- **Điểm trung tính Halftone**: `1.00`
- **Số điểm mốc vẽ**: `5`

| Mốc | Đầu vào | Đầu ra |
| --- | --- | --- |
| Mốc 0 | 0 | 0 |
| Mốc 1 | 50 | 35 |
| Mốc 2 | 128 | 128 |
| Mốc 3 | 192 | 215 |
| Mốc 4 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output    60 |..............................|
Input  17 => Output  1586 |#.............................|
Input  34 => Output  3113 |##............................|
Input  51 => Output  4702 |####..........................|
Input  68 => Output  7302 |######........................|
Input  85 => Output  9902 |#########.....................|
Input 102 => Output 12501 |###########...................|
Input 119 => Output 15101 |#############.................|
Input 136 => Output 17872 |################..............|
Input 153 => Output 20837 |###################...........|
Input 170 => Output 23801 |#####################.........|
Input 187 => Output 26765 |########################......|
Input 204 => Output 28614 |##########################....|
Input 221 => Output 29998 |###########################...|
Input 238 => Output 31383 |############################..|
Input 255 => Output 32767 |##############################|
```
