@echo off
echo Renaming MINTYtest to MINTYtester...
if exist modules\M99_hive\MINTYtest (
    ren modules\M99_hive\MINTYtest MINTYtester
    echo Done.
) else (
    echo MINTYtest directory not found.
)

echo Renaming MINTYversioning to MINTYgit...
if exist modules\M99_hive\MINTYversioning (
    ren modules\M99_hive\MINTYversioning MINTYgit
    echo Done.
) else (
    echo MINTYversioning directory not found.
)

echo Renaming MINTYcode to MINTYcoder...
if exist modules\M99_hive\MINTYcode (
    ren modules\M99_hive\MINTYcode MINTYcoder
    echo Done.
) else (
    echo MINTYcode directory not found.
)

echo Renaming MINTYarchive to MINTYarchivar...
if exist modules\M99_hive\MINTYarchive (
    ren modules\M99_hive\MINTYarchive MINTYarchivar
    echo Done.
) else (
    echo MINTYarchive directory not found.
)

echo All renames completed.
