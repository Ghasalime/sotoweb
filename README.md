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

### 🛠️ Referensi Perintah Terminal

#### 1. Manajemen Stack (`stack`)
Gunakan perintah ini untuk menginstal dan mengoptimalkan komponen server.
- `sudo soto stack -install` : Instal seluruh LEMP stack (Nginx, MariaDB, PHP 8.x).
* `sudo soto stack -tune` : Optimasi otomatis konfigurasi PHP & MariaDB berdasarkan RAM server.
- `sudo soto stack -redis` : Instal Redis Server & Ekstensi PHP Redis.
- `sudo soto stack -cache` : Siapkan konfigurasi FastCGI Cache global.
- `sudo soto stack -firewall` : Aktifkan UFW & amankan port standar.
- `sudo soto stack -shield` : Instal Fail2Ban untuk perlindungan Brute Force.

#### 2. Manajemen Website (`web`)
Kelola situs Anda dengan mudah.
- `sudo soto web domain.com -wp` : Buat situs WordPress otomatis (siap dipasang di browser).
- `sudo soto web domain.com -php` : Buat situs PHP standar.
- `sudo soto web domain.com -ssl` : Aktifkan SSL Let's Encrypt secara otomatis.
- `sudo soto web domain.com -cache=on` : Aktifkan FastCGI Cache untuk situs tersebut.
- `sudo soto web domain.com -clone=domainbaru.com` : Duplikasi situs beserta database (mendukung WP).
- `sudo soto web domain.com -delete` : Hapus situs dan file konfigurasinya.

#### 3. Keamanan HTTP Auth (`auth`)
Lindungi folder atau dashboard dengan password.
- `sudo soto auth -add username` : Tambah/ubah user HTTP Auth.
- `sudo soto auth -list` : Lihat daftar user yang terdaftar.
- `sudo soto auth -delete username` : Hapus user.

#### 4. Backup Cloud (`backup`)
Amankan data Anda ke S3, Google Drive, atau Dropbox via rclone.
- `sudo soto backup -config` : Konfigurasi koneksi cloud via rclone.
- `sudo soto backup -run remote_name` : Jalankan backup file & database sekarang.

#### 5. Tools & Dashboard (`tools`)
- `sudo soto tools -dash` : Instal & Aktifkan SotoDash (Port 22222).
- `sudo soto tools -status` : Lihat ringkasan penggunaan resource server.

---

<a name="english"></a>
## 🇺🇸 English

**SotoWeb** is a premium command-line interface (CLI) for managing high-performance Ubuntu LEMP (Linux, Nginx, MariaDB, PHP) servers. Built for developers who want the speed of Webinoly with a more modern touch and automated resource tuning.

### 🚀 Rapid Installation
Install with a single command:
```bash
wget -qO- makan.soto.web.id/install | sudo bash
```

### 🛠️ Terminal Command Reference

#### 1. Stack Management (`stack`)
Install and optimize server components.
- `sudo soto stack -install` : Install full LEMP stack (Nginx, MariaDB, PHP 8.x).
- `sudo soto stack -tune` : Auto-tune PHP & MariaDB based on available RAM.
- `sudo soto stack -redis` : Install Redis Server & PHP Redis extension.
- `sudo soto stack -cache` : Setup global FastCGI Cache configuration.
- `sudo soto stack -firewall` : Enable UFW and secure default ports.
- `sudo soto stack -shield` : Install Fail2Ban for Brute Force protection.

#### 2. Website Management (`web`)
Manage your sites effortlessly.
- `sudo soto web domain.com -wp` : Create a WordPress site (ready for browser setup).
- `sudo soto web domain.com -php` : Create a standard PHP site.
- `sudo soto web domain.com -ssl` : Automatically enable Let's Encrypt SSL.
- `sudo soto web domain.com -cache=on` : Enable FastCGI Cache for the site.
- `sudo soto web domain.com -clone=newdomain.com` : Clone site and database (supports WP).
- `sudo soto web domain.com -delete` : Completely remove a site and its configs.

#### 3. HTTP Auth Security (`auth`)
Protect directories or your dashboard with passwords.
- `sudo soto auth -add username` : Add or update an HTTP Auth user.
- `sudo soto auth -list` : List all registered auth users.
- `sudo soto auth -delete username` : Remove an auth user.

#### 4. Cloud Backup (`backup`)
Secure your data to S3, Google Drive, or Dropbox via rclone.
- `sudo soto backup -config` : Configure cloud storage via rclone.
- `sudo soto backup -run remote_name` : Run file & database backup now.

#### 5. Tools & Dashboard (`tools`)
- `sudo soto tools -dash` : Install & Activate SotoDash (Port 22222).
- `sudo soto tools -status` : Quick view of server resource usage.

---

### 🎨 SotoDash
Access your premium server dashboard at:
`http://YOUR_SERVER_IP:22222`
*(Note: Requires at least one user created via `soto auth -add`)*

---
**Author: Ghasali**
*Crafted for High-Performance DevOps*
