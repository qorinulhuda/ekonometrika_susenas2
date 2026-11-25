<div align="center">

# 🗺️ Spillover Kapabilitas Digital & Ekonomi Rumah Tangga antar-Wilayah

**Analisis Ekonometrika Spasial (`SAR`, `SEM`, `SDM`) Berbasis Simulasi *Dummy Micro Data* Berbobot (`pweight` / `fwt`), Agregasi Wilayah, Klasifikasi Kuadran Spasial, dan Visualisasi Peta di Stata**

**Penyusun: Qorinul Huda**

![Stata](https://img.shields.io/badge/Software-Stata-1A476F?style=for-the-badge&logo=stata&logoColor=white)
![Data](https://img.shields.io/badge/Data-Dummy_Micro_Data_Berbobot-2E7D32?style=for-the-badge)
![Method](https://img.shields.io/badge/Model-OLS_%7C_SAR_%7C_SEM_%7C_SDM-0D47A1?style=for-the-badge)
![Penyusun](https://img.shields.io/badge/Penyusun-Qorinul_Huda-D4AF37?style=for-the-badge)

**Direktori Kerja Utama:** `E:\Stata_Mikro\Publish\Multilevel Spasial`

</div>

---

## 📖 Pendahuluan & Pengertian Proyek

Proyek **Spillover Kapabilitas Digital & Ekonomi Rumah Tangga antar-Wilayah** adalah alur kerja analisis spasial mandiri (*self-contained*) berbasis **Stata** yang membangun **12.000 observasi *dummy micro data*** pada **60 wilayah** (`wil_id` `1..60`) lengkap dengan **bobot penimbang survei (`fwt` / `pweight`)**, koordinat geografis (`lon`, `lat`), serta efek *spillover* spasial antarwilayah.

Dalam kajian ekonomi regional dan transformasi digital, capaian ekonomi dan kapabilitas digital penduduk tidak hanya ditentukan oleh karakteristik individu (seperti pendidikan dan usia), tetapi juga oleh keterkaitan geografis dan limpahan (*spillover*) antarwilayah. Seluruh tahapan—mulai dari pembangkitan data mikro berbobot, agregasi tertimbang ke level wilayah, pembentukan matriks spasial `W4`, pengujian Moran dan estimasi **SAR**, **SEM**, serta **SDM**, klasifikasi kuadran spasial, hingga pembuatan grafik peta dan *Moran scatterplot*—dijalankan secara mandiri melalui pengaturan **`cd`** dan menyimpan setiap dataset tahapan ke subfolder **`4_dta`**.

---

## 📌 Ringkasan Proyek

*do-file* **Stata** ini dirancang untuk mensimulasikan alur inferensia spasial berbobot secara terkontrol:
1. **Pembangkitan *Dummy Micro Data* & Struktur Wilayah (`N = 12.000` di `60` wilayah):** Membentuk koordinat spasial (`lon`, `lat`), karakteristik dasar wilayah (`w_dig_base`, `wil_educ_base`), limpahan tetangga terdekat (`spill_dig`, `spill_y`), serta variabel mikro (`fwt`, `educ_yrs`, `dig_skill`, `age`, `y_micro`, `high_inc`).
2. **Agregasi Tertimbang & Matriks Spasial (`W4`):** Mengagregasi data mikro ke level wilayah menggunakan bobot (`[aw=fwt]`), memastikan keunikan `_ID` / `wil_id` sebelum `spset wil_id, coord(lon lat)`, serta membentuk matriks pembobot spasial `W4` berbasis *inverse distance* yang dinormalisasi baris.
3. **Estimasi Model Spasial, Klaster Kuadran & Visualisasi:** Mengestimasi **OLS** tertimbang (`[aw=pop_w]`), **SAR** (`dvarlag(W4)`), **SEM** (`errorlag(W4)`), dan **SDM** (`dvarlag(W4) ivarlag(W4: ...)`), menghitung *spatial lag* (`lag_z_y`) dan kuadran klaster (`High-High`, `Low-Low`, `High-Low`, `Low-High`), serta mengekspor visualisasi spasial ke folder `4_dta\`.

---

## 📁 Struktur Direktori & File Output (`4_dta`)

| Folder / File | Keterangan |
| :--- | :--- |
| **`E:\Stata_Mikro\Publish\Multilevel Spasial`** | Direktori kerja utama (*working directory*, diatur langsung menggunakan **`cd`**) |
| **`4_dta\spasial_dummy_wilayah_master.dta`** | Dataset master `60` wilayah berisi koordinat (`lon`, `lat`), `wil_educ_base`, `wil_dig_true`, `wil_y_true`, dan komponen *spillover* |
| **`4_dta\spasial_dummy_mikro_weighted.dta`** | Dataset simulasi mikro (`12.000` observasi) lengkap dengan bobot `fwt`, `educ_yrs`, `dig_skill`, `age`, `y_micro`, dan `high_inc` |
| **`4_dta\spasial_dummy_wilayah_agregat.dta`** | Dataset agregat tertimbang level wilayah (`y_w`, `dig_w`, `educ_w`, `age_w`, `pop_w`, `n_samp`) beserta *z-score* (`z_y_w`, `z_dig_w`, `z_educ_w`) |
| **`4_dta\spasial_dummy_hasil_estimasi.dta`** | Dataset akhir hasil estimasi spasial lengkap dengan `lag_z_y` dan klasifikasi kuadran `lisa_cluster` |
| **`4_dta\peta_klaster_spasial.png`** | Visualisasi sebaran koordinat dan kuadran klaster spasial wilayah (`twoway scatter`) |
| **`4_dta\peta_moran_scatterplot.png`** | Visualisasi *Moran scatterplot* antara `z_y_w` dan `lag_z_y` berdasarkan kuadran spasial |

---

## 🧩 Variabel Utama & Komponen Spasial

| Variabel / Komponen | Definisi / Peran dalam Model |
| :--- | :--- |
| **`wil_id`**, **`lon`**, **`lat`** | Identitas unik `60` wilayah serta koordinat bujur dan lintang untuk pendaftaran spasial (`spset`) dan pemetaan |
| **`fwt`** & **`pop_w`** | Bobot penimbang mikro (`pweight` / `fwt`) saat agregasi wilayah dan estimasi populasi tertimbang wilayah (`sum fwt`) |
| **`wil_educ_base`**, **`wil_dig_true`**, **`wil_y_true`** | Atribut struktural dan *true spatial spillover* level wilayah yang dipetakan ke data mikro |
| **`y_micro`**, **`dig_skill`**, **`educ_yrs`**, **`age`** | Variabel luaran dan kovariat mikro hasil simulasi (`12.000` observasi) |
| **`y_w`**, **`dig_w`**, **`educ_w`** & **`z_*_w`** | Rata-rata tertimbang per wilayah dan bentuk *z-score* terstandarisasi untuk estimasi regresi dan spasial |
| **`W4`** | Matriks pembobot spasial *inverse distance* yang dinormalisasi baris (`normalize(row)`) |
| **`lag_z_y`** & **`lisa_cluster`** | *Spatial lag* dari `z_y_w` (`W * z_y_w`) serta klasifikasi kuadran (`High-High`, `Low-Low`, `High-Low`, `Low-High`, `Not Significant`) |

---

## ⚙️ Tahapan Alur Kerja & Catatan Teknis Stata

1. **Inisialisasi Direktori (`cd`):** Menetapkan direktori kerja ke **`E:\Stata_Mikro\Publish\Multilevel Spasial`** dan memastikan folder `4_dta` tersedia.
2. **Pembangkitan Data Wilayah & Mikro Berbobot:** Menghasilkan dataset `4_dta\spasial_dummy_wilayah_master.dta` (`60` wilayah) dan `4_dta\spasial_dummy_mikro_weighted.dta` (`12.000` observasi) dengan *seed* tetap (`20261125`).
3. **Agregasi Tertimbang & Registrasi Spasial:** Mengagregasi variabel mikro menggunakan `[aw=fwt]`, membersihkan metadata spasial lama (`cap spset, clear` dan `cap drop _ID _CX _CY`), memastikan keunikan `wil_id`, lalu menjalankan `spset wil_id, coord(lon lat)` dan `spmatrix create idistance W4, vtruncate(1/1.5) normalize(row) replace`.
4. **Estimasi OLS, SAR, SEM & SDM:**
   * Menjalankan regresi **OLS** tertimbang (`reg z_y_w z_dig_w z_educ_w [aw=pop_w]`) dan uji Moran (`estat moran, errorlag(W4)`).
   * Mengestimasi **SAR** (`dvarlag(W4)`), **SEM** (`errorlag(W4)`), dan **SDM** (`dvarlag(W4) ivarlag(W4: z_dig_w z_educ_w)`) menggunakan `spregress` (tanpa bobot langsung pada `spregress` sesuai sintaks Stata, serta memakai `gs2sls` dan `estat impact`).
5. **Spatial Lag, Klasifikasi Kuadran & Visualisasi:** Menghitung `lag_z_y` di Mata, mengklasifikasikan kuadran spasial `lisa_cluster`, menyimpan `4_dta\spasial_dummy_hasil_estimasi.dta`, dan mengekspor grafik `peta_klaster_spasial.png` serta `peta_moran_scatterplot.png` memakai `twoway`.

---

## 🚀 Cara Menjalankan

1. Buka **Stata** dan arahkan ke direktori proyek:

```stata
cd "E:\Stata_Mikro\Publish\Multilevel Spasial"
do "do_spasial_dummy_weighted.do"
