/**
 * @file This is a workaround to update the fingerprints / checksum for a given Taskfile task,
 * WITHOUT actually running it! I'm hoping that in the future this will be baked into task as
 * something like `task --mark-up-to-date {TASK}`, but for now this is a convenient script to have.
 *
 * It uses a temporary taskfile and task entry, with the actual `cmd` / `cmds` stripped out and replaced with
 * a harmless noop
 *
 * @example
 * ```bash
 * TASK_NAME="my-expensive-task" TASKFILE="$PWD/Taskfile.yml" node task_mark_up_to_date.mjs
 * ```
 */

// @ts-check
// Requires the `yaml` package for parsing and writing the taskfile
import { parse, stringify } from 'yaml';
import { readFileSync, writeFileSync, copyFileSync, rmSync } from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

// Try to avoid collision with any existing tasks, just in case
const NOOP_TASK_NAME = 'fingerprint_noop_dont_use_this_name';

const taskName = process.env.TASK_NAME;
const taskfilePath = process.env.TASKFILE_PATH;

if (!taskName || !taskfilePath) {
	console.error(`Invalid taskfile path (${taskfilePath}) or task name (${taskName})`);
	process.exit(1);
}
const taskfileDir = path.dirname(taskfilePath);

const parsedTaskfile = parse(readFileSync(taskfilePath).toString());
const taskEntry = parsedTaskfile.tasks[taskName];

if (!taskEntry) {
	console.error(`Invalid task name; ${taskName} was not found in .tasks`);
	console.log(`Valid task names: ${Object.keys(parsedTaskfile.tasks).join(', ')}`);
	process.exit(1);
}

// Check for bare commands
if (typeof taskEntry === 'string') {
	console.error('Invalid task entry - bare command found');
	process.exit(1);
}

// Check for absense of inputs to fingerprint / {{.CHECKSUM}}
if (!taskEntry.sources && !taskEntry.generates) {
	console.error('Invalid task entry - no inputs for fingerprinting. Include `sources` and/or `generates`.');
	process.exit(1);
}

// Good to go!
// Start by cloning task of entry, and configuring it to be a noop for fingerprinting
const cloneEntryForFingerprinting = structuredClone(taskEntry);
delete cloneEntryForFingerprinting.cmds;
cloneEntryForFingerprinting.cmd = 'true';

// Now, clone entire taskfile, with add noop entry, and save to temp file
parsedTaskfile.tasks[NOOP_TASK_NAME] = cloneEntryForFingerprinting;
const tempTaskfilePath = path.join(taskfileDir, 'taskfile_fingerprint_temp.yml');
writeFileSync(
	tempTaskfilePath,
	stringify(parsedTaskfile, {
		toStringDefaults: {
			// auto-wrapping breaks a LOT
			lineWidth: 0,
		},
	})
);

// Exec task, which will generate checksum file
execSync(`task -t ${tempTaskfilePath} ${NOOP_TASK_NAME}`, { stdio: 'inherit' });

// Copy over checksum file
const checksumDir = path.join(taskfileDir, '.task', 'checksum');
const originalCheckSumPath = path.join(checksumDir, taskName).replace(/:/g, '-');
const originalCheckSumVal = readFileSync(originalCheckSumPath).toString().trim();
const updatedCheckSumTempPath = path.join(checksumDir, NOOP_TASK_NAME);
const updatedCheckSumVal = readFileSync(path.join(checksumDir, NOOP_TASK_NAME)).toString().trim();
copyFileSync(updatedCheckSumTempPath, originalCheckSumPath);

// We are done!
if (originalCheckSumVal === updatedCheckSumVal) {
	console.log(`🙈 No changes to checksum for ${taskName}`);
} else {
	console.log(`⏩️ Updated checksum for ${taskName} from ${originalCheckSumVal} to ${updatedCheckSumVal}`);
}

// Cleanup
rmSync(tempTaskfilePath);
rmSync(updatedCheckSumTempPath);
console.log('Cleanup complete');
