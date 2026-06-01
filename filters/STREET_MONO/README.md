# Nikon Custom Picture Control: Street Mono

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `STREET_MONO.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `MONOCHROME (Don sac)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+4` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `+0` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `+0` | Độ lệch dải tông màu |
| **Monochrome Filter** | `RED` | Kính lọc màu |
| **Monochrome Toning** | `B/W (Trắng đen)` | Tông màu nhuộm đơn sắc |
| **Toning Strength** | `255` | Độ đậm nhạt màu đơn sắc |

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
| Mốc 1 | 50 | 25 |
| Mốc 2 | 128 | 128 |
| Mốc 3 | 200 | 230 |
| Mốc 4 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output    40 |..............................|
Input  17 => Output  1131 |#.............................|
Input  34 => Output  2222 |##............................|
Input  51 => Output  3418 |###...........................|
Input  68 => Output  6299 |#####.........................|
Input  85 => Output  9180 |########......................|
Input 102 => Output 12061 |###########...................|
Input 119 => Output 14942 |#############.................|
Input 136 => Output 17922 |################..............|
Input 153 => Output 21013 |###################...........|
Input 170 => Output 24104 |######################........|
Input 187 => Output 27195 |########################......|
Input 204 => Output 29792 |###########################...|
Input 221 => Output 30784 |############################..|
Input 238 => Output 31775 |#############################.|
Input 255 => Output 32767 |##############################|
```
