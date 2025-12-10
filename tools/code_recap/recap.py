import json
from extract_history import main
from datetime import datetime

start = datetime.fromisoformat("2025-01-01T00:00:00+01:00")
end = datetime.fromisoformat("2025-12-31T23:59:59+01:00")

# (name, alias) -> if a commit is named with the alias, it will be replaced with the name
merge = [("Floschy", "flloschy")];


# data = json.load(open("./repo_history.json", "r"))
data = main()

commits = []
for d in data:
    if "weblate" in d["message"]: continue
    if "Weblate" in d["message"]: continue
    d["date"] = datetime.fromisoformat(d["date"])
    if d["date"] > end: continue
    d["files"] = [f for f in d["stats"]["files"] if not f["path"].endswith(".g.dart") and not f["path"].startswith("lib/l10n") ]
    for (a, b) in merge:
        if d["author"] == b:
            d["author"] = a
            break;
    commits.append(d)

def dateBefore(x):
    return x < start
def dateInside(x):
    return x >= start


commitsBefore = [commit for commit in commits if dateBefore(commit["date"])]
commitsWithin = [commit for commit in commits if dateInside(commit["date"])]


allAuthors = set([commit["author"] for commit in commits])
authorsBefore = set([commit["author"] for commit in commitsBefore])
authorsWithin = set([commit["author"] for commit in commitsWithin])
newAuthors = authorsWithin.difference(authorsBefore)


pullRequestsBefore = [commit for commit in commitsBefore if commit["is_merge"]]
pullRequestsWithin = [commit for commit in commitsWithin if commit["is_merge"]]

changesPerPullRequestsBefore = [commit["stats"]["total_changes"] for commit in commitsBefore if commit["is_merge"]]
changesPerPullRequestsWithin = [commit["stats"]["total_changes"] for commit in commitsWithin if commit["is_merge"]]


additionsBefore = [commit["stats"]["total_additions"] for commit in commitsBefore]
additionsWithin = [commit["stats"]["total_additions"] for commit in commitsWithin]
additions = additionsBefore + additionsWithin

deletionsBefore = [commit["stats"]["total_deletions"] for commit in commitsBefore]
deletionsWithin = [commit["stats"]["total_deletions"] for commit in commitsWithin]
deletions = deletionsBefore + deletionsWithin

commitMessagesWithin = [len(commit["message"].split(" ")) for commit in commitsWithin]

changesPerNewAuthor = [(author, sum([commit["stats"]["total_changes"] for commit in commitsWithin if commit["author"] == author])) for author in newAuthors]
commitsPerNewAuthor = [(author, len([commit for commit in commitsWithin if commit["author"] == author])) for author in newAuthors]
changesPerNewAuthor.sort(key=lambda x: -x[1])
commitsPerNewAuthor.sort(key=lambda x: -x[1])

changesPerAuthor = [(author, sum([commit["stats"]["total_changes"] for commit in commits if commit["author"] == author])) for author in allAuthors]
commitsPerAuthor = [(author, len([commit for commit in commits if commit["author"] == author])) for author in allAuthors]
changesPerAuthor.sort(key=lambda x: -x[1])
commitsPerAuthor.sort(key=lambda x: -x[1])






markdown = f"""
# These are the statistics from {start} to {end}:

| Scope         | Description           | Value                                                                                                                       |
|:--------------|:----------------------|:----------------------------------------------------------------------------------------------------------------------------|
| **Timeframe** | Commits               |  {(len(commitsWithin)):,}                                                                                                   |
| **Timeframe** | New Authors           |  {(len(newAuthors)):,}                                                                                                      |
| **Timeframe** | + Additions           |  {(sum(additionsWithin)):,} lines                                                                                           |
| **Timeframe** | - Deletions           |  {(sum(deletionsWithin)):,} lines                                                                                           |
| **Timeframe** | Additions per Commit  |  {round(sum(additionsWithin) / len(commitsWithin)):,} lines                                                                 |
| **Timeframe** | Deletions per Commit  |  {round(sum(deletionsWithin) / len(commitsWithin)):,} lines                                                                 |
| **Timeframe** | Total Difference      | +{(sum(additionsWithin) - sum(deletionsWithin)):,} lines                                                                    |
| **Timeframe** | Commit Message        |  {(sum(commitMessagesWithin)):,} words                                                                                      |
| **Timeframe** | Pull Requests Merged  |  {len(pullRequestsWithin):,}                                                                                                |
| **Timeframe** | Changes Per PR        |  {round(sum(changesPerPullRequestsWithin) / len(pullRequestsWithin)):,}                                                     |
|               |                       |                                                                                                                             |
| *(Lifetime)*  | Commits               |  {(len(commitsBefore) + len(commitsWithin)):,}                                                                              |
| *(Lifetime)*  | Authors               |  {(len(authorsBefore) + len(newAuthors)):,}                                                                                 |
| *(Lifetime)*  | + Additions           |  {(sum(additionsWithin) + sum(additionsBefore)):,} lines                                                                    |
| *(Lifetime)*  | - Deletions           |  {(sum(deletionsWithin) + sum(deletionsBefore)):,} lines                                                                    |
| *(Lifetime)*  | Additions per Commit  |  {round(sum(deletions) / len(commits)):,} lines                                                                             |
| *(Lifetime)*  | Deletions per Commit  |  {round(sum(deletions) / len(commits)):,} lines                                                                             |
| *(Lifetime)*  | Pull Requests Merged  |  {len(pullRequestsBefore + pullRequestsWithin):,}                                                                           |
| *(Lifetime)*  | Changes Per PR        |  {round(sum(changesPerPullRequestsBefore + changesPerPullRequestsWithin) / len(pullRequestsBefore + pullRequestsWithin)):,} |

_____

## New Authors ranked by changes (additions + deletions):

| Nr | Name                        | Changes                       |     | Nr | Name                        | Changes                       |
|:---|:----------------------------|:------------------------------|:---:|:---|:----------------------------|:------------------------------|
| 1. | {changesPerNewAuthor[0][0]} | {changesPerNewAuthor[0][1]:,} |     | 6. | {changesPerNewAuthor[5][0]} | {changesPerNewAuthor[5][1]:,} |
| 2. | {changesPerNewAuthor[1][0]} | {changesPerNewAuthor[1][1]:,} |     | 7. | {changesPerNewAuthor[6][0]} | {changesPerNewAuthor[6][1]:,} |
| 3. | {changesPerNewAuthor[2][0]} | {changesPerNewAuthor[2][1]:,} |     | 8. | {changesPerNewAuthor[7][0]} | {changesPerNewAuthor[7][1]:,} |
| 4. | {changesPerNewAuthor[3][0]} | {changesPerNewAuthor[3][1]:,} |     | 9. | {changesPerNewAuthor[8][0]} | {changesPerNewAuthor[8][1]:,} |
| 5. | {changesPerNewAuthor[4][0]} | {changesPerNewAuthor[4][1]:,} |     | 10.| {changesPerNewAuthor[9][0]} | {changesPerNewAuthor[9][1]:,} |



## New Authors ranked by commits:

| Nr | Name                        | Commits                       |     | Nr | Name                        | Commits                       |
|:---|:----------------------------|:------------------------------|:---:|:---|:----------------------------|:------------------------------|
| 1. | {commitsPerNewAuthor[0][0]} | {commitsPerNewAuthor[0][1]:,} |     | 6. | {commitsPerNewAuthor[5][0]} | {commitsPerNewAuthor[5][1]:,} |
| 2. | {commitsPerNewAuthor[1][0]} | {commitsPerNewAuthor[1][1]:,} |     | 7. | {commitsPerNewAuthor[6][0]} | {commitsPerNewAuthor[6][1]:,} |
| 3. | {commitsPerNewAuthor[2][0]} | {commitsPerNewAuthor[2][1]:,} |     | 8. | {commitsPerNewAuthor[7][0]} | {commitsPerNewAuthor[7][1]:,} |
| 4. | {commitsPerNewAuthor[3][0]} | {commitsPerNewAuthor[3][1]:,} |     | 9. | {commitsPerNewAuthor[8][0]} | {commitsPerNewAuthor[8][1]:,} |
| 5. | {commitsPerNewAuthor[4][0]} | {commitsPerNewAuthor[4][1]:,} |     | 10.| {commitsPerNewAuthor[9][0]} | {commitsPerNewAuthor[9][1]:,} |



## All-time Authors ranked by changes (additions + deletions):

| Nr | Name                     | Changes                    |     | Nr | Name                     | Changes                    |
|:---|:-------------------------|:---------------------------|:---:|:---|:-------------------------|:---------------------------|
| 1. | {changesPerAuthor[0][0]} | {changesPerAuthor[0][1]:,} |     | 6. | {changesPerAuthor[5][0]} | {changesPerAuthor[5][1]:,} |
| 2. | {changesPerAuthor[1][0]} | {changesPerAuthor[1][1]:,} |     | 7. | {changesPerAuthor[6][0]} | {changesPerAuthor[6][1]:,} |
| 3. | {changesPerAuthor[2][0]} | {changesPerAuthor[2][1]:,} |     | 8. | {changesPerAuthor[7][0]} | {changesPerAuthor[7][1]:,} |
| 4. | {changesPerAuthor[3][0]} | {changesPerAuthor[3][1]:,} |     | 9. | {changesPerAuthor[8][0]} | {changesPerAuthor[8][1]:,} |
| 5. | {changesPerAuthor[4][0]} | {changesPerAuthor[4][1]:,} |     | 10.| {changesPerAuthor[9][0]} | {changesPerAuthor[9][1]:,} |


## All-time Authors ranked by commits:

| Nr | Name                     | Commits                    |     | Nr | Name                     | Commits                    |
|:---|:-------------------------|:---------------------------|:---:|:---|:-------------------------|:---------------------------|
| 1. | {commitsPerAuthor[0][0]} | {commitsPerAuthor[0][1]:,} |     | 6. | {commitsPerAuthor[5][0]} | {commitsPerAuthor[5][1]:,} |
| 2. | {commitsPerAuthor[1][0]} | {commitsPerAuthor[1][1]:,} |     | 7. | {commitsPerAuthor[6][0]} | {commitsPerAuthor[6][1]:,} |
| 3. | {commitsPerAuthor[2][0]} | {commitsPerAuthor[2][1]:,} |     | 8. | {commitsPerAuthor[7][0]} | {commitsPerAuthor[7][1]:,} |
| 4. | {commitsPerAuthor[3][0]} | {commitsPerAuthor[3][1]:,} |     | 9. | {commitsPerAuthor[8][0]} | {commitsPerAuthor[8][1]:,} |
| 5. | {commitsPerAuthor[4][0]} | {commitsPerAuthor[4][1]:,} |     | 10.| {commitsPerAuthor[9][0]} | {commitsPerAuthor[9][1]:,} |
"""


for _ in range(100):
    markdown = markdown.replace("  ", " ").replace("----", "---")

print(markdown)
