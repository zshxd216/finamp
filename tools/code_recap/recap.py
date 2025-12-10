import json, os, subprocess

year = 2025
activeBranch = "redesign"

def gitcheckout(hash):
    p = subprocess.Popen(['git', 'checkout', hash], cwd="./finamp", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    p.wait()

def du(path):
    return subprocess.check_output(['du','-sh', path]).split()[0].decode('utf-8')


data = json.load(open("./gitstat_result.json"))

print(f"In {year} .... ")

commits = []
for commit in data["projects"][0]["commits"]:
    if (commit["message"].endswith("Translations update from Hosted Weblate")): continue
    commit["files"] = [file for file in commit["files"] if (not file["filepath"].startswith("lib/l10n")) and (not file["filepath"].endswith(".g.dart"))]
    commits.append(commit)
commitsBefore = [commit for commit in commits if not commit["author"]["time"].startswith(str(year))]
commitsWithin = [commit for commit in commits if commit["author"]["time"].startswith(str(year))]

print(f"- {len(commitsWithin)} commits were made", end=" ")
print(f"(now a total of {len(commitsBefore) + len(commitsWithin)} commits)")

authors = set([x["author"]["name"] for x in commits])
authorsBefore = set([commit["author"]["name"] for commit in commitsBefore])
authorsWithin = set([commit["author"]["name"] for commit in commitsWithin])
newAuthors = authorsWithin.difference(authorsBefore)

print(f"- {len(newAuthors)} authors made their first commit", end=" ")
print(f"(now a total of {len(authorsBefore) + len(newAuthors)} people contributed)")

additions = [sum([file["additions"] for file in commit["files"]]) for commit in commitsWithin]
deletions = [sum([file["deletions"] for file in commit["files"]]) for commit in commitsWithin]

print(f"- {sum(additions)} lines of codes were added")
print(f"- {sum(deletions)} lines of codes were removed")
print(f"- So a total of {sum(additions) + sum(deletions)} changes")
print(f"- And a final difference of {sum(additions) - sum(deletions)} additions")
print(f"- which averages to ...")
print(f"  - {round(sum(additions) / len(additions))} additions per commit")
print(f"  - {round(sum(deletions) / len(deletions))} deletions per commit")

commitMessages = [len(x["message"].split(" ")) for x in commitsWithin]
print(f"- commit messages contained {sum(commitMessages)} words in total")

merges = [x for x in commitsWithin if commit["isMerge"]]
print(f"- {len(merges)} PRs got merged")



commitsPerAuthor = [[author, len([commit for commit in commitsWithin if commit["author"]["name"] == author])] for author in newAuthors]
commitsPerAuthor.sort(key=lambda a: -a[1])
print(f"- top new contributers based on commits")
for i, a in enumerate(commitsPerAuthor[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} commits")

changesPerAuthor = [[author, sum([sum([(file["additions"] - file["deletions"]) for file in commit["files"]]) for commit in commitsWithin if commit["author"]["name"] == author])] for author in newAuthors]
changesPerAuthor.sort(key=lambda a: -a[1])
print(f"- top new contributers based on additions")
for i, a in enumerate(changesPerAuthor[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} additions")


commitsPerAuthorLifeTime = [[author, len([commit for commit in commits if commit["author"]["name"] == author])] for author in authors]
commitsPerAuthorLifeTime.sort(key=lambda a: -a[1])

print(f"- top contributers based on commits")
for i, a in enumerate(commitsPerAuthorLifeTime[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} commits")

changesPerAuthorLifeTime = [[author, sum([sum([(file["additions"] - file["deletions"]) for file in commit["files"]]) for commit in commits if commit["author"]["name"] == author])] for author in authors]
changesPerAuthorLifeTime.sort(key=lambda a: -a[1])
print(f"- top contributers based on additions")
for i, a in enumerate(changesPerAuthorLifeTime[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} additions")

firstCommitOfYear = list(commitsWithin)
firstCommitOfYear.sort(key=lambda x: x["author"]["time"])
firstCommitOfYear = firstCommitOfYear[0]

gitcheckout(firstCommitOfYear["hash"])
print(f"In the begining of {year} the lib folder was {du("./finamp/lib")} Big", end=" ")
gitcheckout(activeBranch)
print(f"and now its {du("./finamp/lib")}!")