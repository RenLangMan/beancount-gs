#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
LastEditors: liangzai450
LastEditTime: 2025-10-02 18:40:46
FilePath: \\V-1.3.0\\importer\\rule_generator.py
Description: rule_generator.py - Beancount规则生成工具主入口
Copyright (c) 2025 by ${git_name_email}, All Rights Reserved.
==============================================
"""

import argparse
import logging
import os
import sys
import json
from typing import Optional

# 导入拆分后的模块
from rule_init import DatabaseInitializer
from rule_extractor import DataExtractor
from rule_analyzer import RuleAnalyzer
from rule_exporter import RuleExporter


def get_ledger_dir_by_id(ledger_id: Optional[str] = None) -> str:
    """根据账本ID获取路径"""
    config_path = "data/beancount/ledger_config.json"
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
            if ledger_id:
                return config.get(ledger_id, {}).get("dataPath", ".")
            # 没有指定ID则返回第一个账本路径
            return next(iter(config.values())).get("dataPath", ".")
    except (FileNotFoundError, json.JSONDecodeError, StopIteration):
        return "."


def show_help():
    """显示脚本用法帮助信息"""
    print(
        """
Beancount规则生成工具 - 使用说明
================================

功能说明:
- 从beancount账本中学习交易规则并写入SQLite数据库
- 支持生成YAML格式的规则文件

四步执行流程:
1. 初始化数据库: --init
2. 加载并提取数据: --load-extract
3. 分析数据生成规则: --analyze
4. 生成规则文件: --generate [FILE]

使用方法:
python rule_generator.py [选项] --ledger-id <账本ID>

必选参数:
--ledger-id <ID>    指定账本ID (必选)

操作流程:
--init              步骤1: 初始化数据库
--load-extract      步骤2: 加载账本并提取交易数据
--analyze           步骤3: 分析交易数据生成规则
--generate [FILE]   步骤4: 生成YAML规则文件(默认: rules.yaml)

辅助参数:
--debug             启用调试模式
--help              显示本帮助信息

完整流程示例:
python rule_generator.py --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb \\
  --init --load-extract --analyze --generate

分步执行示例:
1. python rule_generator.py --ledger-id 3978... --init
2. python rule_generator.py --ledger-id 3978... --load-extract
3. python rule_generator.py --ledger-id 3978... --analyze
4. python rule_generator.py --ledger-id 3978... --generate my_rules.yaml
"""
    )


class RuleGenerator:
    """规则生成器主类 - 协调各个模块"""

    def __init__(self, ledger_dir: str = ".", db_file: Optional[str] = None):
        """初始化规则生成器"""
        self.ledger_dir = ledger_dir
        self.db_file = db_file or os.path.abspath(os.path.join(ledger_dir, "importer", "account_rules.db"))

        # 初始化日志
        self._setup_logging()

        # 初始化各个模块
        self.initializer = DatabaseInitializer(self.db_file, self.logger)
        self.extractor = DataExtractor(ledger_dir, self.db_file, self.logger)
        self.analyzer = RuleAnalyzer(self.db_file, self.logger)
        self.exporter = RuleExporter(ledger_dir, self.db_file, self.logger)

    def _setup_logging(self):
        """设置日志配置"""
        logs_dir = os.path.abspath(os.path.join(self.ledger_dir, "importer", "logs"))
        os.makedirs(logs_dir, exist_ok=True)

        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[
                logging.FileHandler(os.path.join(logs_dir, "rule_generator.log"), encoding="utf-8"),
                logging.StreamHandler(),
            ],
        )
        self.logger = logging.getLogger("RuleGenerator")

    def init_database(self) -> bool:
        """初始化数据库"""
        return self.initializer.init_database()

    def load_and_extract(self) -> bool:
        """加载账本并提取数据"""
        if not self.extractor.load_beancount_files():
            return False
        return self.extractor.extract_transactions()

    def analyze_rules(self) -> bool:
        """分析规则"""
        return self.analyzer.analyze_rules()

    def generate_rules(self, output_file: str) -> bool:
        """生成规则文件"""
        return self.exporter.generate_yaml_rules(output_file)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="Beancount规则生成工具", add_help=False)

    # 必选参数
    parser.add_argument("--ledger-id", required=True, help="指定账本ID (必选)")

    # 操作流程参数
    parser.add_argument("--init", action="store_true", help="步骤1: 初始化数据库")
    parser.add_argument("--load-extract", action="store_true", help="步骤2: 加载账本并提取交易数据")
    parser.add_argument("--analyze", action="store_true", help="步骤3: 分析交易数据生成规则")
    parser.add_argument(
        "--generate",
        metavar="FILE",
        nargs="?",
        const="rules.yaml",
        help="步骤4: 生成YAML规则文件（默认: rules.yaml）",
    )

    # 辅助参数
    parser.add_argument("--debug", action="store_true", help="启用调试模式")
    parser.add_argument("--show-help", action="store_true", help="显示帮助信息")

    args = parser.parse_args()

    if args.show_help:
        show_help()
        sys.exit(0)

    if not args.ledger_id:
        print("错误: 必须提供 --ledger-id 参数")
        show_help()
        sys.exit(1)

    # 创建RuleGenerator实例
    ledger_dir = get_ledger_dir_by_id(args.ledger_id)
    generator = RuleGenerator(ledger_dir)

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
        generator.logger.setLevel(logging.DEBUG)

    success = True

    # 步骤1: 初始化数据库
    if args.init:
        print("=== 步骤1: 初始化数据库 ===")
        if generator.init_database():
            print(f"✅ 数据库初始化成功: {os.path.abspath(generator.db_file)}")
        else:
            print("❌ 数据库初始化失败")
            success = False

    # 步骤2: 加载账本并提取数据
    if args.load_extract and success:
        print("\n=== 步骤2: 加载账本并提取交易数据 ===")
        if generator.load_and_extract():
            print("✅ 数据加载和提取完成")
        else:
            print("❌ 数据加载和提取失败")
            success = False

    # 步骤3: 分析数据生成规则
    if args.analyze and success:
        print("\n=== 步骤3: 分析交易数据生成规则 ===")
        if generator.analyze_rules():
            print("✅ 规则分析完成")
        else:
            print("❌ 规则分析失败")
            success = False

    # 步骤4: 生成规则文件
    if args.generate and success:
        print("\n=== 步骤4: 生成YAML规则文件 ===")
        if generator.generate_rules(args.generate):
            full_path = os.path.abspath(os.path.join(generator.ledger_dir, "importer", args.generate))
            print(f"✅ 规则文件已生成: {full_path}")
        else:
            print("❌ 规则文件生成失败")
            success = False

    # 如果没有指定任何操作，显示帮助
    if not any([args.init, args.load_extract, args.analyze, args.generate]):
        print("提示: 未指定任何操作，使用 --help 查看使用方法")

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
