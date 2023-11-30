require 'fiddle/import'

module LogManager
  module Utils
    module WinKernel32
      extend Fiddle::Importer
      dlload 'kernel32.dll'
      # https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfileattributesexw
      extern 'int GetFileAttributesExW(wchar*, int, void*)'

      # https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ne-minwinbase-get_fileex_info_levels
      GetFileExInfoStandard = 0
      GetFileExMaxInfoLevel = 1

      # https://learn.microsoft.com/en-us/windows/win32/api/fileapi/ns-fileapi-win32_file_attribute_data
      # https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
      FileAttributeData = struct(
        [
          'unsigned long dwFileAttributes',
          'unsigned long ftCreationTime_dwLowDateTime',
          'unsigned long ftCreationTime_dwHighDateTime',
          'unsigned long ftLastAccessTime_dwLowDateTime',
          'unsigned long ftLastAccessTime_dwHighDateTime',
          'unsigned long ftLastWriteTime_dwLowDateTime',
          'unsigned long ftLastWriteTime_dwHighDateTime',
          'unsigned long nFileSizeHigh',
          'unsigned long nFileSizeLow',
        ])

      # https://learn.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
      FILE_ATTRIBUTE_READONLY              = 0x00000001
      FILE_ATTRIBUTE_HIDDEN                = 0x00000002
      FILE_ATTRIBUTE_SYSTEM                = 0x00000004
      FILE_ATTRIBUTE_DIRECTORY             = 0x00000010
      FILE_ATTRIBUTE_ARCHIVE               = 0x00000020
      FILE_ATTRIBUTE_DEVICE                = 0x00000040
      FILE_ATTRIBUTE_NORMAL                = 0x00000080
      FILE_ATTRIBUTE_TEMPORARY             = 0x00000100
      FILE_ATTRIBUTE_SPARSE_FILE           = 0x00000200
      FILE_ATTRIBUTE_REPARSE_POINT         = 0x00000400
      FILE_ATTRIBUTE_COMPRESSED            = 0x00000800
      FILE_ATTRIBUTE_OFFLINE               = 0x00001000
      FILE_ATTRIBUTE_NOT_CONTENT_INDEXED   = 0x00002000
      FILE_ATTRIBUTE_ENCRYPTED             = 0x00004000
      FILE_ATTRIBUTE_INTEGRITY_STREAM      = 0x00008000
      FILE_ATTRIBUTE_VIRTUAL               = 0x00010000
      FILE_ATTRIBUTE_NO_SCRUB_DATA         = 0x00020000
      FILE_ATTRIBUTE_EA                    = 0x00040000
      FILE_ATTRIBUTE_PINNED                = 0x00080000
      FILE_ATTRIBUTE_UNPINNED              = 0x00100000
      FILE_ATTRIBUTE_RECALL_ON_OPEN        = 0x00040000
      FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = 0x00400000

      # https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
      extern 'unsigned long GetLastError()'
    end
  end
end
