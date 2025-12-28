Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "Wireless Network Credentials"
$form.Size = New-Object System.Drawing.Size(740,520)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false


$menu = New-Object System.Windows.Forms.MenuStrip
$menu.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
$menu.ForeColor = [System.Drawing.Color]::White

$fileMenu  = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$openItem  = New-Object System.Windows.Forms.ToolStripMenuItem("Open")
$saveItem  = New-Object System.Windows.Forms.ToolStripMenuItem("Save")
$saveAsItem= New-Object System.Windows.Forms.ToolStripMenuItem("Save As")
$exitItem  = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")

$fileMenu.DropDownItems.AddRange(@(
    $openItem,$saveItem,$saveAsItem,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $exitItem
))

$menu.Items.Add($fileMenu)
$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Wi-Fi Networks And Password Scanner"
$title.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(0,180,200)
$title.Location = New-Object System.Drawing.Point(20,35)
$title.AutoSize = $true
$form.Controls.Add($title)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Processing networks..."
$status.Font = New-Object System.Drawing.Font("Segoe UI",10)
$status.ForeColor = [System.Drawing.Color]::LightGray
$status.Location = New-Object System.Drawing.Point(22,70)
$status.AutoSize = $true
$form.Controls.Add($status)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20,95)
$progress.Size = New-Object System.Drawing.Size(680,18)
$progress.Style = "Continuous"
$form.Controls.Add($progress)


$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(20,125)
$grid.Size = New-Object System.Drawing.Size(680,320)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.RowHeadersVisible = $false
$grid.AutoSizeColumnsMode = "Fill"
$grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40,40,40)
$grid.BorderStyle = "None"
$grid.EnableHeadersVisualStyles = $false
$grid.Font = New-Object System.Drawing.Font("Segoe UI",10)

$grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
$grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0,180,200)
$grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::Black

$grid.Columns.Add("SSID","Network Name")
$grid.Columns.Add("KEY","Password")
$form.Controls.Add($grid)

# ================= COPYRIGHT ANMATH =================
$copyright = New-Object System.Windows.Forms.Label
$copyright.Text = "Version 1.0 © Owned By ANMATH RAJ"
$copyright.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Italic)
$copyright.ForeColor = [System.Drawing.Color]::Gray
$copyright.AutoSize = $true
$copyright.Location = New-Object System.Drawing.Point(520,455)
$form.Controls.Add($copyright)

$global:CurrentFile = $null


function Save-GridData($path) {
    $data = foreach ($row in $grid.Rows) {
        "$($row.Cells[0].Value),$($row.Cells[1].Value)"
    }
    $data | Set-Content -Encoding UTF8 $path
}

$openItem.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt"

    if ($dlg.ShowDialog() -eq "OK") {
        $grid.Rows.Clear()
        Get-Content $dlg.FileName | ForEach-Object {
            $p = $_ -split ",",2
            if ($p.Count -eq 2) {
                $grid.Rows.Add($p[0],$p[1])
            }
        }
        $global:CurrentFile = $dlg.FileName
        $status.Text = "Loaded file"
    }
})

$saveItem.Add_Click({
    if (-not $global:CurrentFile) {
        $saveAsItem.PerformClick()
    } else {
        Save-GridData $global:CurrentFile
        $status.Text = "Saved"
    }
})

$saveAsItem.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt"

    if ($dlg.ShowDialog() -eq "OK") {
        Save-GridData $dlg.FileName
        $global:CurrentFile = $dlg.FileName
        $status.Text = "Saved As"
    }
})

$exitItem.Add_Click({ $form.Close() })

# ================= LOAD WIFI =================
$form.Add_Shown({

    $profiles = netsh wlan show profiles |
        Select-String "All User Profile" |
        ForEach-Object { ($_ -split ":")[1].Trim() }

    $progress.Maximum = $profiles.Count
    $progress.Value = 0

    foreach ($ssid in $profiles) {
        $pwd = netsh wlan show profile name="$ssid" key=clear |
            Select-String "Key Content" |
            ForEach-Object { ($_ -split ":")[1].Trim() }

        if (-not $pwd) { $pwd = "N/A" }

        $grid.Rows.Add($ssid,$pwd)
        $progress.Value++
        [System.Windows.Forms.Application]::DoEvents()
    }

    $status.Text = "Completed"
})

$form.Topmost = $true
[void]$form.ShowDialog()
