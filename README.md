# SotoWeb - Premium LEMP Stack CLI
**The Next-Generation Web Server Management Tool for Ubuntu**

[Indonesian Version](#bahasa-indonesia) | [English Version](#english)

---

<a name="bahasa-indonesia"></a>
## 🇮🇩 Bahasa Indonesia

**SotoWeb** adalah alat baris perintah (CLI) premium dan independen untuk mengelola server Ubuntu LEMP (Linux, Nginx, MariaDB, PHP) dengan performa tinggi. Dirancang untuk developer yang menginginkan kontrol total, keamanan maksimal, dan kemudahan otomasi dalam satu genggaman.

### 🚀 Instalasi Cepat (One-Liner)
Jalankan perintah ini di terminal Ubuntu Anda:
```bash
wget -qO- makan.soto.web.id | sudo bash
```

### 🛠️ Fitur Unggulan SotoWeb

#### 1. Performa "Ultra" WordPress (`-wp`)
SotoWeb mengonfigurasi stack terbaik untuk WordPress secara otomatis:
- **Redis Server & PHP Extension**: Langsung terpasang dan aktif.
- **FastCGI Cache**: Optimasi cache sisi server (global & per-situs).
- **Redis Object Cache**: Plugin otomatis terpasang dan terkonfigurasi di WP.

#### 2. Keamanan & Proteksi (`soto auth`)
- **WP-Admin Protection**: Kunci halaman login WordPress Anda dengan HTTP Basic Auth.
- **Directory Protection**: Lindungi folder apapun dengan password tambahan.
- **Server Shield**: Satu perintah `soto tools -shield` untuk mengaktifkan UFW, Fail2Ban, dan proteksi Network Hardening.
- **Firewall Management**: Blokir IP mencurigakan secara instan dengan `soto tools -blockip`.

#### 3. Fleksibilitas Developer
- **Multi-PHP Version**: Jalankan berbagai versi PHP (8.4, 8.3, 8.2, dll) di server yang sama.
- **Reverse Proxy support**: Hubungkan domain Anda ke aplikasi modern (Node.js, Docker, dll).
- **DB Import/Export**: Kelola database langsung dari baris perintah.

#### 4. SotoDash: Dashboard Real-time
Dashboard premium (Port 22222) dengan desain modern untuk memantau beban CPU, penggunaan RAM, sisa Disk, dan status layanan secara visual.

### 📜 Panduan Perintah (Cheat Sheet)

| Perintah | Deskripsi |
| :--- | :--- |
| `sudo soto web -list` | Menampilkan semua website yang terinstall. |
| `sudo soto web domain.com -info` | Menampilkan detail Path, PHP, DB, dan SSL situs. |
| `sudo soto web domain.com -wp` | Setup WordPress High-Performance (Ultra). |
| `sudo soto web domain.com -pma` | Aktifkan akses phpMyAdmin di `domain.com/pma`. |
| `sudo soto web domain.com -on / -off` | Mengaktifkan/mematikan akses situs sementara. |
| `sudo soto stack -tune` | Optimasi cerdas berdasarkan jumlah RAM & CPU. |
| `sudo soto tools -shield` | Aktifkan Firewall & Fail2Ban secara instan. |
| `sudo soto tools -verify` | Diagnosa kesehatan server secara otomatis. |
| `sudo soto tools -blockip <ip>` | Blokir akses IP tertentu ke server. |
| `sudo soto auth domain.com -wp-admin` | Amankan halaman login WP dengan password. |
| `sudo soto log domain.com -wp` | Pantau debug log WordPress secara real-time. |
| `sudo soto tools -update` | Update SotoWeb ke versi terbaru dari GitHub. |

---

<a name="english"></a>
## 🇺🇸 English

**SotoWeb** is a premium, independent command-line interface (CLI) for managing high-performance Ubuntu LEMP (Linux, Nginx, MariaDB, PHP) servers. It is built for developers who demand total control, maximum security, and seamless automation in a single tool.

### 🚀 Rapid Installation (One-Liner)
Run this command on your Ubuntu terminal:
```bash
wget -qO- makan.soto.web.id | sudo bash
```

### 🛠️ Premium SotoWeb Features

#### 1. "Ultra" WordPress Performance (`-wp`)
SotoWeb automatically configures the best stack for WordPress:
- **Redis Server & PHP Extension**: Installed and activated out-of-the-box.
- **FastCGI Cache**: Server-side cache optimization (global & per-site).
- **Redis Object Cache**: Plugin automatically installed and configured in WP.

#### 2. Security & Protection (`soto auth`)
- **WP-Admin Protection**: Secure your WordPress login page with HTTP Basic Auth.
- **Directory Protection**: Protect any folder with an additional password layer.
- **Firewall Management**: Instantly block suspicious IPs using `soto tools -blockip`.

#### 3. Developer Flexibility
- **Multi-PHP Version**: Run multiple PHP versions (8.4, 8.3, 8.2, etc.) on the same server.
#### 2. Multi-PHP Support per Site
Switch PHP versions without affecting other sites. Default installation uses the latest stable **PHP 8.4**.
- `sudo soto web domain.com -php=8.4` : Use the high-performance standard version.
- `sudo soto web domain.com -php=8.1` : Supports custom versioning if required.
- **Reverse Proxy Support**: Connect your domain to modern apps (Node.js, Docker, etc.).
- **DB Import/Export**: Manage your databases directly from the command line.

#### 4. SotoDash: Real-time Dashboard
A premium dashboard (Port 22222) with a modern design to visually monitor CPU load, RAM usage, Disk space, and service status.

### 📜 Command Reference (Cheat Sheet)

| Command | Description |
| :--- | :--- |
| `sudo soto web -list` | List all installed websites and their status. |
| `sudo soto web domain.com -info` | Show details about Path, PHP, DB, and SSL. |
| `sudo soto web domain.com -wp` | Setup "Ultra" High-Performance WordPress. |
| `sudo soto web domain.com -pma` | Enable phpMyAdmin access at `domain.com/pma`. |
| `sudo soto web domain.com -alias=new.com` | Add a domain alias / parked domain. |
| `sudo soto web domain.com -db-import=f.sql` | Import a database dump directly. |
| `sudo soto web domain.com -on / -off` | Enable or disable site access temporarily. |
| `sudo soto stack -tune` | Intelligent auto-tuning (RAM & CPU). |
| `sudo soto tools -shield` | Activate Firewall, Fail2Ban, & Hardening. |
| `sudo soto tools -verify` | Run an automated server health diagnostic. |
| `sudo soto tools -blockip <ip>` | Block a specific IP from the server. |
| `sudo soto auth global -add user` | Secure SotoDash with HTTP Password. |
| `sudo soto auth domain.com -wp-admin` | Secure WP login page with a password. |
| `sudo soto log domain.com -wp` | Monitor WordPress debug logs in real-time. |
| `sudo soto tools -update` | Update SotoWeb CLI to the latest version. |

---
**Author: Ghasali**  
*Crafted for High-Performance DevOps & Premium Web Experience*
