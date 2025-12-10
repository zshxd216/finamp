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
for x in data["projects"][0]["commits"]:
    if (x["message"].endswith("Translations update from Hosted Weblate")): continue
    x["files"] = [y for y in x["files"] if not y["filepath"].startswith("lib/l10n")]
    commits.append(x)
commitsBefore = [x for x in commits if not x["author"]["time"].startswith(str(year))]
commitsWithin = [x for x in commits if x["author"]["time"].startswith(str(year))]

print(f"- {len(commitsWithin)} commits were made", end="")
print(f"(now a total of {len(commitsBefore) + len(commitsWithin)} commits)")

authors = set([x["author"]["name"] for x in commits])
authorsBefore = set([x["author"]["name"] for x in commitsBefore])
authorsWithin = set([x["author"]["name"] for x in commitsWithin])
newAuthors = authorsWithin.difference(authorsBefore)

print(f"- {len(newAuthors)} authors made their first commit", end="")
print(f"(now a total of {len(authorsBefore) + len(newAuthors)} people contributed)")

additions = [sum([y["additions"] for y in x["files"]]) for x in commitsWithin]
deletions = [sum([y["deletions"] for y in x["files"]]) for x in commitsWithin]

print(f"- {sum(additions)} lines of codes were added")
print(f"- {sum(deletions)} lines of codes were removed")
print(f"- So a total of {sum(additions) + sum(deletions)} changes")
print(f"- which averages to ...")
print(f"  - {round(sum(additions) / len(additions))} additions per commit")
print(f"  - {round(sum(deletions) / len(deletions))} deletions per commit")

commitMessages = [len(x["message"].split(" ")) for x in commitsWithin]
print(f"- commit messages contained {sum(commitMessages)} words in total")

merges = [x for x in commitsWithin if x["isMerge"]]
print(f"- {len(merges)} PRs got merged")



commitsPerAuthor = [[a, len([x for x in commitsWithin if x["author"]["name"] == a])] for a in newAuthors]
commitsPerAuthor.sort(key=lambda a: -a[1])
print(f"- top new contributers based on commits")
for i, a in enumerate(commitsPerAuthor[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} commits")

changesPerAuthor = [[a, sum([sum([z["additions"] + z["deletions"] for z in x["files"]]) for x in commitsWithin if x["author"]["name"] == a])] for a in newAuthors]
changesPerAuthor.sort(key=lambda a: -a[1])
print(f"- top new contributers based on changes")
for i, a in enumerate(changesPerAuthor[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} changes")




commitsPerAuthorLifeTime = [[a, len([x for x in commits if x["author"]["name"] == a])] for a in authors]
commitsPerAuthorLifeTime.sort(key=lambda a: -a[1])
print(f"- top contributers based on commits")
for i, a in enumerate(commitsPerAuthorLifeTime[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} commits")

changesPerAuthorLifeTime = [[a, sum([sum([z["additions"] + z["deletions"] for z in x["files"]]) for x in commits if x["author"]["name"] == a])] for a in authors]
changesPerAuthorLifeTime.sort(key=lambda a: -a[1])
print(f"- top contributers based on changes")
for i, a in enumerate(changesPerAuthorLifeTime[:5]):
    print(f"   {i+1}. {a[0]} with {a[1]} changes")



firstCommitOfYear = list(commitsWithin)
firstCommitOfYear.sort(key=lambda x: x["author"]["time"])
firstCommitOfYear = firstCommitOfYear[0]

gitcheckout(firstCommitOfYear["hash"])
print(f"In the begining of {year} the lib folder was {du("./finamp/lib")} Big", end=" ")
gitcheckout(activeBranch)
print(f"and now its {du("./finamp/lib")}!")