#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 数据库初始化模块
"""

import logging
import sqlite3
from typing import Optional
from common.database import DatabaseManager


class DatabaseInitializer:
    """数据库初始化器"""

    def __init__(self, db_file: str, logger: Optional[logging.Logger] = None):
        self.db_manager = DatabaseManager(db_file, logger)
        self.logger = logger or logging.getLogger("DatabaseInitializer")

    def init_database(self) -> bool:
        """初始化数据库表结构"""
        try:
            self.db_manager.ensure_directory_exists()

            with self.db_manager.connection() as conn:
                cursor = conn.cursor()
                self._create_tables(cursor)
                self._create_indexes(cursor)
                self._create_views(cursor)
                conn.commit()

                self.logger.info("数据库初始化完成: %s", self.db_manager.db_file)
                return True

        except (OSError, sqlite3.Error) as e:
            self.logger.error("数据库初始化失败: %s", e)
            return False

    def _create_tables(self, cursor: sqlite3.Cursor):
        """创建所有需要的数据库表"""
        tables = [
            # 原始交易表
            """
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                payee TEXT,
                description TEXT,
                account TEXT,
                amount REAL,
                currency TEXT,
                payment_method TEXT,
                transaction_type TEXT,
                source_file TEXT,
                created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                beancount_id TEXT
            )
            """,
            # 规则表
            """
            CREATE TABLE IF NOT EXISTS rules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                rule_type TEXT CHECK(rule_type IN ('payment', 'counterparty')),
                name TEXT,
                payment_method TEXT,
                transaction_type TEXT,
                counterparty TEXT,
                description TEXT,
                category TEXT,
                account TEXT,
                debit_accounts TEXT,
                credit_accounts TEXT,
                default_amount TEXT,
                confidence REAL DEFAULT 0.0,
                example_count INTEGER DEFAULT 0,
                created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_used_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            # beancount entries 相关表
            """
            CREATE TABLE IF NOT EXISTS beancount_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                flag TEXT,
                payee TEXT,
                narration TEXT,
                tags TEXT,
                links TEXT,
                source_file TEXT,
                created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS entry_meta (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entry_id INTEGER,
                meta_key TEXT,
                meta_value TEXT,
                FOREIGN KEY (entry_id) REFERENCES beancount_entries(id)
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS entry_postings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entry_id INTEGER,
                account TEXT,
                units TEXT,
                cost TEXT,
                price TEXT,
                flag TEXT,
                FOREIGN KEY (entry_id) REFERENCES beancount_entries(id)
            )
            """,
            # 分析结果表
            """
            CREATE TABLE IF NOT EXISTS analysis_results (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                rule_type TEXT NOT NULL,
                rule_name TEXT NOT NULL,
                rule_data TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                disabled_time TIMESTAMP NULL,
                version INTEGER DEFAULT 1,
                notes TEXT,
                UNIQUE(rule_type, rule_name)
            )
            """,
        ]

        for table_sql in tables:
            cursor.execute(table_sql)

    def _create_indexes(self, cursor: sqlite3.Cursor):
        """创建数据库索引"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_transactions_payee ON transactions(payee)",
            "CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account)",
            "CREATE INDEX IF NOT EXISTS idx_transactions_beancount_id ON transactions(beancount_id)",
            "CREATE INDEX IF NOT EXISTS idx_rules_type ON rules(rule_type)",
            "CREATE INDEX IF NOT EXISTS idx_rules_payment ON rules(payment_method, transaction_type)",
            "CREATE INDEX IF NOT EXISTS idx_beancount_entries_date ON beancount_entries(date)",
            "CREATE INDEX IF NOT EXISTS idx_entry_meta_entry_id ON entry_meta(entry_id)",
            "CREATE INDEX IF NOT EXISTS idx_entry_postings_entry_id ON entry_postings(entry_id)",
            "CREATE INDEX IF NOT EXISTS idx_entry_postings_account ON entry_postings(account)",
            "CREATE INDEX IF NOT EXISTS idx_analysis_results_type ON analysis_results(rule_type)",
            "CREATE INDEX IF NOT EXISTS idx_analysis_results_active ON analysis_results(is_active) WHERE is_active = 1",
        ]

        for index_sql in indexes:
            cursor.execute(index_sql)

    def _create_views(self, cursor: sqlite3.Cursor):
        """创建数据库视图"""
        views = [
            """
            CREATE VIEW IF NOT EXISTS account_transaction_count AS
            SELECT account, COUNT(*) as transaction_count
            FROM transactions
            GROUP BY account
            ORDER BY transaction_count DESC
            """,
            """
            CREATE VIEW IF NOT EXISTS transaction_by_id AS
            SELECT beancount_id, COUNT(*) as entry_count
            FROM transactions
            GROUP BY beancount_id
            ORDER BY entry_count DESC
            """,
            """
            CREATE VIEW IF NOT EXISTS rule_statistics AS
            SELECT rule_type,
                COUNT(*) as rule_count,
                SUM(example_count) as total_examples,
                AVG(confidence) as avg_confidence
            FROM rules
            GROUP BY rule_type
            """,
        ]

        for view_sql in views:
            cursor.execute(view_sql)

    def ensure_tables_exist(self):
        """确保所有表都存在"""
        try:
            with self.db_manager.connection() as conn:
                cursor = conn.cursor()
                self._create_tables(cursor)
                self._create_indexes(cursor)
                self._create_views(cursor)
                conn.commit()
                self.logger.debug("已确保所有数据库表存在")
        except sqlite3.Error as e:
            self.logger.error("确保表存在时出错: %s", e)
