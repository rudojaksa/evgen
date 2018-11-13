
[36mNAME[0m
    evgen - event generator

[36mUSAGE[0m
    evgen [[36mOPTIONS[0m] [[36mNUM[0m]

[36mDESCRIPTION[0m
    Evgen generates a stream of NUM events.  Infinite loop without NUM specified.
    Events consist from action and context.  Events generation policies are:

    1. random - choose any random event,
    2. steps - loop from the event-1 to the event-N and again,
    3. from file - wait until the event number is provided in the file.

[36mOPTIONS[0m
          [36m-h[0m  This help.
          [36m-v[0m  Verbose execution using [0mSTDERR[0m.

     [36m-t=MSEC[0m  Interval between events in milliseconds [90m(default none).[0m
         [36m-nt[0m  No timestamps.
         [36m-nm[0m  No meta-information header.

      [36m-e=NUM[0m  Number of possible events [90m(default 2: event 1 and event 2).[0m
      [36m-c=NUM[0m  Dimensionality of the context vector [90m(default 0 = no_context).[0m
     [36m-cn=NUM[0m  Number of context states [90m(default 2: 0 and 1).[0m
  [36m-i=NUM,NUM[0m  Interval of event IDs [90m(default [1,No_of_events]).[0m
 [36m-ci=NUM,NUM[0m  Interval of context values [90m(default [0,Context_states-1]).[0m

random policy:
          [36m-r[0m  Choose the event randomly [90m(default).[0m
         [36m-cr[0m  Choose the context randomly [90m(default).[0m
      [36m-r=NUM[0m  Produce the same random event NUM times.
     [36m-cr=NUM[0m  Produce the same random context NUM times.

steps policy:
      [36m-s=NUM[0m  Cycle events in steps with the NUM events in each.
     [36m-cs=NUM[0m  Cycle context in steps with the NUM events in each.
          [36m-s[0m  Steps of 100 events.
         [36m-cs[0m  Steps of 10 contexts.

from-file policy:
     [36m-f=FILE[0m  File to read the event ID from.  After any close operation
              the file will be inspected.  The last number from the last
              line will be used as the requested event ID.

[36mMETA-INFORMATION[0m
    Comment on the first line in output is used to indicate columns names:

        [36mdate[0m  ISO 8601 current local date
        [36mtime[0m  ISO 8601 current local time
          [36ma1[0m  actions one [90m(the 1st dimension of actions vector)[0m
          [36ma2[0m  actions two [90m(the 2nd dimension of actions vector)[0m
          [36mc1[0m  context one [90m(the 1st dimension of context vector)[0m
          [36mc2[0m  context two [90m(the 2nd dimension of context vector)[0m

[36mEXAMPLES[0m
    evgen 


[36mVERSION[0m
    evgen.0.3 (c) R.Jaksa 2018 GPLv3

