Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ErrorActionPreference = "SilentlyContinue"

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Atlas Mod Analyzer" Height="780" Width="900" WindowStartupLocation="CenterScreen"
        Background="#1E1E1E">
    <Window.Resources>
        <!-- Flat Button Style -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#444444"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#222222"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#2A2A2A"/>
                    <Setter Property="Foreground" Value="#777777"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#0098FF"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#005A9E"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#C62828"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#E53935"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="#CCCCCC"/>
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="8"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top Section: Centered Controls -->
        <StackPanel Grid.Row="0" HorizontalAlignment="Center" Margin="0,20,0,30">
            <TextBlock Text="ATLAS MOD ANALYZER" Foreground="#E0E0E0" FontFamily="Segoe UI" FontSize="24" FontWeight="Light" HorizontalAlignment="Center" Margin="0,0,0,20"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,15">
                <TextBlock Text="Target Path:" Foreground="#AAAAAA" FontFamily="Segoe UI" FontSize="14" VerticalAlignment="Center" Margin="0,0,10,0"/>
                <TextBox Name="txtPath" Width="380" Text="$env:USERPROFILE\AppData\Roaming\.minecraft\mods" VerticalAlignment="Center"/>
                <Button Name="btnBrowse" Content="Browse..." Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="btnScan" Style="{StaticResource PrimaryButton}" Content="START SCAN" FontSize="16" Padding="40,12"/>
                <Button Name="btnStop" Style="{StaticResource DangerButton}" Content="STOP" FontSize="16" Padding="30,12" Margin="10,0,0,0" IsEnabled="False"/>
                <Button Name="btnSave" Content="Save Report..." FontSize="14" Padding="20,12" Margin="10,0,0,0" IsEnabled="False"/>
            </StackPanel>
        </StackPanel>

        <!-- Output Area -->
        <Border Grid.Row="1" Background="#111111" BorderBrush="#3E3E42" BorderThickness="1" CornerRadius="4">
            <RichTextBox Name="rtbOutput" Background="Transparent" Foreground="#CCCCCC" BorderThickness="0" FontFamily="Consolas" FontSize="13" Margin="5" IsReadOnly="True" VerticalScrollBarVisibility="Auto">
                <FlowDocument Name="flowDoc">
                    <Paragraph Margin="0">
                        <Run Text="Ready." Foreground="#888888"/>
                    </Paragraph>
                </FlowDocument>
            </RichTextBox>
        </Border>

        <!-- Status Bar -->
        <TextBlock Name="lblStatus" Grid.Row="2" Text="Idle." Foreground="#888888" FontFamily="Segoe UI" FontSize="12" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Form = [Windows.Markup.XamlReader]::Load($reader)

$txtPath   = $Form.FindName("txtPath")
$btnBrowse = $Form.FindName("btnBrowse")
$btnScan   = $Form.FindName("btnScan")
$btnStop   = $Form.FindName("btnStop")
$btnSave   = $Form.FindName("btnSave")
$rtbOutput = $Form.FindName("rtbOutput")
$lblStatus = $Form.FindName("lblStatus")
$flowDoc   = $Form.FindName("flowDoc")

$global:stopScan     = $false
$global:closePending = $false
$global:isScanning   = $false
$global:reportLines  = [System.Collections.Generic.List[string]]::new()

$Form.Add_Closing({
    param($sender, $e)
    if ($global:isScanning) {
        $e.Cancel = $true
        $global:stopScan = $true
        $global:closePending = $true
    }
})

function Append-Log {
    param([string]$text, [string]$color="#CCCCCC", [switch]$Bold)
    if ($global:stopScan) { return }
    try {
        [void]$global:reportLines.Add($text)
        $brush = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($color)
        $run = New-Object System.Windows.Documents.Run($text + "`r`n")
        $run.Foreground = $brush
        if ($Bold) { $run.FontWeight = [System.Windows.FontWeights]::Bold }
        $paragraph = New-Object System.Windows.Documents.Paragraph($run)
        $paragraph.Margin = New-Object System.Windows.Thickness(0)
        $flowDoc.Blocks.Add($paragraph)
        $rtbOutput.ScrollToEnd()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {
        $global:stopScan = $true
    }
}

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $txtPath.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $dialog.SelectedPath
    }
})

$btnStop.Add_Click({
    $global:stopScan = $true
    $lblStatus.Text = "Stopping..."
})

$btnSave.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "Text file (*.txt)|*.txt"
    $dialog.FileName = "AtlasScanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $global:reportLines | Out-File -FilePath $dialog.FileName -Encoding UTF8
            $lblStatus.Text = "Report saved to $($dialog.FileName)"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to save report: $($_.Exception.Message)") | Out-Null
        }
    }
})

# ---------- PATTERN LISTS ----------
# NOTE: lists are de-duplicated at load time below, so repeated entries here are harmless
# (kept for readability / provenance) but do not bloat the compiled regex or hash set.
$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand", "JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",  "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill",  "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap",  "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "KeyPearl", "AutoNethPot", "AutoDtap",
    "AutoWeb", "AnchorAction",

    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class",
    "ね.class", "そ.class", "な.class", "ど.class", "ぐ.class",
    "ず.class", "で.class", "つ.class", "べ.class", "せ.class",
    "と.class", "み.class", "び.class", "す.class", "の.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ",
    "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ", "Ｄｏｕｂｌｅ Ａｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ｓａｆｅ Ａｎｃｈｏｒ",
    "Ａｎｃｈｏｒ Ｍａｃｒｏ", "anchorMacro",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "ＡｕｔｏＴｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Ａｕｔｏ Ｔｏｔｅｍ Ｈｉｔ",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "ＡｕｔｏＰｏｔ", "Ａｕｔｏ Ｐｏｔ",
    "Ａｕｔｏ Ｐｏｔ Ｒｅｆｉｌｌ", "AutoPotRefill",
    "ＡｕｔｏＡｒｍｏｒ", "Ａｕｔｏ Ａｒｍｏｒ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker",
    "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ",
    "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ",
    "AutoClicker",
    "ＡｕｔｏＣｌｉｃｋｅｒ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "ＡｕｔｏＭａｃｅ", "Ａｕｔｏ Ｍａｃｅ",
    "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ",
    "Ｓｔｕｎ Ｓｌａｍ", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam",
    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "ＡｉｍＡｓｓｉｓｔ", "Ａｉｍ Ａｓｓｉｓｔ",
    "ＴｒｉｇｇｅｒＢｏｔ", "Ｔｒｉｇｇｅｒ Ｂｏｔ",
    "Silent Rotations", "SilentRotations",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "FakeInv", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof",
    "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｌａｇ",
    "fakePunch", "Fake Punch",
    "Ｆａｋｅ Ｐｕｎｃｈ",
    "𝐌𝐨𝐝𝐮𝐥𝐞𝐬",
    "𝐂𝐨𝐧𝐟𝐢𝐠𝐬",
    "𝐄𝐍𝐀𝐁𝐋𝐄𝐃",
    "𝐃𝐈𝐒𝐀𝐁𝐋𝐄𝐃",
    "mace_swap", "quick_strike", "macro_198", "stun_slam",
    "safe_anchor", "double_anchor", "auto_pot_refill",
    "walksy_optimizer", "key_pearl", "aim_assist",
    "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web",
    "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL",
    "ROTATING_DOWN", "ROTATING_BACK", "REFILLING", "PLANTING", "BONEMEALING",
    "AnchorAction", "Places two anchors for massive damage",
    "REOFFHAND_TOTEM",
    "webmacro", "web macro",
    "AntiWeb", "AutoWeb",
    "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ",
    "Ｐｌａｃｅｓ Ｗｅｂｓ Ｏｎ Ｅｎｅｍｉｅｓ",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "autoCrystalPlaceClock",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "ＥｌｙｔｒａＳｗａｐ", "Ｅｌｙｔｒａ Ｓｗａｐ",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "FreezePlayer","VirtualMachine",
    "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｕｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ",
    "KeyPearl", "LootYeeter",
    "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ",
    "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "AutoBreach",
    "Ａｕｔｏ Ｂｒｅａｃｈ",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "setSelectedSlot", "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "Ａｃｔｉｖａｔｅ Ｋｅｙ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "On RMB", "Ｏｎ ＲＭＢ",
    "No Count Glitch", "Ｎｏ Ｃｏｕｎｔ Ｇｌｉｔｃｈ",
    "No Bounce", "NoBounce", "Ｎｏ Ｂｏｕｎｃｅ", "ＮｏＢｏｕｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｕｎｃｅ ａｎｉｍａｔｉｏｎ",
    "Place Delay", "Ｐｌａｃｅ Ｄｅｌａｙ",
    "Break Delay", "Ｂｒｅａｋ Ｄｅｌａｙ",
    "Ｆａｓｔ Ｍｏｄｅ",
    "Place Chance", "Ｐｌａｃｅ Ｃｈａｎｃｅ",
    "Break Chance", "Ｂｒｅａｋ Ｃｈａｎｃｅ",
    "Stop On Kill", "Ｓｔｏｐ Ｏｎ Ｋｉｌｌ",
    "Ｄａｍａｇｅ Ｔｉｃｋ", "damagetick",
    "Anti Weakness", "Ａｎｔｉ Ｗｅａｋｎｅｓｓ",
    "Particle Chance", "Ｐａｒｔｉｃｌｅ Ｃｈａｎｃｅ",
    "Trigger Key", "Ｔｒｉｇｇｅｒ Ｋｅｙ",
    "Switch Delay", "Ｓｗｉｔｃｈ Ｄｅｌａｙ",
    "Totem Slot", "Ｔｏｔｅｍ Ｓｌｏｔ",
    "Silent Rotations", "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "Smooth Rotations", "Ｓｍｏｏｔｈ Ｒｏｔａｔｉｏｎｓ",
    "Rotation Speed", "Ｒｏｔａｔｉｏｎ Ｓｐｅｅｄ",
    "Use Easing", "Ｕｓｅ Ｅａｓｉｎｇ",
    "Easing Strength", "Ｅａｓｉｎｇ Ｓｔｒｅｎｇｔｈ",
    "While Use", "Ｗｈｉｌｅ Ｕｓｅ",
    "Stop on Kill", "Ｓｔｏｐ ｏｎ Ｋｉｌｌ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "Glowstone Delay", "Ｇｌｏｗｓｔｏｎｅ Ｄｅｌａｙ",
    "Glowstone Chance", "Ｇｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ",
    "Explode Delay", "Ｅｘｐｌｏｄｅ Ｄｅｌａｙ",
    "Explode Chance", "Ｅｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Explode Slot", "Ｅｘｐｌｏｄｅ Ｓｌｏｔ",
    "Only Charge", "Ｏｎｌｙ Ｃｈａｒｇｅ",
    "Anchor Macro", "Ａｎｃｈｏｒ Ｍａｃｒｏ",
    "Reach Distance", "Ｒｅａｃｈ Ｄｉｓｔａｎｃｅ",
    "Min Height", "Ｍｉｎ Ｈｅｉｇｈｔ",
    "Min Fall Speed", "Ｍｉｎ Ｆａｌｌ Ｓｐｅｅｄ",
    "Attack Delay", "Ａｔｔａｃｋ Ｄｅｌａｙ",
    "Breach Delay", "Ｂｒｅａｃｈ Ｄｅｌａｙ",
    "Require Elytra", "Ｒｅｑｕｉｒｅ Ｅｌｙｔｒａ",
    "Auto Switch Back", "Ａｕｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ",
    "Require Crit", "Ｒｅｑｕｉｒｅ Ｃｒｉｔ",
    "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｕｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ",
    "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ",
    "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ",
    "On Ground", "Ｏｎ Ｇｒｏｕｎｄ",
    "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ",
    "Check Aim", "Ｃｈｅｃｋ Ａｉｍ",
    "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ",
    "Blatant", "Ｂｌａｔａｎｔ",
    "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ",
    "Auto Inventory Totem", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Only On Pop", "Ｏｎｌｙ Ｏｎ Ｐｏｐ",
    "Vertical Speed", "Ｖｅｒｔｉｃａｌ Ｓｐｅｅｄ",
    "Hover Totem", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "Swap Speed", "Ｓｗａｐ Ｓｐｅｅｄ",
    "Strict One-Tick", "Ｓｔｒｉｃｔ Ｏｎｅ－Ｔｉｃｋ",
    "Mace Priority", "Ｍａｃｅ Ｐｒｉｏｒｉｔｙ",
    "Min Totems", "Ｍｉｎ Ｔｏｔｅｍｓ",
    "Min Pearls", "Ｍｉｎ Ｐｅａｒｌｓ",
    "Totem First", "Ｔｏｔｅｍ Ｆｉｒｓｔ",
    "Drop Interval", "Ｄｒｏｐ Ｉｎｔｅｒｖａｌ",
    "Random Pattern", "Ｒａｎｄｏｍ Ｐａｔｔｅｒｎ",
    "Loot Yeeter", "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "Horizontal Aim Speed", "Ｈｏｒｉｚｏｎｔａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Vertical Aim Speed", "Ｖｅｒｔｉｃａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Include Head", "Ｉｎｃｌｕｄｅ Ｈｅａｄ",
    "Web Delay", "Ｗｅｂ Ｄｅｌａｙ",
    "Holding Web", "Ｈｏｌｄｉｎｇ Ｗｅｂ",
    "Not When Affects Player", "Ｎｏｔ Ｗｈｅｎ Ａｆｆｅｃｔｓ Ｐｌａｙｅｒ",
    "Hit Delay", "Ｈｉｔ Ｄｅｌａｙ",
    "Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Require Hold Axe", "Ｒｅｑｕｉｒｅ Ｈｏｌｄ Ａｘｅ",
    "Fake Punch", "Ｆａｋｅ Ｐｕｎｃｈ",
    "placeInterval", "breakInterval", "stopOnKill",
    "activateOnRightClick", "holdCrystal",
    "ｐｌａｃｅＩｎｔｅｒｖａｌ", "ｂｒｅａｋＩｎｔｅｒｖａｌ",
    "ｓｔｏｐＯｎＫｉｌｌ", "ａｃｔｉｖａｔｅＯｎＲｉｇｈｔＣｌｉｃｋ",
    "ｄａｍａｇｅｔｉｃｋ", "ｈｏｌｄＣｒｙｓｔａｌ",
    "ｆａｋｅＰｕｎｃｈ",
    "Ｒｅｆｉｌｌｓ ｙｏｕｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｕ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ",
    "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｕ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｕｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ",
    "Macro Key", "Ａｕｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "SilentAim", "AimLock", "HeadSnap",
    "CrystalAura",
    "AnchorAura", "AnchorFill", "AnchorPlace",
    "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow",
    "AutoCrit", "CritBypass", "AlwaysCrit", "CriticalHit",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand",
    "AntiKB", "NoKnockback", "GrimVelocity", "GrimDisabler", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch",
    "AutoWeapon", "AutoSword", "AutoCity", "Burrow", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow",
    "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump",
    "SpeedHack", "BHop", "BunnyHop",
    "AntiFall", "NoFallDamage", "SafeFall",
    "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk",
    "NoSlow", "NoSlowdown", "NoWeb", "NoSoulSand",
    "WallHack",
    "ElytraSpeed", "InstantElytra",
    "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak",
    "GhostHand", "NoSwing",
    "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP",
    "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP",
    "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay",
    "DoubleClicker", "JitterClick", "ButterflyClick", "CPSBoost",
    "ChestStealer", "InvManager", "InvMovebypass",
    "AutoSprint", "AntiAFK", "AutoRespawn",
    "FakeNick", "PopSwitch",
    "FakeLatency", "FakePing", "SpoofRotation", "PositionSpoof",
    "GameSpeed", "SpeedTimer",
    "GrimBypass", "VulcanBypass", "MatrixBypass",
    "AACBypass", "VerusDisabler", "IntaveBypass", "WatchdogBypass",
    "PacketMine", "PacketWalk", "PacketSneak", "PacketCancel", "PacketDupe", "PacketSpam",
    "SelfDestruct", "HideClient",
    "SessionStealer", "TokenLogger", "TokenGrabber", "DiscordToken",
    "RemoteAccess", "ReverseShell", "C2Server", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder",
    "imgui.binding",
    "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline",
    "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai",
    "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth",
    "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol",
    "WalksyOptimizer", "LWFH Crystal",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "intent.store", "IntentClient",
    "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "net.ccbluex",
    "novoware", "novoclient",
    "aristois", "impactclient", "azura",
    "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition",
    "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
    "VirginClient", "virgin client",
    "catlean", "CatleanClient", "catlean client",
    "ArgonClient", "argon client",
    "Asteria", "AsteriaClient", "asteria client",
    "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client",
    "Xenon", "XenonClient", "xenon client",
    "GrimClient", "grim client",
    "phantom-refmap.json",
    "dqrkis.xyz", "Dqrkis Client"
)

# De-duplicate once at load time. This shrinks the compiled alternation regex
# (fewer branches = faster matching) and keeps the hash-set lookup clean,
# without requiring the lists above to be hand-curated for duplicates.
$suspiciousPatterns = @($suspiciousPatterns | Select-Object -Unique)
$cheatStrings       = @($cheatStrings       | Select-Object -Unique)

$fullwidthRegex = [regex]::new("[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}", [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Escape each literal before joining into the alternation so that patterns
# containing regex metacharacters (e.g. the dots in "org.chainlibs...") are
# matched literally instead of "." meaning "any character".
$escapedPatterns = $suspiciousPatterns | ForEach-Object { [regex]::Escape($_) }
$patternRegex = [regex]::new('(?<![A-Za-z])(' + ($escapedPatterns -join '|') + ')(?![A-Za-z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

# --- SCANNER LOGIC ---
function Invoke-ModScan {
    param([string]$FilePath)
    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    $archive = $null
    $innerArchives = [System.Collections.Generic.List[object]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $allEntries = [System.Collections.Generic.List[object]]::new()

        $entryCount = 0
        foreach ($entry in $archive.Entries) {
            if ($global:stopScan) { return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $foundFullwidth } }
            $entryCount++
            if ($entryCount % 25 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }

            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
            $allEntries.Add($entry)

            if ($entry.FullName -match "^META-INF/jars/.+\.jar$") {
                try {
                    $ns = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                    $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                    $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                    $innerArchives.Add($iz)
                    foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
                } catch { }
            }
        }

        $entryCount = 0
        foreach ($entry in $allEntries) {
            if ($global:stopScan) { return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $foundFullwidth } }
            $entryCount++
            if ($entryCount % 25 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }

            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)
                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s, [System.StringComparison]::Ordinal)) { [void]$foundStrings.Add($s); continue }
                        if ($utf8.Contains($s, [System.StringComparison]::Ordinal))  { [void]$foundStrings.Add($s) }
                    }
                    foreach ($m in $fullwidthRegex.Matches($utf8)) { [void]$foundFullwidth.Add($m.Value) }
                } catch { }
            }
        }
    } catch {
        # Locked/corrupt/non-zip jar - surface nothing rather than silently
        # pretending the file was clean.
        [void]$foundStrings.Add("[scan error: $($_.Exception.Message)]")
    } finally {
        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        if ($archive) { try { $archive.Dispose() } catch { } }
    }

    $fwCheatPool = @($cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) {
                if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs }
            }
        }
        if ($null -ne $bestMatch) { [void]$resolvedFullwidth.Add($bestMatch) }
        elseif ($fw.Length -ge 6) { [void]$resolvedFullwidth.Add($fw) }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) {
            if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break }
        }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }

    return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $finalFullwidth }
}

function Invoke-ObfuscationScan {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    $archive = $null
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $totalClass=0; $numericCount=0; $unicodeCount=0; $fullwidthCount=0; $japaneseCount=0
        $singleLetterCount=0; $twoLetterCount=0; $gibberishCount=0; $noVowelCount=0
        $confusionCount=0; $singleCharPkg=0
        $contentSample = [System.Text.StringBuilder]::new(); $sampleSize = 0
        $cheatObfuscators = @{
            "Skidfuscator"   = @("dev/skidfuscator","Skidfuscator","skidfuscator.dev")
            "Paramorphism"   = @("Paramorphism","paramorphism-","dev/paramorphism")
            "Radon"          = @("ItzSomebody/Radon","me/itzsomebody/radon","Radon Obfuscator")
            "Caesium"        = @("sim0n/Caesium","Caesium Obfuscator","dev/sim0n/caesium")
            "Bozar"          = @("vimasig/Bozar","Bozar Obfuscator","com/bozar")
            "Branchlock"     = @("Branchlock","branchlock.dev")
            "Binscure"       = @("Binscure","com/binscure")
            "SuperBlaubeere" = @("superblaubeere","superblaubeere27")
            "Qprotect"       = @("Qprotect","QProtect","mdma.dev/qprotect")
            "Zelix"          = @("ZKMFLOW","ZKM","ZelixKlassMaster","com/zelix")
            "Stringer"       = @("StringerJavaObfuscator","com/licel/stringer")
            "JNIC"           = @("JNIC","jnic.obf","jnic-obfuscator")
            "Scuti"          = @("ScutiObf","scuti.obf")
            "Smoke"          = @("SmokeObf","smoke.obf")
            "Allatori"       = @("Allatori","allatori","com/allatori","allatori.obf")
            "DashO"          = @("DashO","dasho","com/dasho","preEmptive.DashO")
            "MinecraftSelfObf"= @("selfObf","selfobf","minecraft/Obfuscation","magic/Obfuscator")
            "NameObfuscation" = @("NameObfuscation","nameObfuscator","renameObf")
            "XenForgeObf"    = @("xenforgewrapper","XenForge","xenforge.obf")
            "SandboxObf"     = @("sandbox_obf","SandboxObfuscator")
            "Morphii"        = @("morphii","MorphiiObf","morph.obf")
            "JavaCrack"      = @("javamc.obf","MCrack","mcObfuscator")
        }

        $entryCount = 0
        foreach ($entry in $archive.Entries) {
            if ($global:stopScan) { return $flags }
            $entryCount++
            if ($entryCount % 25 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }

            $name = $entry.FullName
            if ($name -match "\.class$") {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
                if ($className -match "^\d+$")                                                       { $numericCount++ }
                if ($className -match "[^\x00-\x7F]")                                                { $unicodeCount++ }
                if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]")                  { $fullwidthCount++ }
                if ($className -match "[\u3040-\u309F\u30A0-\u30FF]")                               { $japaneseCount++ }
                if ($className -match "^[a-zA-Z]$")                                                  { $singleLetterCount++ }
                if ($className -match "^[a-zA-Z]{2}$")                                               { $twoLetterCount++ }
                if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$")                  { $confusionCount++ }
                if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                    $vowels = ($className.ToCharArray() | Where-Object { $_ -match "[aeiouAEIOU]" }).Count
                    if ($vowels -eq 0) { $noVowelCount++ }
                    $hasCluster = $className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                    if ($hasCluster -and ($vowels / $className.Length) -lt 0.3) { $gibberishCount++ }
                }
                $segs = ($name -replace "\.class$","") -split "/"
                foreach ($seg in $segs[0..($segs.Count-2)]) { if ($seg.Length -eq 1) { $singleCharPkg++ } }
                if ($sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray()); $ms.Dispose()
                        [void]$contentSample.Append($ascii); $sampleSize += $ascii.Length
                    } catch { }
                }
            }
        }
        if ($totalClass -lt 5) { return $flags }

        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
        $numPct  = & $pct $numericCount;  $uniPct  = & $pct $unicodeCount;  $fwPct = & $pct $fullwidthCount
        $jpPct   = & $pct $japaneseCount; $s1Pct   = & $pct $singleLetterCount; $s2Pct = & $pct $twoLetterCount
        $gibPct  = & $pct $gibberishCount; $novPct = & $pct $noVowelCount; $confPct = & $pct $confusionCount
        if ($numPct  -ge 20) { $flags.Add("Numeric class names - $numPct% of classes have numeric-only names") }
        if ($uniPct  -ge 10) { $flags.Add("Unicode class names - $uniPct% of classes use non-ASCII characters") }
        if ($fwPct   -gt  0) { $flags.Add("Fullwidth Unicode class names - $fwPct% use fullwidth chars") }
        if ($jpPct   -gt  0) { $flags.Add("Japanese obfuscation - $jpPct% use hiragana/katakana names") }
        if ($s1Pct   -ge 15) { $flags.Add("Single-letter class names - $s1Pct%") }
        if ($s2Pct   -ge 20) { $flags.Add("Two-letter class names - $s2Pct%") }
        if ($gibPct  -ge 5) { $flags.Add("Gibberish class names - $gibPct% have no vowels/consonant clusters") }
        if ($novPct  -ge 8) { $flags.Add("No-vowel class names - $novPct%") }
        if ($confPct -ge 3) { $flags.Add("Confusion-char names (Il1O0/_) - $confPct%") }
        if ($singleCharPkg -ge 6) { $flags.Add("Single-char package paths - $singleCharPkg path segments like a/b/c") }

        $sampleStr = $contentSample.ToString()
        $fwStringMatches = [regex]::Matches($sampleStr, "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwStringMatches.Count -gt 0) {
            $flags.Add("Fullwidth strings in class content - $($fwStringMatches.Count) occurrences")
        }

        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($pat in $cheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) { $flags.Add("Known cheat obfuscator detected - $obfName (matched: $pat)"); break }
            }
        }

        $obfStringPatterns = @(
            @{Pattern='(?i)(?:string|str)_(?:obf|enc|crypt|hide|mangle)'; Label='String obfuscation methods'},
            @{Pattern='(?i)decrypt(?:String|Str|Key|Payload)'; Label='Decryption methods present'},
            @{Pattern='(?i)\.(?:obfuscate|deobfuscate|remap|rename)\(?\)'; Label='Obfuscation API calls'},
            @{Pattern='(?i)(?:class|method|field)_(?:mapping|remap|rename|transform)'; Label='Runtime mapping/remap methods'}
        )
        foreach ($obfPat in $obfStringPatterns) {
            if ($sampleStr -match $obfPat.Pattern) { $flags.Add("$($obfPat.Label) - matched: $($matches[0])") }
        }

        $reflectCount = [regex]::Matches($sampleStr, '(?i)(?:getDeclaredMethod|getDeclaredField|setAccessible|invoke\s*\(|forName\s*\()').Count
        if ($reflectCount -ge 50) { $flags.Add("Heavy reflection usage - $reflectCount reflection calls") }

    } catch { } finally {
        if ($archive) { try { $archive.Dispose() } catch { } }
    }
    return $flags
}

function Invoke-JvmScan {
    $javaProcesses = Get-Process -Name javaw -ErrorAction SilentlyContinue
    if ($javaProcesses.Count -eq 0) {
        Append-Log "  [i] No javaw.exe processes found (Minecraft not running)" "#AAAAAA"
        return
    }

    Append-Log "  [i] Scanning $($javaProcesses.Count) Java process(es)..." "#00FFFF"

    $fabricPatterns = @{
        "fabric.addMods"='-Dfabric\.addMods=';
        "fabric.loadMods"='-Dfabric\.loadMods=';
        "fabric.classPathGroups"='-Dfabric\.classPathGroups=';
        "fabric.gameJarPath"='-Dfabric\.gameJarPath=';
        "fabric.skipMcProvider"='-Dfabric\.skipMcProvider=';
        "fabric.development"='-Dfabric\.development=';
        "fabric.allowUnsupportedVersion"='-Dfabric\.allowUnsupportedVersion=';
        "fabric.remapClasspathFile"='-Dfabric\.remapClasspathFile=';
        "fabric.skipIntermediary"='-Dfabric\.skipIntermediary=';
        "fabric.configDir"='-Dfabric\.configDir=';
        "fabric.loader.config"='-Dfabric\.loader\.config=';
        "fabric.log.level"='-Dfabric\.log\.level=';
        "fabric.debug.dumpClasspath"='-Dfabric\.debug\.dumpClasspath=';
        "fabric.log.config"='-Dfabric\.log\.config=';
        "fabric.dli.config"='-Dfabric\.dli\.config=';
        "fabric.mixin.configs"='-Dfabric\.mixin\.configs=';
        "fabric.mixin.hotSwap"='-Dfabric\.mixin\.hotSwap=';
        "fabric.mixin.debug.export"='-Dfabric\.mixin\.debug\.export=';
        "fabric.mixin.debug.verbose"='-Dfabric\.mixin\.debug\.verbose=';
        "fabric.gameVersion"='-Dfabric\.gameVersion=';
        "fabric.forceVersion"='-Dfabric\.forceVersion=';
        "fabric.autoDetectVersion"='-Dfabric\.autoDetectVersion=';
        "fabric.launcher.name"='-Dfabric\.launcher\.name=';
        "fabric.launcher.brand"='-Dfabric\.launcher\.brand=';
        "fabric.mods.toml.path"='-Dfabric\.mods\.toml\.path=';
        "fabric.customModList"='-Dfabric\.customModList=';
        "fabric.resolve.modFiles"='-Dfabric\.resolve\.modFiles=';
        "fabric.skipDependencyResolution"='-Dfabric\.skipDependencyResolution=';
        "fabric.loader.entrypoints"='-Dfabric\.loader\.entrypoints=';
        "fabric.language.providers"='-Dfabric\.language\.providers=';
        "forge.addMods"='-Dforge\.addMods=';
        "forge.mods"='-Dforge\.mods=';
        "fml.coreMods.load"='-Dfml\.coreMods\.load=';
        "forge.coreMods.dir"='-Dforge\.coreMods\.dir=';
        "forge.modDir"='-Dforge\.modDir=';
        "forge.modsDirectories"='-Dforge\.modsDirectories=';
        "fml.customModList"='-Dfml\.customModList=';
        "forge.disableModScan"='-Dforge\.disableModScan=';
        "forge.modList"='-Dforge\.modList=';
        "forge.forceVersion"='-Dforge\.forceVersion=';
        "forge.disableUpdateCheck"='-Dforge\.disableUpdateCheck=';
        "forge.logging.mojang.level"='-Dforge\.logging\.mojang\.level=';
        "forge.mixin.hotSwap"='-Dforge\.mixin\.hotSwap=';
        "forge.resourcePack"='-Dforge\.resourcePack=';
        "forge.defaultResourcePack"='-Dforge\.defaultResourcePack=';
        "forge.texturePacks"='-Dforge\.texturePacks=';
        "forge.assetIndex"='-Dforge\.assetIndex=';
        "forge.assetsDir"='-Dforge\.assetsDir=';
        "javaSecurityManager"='-Djava\.security\.manager=';
        "javaSecurityPolicy"='-Djava\.security\.policy=';
        "bootClasspath"='-Xbootclasspath';
        "systemClassLoader"='-Djava\.system\.class\.loader=';
        "javaClassPath"='-Djava\.class\.path=';
        "cp"='-cp\s+["''][^"'';]*\.jar';
        "cheatClientBrand"='-D(client|launcher)\.brand=(Wurst|Aristois|Impact|Kilo|Future|Lambda|Rusher|Konas|Phobos|Salhack|ForgeHax|Mathax|Meteor|Async|Seppuku|Xatz|Wolfram|Huzuni|Jigsaw|Zamorozka|Moon|Rage|Exhibition|Virtue|Novoline|Rekt|Skid|Ares|Abyss|Thunder|Tenacity|Rise|Flux|Gamesense|Intent|Remix|Sight|Vape|Shield|Ghost|Crispy|Inertia)';
        "optifine"='-Doptifine\.';
        "shadersmod"='-Dshaders?\.';
        "shaderPack"='-Dshader[sP]ack=';
        "cheatPattern"='-D(xray|fly|speed|killaura|reach|esp|wallhack|noclip|autoclick|aimbot|triggerbot|antiknockback|nofall|timer|step|fullbright|nightvision|cavefinder)\.'
    }
    $cheatClients = @('Wurst','Aristois','Impact','Kilo','Future','Lambda','Rusher','Konas','Phobos','Salhack','ForgeHax','Mathax','Meteor','Async','Seppuku','Xatz','Wolfram','Huzuni','Jigsaw','Zamorozka','Moon','Rage','Exhibition','Virtue','Novoline','Rekt','Skid','Ares','Abyss','Thunder','Tenacity','Rise','Flux','Gamesense','Intent','Remix','Sight','Vape','Shield','Ghost','Crispy','Inertia')

    foreach ($proc in $javaProcesses) {
        if ($global:stopScan) { return }
        try {
            # Get-CimInstance replaces the deprecated Get-WmiObject: faster,
            # works over WSMan/DCOM, and is the supported cmdlet on modern
            # PowerShell (Get-WmiObject is gone entirely in PowerShell 7+).
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop).CommandLine
            if (-not $cmdLine) { continue }
            Append-Log "  +- Process: PID $($proc.Id)" "#81C784"

            $detectedPatterns = @()
            foreach ($k in $fabricPatterns.Keys) {
                if ($cmdLine -match $fabricPatterns[$k]) {
                    $detectedPatterns += $k
                }
            }
            foreach ($cc in $cheatClients) {
                if ($cmdLine -match "(?i)\b$cc\b" -and $detectedPatterns -notcontains "CheatClient-$cc") { $detectedPatterns += "CheatClient-$cc" }
            }
            if ($cmdLine -match '(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)') { $detectedPatterns += "EncodedInjection" }

            if ($detectedPatterns.Count -gt 0) {
                Append-Log "  |  [!] JVM INJECTION DETECTED!" "#E53935" -Bold
                foreach ($d in $detectedPatterns) { Append-Log "  |    - $d" "#EF5350" }
            } else {
                Append-Log "  |  [v] No JVM injection patterns detected." "#81C784"
            }
        } catch {
            Append-Log "  |  [!] Could not retrieve cmdline. Run as Admin." "#FFB74D"
        }
    }
}

# --- BUTTON CLICK HANDLER ---
$btnScan.Add_Click({
    $global:stopScan = $false
    $global:closePending = $false
    $global:isScanning = $true
    $global:reportLines.Clear()
    $btnScan.IsEnabled = $false
    $btnStop.IsEnabled = $true
    $btnSave.IsEnabled = $false
    $rtbOutput.Document.Blocks.Clear()
    $lblStatus.Text = "Scanning..."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Every early-return path below must restore isScanning/button state,
    # otherwise a closed-window race can leave the app unresponsive to
    # further close attempts (isScanning stays true forever).
    function Reset-ScanState {
        $global:isScanning = $false
        $btnScan.IsEnabled = $true
        $btnStop.IsEnabled = $false
        $btnSave.IsEnabled = ($global:reportLines.Count -gt 0)
        if ($global:closePending) { $Form.Close() }
    }

    Append-Log " ATLAS MOD ANALYZER SCAN STARTED" "#64B5F6" -Bold
    Append-Log " Target: $($txtPath.Text)" "#AAAAAA"
    if (-not (Test-Path $txtPath.Text -PathType Container)) {
        Append-Log "[!] Directory does not exist!" "#E53935" -Bold
        $lblStatus.Text = "Idle."
        Reset-ScanState
        return
    }

    try { $jarFiles = Get-ChildItem -Path $txtPath.Text -Filter *.jar -ErrorAction Stop } catch {
        Append-Log "[!] Error accessing directory." "#E53935"
        $lblStatus.Text = "Idle."
        Reset-ScanState
        return
    }

    if ($jarFiles.Count -eq 0) {
        Append-Log "[!] No JAR files found." "#FFB74D"
        $lblStatus.Text = "Idle."
        Reset-ScanState
        return
    }

    $total = $jarFiles.Count
    Append-Log "Found $total JAR files to analyze.`r`n" "#81C784"

    $flaggedCount = 0
    $obfCount = 0

    for ($i = 0; $i -lt $total; $i++) {
        if ($global:stopScan) {
            Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
            Reset-ScanState
            return
        }
        $jar = $jarFiles[$i]

        try {
            $lblStatus.Text = "Scanning ($($i+1)/$total): $($jar.Name)"
            [System.Windows.Forms.Application]::DoEvents()
        } catch {
            $global:stopScan = $true
            Reset-ScanState
            return
        }

        if ($global:stopScan) {
            Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
            Reset-ScanState
            return
        }

        $modRes = Invoke-ModScan -FilePath $jar.FullName
        $obfRes = Invoke-ObfuscationScan -FilePath $jar.FullName

        $isFlagged = ($modRes.Patterns.Count -gt 0 -or $modRes.Strings.Count -gt 0 -or $modRes.Fullwidth.Count -gt 0)
        $isObfuscated = ($obfRes.Count -gt 0)

        if ($isFlagged) {
            $flaggedCount++
            Append-Log " [FLAGGED] $($jar.Name)" "#E53935" -Bold
            foreach ($p in $modRes.Patterns) { Append-Log "    Pattern: $p" "#EF5350" }
            foreach ($s in $modRes.Strings) { Append-Log "    String: $s" "#FFB74D" }
            foreach ($f in $modRes.Fullwidth) { Append-Log "    Fullwidth: $f" "#9E9E9E" }
            Append-Log ""
        }

        if ($isObfuscated) {
            $obfCount++
            Append-Log " [OBFUSCATED] $($jar.Name)" "#FFF176" -Bold
            foreach ($o in $obfRes) { Append-Log "    Flag: $o" "#AAAAAA" }
            Append-Log ""
        }
    }

    Append-Log " JVM PROCESS SCAN" "#64B5F6" -Bold
    Invoke-JvmScan

    if ($global:stopScan) {
        Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
        Reset-ScanState
        return
    }

    $stopwatch.Stop()
    Append-Log " SCAN COMPLETE!" "#81C784" -Bold
    Append-Log " Total Scanned: $total" "#FFFFFF"
    Append-Log " Flagged Mods:  $flaggedCount" "#E53935"
    Append-Log " Obfuscated:    $obfCount" "#FFF176"
    Append-Log " Elapsed:       $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s" "#888888"

    $lblStatus.Text = "Scan Complete."
    Reset-ScanState
})

$Form.ShowDialog() | Out-Null
