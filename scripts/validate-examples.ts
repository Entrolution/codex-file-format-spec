#!/usr/bin/env npx tsx

/**
 * Validates example documents against their corresponding schemas.
 */

import Ajv2020, { ValidateFunction } from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';

const schemasDir = path.join(__dirname, '..', 'schemas');
const examplesDir = path.join(__dirname, '..', 'examples');

interface Validation {
  schema: string;
  file: string;
}

// Schema validators (compiled once)
const validators: Record<string, ValidateFunction> = {};

function createAjv(): Ajv2020 {
  const ajv = new Ajv2020({
    strict: false,
    allErrors: true,
  });
  addFormats(ajv);
  return ajv;
}

function loadSchema(filename: string): object {
  const filepath = path.join(schemasDir, filename);
  const content = fs.readFileSync(filepath, 'utf8');
  return JSON.parse(content);
}

function loadJson(filepath: string): unknown {
  const content = fs.readFileSync(filepath, 'utf8');
  return JSON.parse(content);
}

// Schema dependencies (schemas that need other schemas loaded first)
const schemaDependencies: Record<string, string[]> = {
  'content.schema.json': ['semantic.schema.json', 'academic.schema.json', 'presentation.schema.json'],
  'collaboration.schema.json': ['anchor.schema.json'],
  'phantoms.schema.json': ['anchor.schema.json'],
  'security.schema.json': ['anchor.schema.json'],
};

function getValidator(schemaName: string): ValidateFunction {
  if (!validators[schemaName]) {
    const ajv = createAjv();
    // Load dependency schemas first
    const deps = schemaDependencies[schemaName] || [];
    for (const dep of deps) {
      const depSchema = loadSchema(dep);
      ajv.addSchema(depSchema);
    }
    const schema = loadSchema(schemaName);
    validators[schemaName] = ajv.compile(schema);
  }
  return validators[schemaName];
}

// Document validations to perform (common files)
const validations: Validation[] = [
  { schema: 'manifest.schema.json', file: 'manifest.json' },
  { schema: 'content.schema.json', file: 'content/document.json' },
  { schema: 'dublin-core.schema.json', file: 'metadata/dublin-core.json' },
];

// Extension-specific validations (only if files exist)
const extensionValidations: Validation[] = [
  { schema: 'collaboration.schema.json', file: 'collaboration/comments.json' },
  { schema: 'collaboration.schema.json', file: 'collaboration/changes.json' },
  { schema: 'forms.schema.json', file: 'forms/data.json' },
  { schema: 'phantoms.schema.json', file: 'phantoms/clusters.json' },
];

let hasErrors = false;

console.log('Validating example documents...\n');

// Find all example directories
const exampleDirs = fs.readdirSync(examplesDir, { withFileTypes: true })
  .filter(dirent => dirent.isDirectory())
  .map(dirent => dirent.name);

for (const exampleName of exampleDirs) {
  console.log(`${exampleName}/`);
  const examplePath = path.join(examplesDir, exampleName);

  // Validate common files
  for (const { schema, file } of validations) {
    const filepath = path.join(examplePath, file);

    if (!fs.existsSync(filepath)) {
      console.log(`  - ${file} (not found, skipping)`);
      continue;
    }

    try {
      const validate = getValidator(schema);
      const data = loadJson(filepath);
      const valid = validate(data);

      if (valid) {
        console.log(`  ✓ ${file}`);
      } else {
        console.log(`  ✗ ${file}`);
        for (const err of validate.errors ?? []) {
          console.log(`    - ${err.instancePath || '/'}: ${err.message}`);
        }
        hasErrors = true;
      }
    } catch (err) {
      console.log(`  ✗ ${file}`);
      console.log(`    Error: ${err instanceof Error ? err.message : String(err)}`);
      hasErrors = true;
    }
  }

  // Validate extension-specific files (silently skip if not present)
  for (const { schema, file } of extensionValidations) {
    const filepath = path.join(examplePath, file);

    if (!fs.existsSync(filepath)) {
      continue;
    }

    try {
      const validate = getValidator(schema);
      const data = loadJson(filepath);
      const valid = validate(data);

      if (valid) {
        console.log(`  ✓ ${file}`);
      } else {
        console.log(`  ✗ ${file}`);
        for (const err of validate.errors ?? []) {
          console.log(`    - ${err.instancePath || '/'}: ${err.message}`);
        }
        hasErrors = true;
      }
    } catch (err) {
      console.log(`  ✗ ${file}`);
      console.log(`    Error: ${err instanceof Error ? err.message : String(err)}`);
      hasErrors = true;
    }
  }
  console.log('');
}

if (hasErrors) {
  console.log('Example validation failed!');
  process.exit(1);
} else {
  console.log('All examples valid.');
}
