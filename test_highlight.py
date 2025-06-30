#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
这是一个测试vim语法高亮的Python文件
包含了各种语法元素来验证高亮效果
"""

import os
import sys
from datetime import datetime

class TestClass:
    """测试类"""
    
    def __init__(self, name: str):
        self.name = name
        self.created_at = datetime.now()
    
    def greet(self) -> str:
        """问候方法"""
        return f"Hello, {self.name}!"
    
    @staticmethod
    def calculate(x: int, y: int) -> int:
        """计算方法"""
        if x > 0 and y > 0:
            result = x + y
            print(f"Result: {result}")
            return result
        else:
            raise ValueError("Both values must be positive")

def main():
    """主函数"""
    # 创建测试对象
    test_obj = TestClass("世界")
    
    # 输出问候
    message = test_obj.greet()
    print(message)
    
    # 计算测试
    try:
        result = TestClass.calculate(5, 3)
        print(f"计算结果: {result}")
    except ValueError as e:
        print(f"错误: {e}")
    
    # 列表推导式
    numbers = [i**2 for i in range(10) if i % 2 == 0]
    print(f"偶数的平方: {numbers}")
    
    # 字典
    data = {
        'name': 'vim',
        'version': '9.1',
        'features': ['syntax_highlighting', 'line_numbers', 'search']
    }
    
    return 0

if __name__ == "__main__":
    main() 