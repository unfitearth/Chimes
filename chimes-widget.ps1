# Chimes widget: a system-tray app for the mute switch. The tray icon shows
# the current state (green dot = sounds on, red dot = muted); left-click opens
# a small always-on-top panel with an animated on/off switch and timed-mute
# buttons, right-click gives a quick menu. Closing the panel hides it back to
# the tray; quit from the tray menu. It is just a front-end for chimes.ps1 —
# the same .muted flag file, nothing else.
# Launch via chimes-widget.bat (WPF needs an STA thread).

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# One instance is enough — a second launch would just add a duplicate tray icon.
$created = $false
$script:mutex = New-Object System.Threading.Mutex($true, "ChimesWidget", [ref]$created)
if (-not $created) { exit }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:chimes = Join-Path $here "chimes.ps1"

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Chimes" Width="300" SizeToContent="Height"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ResizeMode="NoResize" ShowInTaskbar="False">
  <Window.Resources>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="Background" Value="#313244"/>
      <Setter Property="Margin" Value="5,0"/>
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="15" Padding="16,7">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#45475A"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#585B70"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Margin="12" CornerRadius="14" Background="#1E1E2E"
          BorderBrush="#313244" BorderThickness="1" Padding="20,14,20,20">
    <Border.Effect>
      <DropShadowEffect BlurRadius="18" ShadowDepth="2" Opacity="0.55"/>
    </Border.Effect>
    <StackPanel>

      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Text="&#xE767;" FontFamily="Segoe MDL2 Assets" FontSize="15"
                     Foreground="#CBA6F7" VerticalAlignment="Center"/>
          <TextBlock Text="Chimes" FontFamily="Segoe UI" FontWeight="SemiBold" FontSize="16"
                     Foreground="#CDD6F4" Margin="9,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <Button x:Name="CloseBtn" Width="26" Height="26" HorizontalAlignment="Right"
                VerticalAlignment="Center" Cursor="Hand" Foreground="#6C7086"
                FontFamily="Segoe MDL2 Assets" FontSize="10" Content="&#xE711;"
                ToolTip="Hide (Chimes stays in the tray)">
          <Button.Template>
            <ControlTemplate TargetType="Button">
              <Border x:Name="bg" CornerRadius="13" Background="Transparent">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter TargetName="bg" Property="Background" Value="#313244"/>
                  <Setter Property="Foreground" Value="#F38BA8"/>
                </Trigger>
              </ControlTemplate.Triggers>
            </ControlTemplate>
          </Button.Template>
        </Button>
      </Grid>

      <ToggleButton x:Name="PowerToggle" Width="76" Height="38" HorizontalAlignment="Center"
                    Margin="0,20,0,0" Cursor="Hand">
        <ToggleButton.Template>
          <ControlTemplate TargetType="ToggleButton">
            <Grid>
              <Border x:Name="Track" Width="76" Height="38" CornerRadius="19">
                <Border.Background>
                  <SolidColorBrush x:Name="TrackBrush" Color="#45475A"/>
                </Border.Background>
              </Border>
              <Ellipse x:Name="Knob" Width="30" Height="30" Fill="#F8F8F2"
                       HorizontalAlignment="Left" Margin="4,0,0,0">
                <Ellipse.RenderTransform>
                  <TranslateTransform x:Name="KnobShift" X="0"/>
                </Ellipse.RenderTransform>
              </Ellipse>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="KnobShift"
                                       Storyboard.TargetProperty="X"
                                       To="38" Duration="0:0:0.18">
                        <DoubleAnimation.EasingFunction>
                          <CubicEase EasingMode="EaseOut"/>
                        </DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <ColorAnimation Storyboard.TargetName="TrackBrush"
                                      Storyboard.TargetProperty="Color"
                                      To="#A6E3A1" Duration="0:0:0.18"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimation Storyboard.TargetName="KnobShift"
                                       Storyboard.TargetProperty="X"
                                       To="0" Duration="0:0:0.18">
                        <DoubleAnimation.EasingFunction>
                          <CubicEase EasingMode="EaseOut"/>
                        </DoubleAnimation.EasingFunction>
                      </DoubleAnimation>
                      <ColorAnimation Storyboard.TargetName="TrackBrush"
                                      Storyboard.TargetProperty="Color"
                                      To="#45475A" Duration="0:0:0.18"/>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </ToggleButton.Template>
      </ToggleButton>

      <TextBlock x:Name="StatusText" Text="..." HorizontalAlignment="Center"
                 Margin="0,12,0,0" FontFamily="Segoe UI" FontSize="12" Foreground="#A6ADC8"/>

      <TextBlock Text="MUTE FOR" HorizontalAlignment="Center" Margin="0,20,0,9"
                 FontFamily="Segoe UI" FontSize="10" Foreground="#6C7086"/>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
        <Button x:Name="Pill30" Style="{StaticResource Pill}" Content="30m"/>
        <Button x:Name="Pill1h" Style="{StaticResource Pill}" Content="1h"/>
        <Button x:Name="Pill2h" Style="{StaticResource Pill}" Content="2h"/>
      </StackPanel>

    </StackPanel>
  </Border>
</Window>
'@

$script:window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$script:toggle = $script:window.FindName("PowerToggle")
$script:status = $script:window.FindName("StatusText")
$script:exiting = $false
$script:positioned = $false

# --- tray icon -------------------------------------------------------------

function New-DotIcon([int]$r, [int]$g, [int]$b) {
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($r, $g, $b))
    $edge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(30, 30, 46)), 1
    $gfx.FillEllipse($fill, 2, 2, 12, 12)
    $gfx.DrawEllipse($edge, 2, 2, 12, 12)
    $gfx.Dispose(); $fill.Dispose(); $edge.Dispose()
    $ico = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    $bmp.Dispose()
    return $ico
}

$script:iconOn    = New-DotIcon 166 227 161   # green
$script:iconMuted = New-DotIcon 243 139 168   # red

$script:tray = New-Object System.Windows.Forms.NotifyIcon
$script:tray.Icon = $script:iconOn
$script:tray.Text = "Chimes"
$script:tray.Visible = $true

$script:menu = New-Object System.Windows.Forms.ContextMenuStrip
$script:menuStatus = $script:menu.Items.Add("Chimes")
$script:menuStatus.Enabled = $false
[void]$script:menu.Items.Add("-")
$script:menuToggle = $script:menu.Items.Add("Mute")
$muteItems = @()
foreach ($d in "30m", "1h", "2h") {
    $item = $script:menu.Items.Add("Mute for $d")
    $item.Tag = $d
    $muteItems += $item
}
[void]$script:menu.Items.Add("-")
$script:menuOpen = $script:menu.Items.Add("Open panel")
$script:menuExit = $script:menu.Items.Add("Exit")
$script:tray.ContextMenuStrip = $script:menu

# --- state -----------------------------------------------------------------

function Update-UI {
    $out = [string](& $script:chimes status)   # "Chimes: on" | "Chimes: muted until HH:mm" | "Chimes: muted"
    if ($out -match 'muted until (\d{1,2}:\d{2})') {
        $script:toggle.IsChecked = $false
        $script:status.Text = "muted until $($Matches[1])"
        $script:status.Foreground = "#F9E2AF"
    } elseif ($out -match 'muted') {
        $script:toggle.IsChecked = $false
        $script:status.Text = "muted until you switch it back on"
        $script:status.Foreground = "#F38BA8"
    } else {
        $script:toggle.IsChecked = $true
        $script:status.Text = "sounds on"
        $script:status.Foreground = "#A6E3A1"
    }
    $on = [bool]$script:toggle.IsChecked
    $script:tray.Icon = if ($on) { $script:iconOn } else { $script:iconMuted }
    $script:tray.Text = "Chimes: $($script:status.Text)"
    $script:menuStatus.Text = "Chimes: $($script:status.Text)"
    $script:menuToggle.Text = if ($on) { "Mute" } else { "Turn back on" }
}

function Show-Panel {
    $script:window.Show()
    if (-not $script:positioned) {   # first open: bottom-right, near the tray
        $script:window.UpdateLayout()
        $wa = [System.Windows.SystemParameters]::WorkArea
        $script:window.Left = $wa.Right - $script:window.ActualWidth - 8
        $script:window.Top  = $wa.Bottom - $script:window.ActualHeight - 8
        $script:positioned = $true
    }
    [void]$script:window.Activate()
}

function Exit-App {
    $script:exiting = $true
    $script:refresh.Stop()
    $script:tray.Visible = $false
    $script:tray.Dispose()
    $script:window.Close()
    [System.Windows.Forms.Application]::Exit()
}

# --- wiring ----------------------------------------------------------------

# Click fires only on user interaction, so Update-UI setting IsChecked can't loop.
$script:toggle.Add_Click({
    if ($script:toggle.IsChecked) { & $script:chimes on | Out-Null }
    else                          { & $script:chimes off | Out-Null }
    Update-UI
})

$muteHandler = {
    param($sender, $e)
    & $script:chimes off ([string]$sender.Tag) | Out-Null
    Update-UI
}
foreach ($pill in @(@{ Name = "Pill30"; Mins = "30m" },
                    @{ Name = "Pill1h"; Mins = "1h"  },
                    @{ Name = "Pill2h"; Mins = "2h"  })) {
    $btn = $script:window.FindName($pill.Name)
    $btn.Tag = $pill.Mins
    $btn.Add_Click($muteHandler)
}
foreach ($item in $muteItems) { $item.Add_Click($muteHandler) }

$script:menuToggle.Add_Click({
    if ($script:toggle.IsChecked) { & $script:chimes off | Out-Null }
    else                          { & $script:chimes on | Out-Null }
    Update-UI
})
$script:menuOpen.Add_Click({ Show-Panel })
$script:menuExit.Add_Click({ Exit-App })

$script:tray.Add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        if ($script:window.IsVisible) { $script:window.Hide() } else { Show-Panel; Update-UI }
    }
})

$script:window.FindName("CloseBtn").Add_Click({ $script:window.Hide() })
$script:window.Add_Closing({
    param($sender, $e)
    if (-not $script:exiting) { $e.Cancel = $true; $sender.Hide() }   # X / Alt+F4 hide to tray
})
$script:window.Add_MouseLeftButtonDown({ try { $script:window.DragMove() } catch {} })

# Re-read the flag now and then, so an expired timed mute (or a chimes-off.bat
# run outside the widget) shows up without restarting.
$script:refresh = New-Object System.Windows.Forms.Timer
$script:refresh.Interval = 20000
$script:refresh.Add_Tick({ Update-UI })
$script:refresh.Start()

# --- run -------------------------------------------------------------------

Update-UI
Show-Panel
[System.Windows.Forms.Application]::Run((New-Object System.Windows.Forms.ApplicationContext))
