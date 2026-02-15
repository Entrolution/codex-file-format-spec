/**
 * Shared AJV utilities for schema validation scripts.
 */

import Ajv2020 from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';

const schemasDir = path.join(__dirname, '..', '..', 'schemas');

export function createAjv(): Ajv2020 {
  const ajv = new Ajv2020({
    strict: false,
    allErrors: true,
  });
  addFormats(ajv);
  return ajv;
}

export function loadSchema(filename: string): object {
  const filepath = path.join(schemasDir, filename);
  const content = fs.readFileSync(filepath, 'utf8');
  return JSON.parse(content);
}
