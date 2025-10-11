#!/usr/bin/env python3
# coding=utf-8
"""
Author: liangzai450
Date: 2025-10-02 18:37:43
Description: 公共类型定义
"""

from typing import TypedDict, List, Dict, Any


class RuleData(TypedDict):
    """表示记账规则核心数据的类型化字典。"""

    transaction_type: str
    debit_accounts: List[str]
    credit_accounts: List[str]


class PaymentRule(TypedDict):
    """支付规则类型定义"""

    name: str
    payment_method: str
    transaction_type: str
    debit_accounts: List[str]
    credit_accounts: List[str]
    default_amount: str
    example_count: int


class CounterpartyRule(TypedDict):
    """交易对方规则类型定义"""

    name: str
    counterparty: str
    description: str
    category: str
    account: str
    example_count: int


class AnalysisResult(TypedDict):
    """分析结果类型定义"""

    rule_type: str
    rule_name: str
    rule_data: Dict[str, Any]
    is_active: bool
    version: int
