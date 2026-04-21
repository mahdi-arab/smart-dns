# 🚀 Smart DNS Selector

A production-ready Bash script that automatically finds the fastest working DNS servers and applies them intelligently based on your Linux environment.

## ✨ Features

* 🔍 Automatically tests multiple DNS servers
* ⚡ Selects the fastest working ones
* 🧠 Smart detection:

  * NetworkManager (`nmcli`)
  * systemd-resolved (`resolvectl`)
  * Fallback to `/etc/resolv.conf`
* 🛡️ Fail-safe (won't break your network if no DNS works)
* 💾 Automatic backup
* 🎯 Custom test domain support
* 📦 Auto-installs `dig` if missing

---

## 📦 Installation

```bash
git clone https://github.com/YOUR_USERNAME/smart-dns.git
cd smart-dns
chmod +x dns.sh
```

---

## 🚀 Usage

### Default (uses google.com)

```bash
sudo ./dns.sh
```

### Custom domain

```bash
sudo ./dns.sh example.com
```

### Using environment variable

```bash
TEST_DOMAIN=cloudflare.com sudo ./dns.sh
```

---

## 🧠 How It Works

1. Tests a list of DNS servers using `dig`
2. Picks the first working ones (default: 5)
3. Detects your system:

   * If **NetworkManager** → uses `nmcli`
   * If **systemd-resolved** → uses `resolvectl`
   * Otherwise → writes to `/etc/resolv.conf`
4. Applies DNS safely

---

## ⚠️ Requirements

* Linux system (Ubuntu, Debian, Rocky, CentOS, etc.)
* Root access
* Internet access (for initial DNS testing)

---

## 🔧 Supported Environments

| System        | Supported          |
| ------------- | ------------------ |
| Ubuntu        | ✅                  |
| Debian        | ✅                  |
| Rocky Linux   | ✅                  |
| AlmaLinux     | ✅                  |
| CentOS        | ✅                  |
| VPS (minimal) | ✅                  |
| Custom setups | ⚠️ (fallback mode) |

---

## 🛡️ Safety

* Creates backup of `/etc/resolv.conf`
* Will **not** apply changes if no working DNS is found

---

## 📁 Project Structure

```
smart-dns/
 ├── dns.sh
 ├── README.md
 └── LICENSE
```

---

## 📜 License

MIT License

---

## 👨‍💻 Author

Developed by **Mahdi Arab**
Powered by Avaan.site

---

## ⭐ Support

If you like this project, give it a star ⭐ on GitHub!
