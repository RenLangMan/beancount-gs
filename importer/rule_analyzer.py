#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 规则分析模块
"""

import json
import logging
import sqlite3
from typing import List, Dict, Optional, Tuple, Union, Any, Sequence

from common.database import DatabaseManager
from common.types import PaymentRule, CounterpartyRule, RuleData


class RuleAnalyzer:
    """规则分析器"""

    # 配置常量
    MIN_COUNTERPARTY_COUNT = 2

    # 分类映射
    CATEGORY_MAP = {
        "food": "餐饮美食",
        "restaurant": "餐饮美食",
        "transport": "交通出行",
        "taxi": "交通出行",
        "shopping": "购物消费",
        "medical": "医疗健康",
        "education": "教育培训",
        "entertainment": "娱乐休闲",
        "travel": "旅行度假",
        "utilities": "生活缴费",
        "salary": "工资收入",
        "investment": "投资收益",
        "gift": "礼物红包",
    }

    # 描述关键词映射
    DESC_KEYWORDS = {
        "外卖": "餐饮美食",
        "打车": "交通出行",
        "网购": "购物消费",
        "医院": "医疗健康",
        "学费": "教育培训",
        "电影": "娱乐休闲",
        "机票": "旅行度假",
        "水电": "生活缴费",
        "工资": "工资收入",
        "股票": "投资收益",
        "红包": "礼物红包",
    }

    def __init__(self, db_file: str, logger: Optional[logging.Logger] = None):
        self.db_manager = DatabaseManager(db_file, logger)
        self.logger = logger or logging.getLogger("RuleAnalyzer")

    def analyze_rules(self, incremental: bool = False) -> bool:
        """分析交易数据并生成规则"""
        try:
            with self.db_manager.connection() as conn:
                cursor = conn.cursor()

                # 获取现有规则快照
                existing_rules = self._get_existing_rules(cursor)

                # 处理支付方式规则
                payment_rules = self._analyze_payment_rules(cursor)
                self._process_rules(cursor, payment_rules, "payment", existing_rules)

                # 处理交易对手规则
                counterparty_rules = self._analyze_counterparty_rules(cursor)
                self._process_rules(cursor, counterparty_rules, "counterparty", existing_rules)

                # 更新existing_rules集合
                self._update_existing_rules(existing_rules, counterparty_rules, "counterparty")

                # 标记未出现的旧规则为停用
                if not incremental:
                    self._deactivate_old_rules(cursor, existing_rules)

                conn.commit()

                self.logger.info(
                    "规则分析完成: %d 条支付规则, %d 条交易对方规则", len(payment_rules), len(counterparty_rules)
                )
                return True

        except (sqlite3.OperationalError, sqlite3.IntegrityError) as e:
            self.logger.error("数据库操作失败: %s", e)
            return False
        except (TypeError, ValueError) as e:
            self.logger.error("规则数据序列化失败: %s", e)
            return False
        except Exception as e:  # pylint: disable=broad-except
            self.logger.exception("未预期的分析结果更新失败")
            return False

    def _get_existing_rules(self, cursor: sqlite3.Cursor) -> Dict[Tuple[str, str], bool]:
        """获取现有规则快照"""
        existing_rules = {}
        for row in cursor.execute("SELECT rule_type, rule_name FROM analysis_results"):
            existing_rules[(row[0], row[1])] = True
        return existing_rules

    def _process_rules(
        self,
        cursor: sqlite3.Cursor,
        rules: Sequence[Union[PaymentRule, CounterpartyRule]],
        rule_type: str,
        existing_rules: Dict[Tuple[str, str], bool],
    ) -> None:
        """处理规则更新或插入"""
        for rule in rules:
            key = (rule_type, rule["name"])
            rule_dict = dict(rule)  # 转换为普通字典
            if key in existing_rules:
                self._update_rule(cursor, rule_dict, key)
            else:
                self._insert_rule(cursor, rule_dict, key)

    def _update_rule(self, cursor: sqlite3.Cursor, rule: Dict[str, Any], key: Tuple[str, str]) -> None:
        """更新现有规则"""
        cursor.execute(
            """
            UPDATE analysis_results 
            SET rule_data = ?, version = version + 1,
                updated_time = CURRENT_TIMESTAMP,
                is_active = 1,
                disabled_time = NULL
            WHERE rule_type = ? AND rule_name = ?
            """,
            (json.dumps(rule), key[0], key[1]),
        )

    def _insert_rule(self, cursor: sqlite3.Cursor, rule: Dict[str, Any], key: Tuple[str, str]) -> None:
        """插入新规则"""
        cursor.execute(
            """
            INSERT INTO analysis_results (
                rule_type, rule_name, rule_data
            ) VALUES (?, ?, ?)
            """,
            (key[0], key[1], json.dumps(rule)),
        )

    def _update_existing_rules(
        self, existing_rules: Dict[Tuple[str, str], bool], rules: Sequence[Dict[str, Any]], rule_type: str
    ) -> None:
        """更新existing_rules集合"""
        for rule in rules:
            existing_rules[(rule_type, rule["name"])] = True

    def _deactivate_old_rules(self, cursor: sqlite3.Cursor, existing_rules: Dict[Tuple[str, str], bool]) -> None:
        """标记未出现的旧规则为停用"""
        placeholders = ",".join(["(?,?)"] * len(existing_rules))
        params = []
        for rule_type, rule_name in existing_rules:
            params.extend([rule_type, rule_name])

        if existing_rules:  # 只有在有现有规则时才执行
            cursor.execute(
                f"""
                UPDATE analysis_results 
                SET is_active = 0, disabled_time = CURRENT_TIMESTAMP
                WHERE (rule_type, rule_name) NOT IN (
                    SELECT rule_type, rule_name FROM (
                        VALUES {placeholders}
                    )
                )
                """,
                params,
            )

    def _analyze_payment_rules(self, cursor: sqlite3.Cursor) -> List[PaymentRule]:
        """分析支付方式规则"""
        self.logger.info("分析支付方式规则...")

        cursor.execute(
            """
            SELECT account, COUNT(*) as count
            FROM entry_postings 
            WHERE account LIKE 'Expenses:%' OR account LIKE 'Income:%'
            GROUP BY account 
            HAVING count >= 1
            ORDER BY count DESC
            """
        )

        payment_rules: List[PaymentRule] = []
        for account, count in cursor.fetchall():
            if account.startswith("Expenses:"):
                rule_data: RuleData = {
                    "transaction_type": "支出",
                    "debit_accounts": [account],
                    "credit_accounts": ["Assets:Unknown"],
                }
            elif account.startswith("Income:"):
                rule_data = {
                    "transaction_type": "收入",
                    "debit_accounts": ["Assets:Unknown"],
                    "credit_accounts": [account],
                }
            else:
                continue

            payment_rule: PaymentRule = {
                "name": f"auto_{account.replace(':', '_')}",
                "payment_method": "自动识别",
                "default_amount": "0.00",
                "example_count": count,
                "transaction_type": rule_data["transaction_type"],
                "debit_accounts": rule_data["debit_accounts"],
                "credit_accounts": rule_data["credit_accounts"],
            }
            payment_rules.append(payment_rule)

        return payment_rules

    def _analyze_counterparty_rules(self, cursor: sqlite3.Cursor) -> List[CounterpartyRule]:
        """分析交易对方规则"""
        self.logger.info("分析交易对方规则...")

        cursor.execute(
            """
            SELECT payee, narration, COUNT(*) as count
            FROM beancount_entries 
            WHERE payee IS NOT NULL AND payee != '未知的对方机构'
            GROUP BY payee, narration
            HAVING count >= 2
            ORDER BY count DESC
            """
        )

        counterparty_stats = cursor.fetchall()
        counterparty_rules: List[CounterpartyRule] = []

        for payee, narration, count in counterparty_stats:
            # 查找对应的账户
            cursor.execute(
                """
                SELECT DISTINCT ep.account
                FROM beancount_entries be
                JOIN entry_postings ep ON be.id = ep.entry_id
                WHERE be.payee = ? AND be.narration = ?
                ORDER BY ep.account
                """,
                (payee, narration),
            )

            accounts = [row[0] for row in cursor.fetchall()]

            if not accounts:
                continue

            # 选择最可能的账户
            target_account: Optional[str] = None
            for account in accounts:
                if account.startswith("Expenses:") or account.startswith("Income:"):
                    target_account = account
                    break
            if not target_account and accounts:
                target_account = accounts[0]

            category = self._guess_category(target_account, narration)

            rule_name = f"{payee}_{narration}" if narration else f"{payee}_default"
            counterparty_rule: CounterpartyRule = {
                "name": rule_name,
                "counterparty": payee,
                "description": narration or "默认描述",
                "category": category,
                "account": target_account or "Unknown",
                "example_count": count,
            }
            counterparty_rules.append(counterparty_rule)

        return counterparty_rules

    def _guess_category(self, account: Optional[str | None], description: Optional[str]) -> str:
        """根据账户和描述猜测分类"""
        if account is None:
            return "其他"

        if not account:
            return "其他"

        account_lower = account.lower()
        desc_lower = description.lower() if description else ""

        # 从账户名猜测
        for keyword, category in self.CATEGORY_MAP.items():
            if keyword in account_lower:
                return category

        # 从描述猜测
        for keyword, category in self.DESC_KEYWORDS.items():
            if keyword in desc_lower:
                return category

        # 从账户路径猜测
        if ":" in account:
            account_part = account.split(":")[1].lower()
            for keyword, category in self.CATEGORY_MAP.items():
                if keyword in account_part:
                    return category

        return "其他"
