# Nikon Custom Picture Control: Nostalgic Neg NN400

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `NN400_NOSTALGIC_NEG.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `NEUTRAL (Trung tinh)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+2` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `+0` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `-1` | Độ lệch dải tông màu |

## 📈 Đường cong tùy chọn (Custom Tone Curve)
- **Điểm đen đầu vào (Black Point)**: `0`
- **Điểm trắng đầu vào (White Point)**: `255`
- **Ngõ ra tối thiểu (Out Min)**: `0`
- **Ngõ ra tối đa (Out Max)**: `255`
- **Điểm trung tính Halftone**: `1.00`
- **Số điểm mốc vẽ**: `5`

| Mốc | Đầu vào | Đầu ra |
| --- | --- | --- |
| Mốc 0 | 0 | 14 |
| Mốc 1 | 64 | 70 |
| Mốc 2 | 128 | 130 |
| Mốc 3 | 192 | 188 |
| Mốc 4 | 255 | 250 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output  1922 |#.............................|
Input  17 => Output  3826 |###...........................|
Input  34 => Output  5729 |#####.........................|
Input  51 => Output  7633 |######........................|
Input  68 => Output  9569 |########......................|
Input  85 => Output 11609 |##########....................|
Input 102 => Output 13649 |############..................|
Input 119 => Output 15689 |##############................|
Input 136 => Output 17696 |################..............|
Input 153 => Output 19668 |##################............|
Input 170 => Output 21640 |###################...........|
Input 187 => Output 23612 |#####################.........|
Input 204 => Output 25703 |#######################.......|
Input 221 => Output 27845 |#########################.....|
Input 238 => Output 29986 |###########################...|
Input 255 => Output 32127 |#############################.|
```
