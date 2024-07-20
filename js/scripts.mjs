// @ts-check

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// 获取当前文件的 URL
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const tpl = `
import Foundation

extension CBWebkitBridge {
public static let jsScript = """
__content__ 
"""
}

`;

const content = await fs.readFile(path.join(__dirname, './dist/umd/cbWebkitBridge.min.js'), 'utf-8');

await fs.writeFile(path.join(__dirname, '../Sources/CBWebkitBridge/CBWebKitBridgeJs.swift'), tpl.replace('__content__', content));