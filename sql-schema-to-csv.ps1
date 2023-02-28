$target = "<Path to TableSchema.sql>"

#Prep for rename
$path = Split-Path $target -Parent
$file = Split-Path $target -Leaf
$outfile = [IO.Path]::ChangeExtension($file, "csv")
$output = Join-Path $path $outfile

# Read the SQL file contents
$sqlContent = Get-Content $file -Encoding UTF8

# Define the regex pattern to match integers and the word "max" between the brackets
$pattern = "\((max|\d+)\)"

# Initialize an empty array to hold the CSV rows
$rows = @()

# Initialize an empty variable to hold the current field type
$currentType = ""

# Loop through each line in the SQL file
foreach ($line in $sqlContent) {
    # If the line contains a CREATE TABLE statement, extract the table name
    if ($line -match "CREATE TABLE\s+\[dbo\]\.\[(?<Table>\w+)\]") {
        $table = $Matches["Table"]
    }
    # If the line contains a field definition, extract the field name and type
    elseif ($line -match "^\s*\[(?<Field>\w+)\]\s+\[(?<Type>\w+)(\((?<TypeLength>.+)\))?\]") {
        $field = $Matches["Field"]
        $currentType = $Matches["Type"]
        $typeLengthMatch = [regex]::Match($line, $pattern)
        if ($typeLengthMatch.Success) {
            $content = $typeLengthMatch.Groups[1].Value
            if ($content -ne "max" -and $content -notmatch "^\d+$") {
                $content = ""
            }
            $currentType += "($content)"
        }
        $rows += "$table,$field,$currentType"
    }
    # If the line matches the pattern, append the content to the current field type
    elseif ($line -match $pattern) {
        $content = $Matches[1]
        if ($content -ne "max" -and $content -notmatch "^\d+$") {
            $content = ""
        }
        $currentType += "($content)"
        $rows[-1] = "$table,$field,$currentType"
    }
}

# Export the CSV file
$rows | Out-File -FilePath $output -Encoding UTF8
