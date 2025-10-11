#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 数据库工具模块
"""

import sqlite3
import logging
import os
from typing import Iterator, Optional
from contextlib import contextmanager


class DatabaseManager:
    """数据库管理工具类"""

    def __init__(self, db_file: str, logger: Optional[logging.Logger] = None):
        self.db_file = db_file
        self.logger = logger or logging.getLogger("DatabaseManager")

    @contextmanager
    def connection(self) -> Iterator[sqlite3.Connection]:
        """数据库连接上下文管理器"""
        conn = None
        try:
            conn = sqlite3.connect(self.db_file)
            conn.row_factory = sqlite3.Row
            yield conn
        except sqlite3.Error as e:
            self.logger.error("数据库连接错误: %s", e)
            raise
        finally:
            if conn:
                conn.close()

    def ensure_directory_exists(self):
        """确保数据库目录存在"""
        os.makedirs(os.path.dirname(self.db_file), exist_ok=True)

    def table_exists(self, table_name: str) -> bool:
        """检查表是否存在"""
        try:
            with self.connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table_name,))
                return cursor.fetchone() is not None
        except sqlite3.Error as e:
            self.logger.error("检查表存在失败: %s", e)
            return False
