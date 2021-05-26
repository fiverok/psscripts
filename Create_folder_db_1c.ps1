#по вопросам касаемо скрипта пишите на kapalkin-artem@yandex.ru
#конфиги скрипта лежат на 150-160 строках

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

function GreateADGroub

{
#создаем группу безоапасности 
 
   $ADGroup = Get-ADGroup -Filter * | where {$_.name -eq $adgroupname}
    if ($ADGroup -eq $NULL)
    { 
   
        
         New-ADGroup "$adgroupname" -path $param -GroupScope DomainLocal -PassThru 
         $result = "success"
    }
# ждем подиверждения создания группы	
        WHILE  ($group_find -eq $NULL) 
        { 

           $group_find = Get-ADGroup -Filter * | where {$_.name -eq $adgroupname}
           Wait-Event -Timeout 2    
        }                        
}

function GreateDBfolder($Path,$groupname,$ACLmode,$inheritance,$inheritance2)
{
    
    #Проверка существования папки. Если существует - первый блок, если нет - второй
    if (Test-Path $Path) {

       $CountExist = $CountExist + 1
        }
    else {    
        #Создать папку, 
        New-Item -Path $Path -ItemType Directory
        #Назначение прав
        #$adgroupname
        $Args = New-Object system.security.accesscontrol.FileSystemAccessRule ($groupname,"$ACLmode", "$inheritance, $inheritance2", "None", "Allow")  # http://coolcode.ru/razdacha-prav-na-ntfs-iz-powershell/ смитри тут
        $ACL = Get-Acl $Path
        $ACL.SetAccessRule($Args)
        Set-Acl -Path $Path -AclObject $ACL
         }

}

function GrateRunfile
{

$DBrunfile = @"
[$dbname]
Connect=File="$Path";
ClientConnectionSpeed=Normal
App=Auto
WA=1
Version=8.3
"@
$DBrunfile | Out-FileUtf8NoBom $dir\access\$dbname.v8i 


$Filepath = "$dir\access\$dbname.v8i"
Setaccesfile $Filepath $adgroupname

#===========================================================#

$DBLine = @"
CommonInfoBases=$dir\access\$dbname.v8i
"@
$DBline | out-file $dir\access\1cestart.cfg -append

$Filepath = "$dir\access\1cestart.cfg"
Setaccesfile $Filepath $groupname
}


function Setaccesfile ($Filepath,$groupnamefile)   # Назначаем права на файл
 {
  $Args = New-Object system.security.accesscontrol.FileSystemAccessRule ($groupnamefile,"ReadAndExecute","Allow") 
 $ACL = Get-Acl $Filepath
 $ACL.SetAccessRule($Args)
 Set-Acl -Path $Filepath -AclObject $ACL
 }

 function Out-FileUtf8NoBom 
  {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)] [string] $LiteralPath,
    [switch] $Append,
    [switch] $NoClobber,
    [AllowNull()] [int] $Width,
    [Parameter(ValueFromPipeline)] $InputObject
  )

  #requires -version 3

  # Make sure that the .NET framework sees the same working dir. as PS
  # and resolve the input path to a full path.
  [System.IO.Directory]::SetCurrentDirectory($PWD) # Caveat: .NET Core doesn't support [Environment]::CurrentDirectory
  $LiteralPath = [IO.Path]::GetFullPath($LiteralPath)

  # If -NoClobber was specified, throw an exception if the target file already
  # exists.
  if ($NoClobber -and (Test-Path $LiteralPath)) {
    Throw [IO.IOException] "The file '$LiteralPath' already exists."
  }

  # Create a StreamWriter object.
  # Note that we take advantage of the fact that the StreamWriter class by default:
  # - uses UTF-8 encoding
  # - without a BOM.
  $sw = New-Object IO.StreamWriter $LiteralPath, $Append

  $htOutStringArgs = @{}
  if ($Width) {
    $htOutStringArgs += @{ Width = $Width }
  }

  # Note: By not using begin / process / end blocks, we're effectively running
  #       in the end block, which means that all pipeline input has already
  #       been collected in automatic variable $Input.
  #       We must use this approach, because using | Out-String individually
  #       in each iteration of a process block would format each input object
  #       with an indvidual header.
  try {
    $Input | Out-String -Stream @htOutStringArgs | % { $sw.WriteLine($_) }
  } finally {
    $sw.Dispose()
  }

  }


Add-Type -assembly System.Windows.Forms

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Создание каталога БД 1С'
$main_form.Width = 410
$main_form.Height = 175
$main_form.AutoSize = $false

$main_form.Controls.Add($Label1534)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Создать базу"
$Button1.width                   = 100
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(280,91)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$Button1.Add_Click(
{
$dbname = $TextBox1.Text

###################################
$adgroupname =   "TS1_" + $dbname
$Dir = "\\ts1\db$"                   # Путь до каталога с БД 1с
$Path = $Dir+"\DataBases\" + $dbname  
$groupname = "Domain users"
$param = "OU=Folder_Access,OU=ClientsGroups,OU=iGroups,DC=fiverok,DC=local"   ##Путь до OU с группамии безопасности 
###################################
GreateADGroub
GreateDBfolder $dir\access\ $groupname ReadAndExecute None None 
GreateDBfolder $dir\access\ $groupname ReadAndExecute None None 
GreateDBfolder $dir\DataBases\ $groupname ReadAndExecute None None
GreateDBfolder $dir\DataBases\ $groupname ReadAndExecute None None
GreateDBfolder $Path $adgroupname Modify ContainerInherit ObjectInherit
GrateRunfile

 $wshell = New-Object -ComObject Wscript.Shell
$Output = $wshell.Popup("БД Созданна")
}
)

$main_form.Controls.Add($Button1)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Название Базы"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(21,63)
$Label1.Font                     = 'Microsoft Sans Serif,10'
$main_form.Controls.Add($Label1)

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 216
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(167,57)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'
$main_form.Controls.Add($TextBox1)


$main_form.ShowDialog()


