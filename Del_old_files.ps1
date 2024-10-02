#Дата с которой сравнивать. В этом случае -15 дней от текущей даты
$date = (Get-Date).AddDays(-15)
#Путь до директории откуда удалять файлы
$path = "d:\data\public"
#Расположение отчетов 
$report = "C:\scripts\Result\file_list.txt"

#Работаем с файлами
#Вывод спписка всех файлов без  папок (в т.ч. внутри папок) старше чем значение в $date
$filelist = Get-ChildItem -Recurse -Path $path -file | Where-Object -Property CreationTime -lT $date  
$filelist  | Sort-Object -Property CreationTime | ft CreationTime ,VersionInfo | tee $report
#Удаляем файлы
#$filelist | Remove-Item 

#Работаем с каталогами
#вывод списка пустых директорий(где нет ни файлов ни директорий) старше чем дата $date 
$folderlist =  Get-ChildItem -Recurse -Path $path -Directory | Where-Object -Property LastWriteTime -lT $date | where { $_.psiscontainer -eq $true -and $_.GetFiles().count -eq 0 -and $_.GetDirectories().count -eq 0 } 
#вывод списка пустых директорий (где нет файлов, но есть директории)  старше чем дата $date 
#$folderlist =  Get-ChildItem -Recurse -Path $path -Directory | Where-Object -Property LastWriteTime -lT $date | where { $_.psiscontainer -eq $true -and $_.GetFiles().count -eq 0 } 
$folderlist | Sort-Object -Property LastWriteTime | ft LastWriteTime ,FullName | tee $report -Append
#Удаляем каталоги
#$folderlist | Remove-Item
