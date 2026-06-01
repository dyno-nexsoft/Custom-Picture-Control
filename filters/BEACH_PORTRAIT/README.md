# Nikon Custom Picture Control: Beach Portrait

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `BEACH_PORTRAIT.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `PORTRAIT (Chan dung)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+3` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `+1` | Độ bão hòa màu sắc |
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
| Mốc 0 | 0 | 8 |
| Mốc 1 | 50 | 56 |
| Mốc 2 | 128 | 135 |
| Mốc 3 | 200 | 195 |
| Mốc 4 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output  1144 |#.............................|
Input  17 => Output  3234 |##............................|
Input  34 => Output  5323 |####..........................|
Input  51 => Output  7419 |######........................|
Input  68 => Output  9624 |########......................|
Input  85 => Output 11828 |##########....................|
Input 102 => Output 14032 |############..................|
Input 119 => Output 16237 |##############................|
Input 136 => Output 18257 |################..............|
Input 153 => Output 20071 |##################............|
Input 170 => Output 21885 |####################..........|
Input 187 => Output 23698 |#####################.........|
Input 204 => Output 25644 |#######################.......|
Input 221 => Output 28018 |#########################.....|
Input 238 => Output 30393 |###########################...|
Input 255 => Output 32767 |##############################|
```
