import json, os, subprocess

year = 2025
activeBranch = "redesign"

def gitcheckout(hash):
    p = subprocess.Popen(['git', 'checkout', hash], cwd="./finamp", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    p.wait()

def du(path):
    return subprocess.check_output(['du','-sh', path]).split()[0].decode('utf-8')


data = json.load(open("./gitstat_result.json"))

# Filter Commits to exclude some spammy ones
commits = []
for commit in data["projects"][0]["commits"]:
    if (commit["message"].endswith("Translations update from Hosted Weblate")):
        continue
    commit["files"] = [file for file in commit["files"] if (not file["filepath"].startswith("lib/l10n")) and (not file["filepath"].endswith(".g.dart"))]
    commits.append(commit)

# commits before/after the given year
commitsBefore = [commit for commit in commits if not commit["author"]["time"].startswith(str(year))]
commitsWithin = [commit for commit in commits if commit["author"]["time"].startswith(str(year))]


# [all] authors before/after the given year
authors = set([x["author"]["name"] for x in commits])
authorsBefore = set([commit["author"]["name"] for commit in commitsBefore])
authorsWithin = set([commit["author"]["name"] for commit in commitsWithin])
# authers who only appear within the year
newAuthors = authorsWithin.difference(authorsBefore)


# sum of additions/deletions
additions = [sum([file["additions"] for file in commit["files"]]) for commit in commitsWithin]
deletions = [sum([file["deletions"] for file in commit["files"]]) for commit in commitsWithin]


commitMessages = [len(x["message"].split(" ")) for x in commitsWithin]
merges = [int(x["isMerge"]) for x in commitsWithin]


# [author, commits]
commitsPerAuthor = [[author, len([commit for commit in commitsWithin if commit["author"]["name"] == author])] for author in newAuthors]
commitsPerAuthor.sort(key=lambda a: -a[1])

# [author, changes]
changesPerAuthor = [[author, sum([sum([(file["additions"] - file["deletions"]) for file in commit["files"]]) for commit in commitsWithin if commit["author"]["name"] == author])] for author in newAuthors]
changesPerAuthor.sort(key=lambda a: -a[1])

# [author, commits]
commitsPerAuthorLifeTime = [[author, len([commit for commit in commits if commit["author"]["name"] == author])] for author in authors]
commitsPerAuthorLifeTime.sort(key=lambda a: -a[1])

# [author, changes]
changesPerAuthorLifeTime = [[author, sum([sum([(file["additions"] - file["deletions"]) for file in commit["files"]]) for commit in commits if commit["author"]["name"] == author])] for author in authors]
changesPerAuthorLifeTime.sort(key=lambda a: -a[1])


# The hash of the first commit
firstCommitOfYear = list(commitsWithin)
firstCommitOfYear.sort(key=lambda x: x["author"]["time"])
firstCommitOfYear = firstCommitOfYear[0]["hash"]

# Get File-System Level stats from the begining of the year
gitcheckout(firstCommitOfYear)
translationsMapBefore = json.load(open("./finamp/lib/l10n/app_en.arb", "r"))
translationKeysBefore = [x for x in translationsMapBefore.keys() if not x.startswith("@")]
translationWordsBefore = len([len(translationsMapBefore[x].split(" ")) for x in translationKeysBefore])
projectSizeBefore = du("./finamp/lib")

# Get File-System Level stats from now
gitcheckout(activeBranch)
translationsMapAfter = json.load(open("./finamp/lib/l10n/app_en.arb", "r"))
translationKeysAfter = [x for x in translationsMapAfter.keys() if not x.startswith("@")]
translationWordsAfter = len([len(translationsMapAfter[x].split(" ")) for x in translationKeysAfter])
projectSizeAfter = du("./finamp/lib")


# output

print(f"In {year} the codebase of the '{activeBranch}' branch had a size of `{projectSizeBefore}` now its `{projectSizeAfter}`. But why is that?")

print(f"- {len(commitsWithin):,} commits were made", end=" ")
print(f"(now a total of {(len(commitsBefore) + len(commitsWithin)):,} commits)")

print(f"- {len(newAuthors):,} authors made their *first* commit", end=" ")
print(f"(now a total of {(len(authorsBefore) + len(newAuthors)):,} people contributed!)")

print(f"- {sum(additions):,} lines of codes were added")
print(f"- {sum(deletions):,} lines of codes were removed")
print(f"- So a total of {(sum(additions) + sum(deletions)):,} changes")
print(f"- Which is a difference of {(sum(additions) - sum(deletions)):,} additions")

print(f"- which averages to ...")
print(f"  - {round(sum(additions) / len(additions)):,} additions per commit")
print(f"  - {round(sum(deletions) / len(deletions)):,} deletions per commit")

print(f"- commit messages contained {sum(commitMessages):,} words in total")
print(f"- {sum(merges):,} PRs got merged")
print(f"- {(len(translationKeysAfter) - len(translationKeysBefore)):,} translation strings were added ({len(translationsMapAfter):,} total)")
print(f"- which is {(translationWordsAfter - translationWordsBefore):,} new words in the english translation ({translationWordsAfter:,} total)")

print(f"- top **new** contributers based on commits (*)")
for i, a in enumerate(commitsPerAuthor[:5]):
    print(f"   {i+1}. **{a[0]}** with `{a[1]:,}` commits")

print(f"- top **new** contributers based on additions (*)")
for i, a in enumerate(changesPerAuthor[:5]):
    print(f"   {i+1}. **{a[0]}** with `{a[1]:,}` additions")

print(f"- top **alltime** contributers based on commits (*)")
for i, a in enumerate(commitsPerAuthorLifeTime[:5]):
    print(f"   {i+1}. **{a[0]}** with `{a[1]:,}` commits")

print(f"- top **alltime** based on additions (*)")
for i, a in enumerate(changesPerAuthorLifeTime[:5]):
    print(f"   {i+1}. **{a[0]}** with `{a[1]:,}` additions")

print("* Please understand that these stats are **just for fun** and dont represent any good objective metric")
print("  Numbers may also not be totally acurrate and are only a non-representetive snapshot of one moment in time")