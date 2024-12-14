import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
from datetime import datetime
import os

class TestAnalyzer:
    def __init__(self, results_dir='results'):
        self.results_dir = results_dir
        self.analysis_dir = os.path.join(results_dir, 'analysis')
        os.makedirs(self.analysis_dir, exist_ok=True)
        
    def analyze_response_times(self, data):
        """分析响应时间"""
        df = pd.DataFrame(data)
        
        # 创建响应时间图表
        plt.figure(figsize=(10, 6))
        sns.boxplot(data=df['response_time'])
        plt.title('Response Time Distribution')
        plt.savefig(os.path.join(self.analysis_dir, 'response_times.png'))
        plt.close()
        
        return {
            'mean': df['response_time'].mean(),
            'median': df['response_time'].median(),
            'std': df['response_time'].std()
        }
    
    def analyze_temperature_effects(self, data):
        """分析温度参数效果"""
        df = pd.DataFrame(data)
        
        plt.figure(figsize=(12, 6))
        sns.scatterplot(data=df, x='temperature', y='response_length')
        plt.title('Temperature vs Response Length')
        plt.savefig(os.path.join(self.analysis_dir, 'temperature_effects.png'))
        plt.close()
        
        return df.groupby('temperature').agg({
            'response_length': ['mean', 'std']
        }).to_dict()
    
    def generate_report(self, analysis_results):
        """生成分析报告"""
        report_path = os.path.join(self.analysis_dir, 'analysis_report.html')
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"""
            <html>
            <head>
                <title>Ollama API Test Analysis Report</title>
                <style>
                    body {{ font-family: Arial, sans-serif; margin: 20px; }}
                    .section {{ margin: 20px 0; }}
                    table {{ border-collapse: collapse; width: 100%; }}
                    th, td {{ border: 1px solid #ddd; padding: 8px; }}
                    th {{ background-color: #f2f2f2; }}
                </style>
            </head>
            <body>
                <h1>Ollama API Test Analysis Report</h1>
                <div class="section">
                    <h2>Response Time Analysis</h2>
                    <img src="response_times.png" />
                    <table>
                        <tr>
                            <th>Metric</th>
                            <th>Value</th>
                        </tr>
                        <tr>
                            <td>Mean Response Time</td>
                            <td>{analysis_results['response_times']['mean']:.2f} ms</td>
                        </tr>
                    </table>
                </div>
            </body>
            </html>
            """)