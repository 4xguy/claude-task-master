# Task Master MCP Server Launcher
Write-Host "Starting Task Master MCP Server..." -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Set the absolute path to the project directory
$projectDir = "F:\SkyDrive\_AI\Cursor-Projects\claude-task-master"

# Navigate to the project directory
Set-Location -Path $projectDir

try {
    # Run the MCP server
    node mcp-server/server.js
}
catch {
    Write-Host "An error occurred while starting the server:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
finally {
    # This will execute if the script is manually terminated (Ctrl+C)
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Server exited with code $LASTEXITCODE" -ForegroundColor Yellow
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} 