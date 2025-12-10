import subprocess
import json
import os
import re
import sys
from datetime import datetime

PATH = "./" 


def run_git_command(args, cwd):
    try:
        result = subprocess.run(
            ['git'] + args,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding='utf-8',
            errors='replace'
        )
        if result.returncode != 0:
            print(f"Error running git command: {result.stderr}", file=sys.stderr)
            return None
        return result.stdout.strip()
    except FileNotFoundError:
        print("Error: 'git' command not found. Please ensure Git is installed.", file=sys.stderr)
        sys.exit(1)

def get_commit_stats(commit_hash, cwd):
    output = run_git_command(['show', '--numstat', '--format=', commit_hash], cwd)

    files_changed = []
    total_additions = 0
    total_deletions = 0

    if not output:
        return files_changed, 0, 0

    for line in output.split('\n'):
        if not line.strip():
            continue

        parts = line.split(maxsplit=2)
        if len(parts) < 3:
            continue

        additions_raw, deletions_raw, file_path = parts

        if additions_raw == '-' or deletions_raw == '-':
            additions = 0
            deletions = 0
        else:
            additions = int(additions_raw)
            deletions = int(deletions_raw)

        files_changed.append({
            "path": file_path,
            "additions": additions,
            "deletions": deletions,
            "total_changes": additions + deletions
        })

        total_additions += additions
        total_deletions += deletions

    return files_changed, total_additions, total_deletions

def main():
    if not os.path.exists(os.path.join(PATH, ".git")):
        print(f"Error: No git repository found at {PATH}")
        return

    print(f"Processing repository at: {PATH}...")

    hashes_output = run_git_command(['log', '--pretty=format:%H'], PATH)
    if not hashes_output:
        print("No commits found.")
        return

    commit_hashes = hashes_output.split('\n')
    history_data = []

    total_commits = len(commit_hashes)
    print(f"Found {total_commits} commits. Extracting details...")

    for i, commit_hash in enumerate(commit_hashes):
        # Progress indicator
        if i % 100 == 0:
            print(f"Processing {i}/{total_commits}...")

        meta_cmd = [
            'show', 
            '-s', 
            '--format=%H%n%an%n%ae%n%cn%n%ce%n%aI%n%P%n%s%n%b', 
            commit_hash
        ]
        meta_output = run_git_command(meta_cmd, PATH)

        if not meta_output:
            continue

        lines = meta_output.split('\n')

        c_hash = lines[0]
        a_name = lines[1]
        a_email = lines[2]
        c_name = lines[3]
        c_email = lines[4]
        date_iso = lines[5]
        parents = lines[6].split()
        subject = lines[7]

        body = "\n".join(lines[8:])

        # Determine Merge Status
        is_merge = len(parents) > 1
        # Detect if it's a GitHub PR Merge via standard commit message pattern
        is_pr_merge = is_merge and ("Merge pull request" in subject or "Merge branch" in subject)

        # Get File Stats
        files, adds, dels = get_commit_stats(c_hash, PATH)

        commit_entry = {
            "hash": c_hash,
            "author": a_name,
            "date": date_iso,
            "is_merge": is_merge,
            "message": subject,
            "stats": {
                "total_changes": adds + dels,
                "total_additions": adds,
                "total_deletions": dels,
                "files": files
            }
        }

        history_data.append(commit_entry)


    output_file = "repo_history.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(history_data, f, indent=2)
    print(f"\nSuccess! Extracted {len(history_data)} commits to '{output_file}'.")

    return history_data

if __name__ == "__main__":
    main()
