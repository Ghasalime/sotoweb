# SotoWeb - Premium LEMP Stack CLI
**High-Performance Linux Web Server Management Tool**

[Indonesian Version](#bahasa-indonesia) | [English Version](#english)

---

<a name="bahasa-indonesia"></a>
## 🇮🇩 Bahasa Indonesia

**SotoWeb** adalah alat baris perintah (CLI) premium untuk mengelola server Ubuntu LEMP (Linux, Nginx, MariaDB, PHP) dengan performa tinggi. Dirancang untuk developer yang menginginkan kecepatan seperti Webinoly namun dengan fitur penyesuaian yang lebih modern.

### 🚀 Instalasi Cepat
Hanya dengan satu baris perintah:
```bash
wget -qO- makan.soto.web.id/install | sudo bash
```

### 🛠️ Fitur Premium SotoWeb

#### 1. Performa Ultra WordPress (`-wp`)
SotoWeb tidak sekadar menginstal WordPress. Dengan satu perintah:
- **Otomatis Redis**: Instalasi server Redis & PHP Extension.
- **Otomatis Cache**: Konfigurasi FastCGI Cache global & per-site.
- **Object Cache**: Otomatis mengaktifkan plugin Redis Object Cache di WP.
- **Browser-Side Install**: Memberikan keleluasaan Anda menyelesaikan instalasi di browser.

#### 2. Dukungan Multi-PHP per Situs
Ubah versi PHP tanpa mengganggu situs lain.
- `sudo soto web domain.com -php=8.2` : Ubah versi PHP situs ke 8.2 secara instan.
- SotoWeb akan otomatis menginstal versi PHP yang diminta jika belum ada di server.

#### 3. Keamanan Tingkat Tinggi (Soto Auth)
- `sudo soto auth -add username` : Proteksi dashboard dan situs Anda dengan HTTP Basic Auth.
- Dashboard **SotoDash (Port 22222)** kini otomatis diproteksi demi keamanan maksimal.

#### 4. SotoDash: Dashboard Modern
Dashboard premium dengan desain **Glassmorphism & Dark Mode** untuk memantau CPU Load, RAM, Disk, dan status layanan secara real-time.

### 🛠️ Daftar Lengkap Perintah

- `sudo soto stack -install` : Instal full stack LEMP.
- `sudo soto stack -tune` : Optimasi otomatis konfigurasi RAM.
- `sudo soto web domain.com -wp` : Setup WordPress "Ultra" (High Performance).
- `sudo soto web domain.com -ssl` : Aktifkan SSL Let's Encrypt.
- `sudo soto backup -run remote` : Backup cloud lengkap (Files + Databases).

---

<a name="english"></a>
## 🇺🇸 English

**SotoWeb** is a premium command-line interface (CLI) for managing high-performance Ubuntu LEMP (Linux, Nginx, MariaDB, PHP) servers. Built for developers who want the speed of Webinoly with a more modern touch and automated resource tuning.

### 🚀 Rapid Installation
Install with a single command:
```bash
wget -qO- makan.soto.web.id/install | sudo bash
```

### 🛠️ Premium SotoWeb Features

#### 1. WordPress Ultra Performance (`-wp`)
SotoWeb does more than just install WordPress. With one command:
- **Auto Redis**: Installs Redis server & PHP Extension.
- **Auto Cache**: Configures global & per-site FastCGI Cache.
- **Object Cache**: Automatically activates the Redis Object Cache plugin in WP.
- **Browser-Side Install**: Lets you finish the setup in your browser for a custom experience.

#### 2. Multi-PHP Support per Site
Switch PHP versions without affecting other sites.
- `sudo soto web domain.com -php=8.2` : Instantly change a site's PHP version to 8.2.
- SotoWeb auto-installs the requested PHP version if it's missing from the server.

#### 3. Advanced Security (Soto Auth)
- `sudo soto auth -add username` : Protect your dashboard and sites with HTTP Basic Auth.
- **SotoDash (Port 22222)** is now automatically protected for maximum safety.

#### 4. SotoDash: Modern Dashboard
Premium dashboard with **Glassmorphism & Dark Mode** design to monitor CPU Load, RAM, Disk, and service status in real-time.

### 🛠️ Full Command Reference

- `sudo soto stack -install` : Install full LEMP stack.
- `sudo soto stack -tune` : Auto-tune server based on RAM resources.
- `sudo soto web domain.com -wp` : "Ultra" WordPress Setup (High Performance).
- `sudo soto web domain.com -ssl` : Automatically enable SSL.
- `sudo soto backup -run remote` : Full cloud backup (Files + Databases).

---
**Author: Ghasali**
*Crafted for High-Performance DevOps*
