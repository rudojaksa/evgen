### NAME
evgen - event generator

### USAGE
       evgen [OPTIONS] [NUM]

### DESCRIPTION
Evgen generates a stream of NUM events, or infinite loop without NUM specified.
Events consist from action and context.  Events generation policies are:

1. random - choose any random event,
2. steps - loop from the event-1 to the event-N and again,
3. from file - wait until the event number is provided in the file.

### OPTIONS
             -h  This help.
             -v  Verbose execution using STDERR.
   
        -t=MSEC  Interval between events in milliseconds (default none, 100 wo NUM).
            -nt  No timestamps.
            -nm  No meta-information header.
   
         -e=NUM  Number of possible events (default 2: event 1 and event 2).
         -c=NUM  Dimensionality of the context vector (default 0 = no_context).
        -cn=NUM  Number of context states (default 2: 0 and 1).
     -i=NUM,NUM  Interval of event IDs (default [1,No_of_events]).
    -ci=NUM,NUM  Interval of context values (default [0,Context_states-1]).

#### random policy:
             -r  Choose the event randomly (default).
            -cr  Choose the context randomly (default).
         -r=NUM  Produce the same random event NUM times.
        -cr=NUM  Produce the same random context NUM times.

#### steps policy:
         -s=NUM  Cycle events in steps with the NUM events in each.
        -cs=NUM  Cycle context in steps with the NUM events in each.
             -s  Steps of 100 events.
            -cs  Steps of 10 contexts.

#### from-file policy:
        -f=FILE  File to read the event ID from.  After any close operation
                 the file will be inspected.  The last number from the last
                 line will be used as the requested event ID.
       -fm=FILE  The same, but after any file modification. 

### META-INFORMATION
Comment on the first line in output is used to indicate columns names:

    date  ISO 8601 current local date
    time  ISO 8601 current local time
      a1  actions one (the 1st dimension of actions vector)
      a2  actions two (the 2nd dimension of actions vector)
      c1  context one (the 1st dimension of context vector)
      c2  context two (the 2nd dimension of context vector)

### VERSION
evgen-0.3 (c) R.Jaksa 2018 GPLv3

