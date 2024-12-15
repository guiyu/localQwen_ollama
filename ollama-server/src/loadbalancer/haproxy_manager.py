import os
import subprocess
import logging
from datetime import datetime

class HAProxyManager:
    def __init__(self, config_dir):
        self.config_dir = config_dir
        self.haproxy_cfg = os.path.join(config_dir, 'configs', 'haproxy.cfg')
        self.setup_logging()

    def setup_logging(self):
        log_dir = os.path.join(self.config_dir, 'logs')
        os.makedirs(log_dir, exist_ok=True)
        
        logging.basicConfig(
            filename=os.path.join(log_dir, f'haproxy_{datetime.now().strftime("%Y%m%d")}.log'),
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('HAProxyManager')

    def generate_ssl_cert(self):
        """生成SSL证书"""
        ssl_dir = "/etc/ssl/private"
        if not os.path.exists(ssl_dir):
            os.makedirs(ssl_dir)
        
        cert_path = os.path.join(ssl_dir, "ollama.pem")
        if not os.path.exists(cert_path):
            cmd = f"""
            openssl req -x509 -newkey rsa:2048 -nodes -keyout {cert_path} \
            -out {cert_path} -days 365 \
            -subj "/C=CN/ST=State/L=City/O=Organization/CN=ollama.yourdomain.com"
            """
            subprocess.run(cmd, shell=True, check=True)
            self.logger.info("SSL certificate generated successfully")

    def update_backend_servers(self, servers):
        """更新后端服务器列表"""
        try:
            with open(self.haproxy_cfg, 'r') as f:
                config_lines = f.readlines()

            # 找到backend部分并更新服务器列表
            backend_start = next(i for i, line in enumerate(config_lines) 
                               if 'backend ollama_backend' in line)
            
            # 删除旧的服务器配置
            while backend_start < len(config_lines):
                if 'server ollama' in config_lines[backend_start]:
                    config_lines.pop(backend_start)
                else:
                    backend_start += 1

            # 添加新的服务器配置
            for i, server in enumerate(servers, 1):
                config_lines.insert(
                    backend_start, 
                    f"    server ollama{i} {server['host']}:{server['port']} "
                    f"check weight {server.get('weight', 1)}\n"
                )

            with open(self.haproxy_cfg, 'w') as f:
                f.writelines(config_lines)

            self.logger.info("Backend servers updated successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to update backend servers: {str(e)}")
            return False

    def reload_config(self):
        """重新加载HAProxy配置"""
        try:
            subprocess.run(['systemctl', 'reload', 'haproxy'], check=True)
            self.logger.info("HAProxy configuration reloaded successfully")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to reload HAProxy: {str(e)}")
            return False

    def check_backend_health(self):
        """检查后端服务器健康状态"""
        try:
            result = subprocess.run(
                ['echo "show stat" | socat unix-connect:/var/run/haproxy.sock stdio'],
                shell=True,
                capture_output=True,
                text=True
            )
            self.logger.info("Health check completed")
            return result.stdout
        except Exception as e:
            self.logger.error(f"Health check failed: {str(e)}")
            return None