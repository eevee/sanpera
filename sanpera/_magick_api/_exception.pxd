from sanpera._magick_api cimport _common

cdef extern from "magick/exception.h":
    # XXX this clobbers a couple python builtin names; doubt that matters though
    ctypedef enum ExceptionType:
        UndefinedException

        WarningException
        ResourceLimitWarning
        TypeWarning
        OptionWarning
        DelegateWarning
        MissingDelegateWarning
        CorruptImageWarning
        FileOpenWarning
        BlobWarning
        StreamWarning
        CacheWarning
        CoderWarning
        FilterWarning
        ModuleWarning
        DrawWarning
        ImageWarning
        WandWarning
        RandomWarning
        XServerWarning
        MonitorWarning
        RegistryWarning
        ConfigureWarning
        PolicyWarning

        ErrorException
        ResourceLimitError
        TypeError
        OptionError
        DelegateError
        MissingDelegateError
        CorruptImageError
        FileOpenError
        BlobError
        StreamError
        CacheError
        CoderError
        FilterError
        ModuleError
        DrawError
        ImageError
        WandError
        RandomError
        XServerError
        MonitorError
        RegistryError
        ConfigureError
        PolicyError

        FatalErrorException
        ResourceLimitFatalError
        TypeFatalError
        OptionFatalError
        DelegateFatalError
        MissingDelegateFatalError
        CorruptImageFatalError
        FileOpenFatalError
        BlobFatalError
        StreamFatalError
        CacheFatalError
        CoderFatalError
        FilterFatalError
        ModuleFatalError
        DrawFatalError
        ImageFatalError
        WandFatalError
        RandomFatalError
        XServerFatalError
        MonitorFatalError
        RegistryFatalError
        ConfigureFatalError
        PolicyFatalError


    # Main exception type
    ctypedef struct ExceptionInfo:
        # Description of the exception
        ExceptionType severity
        char* reason
        char* description

        # Value of errno when the exception was thrown
        int error_number


    # Exception handler function reference types
    ctypedef void (*ErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*FatalErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*WarningHandler)(ExceptionType, char*, char*)

    ErrorHandler SetErrorHandler(ErrorHandler)
    FatalErrorHandler SetFatalErrorHandler(FatalErrorHandler)
    WarningHandler SetWarningHandler(WarningHandler)


    ExceptionInfo* AcquireExceptionInfo()
    ExceptionInfo* DestroyExceptionInfo(ExceptionInfo*)

    char* GetExceptionMessage(int)
    char* GetLocaleExceptionMessage(ExceptionType, char*)

    void CatchException(ExceptionInfo*)
    void ClearMagickException(ExceptionInfo*)
    void GetExceptionInfo(ExceptionInfo*)
    void InheritException(ExceptionInfo*, ExceptionInfo*)
    void MagickError(ExceptionType, char*, char*)
    void MagickFatalError(ExceptionType, char*, char*)
    void MagickWarning(ExceptionType, char*, char*)
