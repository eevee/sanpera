from sanpera._magick_api cimport _common

cdef extern from "magick/exception.h":
    ### Enums for exception type hierarchy
    # XXX is BaseType actually needed?
    ctypedef enum ExceptionBaseType:
        UndefinedExceptionBase
        ExceptionBase
        ResourceBase
        ResourceLimitBase
        TypeBase
        AnnotateBase
        OptionBase
        DelegateBase
        MissingDelegateBase
        CorruptImageBase
        FileOpenBase
        BlobBase
        StreamBase
        CacheBase
        CoderBase
        ModuleBase
        DrawBase
        RenderBase
        ImageBase
        WandBase
        TemporaryFileBase
        TransformBase
        XServerBase
        X11Base
        UserBase
        MonitorBase
        LocaleBase
        DeprecateBase
        RegistryBase
        ConfigureBase

    # XXX this clobbers a couple python builtin names; doubt that matters though
    ctypedef enum ExceptionType:
        UndefinedException
        EventException
        ExceptionEvent
        ResourceEvent
        ResourceLimitEvent
        TypeEvent
        AnnotateEvent
        OptionEvent
        DelegateEvent
        MissingDelegateEvent
        CorruptImageEvent
        FileOpenEvent
        BlobEvent
        StreamEvent
        CacheEvent
        CoderEvent
        ModuleEvent
        DrawEvent
        RenderEvent
        ImageEvent
        WandEvent
        TemporaryFileEvent
        TransformEvent
        XServerEvent
        X11Event
        UserEvent
        MonitorEvent
        LocaleEvent
        DeprecateEvent
        RegistryEvent
        ConfigureEvent

        WarningException
        ExceptionWarning
        ResourceWarning
        ResourceLimitWarning
        TypeWarning
        AnnotateWarning
        OptionWarning
        DelegateWarning
        MissingDelegateWarning
        CorruptImageWarning
        FileOpenWarning
        BlobWarning
        StreamWarning
        CacheWarning
        CoderWarning
        ModuleWarning
        DrawWarning
        RenderWarning
        ImageWarning
        WandWarning
        TemporaryFileWarning
        TransformWarning
        XServerWarning
        X11Warning
        UserWarning
        MonitorWarning
        LocaleWarning
        DeprecateWarning
        RegistryWarning
        ConfigureWarning

        ErrorException
        ExceptionError
        ResourceError
        ResourceLimitError
        TypeError
        AnnotateError
        OptionError
        DelegateError
        MissingDelegateError
        CorruptImageError
        FileOpenError
        BlobError
        StreamError
        CacheError
        CoderError
        ModuleError
        DrawError
        RenderError
        ImageError
        WandError
        TemporaryFileError
        TransformError
        XServerError
        X11Error
        UserError
        MonitorError
        LocaleError
        DeprecateError
        RegistryError
        ConfigureError

        FatalErrorException
        ExceptionFatalError
        ResourceFatalError
        ResourceLimitFatalError
        TypeFatalError
        AnnotateFatalError
        OptionFatalError
        DelegateFatalError
        MissingDelegateFatalError
        CorruptImageFatalError
        FileOpenFatalError
        BlobFatalError
        StreamFatalError
        CacheFatalError
        CoderFatalError
        ModuleFatalError
        DrawFatalError
        RenderFatalError
        ImageFatalError
        WandFatalError
        TemporaryFileFatalError
        TransformFatalError
        XServerFatalError
        X11FatalError
        UserFatalError
        MonitorFatalError
        LocaleFatalError
        DeprecateFatalError
        RegistryFatalError
        ConfigureFatalError


    # Main exception type
    ctypedef struct ExceptionInfo:
        # Description of the exception
        ExceptionType severity
        char* reason
        char* description

        # Value of errno when the exception was thrown
        int error_number

        # Source of the exception
        char* module
        char* function
        unsigned long line

    # Exception handler types (these are funcrefs)
    # XXX what's the syntax for this
    ctypedef void (*ErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*FatalErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*WarningHandler)(ExceptionType, char*, char*)
    #ctypedef FatalErrorHandler
    #ctypedef WarningHandler

    char* GetLocaleExceptionMessage(ExceptionType, char *)
    char* GetLocaleMessage(char *)

    ErrorHandler SetErrorHandler(ErrorHandler)
    FatalErrorHandler SetFatalErrorHandler(FatalErrorHandler)
    WarningHandler SetWarningHandler(WarningHandler)

    void CatchException(ExceptionInfo *)
    void CopyException(ExceptionInfo *copy, ExceptionInfo *original)
    void DestroyExceptionInfo(ExceptionInfo *)
    void GetExceptionInfo(ExceptionInfo *)
    void MagickError(ExceptionType,char *,char *)
    void MagickFatalError(ExceptionType,char *,char *)
    void MagickWarning(ExceptionType,char *,char *)
    void _MagickError(ExceptionType,char *,char *)
    void _MagickFatalError(ExceptionType,char *,char *)
    void _MagickWarning(ExceptionType,char *,char *)
    void SetExceptionInfo(ExceptionInfo *,ExceptionType)
    void ThrowException(ExceptionInfo *,ExceptionType,char *,char *)
    void ThrowLoggedException(ExceptionInfo *exception, ExceptionType severity,
        char *reason,char *description, char *module,
        char *function, unsigned long line)

