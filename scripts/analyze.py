#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Codex 一键分析入口。

用法（从仓库根目录）：
  source venv/bin/activate
  python scripts/analyze.py --network bsc --tx 0x...

实际实现位于：codex/analysis.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from codex.analysis import main

if __name__ == "__main__":
    raise SystemExit(main())
