pushd "%~dp0"
go run importconst.go -p dos ^
	FILE_ATTRIBUTE_NORMAL ^
	FILE_ATTRIBUTE_REPARSE_POINT ^
	FILE_ATTRIBUTE_HIDDEN ^
	FILE_ATTRIBUTE_READONLY ^
	FILE_ATTRIBUTE_SYSTEM ^
	FILE_ATTRIBUTE_ARCHIVE ^
	CP_THREAD_ACP ^
	MOVEFILE_REPLACE_EXISTING ^
	MOVEFILE_COPY_ALLOWED ^
	MOVEFILE_WRITE_THROUGH ^
	SW_HIDE ^
	SW_MAXIMIZE ^
	SW_MINIMIZE ^
	SW_RESTORE ^
	SW_SHOW ^
	SW_SHOWDEFAULT ^
	SW_SHOWMAXIMIZED ^
	SW_SHOWMINIMIZED ^
	SW_SHOWMINNOACTIVE ^
	SW_SHOWNA ^
	SW_SHOWNOACTIVATE ^
	SW_SHOWNORMAL ^
	COINIT_APARTMENTTHREADED ^
	COINIT_MULTITHREADED ^
	COINIT_DISABLE_OLE1DDE ^
	COINIT_SPEED_OVER_MEMORY ^
	DRIVE_UNKNOWN ^
	DRIVE_NO_ROOT_DIR ^
	DRIVE_REMOVABLE ^
	DRIVE_FIXED ^
	DRIVE_REMOTE ^
	DRIVE_CDROM ^
	DRIVE_RAMDISK ^
	RESOURCE_CONNECTED ^
	RESOURCE_CONTEXT ^
	RESOURCE_GLOBALNET ^
	RESOURCE_REMEMBERED ^
	RESOURCETYPE_ANY ^
	RESOURCETYPE_DISK ^
	RESOURCETYPE_PRINT ^
	RESOURCEDISPLAYTYPE_NETWORK ^
	RESOURCEUSAGE_CONNECTABLE ^
	RESOURCEUSAGE_CONTAINER ^
	RESOURCEUSAGE_ATTACHED ^
	RESOURCEUSAGE_ALL ^
	NO_ERROR ^
	ERROR_NOT_CONTAINER ^
	ERROR_INVALID_PARAMETER ^
	ERROR_NO_NETWORK ^
	ERROR_EXTENDED_ERROR ^
	ERROR_NO_MORE_ITEMS ^
	ERROR_MORE_DATA
popd
