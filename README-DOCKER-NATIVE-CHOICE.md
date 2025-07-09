# Mail Server Setup - Docker vs Native

This repository provides two installation methods for your complete mail server system:

## 🐳 Docker Installation (Recommended for Development)

### Advantages:
- **Easy to manage** - All services in containers
- **Consistent environment** - Same setup everywhere
- **Easy backup/restore** - Container volumes
- **Isolated from host** - No system-wide changes
- **Quick updates** - Pull new container images

### Disadvantages:
- **Resource overhead** - Docker layer overhead
- **Complexity** - Docker networking and volumes
- **Storage** - Container images take space

### Best for:
- Development environments
- Testing setups
- Users comfortable with Docker
- Temporary installations

## 🖥️ Native Installation (Recommended for Production)

### Advantages:
- **Better performance** - No container overhead
- **Full system control** - Direct access to all components
- **Traditional setup** - Standard Linux mail server
- **Lower resource usage** - No Docker overhead
- **System integration** - Native systemd services

### Disadvantages:
- **System changes** - Installs packages system-wide
- **Harder to remove** - Changes system configuration
- **Manual updates** - Update each component separately

### Best for:
- Production environments
- Performance-critical setups
- Traditional system administrators
- Long-term installations

## 📊 Feature Comparison

| Feature | Docker | Native |
|---------|--------|--------|
| **Performance** | Good | Excellent |
| **Resource Usage** | Higher | Lower |
| **Setup Time** | Fast | Medium |
| **Maintenance** | Easy | Medium |
| **Isolation** | Excellent | None |
| **System Integration** | Limited | Full |
| **Backup/Restore** | Easy | Manual |
| **Updates** | Easy | Manual |
| **Debugging** | Complex | Direct |
| **Port Conflicts** | None | Possible |

## 🚀 Quick Start

### Docker Installation:
```bash
git clone https://github.com/h-smith-h/Email.git
cd Email
sudo ./setup-complete-mail-system.sh
# Choose option 2 for Docker
```

### Native Installation:
```bash
git clone https://github.com/h-smith-h/Email.git
cd Email
sudo ./setup-complete-mail-system.sh
# Choose option 1 for Native
```

## 📁 Directory Structure

```
Email/
├── setup-complete-mail-system.sh    # Main setup script (choose Docker or Native)
├── mail-server/                     # Docker-based setup
│   ├── docker-compose.yml          # Docker services
│   ├── mailserver.env              # Docker mail server config
│   ├── setup-docker-accounts.sh    # Docker account creation
│   └── docker-mail-management.sh   # Docker management commands
├── mail-server-native/              # Native installation
│   ├── install.sh                  # Native installation script
│   ├── configure-*.sh              # Configuration scripts
│   ├── manage-users.sh             # User management
│   └── test-mail-server.sh         # Testing script
├── skins/elastic/                   # Purple theme for Roundcube
├── config/                          # Configuration files
└── render.yaml                      # Render.com deployment (webmail only)
```

## 🛠️ Management Commands

### Docker Management:
```bash
cd mail-server
./docker-mail-management.sh add john@bdgsoftware.com password123
./docker-mail-management.sh list
./docker-mail-management.sh status
./docker-mail-management.sh logs
./docker-mail-management.sh restart
./docker-mail-management.sh backup
./docker-mail-management.sh dkim
```

### Native Management:
```bash
cd mail-server-native
./manage-users.sh add john@bdgsoftware.com password123
./manage-users.sh list
./test-mail-server.sh
systemctl status postfix dovecot
tail -f /var/log/mail.log
```

## 🔧 Configuration

Both methods use the same configuration variables in `setup-complete-mail-system.sh`:

```bash
DOMAIN="bdgsoftware.com"
MAIL_DOMAIN="mail.bdgsoftware.com"  
ADMIN_EMAIL="admin@bdgsoftware.com"
WEBMAIL_PORT="8080"
```

## 🎯 Recommendations

### Choose Docker if:
- You're setting up for development/testing
- You want easy management and updates
- You plan to move the setup frequently
- You're comfortable with Docker
- You want isolated services

### Choose Native if:
- You're setting up for production
- You need maximum performance
- You want full control over the system
- You're a traditional system administrator
- You plan a long-term installation

## 🔄 Switching Between Methods

### Docker to Native:
1. Export email data from Docker containers
2. Stop Docker services
3. Run native installation
4. Import email data

### Native to Docker:
1. Backup native configuration and data
2. Stop native services
3. Run Docker installation
4. Import data into Docker containers

## 🆘 Troubleshooting

### Docker Issues:
- Check container logs: `docker-compose logs mailserver`
- Restart services: `docker-compose restart`
- Check service status: `docker-compose ps`

### Native Issues:
- Check service status: `systemctl status postfix dovecot`
- Check logs: `tail -f /var/log/mail.log`
- Test configuration: `./test-mail-server.sh`

## 📚 Documentation

- **Docker Setup**: See `mail-server/README.md`
- **Native Setup**: See `mail-server-native/README.md`
- **Roundcube Integration**: See integration guides in both directories
- **DNS Configuration**: See `DNS-RECORDS.md` in either directory

Both methods provide the same beautiful purple-themed Roundcube webmail interface and professional email functionality for your domain! 🎨✨
