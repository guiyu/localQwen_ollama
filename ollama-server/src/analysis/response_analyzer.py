import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import os
import glob
from typing import Dict, List

class ResponseAnalyzer:
    def __init__(self, root_dir: str = "D:/ollama-server"):
        self.root_dir = root_dir
        self.results_dir = os.path.join(root_dir, "logs/test_results")
        self.analysis_dir = os.path.join(root_dir, "logs/analysis")
        os.makedirs(self.analysis_dir, exist_ok=True)

    def analyze_temperature_test(self, responses: List[Dict]) -> Dict:
        """分析不同温度参数的响应"""
        df = pd.DataFrame(responses)
        
        # 创建温度参数效果图
        plt.figure(figsize=(10, 6))
        sns.boxplot(x='temperature', y='response_length', data=df)
        plt.title('Response Length Distribution by Temperature')
        plt.savefig(os.path.join(self.analysis_dir, 'temperature_analysis.png'))
        plt.close()

        # 统计分析
        stats = df.groupby('temperature').agg({
            'response_length': ['mean', 'std', 'min', 'max'],
            'response_time': ['mean', 'std']
        }).round(2)
        
        return {
            'stats': stats.to_dict(),
            'plot_path': os.path.join(self.analysis_dir, 'temperature_analysis.png')
        }

    def analyze_response_times(self, responses: List[Dict]) -> Dict:
        """分析响应时间"""
        response_times = [r['response_time'] for r in responses]
        
        # 创建响应时间分布图
        plt.figure(figsize=(10, 6))
        sns.histplot(response_times, kde=True)
        plt.title('Response Time Distribution')
        plt.xlabel('Response Time (ms)')
        plt.savefig(os.path.join(self.analysis_dir, 'response_times.png'))
        plt.close()

        return {
            'mean': round(sum(response_times) / len(response_times), 2),
            'min': round(min(response_times), 2),
            'max': round(max(response_times), 2),
            'plot_path': os.path.join(self.analysis_dir, 'response_times.png')
        }

    def generate_report(self, results: Dict):
        """生成分析报告"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_path = os.path.join(self.analysis_dir, f'report_{timestamp}.html')
        
        html_content = f"""
        <html>
        <head>
            <title>Ollama API Test Analysis Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .section {{ margin: 20px 0; padding: 10px; border: 1px solid #ddd; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
                img {{ max-width: 100%; height: auto; }}
            </style>
        </head>
        <body>
            <h1>Ollama API Test Analysis Report</h1>
            <div class="section">
                <h2>Temperature Test Analysis</h2>
                <img src="temperature_analysis.png" alt="Temperature Analysis">
                <table>
                    <tr>
                        <th>Temperature</th>
                        <th>Mean Response Length</th>
                        <th>Mean Response Time</th>
                    </tr>
                    {self._generate_temperature_table(results)}
                </table>
            </div>
            <div class="section">
                <h2>Response Time Analysis</h2>
                <img src="response_times.png" alt="Response Times">
                <p>Mean Response Time: {results['response_times']['mean']} ms</p>
                <p>Min Response Time: {results['response_times']['min']} ms</p>
                <p>Max Response Time: {results['response_times']['max']} ms</p>
            </div>
        </body>
        </html>
        """
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        return report_path

    def _generate_temperature_table(self, results: Dict) -> str:
        """生成温度分析表格HTML"""
        rows = []
        for temp, stats in results['temperature_analysis']['stats'].items():
            rows.append(f"""
            <tr>
                <td>{temp}</td>
                <td>{stats['response_length']['mean']}</td>
                <td>{stats['response_time']['mean']}</td>
            </tr>
            """)
        return '\n'.join(rows)
    
    def analyze_gpu_metrics(self, metrics: List[Dict]) -> Dict:
        """分析 GPU 使用情况"""
        df = pd.DataFrame(metrics)
        
        plt.figure(figsize=(12, 6))
        plt.subplot(2, 1, 1)
        plt.plot(df['timestamp'], df['gpu_utilization'])
        plt.title('GPU Utilization Over Time')
        plt.ylabel('Utilization %')
        
        plt.subplot(2, 1, 2)
        plt.plot(df['timestamp'], df['gpu_memory'])
        plt.title('GPU Memory Usage Over Time')
        plt.ylabel('Memory Usage (MB)')
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.analysis_dir, 'gpu_metrics.png'))
        plt.close()
        
        return {
            'mean_utilization': df['gpu_utilization'].mean(),
            'max_utilization': df['gpu_utilization'].max(),
            'mean_memory': df['gpu_memory'].mean(),
            'max_memory': df['gpu_memory'].max()
        }
    
    def analyze_benchmark(self, benchmark_results: List[Dict]) -> Dict:
        """分析基准测试结果"""
        df = pd.DataFrame(benchmark_results)
        
        plt.figure(figsize=(10, 6))
        sns.barplot(x='test_type', y='tokens_per_second', data=df)
        plt.title('Processing Speed by Test Type')
        plt.savefig(os.path.join(self.analysis_dir, 'benchmark.png'))
        plt.close()
        
        return {
            'avg_tokens_per_second': df['tokens_per_second'].mean(),
            'throughput_stats': df.groupby('test_type')['tokens_per_second'].agg(['mean', 'std']).to_dict()
        }

if __name__ == "__main__":
    analyzer = ResponseAnalyzer()
    # 获取最新的测试结果文件
    latest_result = max(glob.glob(os.path.join(analyzer.results_dir, 'test_results_*.txt')))
    
    with open(latest_result, 'r', encoding='utf-8') as f:
        results = json.load(f)
    
    # 分析并生成报告
    analysis_results = {
        'temperature_analysis': analyzer.analyze_temperature_test(results['temperature_tests']),
        'response_times': analyzer.analyze_response_times(results['responses'])
    }
    
    report_path = analyzer.generate_report(analysis_results)
    print(f"Analysis report generated: {report_path}")