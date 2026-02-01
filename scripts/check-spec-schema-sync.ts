#!/usr/bin/env npx tsx

/**
 * Checks for drift between spec documentation and JSON schemas.
 *
 * This script:
 * 1. Parses spec markdown files for documented block types
 * 2. Parses JSON schemas for defined block types
 * 3. Reports discrepancies between documented and implemented types
 */

import * as fs from 'fs';
import * as path from 'path';

const rootDir = path.join(__dirname, '..');
const specDir = path.join(rootDir, 'spec');
const schemasDir = path.join(rootDir, 'schemas');

interface BlockType {
  type: string;
  source: string;
  line?: number;
}

interface SyncReport {
  specOnly: BlockType[];
  schemaOnly: BlockType[];
  synced: string[];
}

// Extract block types from spec markdown files
function extractTypesFromSpec(filePath: string): BlockType[] {
  const types: BlockType[] = [];
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const filename = path.relative(rootDir, filePath);

  // Pattern: "type": "<name>" in JSON examples
  const typePattern = /"type":\s*"([^"]+)"/g;

  // Pattern: `"type": "xxx"` in inline code
  const inlinePattern = /`"type":\s*"([^"]+)"`/g;

  lines.forEach((line, index) => {
    let match;

    // Match JSON examples
    while ((match = typePattern.exec(line)) !== null) {
      const typeName = match[1];
      // Skip "text" as it's always present and not a block type
      if (typeName !== 'text' && !types.find(t => t.type === typeName)) {
        types.push({
          type: typeName,
          source: filename,
          line: index + 1
        });
      }
    }

    // Match inline code references
    while ((match = inlinePattern.exec(line)) !== null) {
      const typeName = match[1];
      if (typeName !== 'text' && !types.find(t => t.type === typeName)) {
        types.push({
          type: typeName,
          source: filename,
          line: index + 1
        });
      }
    }
  });

  return types;
}

// Extract block types from JSON schema files
function extractTypesFromSchema(filePath: string): BlockType[] {
  const types: BlockType[] = [];
  const content = fs.readFileSync(filePath, 'utf8');
  const filename = path.relative(rootDir, filePath);

  try {
    const schema = JSON.parse(content);

    // Look for const types in $defs
    if (schema.$defs) {
      for (const [defName, defValue] of Object.entries(schema.$defs)) {
        const def = defValue as Record<string, unknown>;

        // Check for type const in properties
        if (def.properties && typeof def.properties === 'object') {
          const props = def.properties as Record<string, unknown>;
          if (props.type && typeof props.type === 'object') {
            const typeProp = props.type as Record<string, unknown>;
            if (typeProp.const && typeof typeProp.const === 'string') {
              types.push({
                type: typeProp.const,
                source: filename
              });
            }
          }
        }
      }
    }

    // Also check allOf conditionals in block definitions
    if (schema.$defs?.block?.allOf) {
      const allOf = schema.$defs.block.allOf as Array<Record<string, unknown>>;
      for (const condition of allOf) {
        if (condition.if?.properties?.type?.const) {
          const typeName = condition.if.properties.type.const as string;
          if (!types.find(t => t.type === typeName)) {
            types.push({
              type: typeName,
              source: filename
            });
          }
        }
      }
    }
  } catch (err) {
    console.error(`Error parsing ${filename}: ${err}`);
  }

  return types;
}

// Recursively find all markdown files
function findMarkdownFiles(dir: string): string[] {
  const files: string[] = [];

  if (!fs.existsSync(dir)) {
    return files;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findMarkdownFiles(fullPath));
    } else if (entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }

  return files;
}

// Find all schema files
function findSchemaFiles(dir: string): string[] {
  const files: string[] = [];

  if (!fs.existsSync(dir)) {
    return files;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith('.schema.json')) {
      files.push(path.join(dir, entry.name));
    }
  }

  return files;
}

// Main sync check
function checkSync(): SyncReport {
  console.log('Checking spec-schema synchronization...\n');

  // Collect types from specs
  const specTypes: BlockType[] = [];
  const specFiles = findMarkdownFiles(specDir);
  console.log(`Found ${specFiles.length} spec files`);

  for (const file of specFiles) {
    const types = extractTypesFromSpec(file);
    specTypes.push(...types);
  }

  // Collect types from schemas
  const schemaTypes: BlockType[] = [];
  const schemaFiles = findSchemaFiles(schemasDir);
  console.log(`Found ${schemaFiles.length} schema files`);

  for (const file of schemaFiles) {
    const types = extractTypesFromSchema(file);
    schemaTypes.push(...types);
  }

  // Deduplicate
  const specTypeNames = [...new Set(specTypes.map(t => t.type))];
  const schemaTypeNames = [...new Set(schemaTypes.map(t => t.type))];

  console.log(`\nSpec documents ${specTypeNames.length} unique block types`);
  console.log(`Schemas define ${schemaTypeNames.length} unique block types\n`);

  // Find discrepancies
  const specOnly = specTypes.filter(t => !schemaTypeNames.includes(t.type));
  const schemaOnly = schemaTypes.filter(t => !specTypeNames.includes(t.type));
  const synced = specTypeNames.filter(t => schemaTypeNames.includes(t));

  return {
    specOnly: specOnly.filter((t, i, arr) => arr.findIndex(x => x.type === t.type) === i),
    schemaOnly: schemaOnly.filter((t, i, arr) => arr.findIndex(x => x.type === t.type) === i),
    synced
  };
}

// Run check
const report = checkSync();

// Report results
console.log('='.repeat(60));

if (report.synced.length > 0) {
  console.log(`\n✓ ${report.synced.length} types are synchronized:`);
  report.synced.sort().forEach(t => console.log(`    ${t}`));
}

if (report.specOnly.length > 0) {
  console.log(`\n⚠ ${report.specOnly.length} types documented in spec but not in schema:`);
  report.specOnly.forEach(t => {
    console.log(`    ${t.type}`);
    console.log(`      Source: ${t.source}${t.line ? `:${t.line}` : ''}`);
  });
}

if (report.schemaOnly.length > 0) {
  console.log(`\n⚠ ${report.schemaOnly.length} types in schema but not documented in spec:`);
  report.schemaOnly.forEach(t => {
    console.log(`    ${t.type}`);
    console.log(`      Source: ${t.source}`);
  });
}

console.log('\n' + '='.repeat(60));

// Exit with error if there are discrepancies
if (report.specOnly.length > 0 || report.schemaOnly.length > 0) {
  console.log('\nSpec-schema sync check found discrepancies.');
  // Don't fail - this is informational for now
  // process.exit(1);
} else {
  console.log('\nAll documented types have schema definitions.');
}
