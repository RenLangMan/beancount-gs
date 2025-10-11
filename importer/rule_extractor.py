#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 数据提取模块
"""

import glob
import json
import logging
import os
import sqlite3
from typing import List, Any, Dict, Optional

try:
    from beancount import loader
    from beancount.core import data

    HAS_BEANCOUNT = True
except ImportError:
    HAS_BEANCOUNT = False

from common.database import DatabaseManager


class DataExtractor:
    """数据提取器"""

    def __init__(self, ledger_dir: str, db_file: str, logger: Optional[logging.Logger] = None):
        self.ledger_dir = ledger_dir
        self.db_manager = DatabaseManager(db_file, logger)
        self.logger = logger or logging.getLogger("DataExtractor")

        self.entries: List[Any] = []
        self.errors: List[Any] = []
        self.options_map: Dict[str, Any] = {}

    def load_beancount_files(self) -> bool:
        """加载beancount文件"""
        if not HAS_BEANCOUNT:
            self.logger.error("beancount库未安装，无法加载文件")
            return False

        try:
            main_files = (
                glob.glob(os.path.join(self.ledger_dir, "main.bean"))
                + glob.glob(os.path.join(self.ledger_dir, "*.beancount"))
                + glob.glob(os.path.join(self.ledger_dir, "index.bean"))
            )

            if not main_files:
                self.logger.warning("未找到主beancount文件")
                return False

            main_file = main_files[0]
            self.logger.info("加载主文件: %s", main_file)

            self.entries, self.errors, self.options_map = loader.load_file(main_file)

            if not self.options_map.get("operating_currency"):
                self.options_map["operating_currency"] = ["CNY"]

            self.logger.info("成功加载 %d 个条目", len(self.entries))
            if self.errors:
                self.logger.warning("加载过程中有 %d 个错误", len(self.errors))
            return True
        except (OSError, loader.LoadError) as e:
            self.logger.error("加载beancount文件失败: %s", e)
            return False

    def extract_transactions(self) -> bool:
        """提取交易数据到数据库"""
        if not self.entries:
            self.logger.warning("没有加载beancount条目，无法提取交易")
            return False

        try:
            with self.db_manager.connection() as conn:
                cursor = conn.cursor()

                # 清空现有数据
                cursor.executescript(
                    """
                    DELETE FROM entry_meta;
                    DELETE FROM entry_postings; 
                    DELETE FROM beancount_entries;
                """
                )

                # 过滤出交易条目
                transaction_entries = [e for e in self.entries if isinstance(e, data.Transaction)]
                entry_count = len(transaction_entries)
                posting_count = 0

                for entry in transaction_entries:
                    # 插入主表记录
                    cursor.execute(
                        """
                        INSERT INTO beancount_entries (
                            date, flag, payee, narration, tags, links, source_file
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            str(entry.date),
                            entry.flag,
                            entry.payee or "未知的对方机构",
                            entry.narration or "",
                            json.dumps(list(entry.tags)) if entry.tags else "[]",
                            json.dumps(list(entry.links)) if entry.links else "[]",
                            entry.meta.get("filename", "") if hasattr(entry, "meta") else "",
                        ),
                    )
                    entry_id = cursor.lastrowid

                    # 插入元数据
                    if hasattr(entry, "meta") and entry.meta:
                        meta_data = [(entry_id, str(k), str(v)) for k, v in entry.meta.items() if k != "filename"]
                        if meta_data:
                            cursor.executemany(
                                "INSERT INTO entry_meta (entry_id, meta_key, meta_value) VALUES (?, ?, ?)", meta_data
                            )

                    # 插入分录数据
                    if hasattr(entry, "postings") and entry.postings:
                        posting_data = []
                        for posting in entry.postings:
                            posting_data.append(
                                (
                                    entry_id,
                                    posting.account,
                                    str(posting.units),
                                    str(posting.cost) if posting.cost else None,
                                    str(posting.price) if posting.price else None,
                                    posting.flag,
                                )
                            )

                        cursor.executemany(
                            "INSERT INTO entry_postings (entry_id, account, units, cost, price, flag) VALUES (?, ?, ?, ?, ?, ?)",
                            posting_data,
                        )
                        posting_count += len(entry.postings)

                conn.commit()
                self.logger.info(
                    "成功提取 %d 个交易条目, %d 笔分录到数据库",
                    entry_count,
                    posting_count,
                )
                return True

        except (sqlite3.Error, OSError) as e:
            self.logger.error("提取交易失败: %s", e)
            return False

    def get_loaded_entries_count(self) -> int:
        """获取已加载的条目数量"""
        return len(self.entries)
