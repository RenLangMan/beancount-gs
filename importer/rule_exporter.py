#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 规则导出模块
"""

import logging
import os
from datetime import datetime
from typing import Optional, Dict, Any, List

import sqlite3
import json
import yaml

from common.database import DatabaseManager


class RuleExporter:
    """规则导出器"""

    def __init__(self, ledger_dir: str, db_file: str, logger: Optional[logging.Logger] = None):
        self.ledger_dir = ledger_dir
        self.db_manager = DatabaseManager(db_file, logger)
        self.logger = logger or logging.getLogger("RuleExporter")

    def generate_yaml_rules(self, output_file: str, only_active: bool = True) -> bool:
        """从数据库生成YAML规则文件"""
        try:
            # 拼接完整路径
            full_output_path = os.path.join(self.ledger_dir, "importer", output_file)
            os.makedirs(os.path.dirname(full_output_path), exist_ok=True)

            with self.db_manager.connection() as conn:
                # 构建查询条件
                where_clause = "WHERE is_active = 1" if only_active else ""

                # 从数据库读取规则
                payment_rules = []
                counterparty_rules = []

                query = f"""
                SELECT rule_type, rule_data FROM analysis_results
                {where_clause}
                ORDER BY rule_type, rule_name
                """

                for row in conn.execute(query):
                    rule = json.loads(row[1])
                    if row[0] == "payment":
                        payment_rules.append(rule)
                    else:
                        counterparty_rules.append(rule)

            # 生成YAML内容
            yaml_content = {
                "meta": {
                    "generated_at": datetime.now().isoformat(),
                    "active_rules_only": only_active,
                    "payment_rule_count": len(payment_rules),
                    "counterparty_rule_count": len(counterparty_rules),
                },
                "payment_rules": payment_rules,
                "counterparty_rules": counterparty_rules,
            }

            # 写入文件
            with open(full_output_path, "w", encoding="utf-8") as f:
                yaml.dump(yaml_content, f, allow_unicode=True, sort_keys=False, indent=2)

            self.logger.info("成功生成YAML规则文件: %s", full_output_path)
            self.logger.info("包含 %d 条支付规则和 %d 条交易对方规则", len(payment_rules), len(counterparty_rules))

            return True

        except (sqlite3.Error, json.JSONDecodeError, yaml.YAMLError, OSError) as e:
            self.logger.error("规则生成失败: %s", e)
            return False
        except Exception as e:
            self.logger.exception("未预期的规则生成失败")
            return False

    def generate_json_rules(self, output_file: str, only_active: bool = True) -> bool:
        """生成JSON格式的规则文件（可选功能）"""
        try:
            full_output_path = os.path.join(self.ledger_dir, "importer", output_file)
            os.makedirs(os.path.dirname(full_output_path), exist_ok=True)

            with self.db_manager.connection() as conn:
                where_clause = "WHERE is_active = 1" if only_active else ""

                rules_by_type: Dict[str, List[Dict[str, Any]]] = {"payment_rules": [], "counterparty_rules": []}

                query = f"""
                SELECT rule_type, rule_data FROM analysis_results
                {where_clause}
                ORDER BY rule_type, rule_name
                """

                for row in conn.execute(query):
                    rule = json.loads(row[1])
                    if row[0] == "payment":
                        rules_by_type["payment_rules"].append(rule)
                    else:
                        rules_by_type["counterparty_rules"].append(rule)

            # 添加元数据
            json_content = {
                "meta": {
                    "generated_at": datetime.now().isoformat(),
                    "active_rules_only": only_active,
                    "payment_rule_count": len(rules_by_type["payment_rules"]),
                    "counterparty_rule_count": len(rules_by_type["counterparty_rules"]),
                },
                **rules_by_type,
            }

            with open(full_output_path, "w", encoding="utf-8") as f:
                json.dump(json_content, f, ensure_ascii=False, indent=2)

            self.logger.info("成功生成JSON规则文件: %s", full_output_path)
            return True

        except (sqlite3.Error, json.JSONDecodeError, OSError, KeyError, ValueError) as e:
            self.logger.error("JSON规则生成失败: %s", e)
            return False
        except Exception as e:
            self.logger.exception("未预期的JSON规则生成失败")
            return False
