import sys
import re
from subprocess import Popen, PIPE, STDOUT

# block level
# hook -> replace with @logosformathook with ; at the end
# end -> replace with @logosformatend with ; at the end
# property -> replace with @logosformatproperty with NO ; at the end. Special case for block level
# new -> replce with @logosformatnew with ; at the end
# group -> replace with @logosformatgroup with ; at the end
# subclass -> replace with @logosformatsubclass with ; at the end
# top level
# config -> replace with @logosformatconfig
# hookf -> replace with @logosformathookf
# ctor -> replace with @logosformatctor
# dtor -> replace with @logosformatdtor

# function level
# init -> replace with @logosformatinit
# c -> replace with @logosformatc
# orig -> replace with @logosformatorig
# log -> replace with @logosformatlog

specialFilterList = ["%hook", "%end", "%new", "%group", "%subclass"]
filterList = [
    "%property",
    "%config",
    "%hookf",
    "%ctor",
    "%dtor",
    "%init",
    "%c",
    "%orig",
    "%log",
]


fileContentsList = sys.stdin.read().splitlines()
newList = []

for line in fileContentsList:
    for token in filterList:
        if token in line:
            line = re.sub(rf"%({token[1:]})\b", r"@logosformat\1", line)
    for token in specialFilterList:
        if token in line:
            line = re.sub(rf"%({token[1:]})\b", r"@logosformat\1", line) + ";"
    newList.append(line)

command = ["clang-format"] + sys.argv[1:]
process = Popen(command, stdout=PIPE, stderr=None, stdin=PIPE)
stdoutData = process.communicate(input="\n".join(newList).encode())[0]
refinedList = stdoutData.decode().splitlines()


for line in refinedList:
    if "@logosformat" in line:
        fix = line.replace("@logosformat", "%")
        if any(token in fix for token in specialFilterList):
            print(fix.replace(";",""))
        else:
            print(fix)
    else:
        print(line)
