{ pkgs, ... }: {
  channel = "stable-24.11";
  services.docker.enable = true;
  packages = [ pkgs.docker pkgs.cloudflared pkgs.coreutils pkgs.gnugrep pkgs.git pkgs.python3 ];

  idx.workspace.onStart = {
    ubuntu-docker = ''
      set -e
      pkill -f cloudflared || true
      docker stop ubuntu-desktop-container || true
      docker rm ubuntu-desktop-container || true
      sleep 2

      echo "SYSTEM: STARTING DOCKER UBUNTU..."
      docker run -d --name ubuntu-desktop-container -p 8080:80 --privileged dorowu/ubuntu-desktop-lxde-vnc:latest

      sleep 5
      nohup cloudflared tunnel --no-autoupdate --url http://localhost:8080 > /tmp/cloudflared_docker.log 2>&1 &

      sleep 12
      if grep -q "trycloudflare.com" /tmp/cloudflared_docker.log; then
        URL=$(grep -o "https://[a-z0-9.-]*trycloudflare.com" /tmp/cloudflared_docker.log | head -n1)

        # Tạo script Python gửi mail tự động ngay trên máy ảo Google IDX
        cat << 'PYEOF' > /tmp/send_link.py
import smtplib
from email.mime.text import MIMEText

msg = MIMEText(f"Link VPS Google IDX cua ban da san sang:\n\n👉 {URL}/vnc.html\n\nHay bam vao link de su dung.")
msg['Subject'] = '🔥 LINK VPS GOOGLE IDX CỦA BẠN'
msg['From'] = 'bobaobao2013@gmail.com'
msg['To'] = 'bobaobao2013@gmail.com'

try:
    server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    server.login('bobaobao2013@gmail.com', 'dricmlrsepctcvpm')
    server.sendmail('bobaobao2013@gmail.com', ['bobaobao2013@gmail.com'], msg.as_string())
    server.quit()
    print("Email sent successfully!")
except Exception as e:
    print("Failed to send email:", e)
PYEOF
        python3 /tmp/send_link.py || true
      fi

      while true; do sleep 60; done
    '';
  };
}
