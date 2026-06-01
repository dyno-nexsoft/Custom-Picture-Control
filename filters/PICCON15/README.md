# Nikon Custom Picture Control: FLAT

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `PICCON15.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `NEUTRAL (Trung tinh)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+0` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `-2` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `-2` | Độ lệch dải tông màu |

## 📈 Đường cong tùy chọn (Custom Tone Curve)
- **Điểm đen đầu vào (Black Point)**: `0`
- **Điểm trắng đầu vào (White Point)**: `255`
- **Ngõ ra tối thiểu (Out Min)**: `0`
- **Ngõ ra tối đa (Out Max)**: `255`
- **Điểm trung tính Halftone**: `1.30`
- **Số điểm mốc vẽ**: `6`

| Mốc | Đầu vào | Đầu ra |
| --- | --- | --- |
| Mốc 0 | 0 | 23 |
| Mốc 1 | 52 | 50 |
| Mốc 2 | 111 | 111 |
| Mốc 3 | 182 | 175 |
| Mốc 4 | 226 | 217 |
| Mốc 5 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output  3054 |##............................|
Input  17 => Output  4184 |###...........................|
Input  34 => Output  5315 |####..........................|
Input  51 => Output  6445 |#####.........................|
Input  68 => Output  8630 |#######.......................|
Input  85 => Output 10881 |#########.....................|
Input 102 => Output 13133 |############..................|
Input 119 => Output 15248 |#############.................|
Input 136 => Output 17210 |###############...............|
Input 153 => Output 19173 |#################.............|
Input 170 => Output 21136 |###################...........|
Input 187 => Output 23132 |#####################.........|
Input 204 => Output 25211 |#######################.......|
Input 221 => Output 27289 |########################......|
Input 238 => Output 29914 |###########################...|
Input 255 => Output 32767 |##############################|
```
