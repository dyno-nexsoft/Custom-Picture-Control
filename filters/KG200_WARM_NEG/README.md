# Nikon Custom Picture Control: Warm Neg KG200

Bộ lọc màu thiết lập chuyên dụng cho máy ảnh Nikon (được nạp trực tiếp vào máy ảnh hoặc qua phần mềm NX Studio).

## 📊 Thông tin tệp tin
- **Tên tệp**: `KG200_WARM_NEG.NCP`
- **Kích thước**: `638 bytes`
- **Chữ ký**: `NCP\x00` (Hợp lệ)

## ⚙️ Các thông số Slider
| Tham số | Thiết lập | Mô tả |
| --- | --- | --- |
| **Profile gốc** | `STANDARD (Tieu chuan)` | Cấu hình màu nền |
| **Sharpening (Độ nét)** | `+2` | Độ sắc nét chi tiết |
| **Contrast (Tương phản)** | `Custom Curve (Duong cong tuy chinh)` | Độ tương phản sắc độ |
| **Brightness (Độ sáng)** | `Custom Curve (Duong cong tuy chinh)` | Sắc độ sáng |
| **Saturation (Độ rực màu)** | `+1` | Độ bão hòa màu sắc |
| **Hue (Tông màu)** | `-2` | Độ lệch dải tông màu |

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
| Mốc 1 | 64 | 58 |
| Mốc 2 | 128 | 130 |
| Mốc 3 | 192 | 196 |
| Mốc 4 | 255 | 255 |

## 📉 Đồ thị ánh xạ độ sáng (LUT - 256 Entries)
Đồ thị thu gọn minh họa mức độ ánh xạ độ sáng (0 -> 32767):
```text
Input   0 => Output   100 |..............................|
Input  17 => Output  2074 |#.............................|
Input  34 => Output  4047 |###...........................|
Input  51 => Output  6021 |#####.........................|
Input  68 => Output  8107 |#######.......................|
Input  85 => Output 10557 |#########.....................|
Input 102 => Output 13007 |###########...................|
Input 119 => Output 15457 |##############................|
Input 136 => Output 17811 |################..............|
Input 153 => Output 20056 |##################............|
Input 170 => Output 22302 |####################..........|
Input 187 => Output 24548 |######################........|
Input 204 => Output 26648 |########################......|
Input 221 => Output 28688 |##########################....|
Input 238 => Output 30727 |############################..|
Input 255 => Output 32767 |##############################|
```
