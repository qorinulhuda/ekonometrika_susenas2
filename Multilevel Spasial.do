*===============================================================================
* Author  : Qorinul Huda
* Project : Spillover Kapabilitas Digital & Ekonomi Rumah Tangga antar-Wilayah
*           (Simulasi Dummy Micro Data Berbobot, Model SAR/SEM/SDM & Peta)
* Method  : Dummy Micro Data Generation + Survey Weighting (pweight), Weighted
*           Spatial Aggregation, Spatial Weight Matrix (W), Moran's I, SAR,
*           SEM, SDM, Direct/Indirect Impacts & Choropleth Map Visualization
*===============================================================================

*-------------------------------------------------------------------------------
* 1. INISIALISASI LINGKUNGAN & DIREKTORI PROYEK
*-------------------------------------------------------------------------------
clear all
clear matrix
clear mata
set more off
*cap log close

cd "E:\Stata_Mikro\Publish\Multilevel Spasial"
cap mkdir "4_dta"

*-------------------------------------------------------------------------------
* 2. PEMBANGKITAN DUMMY MICRO DATA DENGAN BOBOT (PWEIGHT) & STRUKTUR SPASIAL
*-------------------------------------------------------------------------------
set seed 20261125

* Membuat grid koordinat spasial 6 x 10 (60 wilayah) untuk simulasi peta & jarak
clear
set obs 60
gen long wil_id = _n
gen double lon = 100 + mod(_n - 1, 10) * 0.6 + rnormal(0, 0.03)
gen double lat = -6  - floor((_n - 1) / 10) * 0.5 + rnormal(0, 0.03)

* Membentuk karakteristik laten wilayah & efek spasial (kedekatan geografis)
gen double w_dig_base    = 45 + 8 * sin(wil_id / 5) + rnormal(0, 5)
gen double wil_educ_base = 9.5 + 1.5 * cos(wil_id / 6) + rnormal(0, 0.8)

* Menghitung rata-rata 3 tetangga terdekat sebagai komponen spillover awal
gen double spill_dig = .
gen double spill_y   = .
forvalues i = 1/60 {
    local xi = lon[`i']
    local yi = lat[`i']
    tempvar dist
    gen double `dist' = sqrt((lon - `xi')^2 + (lat - `yi')^2)
    replace `dist' = 999999 in `i'
    sort `dist'
    qui summarize w_dig_base in 1/3
    local d3 = r(mean)
    local y3 = 20 + 1.8 * `d3' + rnormal(0, 2)
    drop `dist'
    sort wil_id
    replace spill_dig = `d3' in `i'
    replace spill_y   = `y3' in `i'
}

* Membangkitkan variabel level wilayah yang mengandung spatial spillover
gen double wil_dig_true = 0.65 * w_dig_base + 0.35 * spill_dig + rnormal(0, 2)
gen double wil_y_true   = 25 + 1.4 * wil_dig_true + 2.2 * wil_educ_base + 0.40 * spill_y + rnormal(0, 3)

label var wil_id        "ID Wilayah (Level Spasial)"
label var lon           "Bujur (Longitude)"
label var lat           "Lintang (Latitude)"
label var w_dig_base    "Skor Dasar Ekosistem Digital Wilayah"
label var wil_educ_base "Rata-Rata Dasar Pendidikan Wilayah (Tahun)"
label var spill_dig     "Spillover Digital dari 3 Wilayah Terdekat"
label var spill_y       "Spillover Luaran dari 3 Wilayah Terdekat"
label var wil_dig_true  "Skor Ekosistem Digital Wilayah"
label var wil_y_true    "Tingkat Luaran Ekonomi-Digital Wilayah"

save "spasial_dummy_wilayah_master.dta", replace

* Membangkitkan dummy micro data (12.000 individu/rumah tangga tersebar di 60 wilayah)
clear
set obs 12000
gen long id_mikro = _n
gen long wil_id   = mod(_n - 1, 60) + 1

merge m:1 wil_id using "spasial_dummy_wilayah_master.dta", assert(match) nogenerate

* Bobot penimbang survei (pweight / fwt) bervariasi antar-observasi & wilayah
gen double fwt = max(150, rgamma(3.5, 450) * (0.8 + 0.4 * mod(wil_id, 5) / 4))

* Kovariat mikro: pendidikan (tahun), kapabilitas digital, dan usia
gen double educ_yrs  = max(0, round(wil_educ_base + rnormal(0, 2.8), 1))
gen double dig_skill = min(100, max(0, 0.75 * wil_dig_true + 2.5 * educ_yrs + rnormal(0, 10)))
gen double age       = round(runiform(15, 70))

* Luaran mikro (indeks inklusi & produktivitas digital rumah tangga)
gen double y_micro  = 15 + 0.45 * dig_skill + 1.6 * educ_yrs + 0.30 * wil_y_true + rnormal(0, 12)
gen byte   high_inc = (y_micro >= 80) if !missing(y_micro)

label var id_mikro  "ID Observasi Mikro"
label var fwt       "Bobot Penimbang Survei (pweight)"
label var educ_yrs  "Lama Pendidikan (Tahun)"
label var dig_skill "Skor Kapabilitas Digital Individu (0-100)"
label var age       "Usia (Tahun)"
label var y_micro   "Indeks Luaran Ekonomi-Digital Mikro"
label var high_inc  "Status Luaran Tinggi (1=Ya, 0=Tidak)"

save "spasial_dummy_mikro_weighted.dta", replace

*-------------------------------------------------------------------------------
* 3. AGREGASI TERTIMBANG KE LEVEL WILAYAH & PENYUSUNAN MATRIKS SPASIAL (W)
*-------------------------------------------------------------------------------
preserve
    collapse (mean) y_w     = y_micro ///
                    dig_w   = dig_skill ///
                    educ_w  = educ_yrs ///
                    age_w   = age ///
             (sum)    pop_w   = fwt ///
             (count)  n_samp  = y_micro [aw=fwt], by(wil_id)

    merge 1:1 wil_id using "4_dta\spasial_dummy_wilayah_master.dta", assert(match) nogenerate

    egen double z_y_w    = std(y_w)
    egen double z_dig_w  = std(dig_w)
    egen double z_educ_w = std(educ_w)

    label var y_w      "Rata-Rata Tertimbang Luaran Mikro per Wilayah"
    label var dig_w    "Rata-Rata Tertimbang Kapabilitas Digital per Wilayah"
    label var educ_w   "Rata-Rata Tertimbang Pendidikan per Wilayah"
    label var age_w    "Rata-Rata Tertimbang Usia per Wilayah"
    label var pop_w    "Estimasi Populasi Tertimbang Wilayah"
    label var n_samp   "Jumlah Sampel Mikro Wilayah"
    label var z_y_w    "Z-Score y_w"
    label var z_dig_w  "Z-Score dig_w"
    label var z_educ_w "Z-Score educ_w"

    save "spasial_dummy_wilayah_agregat.dta", replace


use "spasial_dummy_wilayah_agregat.dta", clear

* Pastikan 1 baris unik per wil_id dan bersihkan metadata spasial lama sebelum spset
cap spset, clear
cap drop _ID _CX _CY
bysort wil_id: keep if _n == 1
isid wil_id
spset wil_id, coord(lon lat)

* Membentuk matriks kedekatan spasial berbasis inverse distance (dinormalisasi baris)
cap spmatrix drop W4
spmatrix create idistance W4, vtruncate(1/1.5) normalize(row) replace

*-------------------------------------------------------------------------------
* 4. UJI MORAN'S I & ESTIMASI MODEL SPASIAL (SAR, SEM, SDM)
*-------------------------------------------------------------------------------
reg z_y_w z_dig_w z_educ_w [aw=pop_w]
estimates store m_ols

estat moran, errorlag(W4)

* Model SAR (Spatial Autoregressive Model)
spregress z_y_w z_dig_w z_educ_w, gs2sls dvarlag(W4)
estimates store m_sar
estat impact z_dig_w z_educ_w

* Model SEM (Spatial Error Model)
spregress z_y_w z_dig_w z_educ_w, gs2sls errorlag(W4)
estimates store m_sem

* Model SDM (Spatial Durbin Model)
spregress z_y_w z_dig_w z_educ_w, gs2sls dvarlag(W4) ivarlag(W4: z_dig_w z_educ_w)
estimates store m_sdm
estat impact z_dig_w z_educ_w

* Menghitung spatial lag z_y_w menggunakan Mata untuk klasifikasi kuadran spasial
gen double lag_z_y = .
mata:
    st_view(Y=., ., "z_y_w")
    W_mat = spmatrix_get_matrix("W4")
    lag_vec = W_mat * Y
    idx = st_varindex("lag_z_y")
    st_store(., idx, lag_vec)
end

gen str12 lisa_cluster = "Not Significant"
replace lisa_cluster = "High-High" if z_y_w >  0.5 & lag_z_y >  0.5
replace lisa_cluster = "Low-Low"   if z_y_w < -0.5 & lag_z_y < -0.5
replace lisa_cluster = "High-Low"  if z_y_w >  0.5 & lag_z_y < -0.5
replace lisa_cluster = "Low-High"  if z_y_w < -0.5 & lag_z_y >  0.5

label var lag_z_y      "Spatial Lag z_y_w (W * z_y_w)"
label var lisa_cluster "Klaster Kuadran Spasial (HH / LL / HL / LH)"

tab lisa_cluster

save "spasial_dummy_hasil_estimasi.dta", replace

*-------------------------------------------------------------------------------
* 5. VISUALISASI PETA SEBARAN & KLASTER SPASIAL WILAYAH
*-------------------------------------------------------------------------------
preserve
    keep wil_id lon lat y_w z_y_w lag_z_y lisa_cluster
    gen long _ID = wil_id
    expand 5
    bysort _ID: gen int pt = _n
    gen double _X = .
    gen double _Y = .
    local d = 0.22
    replace _X = lon - `d' if pt == 1
    replace _Y = lat - `d' if pt == 1
    replace _X = lon + `d' if pt == 2
    replace _Y = lat - `d' if pt == 2
    replace _X = lon + `d' if pt == 3
    replace _Y = lat + `d' if pt == 3
    replace _X = lon - `d' if pt == 4
    replace _Y = lat + `d' if pt == 4
    replace _X = lon - `d' if pt == 5
    replace _Y = lat - `d' if pt == 5
    drop lon lat pt
    save "spasial_dummy_coords.dta", replace
restore

use "spasial_dummy_hasil_estimasi.dta", clear
gen long _ID = wil_id
gen int lisa_code = 0
replace lisa_code = 1 if lisa_cluster == "High-High"
replace lisa_code = 2 if lisa_cluster == "Low-Low"
replace lisa_code = 3 if lisa_cluster == "High-Low"
replace lisa_code = 4 if lisa_cluster == "Low-High"

label define lisa_lbl 0 "Netral / Transisi" 1 "High-High" 2 "Low-Low" 3 "High-Low" 4 "Low-High", modify
label values lisa_code lisa_lbl

cap which grmap
if !_rc {
    grmap y_w using "spasial_dummy_coords.dta", id(_ID) ///
        fcolor(Blues) ocolor(gs10) clnumber(5) ///
        title("Peta Sebaran Tertimbang Luaran Mikro (y_w)") ///
        subtitle("Simulasi 60 Wilayah dengan Bobot Penimbang Survei")
    graph export "peta_sebaran_yw.png", replace width(1400)

    grmap lisa_code using "spasial_dummy_coords.dta", id(_ID) ///
        fcolor(Rainbow) ocolor(gs10) type(lean) ///
        title("Peta Klaster Spasial Luaran Wilayah") ///
        subtitle("Klasifikasi Kuadran Moran Scatterplot (HH / LL / HL / LH)")
    graph export "peta_klaster_lisa.png", replace width(1400)
}
else {
    twoway (scatter lat lon if lisa_code == 1, mcolor(navy) msize(large)) ///
           (scatter lat lon if lisa_code == 2, mcolor(cranberry) msize(large)) ///
           (scatter lat lon if lisa_code == 3, mcolor(gold) msize(large)) ///
           (scatter lat lon if lisa_code == 4, mcolor(teal) msize(large)) ///
           (scatter lat lon if lisa_code == 0, mcolor(gs12) msize(medium)), ///
           legend(order(1 "High-High" 2 "Low-Low" 3 "High-Low" 4 "Low-High" 5 "Netral")) ///
           title("Peta Sebaran Koordinat & Klaster Spasial Wilayah") ///
           subtitle("Simulasi 60 Wilayah Berbobot (Fallback Scatter Map)") ///
           xtitle("Bujur (Longitude)") ytitle("Lintang (Latitude)")
    graph export "peta_klaster_spasial.png", replace width(1400)
}

estimates table m_ols m_sar m_sem m_sdm, b(%9.3f) se(%9.3f) stats(N ll aic bic)