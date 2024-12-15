import paramiko
import os
import logging
from typing import Dict, List

class VPSManager:
    def __init__(self, config_path: str):
        self.logger = logging.getLogger('VPSManager')
        self.config = self._load_config(config_path)
        self.ssh_client = None
        
    def _load_config(self, config_path: str) -> Dict:
        """加载VPS配置"""
        with open(config_path, 'r') as f:
            return json.load(f)
            
    def connect(self):
        """连接到VPS"""
        try:
            self.ssh_client = paramiko.SSHClient()
            self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.ssh_client.connect(
                hostname=self.config['vps_host'],
                username=self.config['vps_user'],
                key_filename=self.config['ssh_key_path']
            )
        except Exception as e:
            self.logger.error(f"Failed to connect to VPS: {str(e)}")
            raise
            
    def setup_haproxy(self):
        """配置HAProxy"""
        try:
            # 上传配置文件
            sftp = self.ssh_client.open_sftp()
            sftp.put('configs/haproxy.cfg', '/etc/haproxy/haproxy.cfg')
            
            # 重启服务
            self._execute_command('systemctl restart haproxy')
        except Exception as e:
            self.logger.error(f"Failed to setup HAProxy: {str(e)}")
            raise
            
    def update_ssl_cert(self):
        """更新SSL证书"""
        commands = [
            'certbot renew --quiet',
            'cat /etc/letsencrypt/live/your-domain.com/fullchain.pem \
             /etc/letsencrypt/live/your-domain.com/privkey.pem > /etc/ssl/private/ollama.pem',
            'chmod 600 /etc/ssl/private/ollama.pem',
            'systemctl reload haproxy'
        ]
        
        for cmd in commands:
            self._execute_command(cmd)
            
    def _execute_command(self, command: str) -> tuple:
        """执行远程命令"""
        stdin, stdout, stderr = self.ssh_client.exec_command(command)
        return stdout.read().decode(), stderr.read().decode()
        
    def check_backend_health(self) -> List[Dict]:
        """检查后端服务器健康状态"""
        try:
            command = "echo 'show stat' | socat unix-connect:/var/run/haproxy.sock stdio"
            stdout, _ = self._execute_command(command)
            
            stats = []
            for line in stdout.splitlines()[1:]:
                fields = line.split(',')
                if fields[1] in ['ollama_api', 'ollama_chat', 'ollama_generate']:
                    stats.append({
                        'backend': fields[1],
                        'status': fields[17],
                        'connections': int(fields[4]),
                        'response_time': int(fields[8])
                    })
            return stats
        except Exception as e:
            self.logger.error(f"Failed to check backend health: {str(e)}")
            return []