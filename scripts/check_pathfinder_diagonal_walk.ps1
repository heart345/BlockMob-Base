$ErrorActionPreference = "Stop"

function Assert-Contains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -notmatch $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

function Assert-NotContains([string]$relativePath, [string]$pattern, [string]$message) {
    $path = Join-Path (Get-Location) $relativePath
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text -match $pattern) {
        throw "ERROR: ${relativePath}: ${message}"
    }
}

$pathfinder = "gmod_addon\lua\bmb\sv_pathfinder.lua"

Assert-Contains $pathfinder 'local DIAGONAL_WALK_COST\s*=\s*1\.41' "Diagonal walk should use a sqrt(2)-style A* cost."
Assert-Contains $pathfinder 'local function manhattanDistance\(a,\s*b\)' "Search budget should keep the previous Manhattan distance envelope."
Assert-Contains $pathfinder 'local function heuristic\(a,\s*b\)(?s).*diagonal \* DIAGONAL_WALK_COST \+ straight' "A* heuristic should understand diagonal walk cost."
Assert-Contains $pathfinder 'local diagonalDirections\s*=\s*\{(?s).*x\s*=\s*1,\s*y\s*=\s*1(?s).*x\s*=\s*1,\s*y\s*=\s*-1(?s).*x\s*=\s*-1,\s*y\s*=\s*1(?s).*x\s*=\s*-1,\s*y\s*=\s*-1' "Pathfinder should define all four diagonal walk directions."
Assert-Contains $pathfinder 'function\s+addDiagonalWalkNeighbors\(found,\s*coord,\s*blockWorld,\s*options,\s*allowVertical\)' "Diagonal walk expansion should be isolated from vertical edge logic."
Assert-Contains $pathfinder 'isPassable\(blockWorld,\s*orthoA,\s*options\)(?s).*isPassable\(blockWorld,\s*orthoB,\s*options\)' "Diagonal walk must require both orthogonal side cells to be passable to prevent corner cutting."
Assert-Contains $pathfinder 'allowVertical and isStandable\(blockWorld,\s*sameLevel,\s*options\)' "Vertical worlds should require diagonal targets to be supported."
Assert-Contains $pathfinder 'not allowVertical and isPassable\(blockWorld,\s*sameLevel,\s*options\)' "Flat mock worlds should still allow diagonal passable walk."
Assert-Contains $pathfinder 'addNeighbor\(found,\s*copyCoord\(sameLevel\),\s*"walk",\s*DIAGONAL_WALK_COST\)' "Diagonal neighbors should be same-level walk edges."
Assert-Contains $pathfinder 'for _, direction in ipairs\(directions\) do(?s).*findDropNeighbor\(blockWorld,\s*coord,\s*direction,\s*options\)(?s).*findClimbNeighbor\(blockWorld,\s*coord,\s*direction,\s*options\)' "Drop and climb expansion should remain on orthogonal directions."
Assert-Contains $pathfinder 'local budgetStart\s*=\s*manhattanDistance\(startCoord,\s*goalCoord\)' "FindPath should compute its search envelope from the previous Manhattan distance."
Assert-Contains $pathfinder 'options\.searchBudget or \(budgetStart \* 2 \+ 24\)' "Default search budget should not shrink when diagonal heuristic is introduced."
Assert-NotContains $pathfinder 'findDropNeighbor\(blockWorld,\s*coord,\s*direction,\s*options\)(?s).*diagonalDirections' "Diagonal directions should not feed drop expansion."
Assert-NotContains $pathfinder 'findClimbNeighbor\(blockWorld,\s*coord,\s*direction,\s*options\)(?s).*diagonalDirections' "Diagonal directions should not feed climb expansion."

Write-Host "Pathfinder diagonal walk checks passed."
