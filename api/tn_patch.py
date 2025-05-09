#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
tn.chinese.normalizer 模块的补丁实现
用于处理某些环境中缺少 tn.chinese 模块的情况
"""

import logging
import re

logger = logging.getLogger(__name__)
logger.info("使用 tn 模块的替代实现")

class ZhNormalizer:
    """
    中文文本标准化器的替代实现
    """
    def __init__(self, loglevel="INFO"):
        self.patterns = {
            'time': re.compile(r'(\d+)[点时]半?(?:(\d+)分)?'),
            'date': re.compile(r'(\d+)年(\d+)月(\d+)[日号]'),
            'money': re.compile(r'(\d+(?:\.\d+)?)元'),
            'percent': re.compile(r'(\d+(?:\.\d+)?)%'),
            'decimal': re.compile(r'(\d+\.\d+)'),
            'integer': re.compile(r'(\d+)'),
            'phone': re.compile(r'(\d{3,4})-(\d{7,8})'),
            'mobile': re.compile(r'1\d{10}')
        }
        self.number_map = {
            '0': '零', '1': '一', '2': '二', '3': '三', '4': '四',
            '5': '五', '6': '六', '7': '七', '8': '八', '9': '九'
        }
        
    def normalize(self, text):
        """简单的文本标准化处理"""
        if not text:
            return ""
            
        # 处理时间
        text = self.patterns['time'].sub(self._process_time, text)
        
        # 处理日期
        text = self.patterns['date'].sub(self._process_date, text)
        
        # 处理金额
        text = self.patterns['money'].sub(self._process_money, text)
        
        # 处理百分比
        text = self.patterns['percent'].sub(self._process_percent, text)
        
        # 处理小数
        text = self.patterns['decimal'].sub(self._process_decimal, text)
        
        # 处理整数
        text = self.patterns['integer'].sub(self._process_integer, text)
        
        # 处理电话号码
        text = self.patterns['phone'].sub(self._process_phone, text)
        
        # 处理手机号码
        text = self.patterns['mobile'].sub(self._process_mobile, text)
        
        return text
        
    def _process_time(self, match):
        hour = match.group(1)
        minute = match.group(2) if match.group(2) else "0"
        
        hour_text = ''.join([self.number_map[d] for d in hour])
        if match.group(2):
            minute_text = ''.join([self.number_map[d] for d in minute])
            return f"{hour_text}点{minute_text}分"
        elif "半" in match.group(0):
            return f"{hour_text}点半"
        else:
            return f"{hour_text}点"
    
    def _process_date(self, match):
        year = match.group(1)
        month = match.group(2)
        day = match.group(3)
        
        year_text = ''.join([self.number_map[d] for d in year])
        month_text = ''.join([self.number_map[d] for d in month])
        day_text = ''.join([self.number_map[d] for d in day])
        
        return f"{year_text}年{month_text}月{day_text}日"
    
    def _process_money(self, match):
        amount = match.group(1)
        if '.' in amount:
            integer_part, decimal_part = amount.split('.')
            integer_text = self._to_chinese_number(integer_part)
            decimal_text = ''.join([self.number_map[d] for d in decimal_part])
            return f"{integer_text}元{decimal_text}角"
        else:
            integer_text = self._to_chinese_number(amount)
            return f"{integer_text}元"
    
    def _process_percent(self, match):
        number = match.group(1)
        if '.' in number:
            integer_part, decimal_part = number.split('.')
            integer_text = self._to_chinese_number(integer_part)
            decimal_text = ''.join([self.number_map[d] for d in decimal_part])
            return f"{integer_text}点{decimal_text}百分之"
        else:
            integer_text = self._to_chinese_number(number)
            return f"{integer_text}百分之"
    
    def _process_decimal(self, match):
        number = match.group(1)
        integer_part, decimal_part = number.split('.')
        integer_text = self._to_chinese_number(integer_part)
        decimal_text = ''.join([self.number_map[d] for d in decimal_part])
        return f"{integer_text}点{decimal_text}"
    
    def _process_integer(self, match):
        number = match.group(1)
        return self._to_chinese_number(number)
    
    def _process_phone(self, match):
        area_code = match.group(1)
        number = match.group(2)
        area_code_text = ' '.join([self.number_map[d] for d in area_code])
        number_text = ' '.join([self.number_map[d] for d in number])
        return f"{area_code_text} {number_text}"
    
    def _process_mobile(self, match):
        number = match.group(0)
        return ' '.join([self.number_map[d] for d in number])
    
    def _to_chinese_number(self, number_str):
        """将阿拉伯数字转换为中文数字"""
        if len(number_str) == 1:
            return self.number_map[number_str]
            
        # 简单处理，仅适用于10000以下的数字
        if len(number_str) <= 4:
            result = []
            units = ['', '十', '百', '千']
            
            for i, digit in enumerate(number_str[::-1]):
                if digit == '0':
                    if i == 0 or number_str[::-1][i-1] != '0':
                        result.append(self.number_map[digit])
                else:
                    result.append(self.number_map[digit] + units[i])
            
            return ''.join(result[::-1])
        else:
            # 简单处理大数
            return ''.join([self.number_map[d] for d in number_str])

class EnNormalizer:
    """
    英文文本标准化器的替代实现
    """
    def __init__(self, loglevel="INFO"):
        pass
        
    def normalize(self, text):
        """简单返回原文本，不做处理"""
        return text

# 导出类，以便可以直接从这个模块导入
__all__ = ['ZhNormalizer', 'EnNormalizer'] 