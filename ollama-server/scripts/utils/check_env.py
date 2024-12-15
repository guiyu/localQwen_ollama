import sys
import pkg_resources
import platform

def check_environment():
    print("Environment Check Report")
    print("=" * 50)
    
    # Python版本
    print(f"\nPython Version: {platform.python_version()}")
    
    # 已安装的包
    print("\nInstalled Packages:")
    print("-" * 50)
    print("Package              Version")
    print("-" * 50)
    
    installed_packages = [dist for dist in pkg_resources.working_set]
    for package in sorted(installed_packages, key=lambda x: x.key):
        print(f"{package.key:20} {package.version}")

    # 检查必要的包
    required_packages = [
        'pandas',
        'matplotlib',
        'seaborn',
        'numpy',
        'requests',
        'python-dateutil',
        'plotly',
        'tabulate'
    ]
    
    print("\nRequired Packages Check:")
    print("-" * 50)
    all_good = True
    for package in required_packages:
        try:
            dist = pkg_resources.get_distribution(package)
            print(f"? {package:20} {dist.version}")
        except pkg_resources.DistributionNotFound:
            print(f"? {package:20} Not found!")
            all_good = False
    
    if all_good:
        print("\nAll required packages are installed correctly!")
    else:
        print("\nSome packages are missing. Please run 'pip install -r requirements.txt'")

if __name__ == "__main__":
    check_environment()