tail -n +2 $0;exit
# Synchronized change of variables by 2 or more scripts, granting consistent values on each script code execution

# open a shell and run:
secExplSyncedShareEnvVarsA.sh

# open another and run:
secExplSyncedShareEnvVarsB.sh
# open another and run:
secExplSyncedShareEnvVarsB.sh
# open another and ...

# see A and B (B can be executed as many times you want) changing values and who changed; they used the last changed value to work on their own algorithm, even if it was changed by the other one.

