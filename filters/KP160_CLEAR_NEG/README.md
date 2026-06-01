# Nikon Custom Picture Control: Clear Neg KP160

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `KP160_CLEAR_NEG.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `PORTRAIT (Chan dung)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+2` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `-1` | Độ bão hòa màu sắc |
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
| Mốc 0 | 0 | 6 |
| Mốc 1 | 64 | 68 |
| Mốc 2 | 128 | 133 |
| Mốc 3 | 192 | 190 |
| Mốc 4 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output   883 |..............................|
Input  17 => Output  2992 |##............................|
Input  34 => Output  5101 |####..........................|
Input  51 => Output  7210 |######........................|
Input  68 => Output  9342 |########......................|
Input  85 => Output 11553 |##########....................|
Input 102 => Output 13764 |############..................|
Input 119 => Output 15975 |##############................|
Input 136 => Output 18058 |################..............|
Input 153 => Output 19996 |##################............|
Input 170 => Output 21935 |####################..........|
Input 187 => Output 23874 |#####################.........|
Input 204 => Output 26029 |#######################.......|
Input 221 => Output 28275 |#########################.....|
Input 238 => Output 30521 |###########################...|
Input 255 => Output 32767 |##############################|
```
