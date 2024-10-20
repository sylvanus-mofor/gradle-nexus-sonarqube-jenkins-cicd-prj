#!/bin/bash
# Update system packages
yum update -y

# Enable JavaOpenJDK 11
amazon-linux-extras enable java-openjdk11

# Install Java OpenJDK 11 if not already installed
if ! java -version &>/dev/null; then
    yum install -y java-11-openjdk
fi

# Create Nexus user
useradd -r -m -s /bin/bash nexus
echo "nexus:admin123" | chpasswd

# Download and install Nexus Repository Manager
NEXUS_VERSION=3.73.0-12 # Check for the latest version if needed
wget https://download.sonatype.com/nexus/3/nexus-$NEXUS_VERSION-unix.tar.gz
tar -xvzf nexus-$NEXUS_VERSION-unix.tar.gz -C /opt
mv /opt/nexus-$NEXUS_VERSION /opt/nexus

# Create a symbolic link for easier access
ln -s /opt/nexus/bin/nexus /usr/bin/nexus

# Set ownership for Nexus directory
chown -R nexus:nexus /opt/nexus /opt/sonatype-work

# Create a systemd service for Nexus
cat <<EOL > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=simple
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus run
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
systemctl daemon-reload

# Start and enable Nexus service
systemctl start nexus
if systemctl status nexus; then
    echo "Nexus service started successfully."
else
    echo "Nexus service failed to start. Check logs for more information."
fi
systemctl enable nexus

# Open port 8081 in the firewall
if ! systemctl is-active firewalld; then
    yum install -y firewalld
    systemctl start firewalld
    systemctl enable firewalld
fi
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --reload

# Clean up
rm -f nexus-$NEXUS_VERSION-unix.tar.gz
