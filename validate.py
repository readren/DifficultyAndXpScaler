#!/usr/bin/env python3
"""
DifficultyMod Validator
Tests XML metadata, JSON configs, and validates Lua syntax with an AST parser.
Ensures zero huge static tables exist in the package.
"""
import glob
import json
import os
import sys
import xml.etree.ElementTree as ET
from luaparser import ast

def main():
    print("=== Validating DifficultyMod Project ===")
    errors = 0

    # 1. Validate meta.lsx XML
    meta_path = "Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/meta.lsx"
    try:
        ET.parse(meta_path)
        print(f"[OK] {meta_path} (Valid XML)")
    except Exception as e:
        print(f"[FAIL] {meta_path}: {e}")
        errors += 1

    # 2. Validate JSON configs
    json_configs = [
        "Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/ScriptExtender/Config.json",
        "Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/OsiToolsConfig.json"
    ]
    for cfg in json_configs:
        try:
            with open(cfg, "r", encoding="utf-8") as f:
                json.load(f)
            print(f"[OK] {cfg} (Valid JSON)")
        except Exception as e:
            print(f"[FAIL] {cfg}: {e}")
            errors += 1

    # 3. Validate all Lua files with strict AST parsing
    lua_files = glob.glob("Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/Story/RawFiles/Lua/*.lua")
    if not lua_files:
        print("[FAIL] No Lua files found in Story/RawFiles/Lua/")
        errors += 1
    for lf in lua_files:
        try:
            with open(lf, "r", encoding="utf-8") as f:
                src = f.read()
            ast.parse(src)
            print(f"[OK] {lf} (Valid Lua AST)")
        except Exception as e:
            print(f"[FAIL] {lf}: {e}")
            errors += 1

    # 4. Verify no static Public tables exist
    if os.path.exists("Public"):
        print("[FAIL] Public/ directory exists (Huge tables should not be included)")
        errors += 1
    else:
        print("[OK] Pure Script Extender project (0 static stat table overrides)")

    if errors == 0:
        print("\nAll project files passed 100% verification!")
        return 0
    else:
        print(f"\nFound {errors} error(s) during validation.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
