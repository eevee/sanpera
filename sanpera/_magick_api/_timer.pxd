cdef extern from "magick/timer.h":
    ctypedef enum TimerState:
        UndefinedTimerState
        StoppedTimerState
        RunningTimerState

    ctypedef struct Timer:
        double start
        double stop
        double total

    ctypedef struct TimerInfo:
        Timer user
        Timer elapsed

        TimerState state

    double GetElapsedTime(TimerInfo*)
    double GetUserTime(TimerInfo*)
    double GetTimerResolution()

    unsigned int ContinueTimer(TimerInfo*)

    void GetTimerInfo(TimerInfo*)
    void ResetTimer(TimerInfo*)
